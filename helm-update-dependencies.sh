#!/usr/bin/env bash

dirs=(${0%/*}/modules/*/charts/*)
for val in ${dirs[@]}; do
    if [[ ! -f "$val/Chart.noupdate" ]] ; then
        helm dependency update --skip-refresh "$val"
    else
        echo "skipped updating $val"
    fi
done
