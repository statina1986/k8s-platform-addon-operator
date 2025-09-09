#!/usr/bin/env bash

### This will (re)generate Images.lock for the modules which do not contain Images.lock files yet.
### Use this script as part of dependencies upgrade workflow.
### If some modules have changes in the images annotations delete Images.lock files for those modules and run this script to regenerate lock files.

dirs=(${0%/*}/modules/*)

for val in ${dirs[@]}; do
    if [[ ! -f "$val/Images.lock" ]] ; then
        ### With this we can define custom 'images-key' annotation in Chart.yaml in order to override key from which images annotations are taken
        imagesKey=( `./utils/yq '.annotations.images-key // "images"' "$val/Chart.yaml"` )
        ./utils/dt images lock --plain --platforms linux/amd64 --platforms linux/arm64 --annotations-key "$imagesKey" "$val" 
    fi  
done

### This will (re)generate Images.lock for the top-level addon-operator Helm chart from Images.lock files from the modules folder.
### This is intended to be run on every build to ensure that addon-operator helm-chart contains full list of images needed for it's modules.
./utils/yq eval-all '. as $item ireduce ({}; . *+ $item )' modules/*/Images.lock chart/Images.lock.template > chart/Images.lock
./utils/yq -i ".images |= unique_by(.image)" chart/Images.lock