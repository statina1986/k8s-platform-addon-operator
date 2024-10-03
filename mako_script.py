#!/usr/bin/env python3
import glob
import mako.template
import json
import os
import sys
import yaml


values_file = open(os.path.dirname(__file__)+"/values-default.yaml")

values_yaml = yaml.safe_load(values_file)

# print(values_yaml)

if (sys.argv.__len__() > 0):
    file = sys.argv[1]+"/values.yaml.mako"
    content = open(file).read()
    template = mako.template.Template(content)
    result = template.render(values=values_yaml, addon_operator=values_yaml)
    output_file_name = file.removesuffix(".mako")
    if os.path.exists(output_file_name):
        os.remove(output_file_name)
    output = open(output_file_name, "w")
    output.write(result)
    output.close()
else:
    for file in glob.glob(os.path.dirname(__file__)+"/modules/**/values.yaml.mako", recursive=True):
        print(file)
        content = open(file).read()
        template = mako.template.Template(content)
        result = template.render(values=values_yaml, addon_operator=values_yaml)
        output_file_name = file.removesuffix(".mako")
        if os.path.exists(output_file_name):
            os.remove(output_file_name)
        output = open(output_file_name, "w")
        output.write(result)
        output.close()
