#!/usr/bin/env bash
changed_files=( `git diff --name-only HEAD HEAD~1` )

for file in ${changed_files[@]}; do    
    if [[ $file == *"Images.lock"* && -f $file ]] ; then
        module=${file%"/Images.lock"}
        echo "Detected changed Images.lock for $module. Updating images"
        ./utils/dt --plain images pull $module
        ./utils/dt --plain charts relocate $module $1
        ./utils/dt --plain images push $module
        git restore $file
        git restore "$module/Chart.yaml"
    fi  
done


commit_comment="$(git log --format=%B -n 1)"
echo $commit_comment

if [[ $commit_comment == *"other: push-images"* ]]; then
echo $commit_comment
    ./utils/dt --plain images pull chart
    ./utils/dt --plain charts relocate chart $1
    ./utils/dt --plain images push chart
fi