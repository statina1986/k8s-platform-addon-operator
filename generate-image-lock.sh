#!/usr/bin/env bash

dirs=(${0%/*}/modules/*)

for val in ${dirs[@]}; do
    helm dt images lock "$val"    
done

yq eval-all '. as $item ireduce ({}; . *+ $item )' chart/Images.lock.template modules/*/Images.lock > chart/Images.lock

rm  modules/*/Images.lock