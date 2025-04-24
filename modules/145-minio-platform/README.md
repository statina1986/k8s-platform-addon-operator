# minio-platform module
This module is responsible for deployment of [MinIO](https://min.io/) in the cluster

Depends on modules:
- no dependencies

Provides:
- Object storage backend ( S3 )

Makes the following buckets by default:

```
cassandra-backup
loki-logs
mariadb-backup
postgres-backup
```

Example usage:

CASSANDRA

```
cluster:
  enabled: true
  spec:
    medusa:
      storageProperties:
        storageProvider: s3_compatible
        bucketName: cassandra-backup
        prefix: cluster
        storageSecretRef:
          name: platform-minio-medusa
        host: minio-platform.platform.svc.cluster.local
        port: 9000
        secure: false
```

LOKI

```
loki:
  objectStorageSecret:
    create: false
    secretName: "platform-minio-readwrite"
    userName: "platform-minio-readwrite"
    userKey: "readwriteUser"
    secretKey: "readwritePassword"
  loki:
    storage:
      type: s3
      s3:
        s3: http://${OBJECT_STORAGE_USER}:${OBJECT_STORAGE_SECRET}@minio-platform.platform.svc.cluster.local:9000/loki-logs
        endpoint: http://minio-platform.platform.svc.cluster.local:9000
        s3ForcePathStyle: true
      bucketNames:
        chunks: loki-logs
    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/index_cache
        resync_interval: 5s
```


MARIADB

```
clusters:
  mariadb:
    spec:
      backup:
        bucketName: mariadb-backup
        endpoint: minio-platform.platform.svc.cluster.local:9000
        secretName: platform-minio-readwrite-mariadb
        secretUserKey: readwriteUser
        secretKey: readwritePassword
        scheduledBackup: "0 0 * * *"
        retention: 72h
```

CNPG

```
clusters:
  qvt-postgredb:
    enabled: true
    spec:
      backup:
        barmanObjectStore:
        destinationPath: "s3://postgres-backup/qvt-postgredb"
        endpointURL: http://minio-platform.platform.svc.cluster.local:9000
        s3Credentials:
          inheritFromIAMRole: false
          accessKeyId:
            name: platform-minio-readwrite-postgres
            key: readwriteUser
          secretAccessKey:
            name: platform-minio-readwrite-postgres
            key: readwritePassword
```




