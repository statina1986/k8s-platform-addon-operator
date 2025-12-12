

# sftpgo-platform

This module offers [Drakkan's SFTPGo](https://github.com/drakkan/sftpgo), providing SFTPGo version 2.7.0 by default.
Deployment uses [sftpgo/helm-chart](https://github.com/sftpgo/helm-chart) to deploy it via Helm.

Dependencies:
 - [Keycloak](../810-keycloak-platform/)
    - SFTPGo requires `keycloak-platform` for `sftpgoPlatform.sftpgo.config.httpd.bidings` OIDC configurations. Can be by-passed by setting it to null, or disabling `sftpgoPlatform.sftpgo.httpd`.

The configuration requirements need a role to access the S3 bucket, which needs to be linked to the service account. Example of this can be found below

```markdown
serviceAccount:
  # -- Enable service account creation.
  create: true

  # -- Annotations to be added to the service account.
  annotations:
    eks.amazonaws.com/role-arn: ${ARN}

  # -- The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template.
  name: ""
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
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--config--httpd--bindings">sftpgoPlatform.sftpgo.config.httpd.bindings</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- oidc:
    client_id: sftpgo
    config_url: https://auth-some-env.qvantel.solutions/auth/realms/qvantel
    implicit_roles: true
    redirect_base_url: https://sftp-ui-some-env.qvantel.solutions
    scopes:
        - openid
        - profile
        - email
        - roles
    username_field: preferred_username</code></pre>
</td>
			<td><div>

OIDC-binding configuration requires `keycloak-platform` deployment. Can be by-passed by setting to `null` or `{}`

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--config--sftpd--enabled_ssh_commands">sftpgoPlatform.sftpgo.config.sftpd.enabled_ssh_commands</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- md5sum
- sha1sum
- sha256sum
- cd
- pwd
- scp</code></pre>
</td>
			<td><div>

Enabled SSH compatible commands.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--envFrom">sftpgoPlatform.sftpgo.envFrom</td>
			<td>list</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>- secretRef:
    name: sftpgo-shared-secrets</code></pre>
</td>
			<td><div>

Keycloak-platform used client-secret

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--httpd">sftpgoPlatform.sftpgo.httpd</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true</code></pre>
</td>
			<td><div>

Web-GUI related configurations

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--image--tag">sftpgoPlatform.sftpgo.image.tag</td>
			<td>string</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>v2.7.0</code></pre>
</td>
			<td><div>

Image tag for to-be-deployed version of SFTPGo. If upgrading more than one release-branch version, refer to [release-1-3-migration.md](../../docs/migration-guides/release-1-3-migration.md) for details. 2.7.0 is the new default version, but for cases where rsync is required, use 2.6.6 instead.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--persistence">sftpgoPlatform.sftpgo.persistence</td>
			<td>object</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>enabled: true
pvc:
    accessModes:
        - ReadWriteOnce
    resources:
        requests:
            storage: 10Gi
    storageClassName: gp3</code></pre>
</td>
			<td><div>

Configurations for persistence of metadata related information, such as users and their data-path and permissions.

</div>
</td>
		</tr>
		<tr>
			<td style="width: 300px;" id="sftpgoPlatform--sftpgo--qvantelCaVolumes">sftpgoPlatform.sftpgo.qvantelCaVolumes</td>
			<td>bool</td>
			<td>
<pre style="width:500px; overflow-x:auto; white-space: pre;" lang="yaml"><code>false</code></pre>
</td>
			<td><div>

Enables qvantel-root-ca pre-configured mounting.

</div>
</td>
		</tr>
	</tbody>
</table>

