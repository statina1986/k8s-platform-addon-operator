#!/usr/bin/env bash

dirs=(${0%/*}/modules/*)

for val in ${dirs[@]}; do
    if [[ ! -f "$val/Images.lock" ]] ; then
        helm dt images lock --platforms linux/amd64 --platforms linux/arm64 "$val" 
    fi  
done

yq eval-all '. as $item ireduce ({}; . *+ $item )' modules/*/Images.lock chart/Images.lock.template > chart/Images.lock