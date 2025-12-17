

# artifactory-platform

<!-- BRIEF -->
This module provides two versions of [Artifactory](https://jfrog.com/artifactory/) deployment on kubernetes. [OSS](https://artifacthub.io/packages/helm/jfrog/artifactory-oss) and [JCR](https://artifacthub.io/packages/helm/jfrog/artifactory-jcr).

Depends on modules:
- [cnpg-postgres-platform](/modules/241-cnpg-postgres-platform/README.md) which is by default is used as main database for both versions.
- [qvantel-glue](../320-qvantel-glue/) needed for provisioing secrets.

Provides:
- OSS artifactory
- JCR artifactory
- Database configurability (cnpg recommended)

Both versions available at:
- artifactory-oss.platform.svc
- artifactory-jcr.platform.svc

### Minimal configuration
* This is minimal required configuration for deploying either both or another of these versions: 
  ```
  artifactoryPlatformEnabled: "true"
  artifactoryPlatform:
    artifactory-oss:
      enabled: true
    artifactory-jcr:
      enabled: true
  ```

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
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--artifactory--admin">artifactoryPlatform.artifactory-jcr.artifactory.artifactory.admin</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>dataKey: bootstrap.creds
secret: artifactory-jcr-admin-secret</code></pre>
</td>
			<td><div>

Defines admin secrets.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--artifactory--name">artifactoryPlatform.artifactory-jcr.artifactory.artifactory.name</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>artifactory-jcr</code></pre>
</td>
			<td><div>

'name' must be same with the 'fullnameOverride'.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--database">artifactoryPlatform.artifactory-jcr.artifactory.database</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>driver: org.postgresql.Driver
secrets:
    password:
        key: password
        name: qvt-postgredb-artifactory-jcr
    url:
        key: db-url
        name: qvt-postgredb-artifactory-jcr
    user:
        key: username
        name: qvt-postgredb-artifactory-jcr
type: postgresql
url: jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-jcr</code></pre>
</td>
			<td><div>

Kube secret name

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--database--secrets">artifactoryPlatform.artifactory-jcr.artifactory.database.secrets</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>password:
    key: password
    name: qvt-postgredb-artifactory-jcr
url:
    key: db-url
    name: qvt-postgredb-artifactory-jcr
user:
    key: username
    name: qvt-postgredb-artifactory-jcr</code></pre>
</td>
			<td><div>

Define DB secret names that are created by the deployment.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--database--url">artifactoryPlatform.artifactory-jcr.artifactory.database.url</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-jcr</code></pre>
</td>
			<td><div>

Define existing postgredb cluster. CNPG module default cluster name used.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--fullnameOverride">artifactoryPlatform.artifactory-jcr.artifactory.fullnameOverride</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>artifactory-jcr</code></pre>
</td>
			<td><div>

'fullnameOverride' fully overrides the deployment name.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--nginx">artifactoryPlatform.artifactory-jcr.artifactory.nginx</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false</code></pre>
</td>
			<td><div>

Enable separate nginx container.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--postgresql">artifactoryPlatform.artifactory-jcr.artifactory.postgresql</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false</code></pre>
</td>
			<td><div>

Enable PostgreSQL dependency sub-chart. Not required in qvantel platform.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--artifactory--router">artifactoryPlatform.artifactory-jcr.artifactory.router</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: jfrog/router</code></pre>
</td>
			<td><div>

Router microservice, discovers other artifactory microservices. See https://jfrog.com/help/r/artifactory-s-microservices-explained/router

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-jcr--enabled">artifactoryPlatform.artifactory-jcr.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable deployment of JCR Artifactory.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--artifactory--admin">artifactoryPlatform.artifactory-oss.artifactory.artifactory.admin</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>dataKey: bootstrap.creds
secret: artifactory-oss-admin-secret</code></pre>
</td>
			<td><div>

Defines admin secrets.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--artifactory--admin--dataKey">artifactoryPlatform.artifactory-oss.artifactory.artifactory.admin.dataKey</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>bootstrap.creds</code></pre>
</td>
			<td><div>

Key identifier set in the kube 'secret'

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--artifactory--admin--secret">artifactoryPlatform.artifactory-oss.artifactory.artifactory.admin.secret</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>artifactory-oss-admin-secret</code></pre>
</td>
			<td><div>

Kube secret name

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--artifactory--name">artifactoryPlatform.artifactory-oss.artifactory.artifactory.name</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>artifactory-oss</code></pre>
</td>
			<td><div>

'name' must be same with the 'fullnameOverride'.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--database">artifactoryPlatform.artifactory-oss.artifactory.database</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>driver: org.postgresql.Driver
secrets:
    password:
        key: password
        name: qvt-postgredb-artifactory-oss
    url:
        key: db-url
        name: qvt-postgredb-artifactory-oss
    user:
        key: username
        name: qvt-postgredb-artifactory-oss
type: postgresql
url: jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-oss</code></pre>
</td>
			<td><div>

Main DB configuration

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--database--secrets">artifactoryPlatform.artifactory-oss.artifactory.database.secrets</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>password:
    key: password
    name: qvt-postgredb-artifactory-oss
url:
    key: db-url
    name: qvt-postgredb-artifactory-oss
user:
    key: username
    name: qvt-postgredb-artifactory-oss</code></pre>
</td>
			<td><div>

Define DB secret names that are created by the deployment.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--database--url">artifactoryPlatform.artifactory-oss.artifactory.database.url</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>jdbc:postgresql://qvt-postgredb.platform.svc.cluster.local.:5432/artifactory-oss</code></pre>
</td>
			<td><div>

Define existing postgredb cluster. CNPG module default cluster name used.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--fullnameOverride">artifactoryPlatform.artifactory-oss.artifactory.fullnameOverride</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>artifactory-oss</code></pre>
</td>
			<td><div>

'fullnameOverride' fully overrides the deployment name.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--nginx">artifactoryPlatform.artifactory-oss.artifactory.nginx</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false</code></pre>
</td>
			<td><div>

Enable separate nginx container.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--postgresql">artifactoryPlatform.artifactory-oss.artifactory.postgresql</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: false</code></pre>
</td>
			<td><div>

Enable PostgreSQL dependency sub-chart. Not required in qvantel platform.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--artifactory--router">artifactoryPlatform.artifactory-oss.artifactory.router</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>image:
    registry: platform.artifactory.qvantel.net/k8s-platform-1-2-0
    repository: jfrog/router</code></pre>
</td>
			<td><div>

Router microservice, discovers other artifactory microservices. See https://jfrog.com/help/r/artifactory-s-microservices-explained/router

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--artifactory-oss--enabled">artifactoryPlatform.artifactory-oss.enabled</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enable deployment of OSS Artifactory.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--databaseJCR--name">artifactoryPlatform.databaseJCR.name</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>qvt-postgredb</code></pre>
</td>
			<td><div>

PostgreSQL cluster name override.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--databaseOSS">artifactoryPlatform.databaseOSS</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
name: qvt-postgredb</code></pre>
</td>
			<td><div>

Qvantel CNPG module database override.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="artifactoryPlatform--databaseOSS--name">artifactoryPlatform.databaseOSS.name</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>qvt-postgredb</code></pre>
</td>
			<td><div>

PostgreSQL cluster name override.

</div>
</td>
		</tr>
	</tbody>
</table>

