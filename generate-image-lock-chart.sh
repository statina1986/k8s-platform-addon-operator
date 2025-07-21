#!/usr/bin/env bash

./utils/yq eval-all '. as $item ireduce ({}; . *+ $item )' modules/*/Images.lock chart/Images.lock.template > chart/Images.lock
./utils/yq -i ".images |= unique_by(.image)" chart/Images.lock