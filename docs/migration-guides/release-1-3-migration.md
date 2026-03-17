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
4. Set Retain on the old cluster Kafka PV's (persistentVolumeReclaimPolicy) to not loose the data. 

5. Deploy new configuration to the cluster. Some restarts will happen on all the kafka/strimzi pods due to Kafka version upgrade and introduction of brokers NodePool. After that, we will have our cluster migrated to NodePools, which is the first step for KRaft migration.

6. After migration, we will have a new set of kafka brokers with the name kafka-cluster-kafka-cluster-kafka-X. That will cause the creation of new PVC's instead of reusing the existing ones from the old cluster. We will perform a set of operations to use them.

    - Pause reconciliation:

    ```kubectl annotate --overwrite Kafka kafka-cluster strimzi.io/pause-reconciliation="true" -n platform```

    - Terminate strimzipodset and pods.

    ```kubectl delete StrimziPodSet kafka-cluster-kafka-cluster-kafka -n platform```

    - Delete the old brokers PVC's (PV status will change to released)

    - Delete the ClaimRef section from the PV's (status will change to available)

    - Create new PVC's manually pointing to existing PV (spec.volumeName)

    - Start reconciliation

    ```kubectl annotate --overwrite Kafka kafka-cluster strimzi.io/pause-reconciliation="false" -n platform```

    - Pod set will pop up and kafka brokers will back online.

7. Migrate to KRaft.
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
8. Prepare configuration for migrated Kafka. Remove the lines which were disabling `controller` NodePool and KRaft annotation. Most ofthe configuration should be taken from default values now. Make sure your broker nodepool has correct configuration (mainly storage , replicas, resources)
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

9. Deploy to have a final state aligned

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

## Cassandra
In this version all cluster definitions were removed from `kasope-platform` module and `qvantel-glue` should be used instead. All cluster definitions should be migrated to `qvantel-glue`. There are steps to avoid data loss:
1. To start off, annotate cluster resources with `helm.sh/resource-policy: keep`, this will prevent you from losing cluster resource in any situation, besides removing it manually.
2. Deploy identical cassandra cluster via `qvantel-glue`, or in the very least with same name so you will face helm resource conflict (yes, this is wanted so you will clearly see that `qvantel-glue` tries to take control of cassandra cluster). Check documentation of `qvantel-glue` module for current up-to-date configuration options and defaults.
3. Manually change helm release-name of the cluster resources from `meta.helm.sh/release-name: kasope-platform` to `meta.helm.sh/release-name: qvantel-glue` with helm annotations. There are other resources besides cluster itself that can cause helm helm release-name conflict, also annotate/remove them, goal is to get addon-operator finish installation. This will result in both `kasope-platform` and `qvantel-glue` having cluster resource in their helm state, causing effectively both modules to have control over it. Note that helm release-name does not equate ownership, it is a safeguard/guardrail for helm. Helm will happily remove said resources if it tracks them in helm release-secret state if they are removed from configurations.
4. Now cluster resource needs to be removed from `kasope-platform` state. Remove helm release secret for `kasope-platform` that has the cluster resource (recommended to remove all helm release sercrets for `kasope-platform`). Then remove cassandra cluster from configuration of `kasope-platform` and let installation go through. **If step 1. is not done, you will lose the cassandra cluster during this operation if any old helm release-secret has cluster resource in it.**
5. There will likely be some K8s resources removed, unless you have them all annotated to prevent removal. In this case it is best to restart addon-operator so it will re-render values from mako-files, restart can be either normal manual restart or deployment of new values/platform version(image).
6. After `qvantel-glue` has succesfully taken control fully of migrated cluster, remove `helm.sh/resource-policy: keep` to allow helm to remove it again. You can check if `qvantel-glue` has control of cluster resource via `helm get manifest -n platform qvantel-glue`. **Testing this procedure in lower environments/local cluster first is highly recommended.**

