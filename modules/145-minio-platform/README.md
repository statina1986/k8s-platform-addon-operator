

# minio-platform


`minio-platform` module is responsible for deployment of [MinIO](https://min.io/) in the cluster. Most common use case for this is when off site S3 backend such as AWS S3 is not available.

Depends on modules:
- [vault-platform](https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/140-vault-platform/README.md) for backing up MinIO root credentials to versioned KV2 secrets 

Provides:
- Local object storage backend ( S3 )
- Default users:
  - platform-minio-root ( for admin actions )
  - platform-minio-readwrite ( for interacting with the MinIO API)
- Default buckets:
  - cassandra-backup
  - loki-logs
  - postgres-backup
  - mariadb-backup
- MinIO Console with advanced metrics dashboard
  - Console available at minio-console.platform.svc
- MinIO root credentials are stored to Vault, can be retrieved from there if password is lost

Configured profiles:
- dev
  - 1 standalone MinIO cluster instead of 3 in distributed mode


## Values

<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;" id="minioPlatform--minio">minioPlatform.minio</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>buckets:
    - name: cassandra-backup
    - name: loki-logs
    - name: postgres-backup
    - name: mariadb-backup
drivesPerNode: 1
environment:
    MINIO_BROWSER_LOGIN_ANIMATION: "off"
    MINIO_PROMETHEUS_URL: http://monitoring-platform-prometheus.platform.svc.cluster.local:9090
existingSecret: platform-minio-root
ignoreChartChecksums: true
image:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/minio/minio
    tag: RELEASE.2025-04-22T22-12-26Z
mcImage:
    repository: platform.artifactory.qvantel.net/k8s-platform-1-2-0/minio/mc
    tag: RELEASE.2025-08-13T08-35-41Z
minioAPIPort: "9000"
minioConsolePort: "9001"
mode: distributed
persistence:
    accessMode: ReadWriteOnce
    enabled: true
    size: 30Gi
    storageClass: ""
    volumeName: ""
pools: 1
replicas: 3
resources:
    requests:
        memory: 1Gi
securityContext:
    enabled: false
tolerations:
    - effect: NoSchedule
      key: dedicated-nodes
      operator: Equal
      value: platform-masters
users:
    - accessKey: platform-minio-readwrite
      existingSecret: platform-minio-readwrite
      existingSecretKey: readwritePassword
      policy: readwrite</code></pre>
</td>
			<td><div>

Configuration for underlying minio helm-chart. See https://github.com/minio/minio/tree/master/helm/minio#configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="minioPlatform--minio--environment--MINIO_BROWSER_LOGIN_ANIMATION">minioPlatform.minio.environment.MINIO_BROWSER_LOGIN_ANIMATION</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>"off"</code></pre>
</td>
			<td><div>

Disables login animation, which breaks login page with kubectl port forwarding ( https://github.com/minio/minio/pull/17123 )

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="minioPlatform--minio--environment--MINIO_PROMETHEUS_URL">minioPlatform.minio.environment.MINIO_PROMETHEUS_URL</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>http://monitoring-platform-prometheus.platform.svc.cluster.local:9090</code></pre>
</td>
			<td><div>

Enables advanced metrics in MinIO Console if monitoring-platform module is enabled

</div>
</td>
		</tr>
	</tbody>
</table>



## NOTE 
#### Cassandra, MariaDB and Postgres modules make their own MinIO secrets when those modules are enabled. No need to configure additional credentials for them in this module.

## Example usage of this MinIO in other modules:
CASSANDRA

```
kasopePlatform:
  clusters:
    cluster:
      enabled: true
      spec:
        cassandra:
          serverVersion: "4.1.8"
          serverImage: "platform.artifactory.qvantel.net/k8s-platform-1-2-0/k8ssandra/cass-management-api:4.1.8-ubi8"
          config:
            cassandraYaml:
              num_tokens: 16
        medusa:
          storageProperties:
            storageProvider: s3_compatible
            bucketName: cassandra-backup
            prefix: cluster
            storageSecretRef:
              name: platform-minio-medusa ## This secret from kasope-platform module
            host: minio-platform.platform.svc.cluster.local
            port: 9000
            secure: false
```

LOKI

```
lokiPlatform:
  loki:
    objectStorageSecret:
      create: false
      secretName: "platform-minio-readwrite"
      userKey: "readwriteUser"
      secretKey: "readwritePassword"
    loki:
      storage:
        s3:
          s3: http://${OBJECT_STORAGE_USER}:${OBJECT_STORAGE_SECRET}@minio-platform.platform.svc.cluster.local:9000/loki-logs
          endpoint: http://minio-platform.platform.svc.cluster.local:9000
          s3ForcePathStyle: true
        bucketNames:
          chunks: loki-logs
```


MARIADB

```
mariadbOperatorPlatform:
  clusters:
    mariadb:
      spec:
        backup:
          bucket: mariadb-backup
          endpoint: minio-platform.platform.svc.cluster.local:9000
          secretName: platform-minio-readwrite-mariadb ## This secret from mariadb-operator-platform module
          secretUserKey: readwriteUser
          secretKey: readwritePassword
          scheduledBackup: "0 0 * * *"
          retention: 72h
```

POSTGRES FROM GLUE MODULE

```
qvantelGlue:
  dbs:
    postgres:
      qvt-postgredb:
        cluster:
          spec:
            storage:
              size: 25Gi
          barmanObjectStore:
            spec:
              configuration:
                destinationPath: "s3://postgres-backup/"
                endpointURL: http://minio-platform.platform.svc.cluster.local:9000
                wal:
                  encryption: null ## as MinIO does not provide SSE capabilities by default
                s3Credentials:
                  inheritFromIAMRole: false
                  accessKeyId:
                    name: platform-minio-readwrite-postgres ## This secret from cnpg-postgres-platform module
                    key: readwriteUser
                  secretAccessKey:
                    name: platform-minio-readwrite-postgres ## This secret from cnpg-postgres-platform module
                    key: readwritePassword
```


