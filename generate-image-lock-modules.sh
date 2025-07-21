#!/usr/bin/env bash

### This will (re)generate Images.lock for the modules which do not contain Images.lock files yet.
### Use this script as part of dependencies upgrade workflow.
### If some modules have changes in the images annotations delete Images.lock files for those modules and run this script to regenerate lock files.

dirs=(${0%/*}/modules/*)

for val in ${dirs[@]}; do
    if [[ ! -f "$val/Images.lock" ]] ; then
        ./utils/dt images lock --plain --platforms linux/amd64 --platforms linux/arm64 "$val" 
    fi  
done