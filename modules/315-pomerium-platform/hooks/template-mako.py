#!/usr/bin/env python3
import glob, mako.template
from common.python.hooks import *


class MyHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
onStartup: 1
""")

    def handle_binding(self, binding):
        match(binding):
            case StartupHook(values_json, configValues_json):
                directory = os.getcwd()
                for file in glob.glob(os.path.dirname(__file__)+"/../**/*.mako", recursive=True):
                    print(file)
                    content = open(file).read()
                    template = mako.template.Template(content)
                    result = template.render(values=values_json)
                    output = open(file.removesuffix(".mako"), "w")
                    output.write(result)
                    output.close()
            case _:
                print("Unknown hook data")


hook = MyHook()
hook.handle_hook()
