#!/usr/bin/env bash
commit_comment=( `git log --format=%B -n 1` )

if [[ $commit_comment == *"other: push-images"* ]]; then
    
    dirs=(${0%/*}/modules/*)
    for val in ${dirs[@]}; do
        helm dt images lock "$val" $1
    done

    yq eval-all '. as $item ireduce ({}; . *+ $item )' chart/Images.lock.template modules/*/Images.lock > chart/Images.lock
    rm  modules/*/Images.lock

    helm dt images pull chart

    helm dt charts relocate chart $2
    
    helm dt images push chart
fi