#!/usr/bin/env python3
import glob
import mako.template
import json
from common.python.hooks import *
from common.python.k8s import *
from common.python.variables import *


class MyHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
onStartup: 1
""")

    def handle_binding(self, binding):
        match(binding):
            case StartupHook(values_json, configValues_json):
                cm = get_config_map(ADDON_OPERATOR_NAMESPACE, "addon-operator")
                directory = os.getcwd()
                for file in glob.glob(os.path.dirname(__file__)+"/../**/*.mako", recursive=True):
                    print(file)
                    content = open(file).read()
                    template = mako.template.Template(content)
                    result = template.render(values=values_json, addon_operator=cm.data)
                    output_file_name = file.removesuffix(".mako")
                    if os.path.exists(output_file_name):
                        os.remove(output_file_name)
                    output = open(output_file_name, "w")
                    output.write(result)
                    output.close()
            case _:
                print("Unknown hook data")


hook = MyHook()
hook.handle_hook()
