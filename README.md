
# K8S Platform Services

This repo conatins implementation of **K8S Platform Services** based on the [addon-operator](https://github.com/flant/addon-operator)

>
> Please check [addon-operator](https://github.com/flant/addon-operator) documentation first
> 

## Dependencies subcharts
**addon-operator** has one significant limitation - it is hard to use external helm charts as dependencies (see https://github.com/flant/addon-operator/issues/153). Main issue is that values files in **addon-operator**  has special structure which is not compatible with subcharts values convention in Helm.

In order to overcome this it ispossible to introduce empty subchart named as module name in camelCase  as first dependency of the module. All external dependencies should be placed as subcharts of that empty subchart.
See example in module "130-cassandra-platform"

```
my-super-module/
    |--charts/
        |--mySuperModule/
            |--Chart.yaml (should define needed external dependencies)
    |--hooks/
        |--helm-update-dependencies.sh (hook which will download external dependencies required)
    |--Chart.yaml (has single dependency - "mySuperModule")
    |--values.yaml (now structure of values yaml is alligned with addon-operator)
```