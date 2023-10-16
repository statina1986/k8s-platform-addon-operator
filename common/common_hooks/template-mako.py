#!/usr/bin/env python3
import glob, mako.template, json
from common.python.hooks import *
from common.python.k8s import *


class MyHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
beforeHelm: 1
""")

    def handle_binding(self, binding):
        match(binding):
            case StartupHook(values_json, configValues_json):
                cm = get_config_map("platform", "addon-operator")                
                directory = os.getcwd()
                for file in glob.glob(os.path.dirname(__file__)+"/../**/*.mako", recursive=True):
                    print(file)
                    content = open(file).read()
                    template = mako.template.Template(content)
                    result = template.render(values=values_json, addon_operator=cm.data)
                    output = open(file.removesuffix(".mako"), "w")
                    output.write(result)
                    output.close()
            case _:
                print("Unknown hook data")


hook = MyHook()
hook.handle_hook()
