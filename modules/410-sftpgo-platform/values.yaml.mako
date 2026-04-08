sftpgoPlatform:
  secrets:
    existingSecretName: sftpgo-shared-secrets
    forceGenerateServiceSecrets: false
    extraSharedSecretLabels: []
  sftpgo:
    replicaCount: 1
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/drakkan/sftpgo
      % endif
      # -- Image tag for to-be-deployed version of SFTPGo. If upgrading more than one release-branch version, refer to [release-1-3-migration.md](../../docs/migration-guides/release-1-3-migration.md) for details. 2.7.0 is the new default version, but for cases where rsync is required, use 2.6.6 instead.
      tag: v2.7.0
    sftpd:
      enabled: true
    # -- Web-GUI related configurations
    httpd:
      enabled: true
    serviceAccount:
      create: false
      annotations: {}
      name: "platform"
    envVars:
      - name: SFTPGO_LOG_LEVEL
        value: "info"
      - name: SFTPGO_LOG_UTC_TIME
        value: "1"
      - name: SFTPGO_DEFAULT_ADMIN_USERNAME
        valueFrom:
          secretKeyRef:
            name: sftpgo-admin-secret
            key: username
      - name: SFTPGO_DEFAULT_ADMIN_PASSWORD
        valueFrom:
          secretKeyRef:
            name: sftpgo-admin-secret
            key: password
    # -- Keycloak-platform used client-secret
    envFrom:
      - secretRef:
          name: sftpgo-shared-secrets
    # -- Configurations for persistence of metadata related information, such as users and their data-path and permissions.
    persistence:
      enabled: true
      pvc:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
        storageClassName: gp3
    # -- Enables qvantel-root-ca pre-configured mounting.
    qvantelCaVolumes: false
    # @schema
    # type: array
    # items:
    #   type: object
    # @schema
    volumes:
      % if values.get("sftpgoPlatform", {}).get("sftpgo", {}).get("qvantelCaVolumes", False):
      - name: trusted-ca-tls
        secret:
          defaultMode: 420
          optional: true
          secretName: qvantel-root-ca
      % endif
    # @schema
    # type: array
    # items:
    #   type: object
    # @schema
    volumeMounts:
      % if values.get("sftpgoPlatform", {}).get("sftpgo", {}).get("qvantelCaVolumes", False):
      - name: trusted-ca-tls
        mountPath: /etc/ssl/certs 
      % endif
    podSecurityContext:
      runAsUser: 0
      runAsGroup: 0
      fsGroup: 0
    config:
      data_provider:
        create_default_admin: true
      common:
        max_per_host_connections: 0 # remove limit, as our MEF publisher do not support it.
      httpd:
        # -- OIDC-binding configuration requires `keycloak-platform` deployment. Can be by-passed by setting to `null` or `{}`
        bindings:
          - oidc:
              client_id: sftpgo
              config_url: "https://auth${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}/auth/realms/qvantel"
              redirect_base_url: "https://sftp-ui${values['global']['ingressBaseUrlSeparator']}${values['global']['ingressBaseUrl']}"
              scopes: 
                - openid
                - profile
                - email
                - roles
              username_field: "preferred_username"
              implicit_roles: true # until we have proper role from Keycloak
      sftpd:
        # -- Enabled SSH compatible commands.
        enabled_ssh_commands:
          ["md5sum", "sha1sum", "sha256sum", "cd", "pwd", "scp"]