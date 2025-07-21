#!/usr/bin/env bash

### This will (re)generate Images.lock for the top-level addon-operator Helm chart from Images.lock files from the modules folder.
### This is intended to be run on every build to ensure that addon-operator helm-chart contains full list of images needed for it's modules in the annotations.

./utils/yq eval-all '. as $item ireduce ({}; . *+ $item )' modules/*/Images.lock chart/Images.lock.template > chart/Images.lock
./utils/yq -i ".images |= unique_by(.image)" chart/Images.lock