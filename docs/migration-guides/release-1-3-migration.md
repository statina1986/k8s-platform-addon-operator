# Release 1.3 migration guide

## Kafka 

This release contains latest version of Strimzi which supports both Zookeeper and KRaft. In this version, migration to NodePools and KRaft should be performed.
For reference see: 
* https://strimzi.io/blog/2023/08/14/kafka-node-pools-introduction/
* https://strimzi.io/blog/2024/03/21/kraft-migration/
* https://strimzi.io/blog/2024/03/22/strimzi-kraft-migration/

> **Breaking Change**: Default `kafka-cluster` is configured in KRaft mode with 2 NodePools: `kafka` (for brokers) and `controller` (for controllers)

If your deployments were using Kafka in Zookeeper mode, then you need to plan migration to KRaft. 

#### Migration procedure assuming default `kafka-cluster` exist in Zookeeper mode:
1. Familiarize youself with NodePools and KRaft migration approach (see links to the reference blogposts earlier).
2. Learn how default `kafka-cluster` resource is configured in the default [values.yaml](../../modules/220-kafka-platform/values.yaml.mako) 
3. Review and Prepare your config files for Kafka upgrade and the introduction of first NodePool (broker role). We do not migrate to KRaft in this step yet.
	- Make sure that you have `strimziHelmVersion` set to 0.45.1 and kafka version set to 3.9.1. Those are default values in the Platform 1.3 version, but your particular configuration might have overrides.
	
	```yaml
    kafkaPlatformEnabled: "true"
    kafkaPlatform:
      strimziHelmVersion: 0.45.1
      clusters:
        kafka-cluster:
          spec:
            kafka:
              version: 3.9.1
	```
	
	- Enable `kafka` (broker role) NodePool and disable `controller` (controller role) NodePool in the cluster. Set `spec` (e.g. storage size, replicas) of the NodePools according to the existing deployment. Disable KRaft migration by setting `strimzi.io/kraft: disabled` annotation.

	```yaml
      clusters:
        kafka-cluster:
          annotations:
            strimzi.io/kraft: disabled
          enabled: true
          nodePools:
            kafka:
              enabled: true
              spec:
                storage:
                  type: persistent-claim
                  size: 100Gi
                  deleteClaim: false
            controller:
              enabled: false
	```
	- Copy `zookeeper` definition because it is not configured in the default `kafka-cluster` anymore.
	```yaml
      kafkaPlatform:
      strimziHelmVersion: 0.45.1
      clusters:
        kafka-cluster:
          zookeeper:
            <zookeper configuration copied here>
	```	
4. Deploy new configuration to the cluster. Some restarts will happen on all the kafka/strimzi pods due to Kafka version upgrade and introduction of brokers NodePool. After that, we will have our cluster migrated to NodePools, which is the first step for KRaft migration.

5. After migration, we will have a new set of kafka brokers with the name kafka-cluster-kafka-cluster-kafka-X. That will cause the creation of new PVC's instead of reusing the existing ones from the old cluster. We will perform a set of operations to use them.

    - Pause reconciliation:

    ```kubectl annotate --overwrite Kafka kafka-cluster strimzi.io/pause-reconciliation="true" -n platform```

    - Terminate strimzipodset and pods.

    ```kubectl delete StrimziPodSet kafka-cluster-kafka-cluster-kafka -n platform```

    - Set Retain on the old cluster PV's (persistentVolumeReclaimPolicy)

    - Delete the old brokers PVC's (PV status will change to released)

    - Delete the ClaimRef section from the PV's (status will change to available)

    - Create new PVC's manually pointing to existing PV (spec.volumeName)

    - Start reconciliation

    ```kubectl annotate --overwrite Kafka kafka-cluster strimzi.io/pause-reconciliation="false" -n platform```

    - Pod set will pop up and kafka brokers will back online.

6. Migrate to KRaft.
    - First we will enable the controller nodepool by just setting the enabled: true and redeploying.

    ```yaml
    controller:
      enabled: true
    ```
    This will create the controller nodepool but it won't work because controllers are only made for KRaft.
    - Add the next annotation with kubectl.
    ```
    kubectl -n platform annotate kafka kafka-cluster strimzi.io/kraft="migration" --overwrite
    ```
    This will trigger the controller nodepool creation and also some rounds of rolling restarts will happen.

    - We could monitor the migration status with the next command.
    ```
    kubectl get kafka kafka-cluster -n platform -w
    ```
    We will wait for output to be something like : 
    ```
	NAME            DESIRED KAFKA REPLICAS   DESIRED ZK REPLICAS   READY   METADATA STATE       WARNINGS
	kafka-cluster   1                        1                     True    KRaftPostMigration   True
    ```
    - Finally, we will enable KRaft by adding next annotation.
    ```
    kubectl -n platform annotate kafka kafka-cluster strimzi.io/kraft="enabled" --overwrite
    ```
    A final round of rolling restarts will happen, and the migration will be done when the cluster status shows the next state
    ```
	NAME            DESIRED KAFKA REPLICAS   DESIRED ZK REPLICAS   READY   METADATA STATE   WARNINGS
	kafka-cluster   1                        3                     True    KRaft            True
    ```
7. Prepare configuration for migrated Kafka. Remove the lines which were disabling `controller` NodePool and KRaft annotation. Most ofthe configuration should be taken from default values now. Make sure your broker nodepool has correct configuration (mainly storage , replicas, resources)
	```yaml
    clusters:
      kafka-cluster:
        spec:
          <here goes details of your Kafka cluster>
        nodePools:
          kafka:
            spec:
              storage:
                type: persistent-claim
                size: 100Gi
                deleteClaim: false
    ```

8. Deploy to have a final state aligned

#### For new Kafka deployments:
1. Configure cluster with needed nodepools and resources (e.g. storage). KRaft and nodepools enabled by default.
	```yaml
    kafkaPlatform:
      clusters:
        kafka-cluster:
          nodePools:
            kafka:
              spec:
                replicas: 2
                storage:
                  size: 1000Gi
    ```

## CNPG
In this version all cluster definitions were removed from `cnpg-platform` module and `qvantel-glue` should be used instead. All cluster definitions should be migrated to `qvantel-glue`. There are steps to avoid data loss:
1. Manually change ownership of the cluster resources from `cnpg-platform` to `qvantel-glue` with helm annotations. Otherwise cluster resources will be deleted by new `cnpg-platform` module.
2. Migrate cluster definitions from `cnpg-platform` to `qvantel-glue` in the values files. Check documentation of `qvantel-glue` module for current up-to-date configuration options and defaults.
3. Deploy new platform configuration. Testing this procedure in lower environments first is highly recommended. 

## MariaDB
* Default cluster definitions were updated to be Galera cluster with max-scale. Existing cluster will require logical backup/restore migration procedure.

* In this version all cluster definitions were removed from `mariadb-operator-platform` module and `qvantel-glue` should be used instead. All cluster definitions should be migrated to `qvantel-glue`. There are steps to avoid data loss:
  1. Manually change ownership of the cluster resources from `mariadb-operator-platform` to `qvantel-glue` with helm annotations. Otherwise cluster resources will be deleted by new `mariadb-operator-platform` module.
  2. Migrate cluster definitions from `mariadb-operator-platform` to `qvantel-glue` in the values files. Check documentation of `qvantel-glue` module for current up-to-date configuration options and defaults.
  3. Deploy new platform configuration. Testing this procedure in lower environments first is highly recommended. 

