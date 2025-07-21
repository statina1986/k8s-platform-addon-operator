#!/usr/bin/env bash

dirs=(${0%/*}/modules/*)

for val in ${dirs[@]}; do
    if [[ ! -f "$val/Images.lock" ]] ; then
        ./utils/dt images lock --plain --platforms linux/amd64 --platforms linux/arm64 "$val" 
    fi  
done

./utils/yq eval-all '. as $item ireduce ({}; . *+ $item )' modules/*/Images.lock chart/Images.lock.template > chart/Images.lock
./utils/yq -i ".images |= unique_by(.image)" chart/Images.lock