## CNPG
In this version all cluster definitions were removed from `cnpg-platform` module and `qvantel-glue` should be used instead. All cluster definitions should be migrated to `qvantel-glue`. There are steps to avoid data loss:
1. To start off, annotate cluster resources with `helm.sh/resource-policy: keep`, this will prevent you from losing cluster resource in any situation, besides removing it manually.
2. Deploy identical pg cluster via `qvantel-glue`, or in the very least with same name so you will face helm resource conflict (yes, this is wanted so you will clearly see that `qvantel-glue` tries to take control of pg cluster). Check documentation of `qvantel-glue` module for current up-to-date configuration options and defaults.
3. Manually change helm release-name of the cluster resources from `meta.helm.sh/release-name: cnpg-platform` to `meta.helm.sh/release-name: qvantel-glue` with helm annotations. There are other resources besides cluster itself that can cause helm helm release-name conflict, also annotate/remove them, goal is to get addon-operator finish installation. This will result in both `cnpg-platform` and `qvantel-glue` having cluster resource in their helm state, causing effectively both modules to have control over it. Note that helm release-name does not equate ownership, it is a safeguard/guardrail for helm. Helm will happily remove said resources if it tracks them in helm release-secret state if they are removed from configurations.
4. Now cluster resource needs to be removed from `cnpg-platform` state. Remove helm release secret for `cnpg-platform` that has the cluster resource (recommended to remove all helm release sercrets for `cnpg-platform`). Then remove pg cluster from configuration of `cnpg-platform` and let installation go through. **If step 1. is not done, you will lose the pg cluster during this operation if any old helm release-secret has cluster resource in it.**
5. There will likely be some K8s resources removed, like service `qvt-postgredb.platform.svc.cluster.local`, unless you have them all annotated to prevent removal. In this case it is best to restart addon-operator so it will re-render values from mako-files, restart can be either normal manual restart or deployment of new values/platform version(image).
6. After `qvantel-glue` has succesfully taken control fully of migrated cluster, remove `helm.sh/resource-policy: keep` to allow helm to remove it again. You can check if `qvantel-glue` has control of cluster resource via `helm get manifest -n platform qvantel-glue`. **Testing this procedure in lower environments/local cluster first is highly recommended.**

## MariaDB
Default cluster definitions were updated to be Galera cluster with max-scale. Existing cluster will require logical backup/restore migration procedure.

  1. Take a logical backup of the user databases. There's couple different ways which you can backup user databases. You can do both if unsure.
     - CRD based backup, either back up into S3 or local PVC. S3 backup for example:
       ```yaml
       apiVersion: k8s.mariadb.com/v1alpha1
       kind: Backup
       metadata:
         name: mariadb-logical-tmp
         namespace: platform
       spec:
         serviceAccountName: platform
         mariaDbRef:
           name: mariadb
         databases: ### CHECK WHAT DBS ARE ACTUALLY NEEDED
           - address
           - b2b_sales_tool
           - catalog_designer
           - cdt
           - cdt_backend
           - cdt_lists
           - crm_orchestration
           - keycloak
           - marketing_bpmn_executor
           - marketingstorage
           - message_manager_wui
           - mockoss
           - sales_and_care_bpmn_executor
           - tug_wui
         compression: gzip
         maxRetention: 500h
         storage:
           s3:
             bucket: mmlyle-devint-mum-mariadb
             endpoint: s3.ap-south-1.amazonaws.com
             prefix: mariadb
             region: ap-south-1
             tls:
               enabled: false
       ```
     - SQL dump:
       ```bash
       mariadb-dump -uroot -p --single-transaction --routines --triggers --events  --databases address b2b_sales_tool catalog_designer cdt cdt_backend cdt_lists crm_orchestration keycloak marketing_bpmn_executor marketingstorage message_manager_wui mnpservice mockoss sales_and_care_bpmn_executor tug_wui webdb | gzip > mmlyle-devint-all-mar11.sql.gz
       ```
  2. Remove the cluster, old PVCs and MaxScale resources. Make sure that no old resources are left.
  3. Deploy new empty cluster from the qvantel-glue module. Cluster must be empty as you will have to restore the cluster from the backup. Check the healthiness of Maxscale and check that Vault DB connection is successful.
  4. Restore: By bootstrapping into the empty cluster from the backups.
      - example from mmlyle-devint: 
     ```yaml
     mariadb:
       mariadb:
         cluster:
           spec:
             serviceAccountName: platform
             bootstrapFrom:
               restoreJob:
                 args:
                   - "--verbose"
                 resources:
                   requests:
                     cpu: 100m
                     memory: 128Mi
                   limits:
                     memory: 1Gi
               s3:
                 bucket: mmlyle-devint-mum-mariadb
                 prefix: mariadb
                 endpoint: s3.ap-south-1.amazonaws.com
                 region: ap-south-1
     ```
        - or restore the manual dump:
     ```bash
     gunzip < mmlyle-devint-all-mar11.sql.gz | mariadb -uroot -p
     ```
  5. Enable the sql installers by adding the db annotations in qvantel-glue module.

## SFTPGo
If environment has prior installation of SFTPGo, migration between release-branches is needed: https://docs.sftpgo.com/latest/data-provider/.
Assuming that env is running prior installation with 2.5.4, you need to deploy SFTPGo first with 2.6.0 and only then 2.7.0 versions. You can set image version via:
```
sftpgoPlatform:
  sftpgo:
    image:
      tag: v2.7.0
```