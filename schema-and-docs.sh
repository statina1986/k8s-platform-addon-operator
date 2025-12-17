#!/usr/bin/env bash

### This will generate README.md and values.schema.json for modules where README.md.gotmpl is present (it is considered such modules are annotated).
### Requires python3 (and packages pyyaml, mako), helm-schema, helm-docs to be present on machine.

dirs=(${0%/*}/modules/*)

for val in ${dirs[@]}; do
    if [[ -f "$val/README.md.gotmpl" ]] ; then
        
        [ -f "$val/values.yaml.mako" ] && ./mako_script.py $val
        helm-schema -n -c $val -k required -k additionalProperties 
        helm-docs -c $val --ignore-non-descriptions --template-files=../../_helm-docs-templates.gotmpl --template-files=README.md.gotmpl
        [ -f "$val/values.yaml.mako" ] && rm $val/values.yaml
    fi
done

./generate_doc_tables.py