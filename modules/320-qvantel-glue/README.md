

# qvantel-glue

`qvantel-glue` module provides abstractions and automations to support Qvantel workloads deployments and operations.
Those are opiniated templates which utilize Qvantel specific conventions.

Depends on modules:
- This is module is collection of thin wrappers on top existing functionality and resources.

Provides:
- SqlInstaller CRD
- Database deployments configuration
  - PostgreSQL (via CNPG)
  - MariaDB (via MariaDB-operator)
  - Cassandra (via k8ssandra)

## Values

<h3> Main Values</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cassandra: {}
mariadb: {}
postgres: {}</code></pre>
</td>
		<td>
<div>

Databases deployment configuration.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.cassandra</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td>
<div>

Cassandra databases configuration. This is a map where each key corresponds to the K8ssandra cluster  and associated configuration like keyspaces and roles.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.mariadb</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td>
<div>

MariaDB databases configuration. This is a map where each key corresponds to the MariaDB cluster  and associated configuration like dbs, roles and extensions.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.dbs.postgres</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>{}</code></pre>
</td>
		<td>
<div>

PostgreSQL databases configuration. This is a map where each key corresponds to the PostgreSQL cluster  and associated configuration like dbs, roles and extensions. For Example, see `example-postgredb` definition in Examples-PostgreSQL section below.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
namespaceSelector:
    nameSelector:
        matchNames:
            - platform
schedule: '*/5 * * * *'</code></pre>
</td>
		<td>
<div>

Configuration for SqlInstaller CRDs reconciliation.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync.enabled</td>
		<td>bool</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>true</code></pre>
</td>
		<td>
<div>

Enables SqlInstaller CRDs reconciliation

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync.namespaceSelector</td>
		<td>object</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>nameSelector:
    matchNames:
        - platform</code></pre>
</td>
		<td>
<div>

Selector for namespaces from which sync SqlInstaller resources. Default is `platform` namespace.

</div>
		</td>
	</tr>
	<tr>
		<td style="width: 300px;">qvantelGlue.sqlinstallersCrdSync.schedule</td>
		<td>string</td>
		<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>'*/5 * * * *'</code></pre>
</td>
		<td>
<div>

Schedule for periodic reconciliation. Default is "*/5 * * * *" - so every 5 minutes.

</div>
		</td>
	</tr>
	</tbody>
</table>

<h3>Examples-PostgreSQL</h3>
<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td style="width: 300px;">example-postgredb</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>cluster:
    spec:
        affinity:
            topologyKey: topology.kubernetes.io/zone
        enableSuperuserAccess: true
        imageName: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.7-1_7_master_b0ee48eda
        instances: 2
        postgresql:
            parameters:
                max_connections: "300"
                pg_stat_statements.max: "10000"
                pg_stat_statements.track: all
                random_page_cost: "1"
                wal_compression: pglz
            shared_preload_libraries:
                - timescaledb
        resources:
            requests:
                cpu: "0.1"
                memory: 1Gi
        storage:
            size: 10Gi
    vaultConfiguration: true
dbs:
    catalog-deployer:
        sql:
            provision: "- \"CREATE ROLE db_catalog_deployer NOLOGIN\"\n- \"GRANT db_catalog_deployer TO CURRENT_USER\"\n- \"CREATE DATABASE catalog_deployer WITH OWNER db_catalog_deployer\"    \n"
    ddl:
        extensions:
            timescaledb: {}
    flex-bpmn-executor:
        owners:
            apps-another-app-to-access-flex: {}
roles:
    custom-role-access-multiple-dbs:
        sql: |
            CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
            GRANT db_ddl TO "{{name}}";
            GRANT db_flex_bpmn_executor TO "{{name}}";
            ALTER ROLE "{{name}}" SET role db_ddl;
            ALTER ROLE "{{name}}" SET role db_flex_bpmn_executor;</code></pre>
</td>
			<td>
<div>

This is example PostgreSQL glue definition.  Note: It is used for documentation purposes only. Real PostgreSQL clusters should be defined under `qvantelGlue.dbs.postgres`

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td>
<div>

Defines CNPG database cluster (kind: Cluster) to deploy.  If it is omitted, no cluster will be deployed as part of `glue` module and it is assumed cluster is deployed externally. Cluster configuration follows same structure which is deinfed in [cnpg-postgres-platform](/modules/241-cnpg-postgres-platform/README.md) module. In this example CNPG cluster is configured with 3 dbs created in this cluster(`catalog-deployer`, `ddl`, `flex-bpmn-executor`) and few additional roles.

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.spec</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td>
<div>

Configure CNPG cluster details. See https://cloudnative-pg.io/documentation/current/cloudnative-pg.v1/#postgresql-cnpg-io-v1-ClusterSpec for API reference. Values configured in this spec are merged with result of templating [_default-cluster-spec.tpl.mako](templates/_default-cluster-spec.tpl.mako).

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.cluster.vaultConfiguration</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code> false</code></pre>
</td>
			<td>
<div>

Create Vault configuration for this cluster according to Qvantel conventions, i.e. DbConnection and common DbRoles.

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td>
<div>

Defines Databases to deploy in the CNPG Cluster. For each  database `SqlInstaller` is created which will execute database creation logic according to Qvnatel conventions.  

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.catalog-deployer.sql.provision</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td>
<div>

It is possible to define provisionsing SQL for the database if customization is required.

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.ddl.extensions</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>null</code></pre>
</td>
			<td>
<div>

Configures PostgreSQL extensions for database. Currently only `timescaledb` is supported.

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.ddl.extensions.timescaledb</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td>
<div>

Enables `timescaledb` extensions for database.

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.dbs.flex-bpmn-executor.owners</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td>
<div>

Additional owners roles to configure in Vault. Each key from this map will be added to Vault with database owner role.

</div>
			</td>
		</tr>
		<tr>
			<td style="width: 300px;">example-postgredb.roles</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang=""><code>{}</code></pre>
</td>
			<td>
<div>

Configures additional custom roles for this cluster in Vault. Keys in this map will be used as Vault roles names.

</div>
			</td>
		</tr>
	</tbody>
</table>

