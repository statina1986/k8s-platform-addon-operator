#!/usr/bin/env python3
import glob
import mako.template
import json
from common.python.hooks import *
from common.python.k8s import *


class MyHook(Hook):
    def __init__(self):
        super().__init__("""
configVersion: v1
beforeHelm: 2
""")

    def handle_binding(self, binding):
        pass
        match(binding):
            case BeforeHelmHook(values_json, configValues_json):
                path = os.path.dirname(__file__) + \
                    "/../charts/kafkaPlatform/charts/"
                files = glob.glob(path+'/*')
                for f in files:
                    if "strimzi-kafka-operator-helm-3-chart" in f:
                        os.remove(f)
                        
                if (values_json['kafkaPlatform']['strimziHelmVersion'] == '0.43.0'):
                    source = os.path.dirname(__file__) + "/../subcharts/strimzi-kafka-operator-helm-3-chart-0.43.0.tgz"
                    os.popen('cp ' + source + ' ' + path)
                else:
                    source = os.path.dirname(__file__) + "/../subcharts/strimzi-kafka-operator-helm-3-chart-0.45.1.tgz"
                    os.popen('cp ' + source + ' ' + path)
            case _:
                print("Unknown hook data")


hook = MyHook()
hook.handle_hook()
