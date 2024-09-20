sftpgoPlatform:
  secrets:
    existingSecretName: sftpgo-shared-secrets
    forceGenerateServiceSecrets: false
    extraSharedSecretLabels: []
  sftpgo:
    replicaCount: 1
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/drakkan/sftpgo
      % endif
      tag: v2.5.4
    sftpd:
      enabled: true
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
    envFrom:
      - secretRef:
          name: sftpgo-shared-secrets
    persistence:
      enabled: true
      pvc:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
        storageClassName: gp3
    volumes:
      - name: trusted-ca-tls
        secret:
          defaultMode: 420
          optional: true
          secretName: qvantel-root-ca
    volumeMounts:
      - name: trusted-ca-tls
        mountPath: /etc/ssl/certs          
    podSecurityContext:
      runAsUser: 0
      runAsGroup: 0
      fsGroup: 0
    config:
      common:
        max_per_host_connections: 0 # remove limit, as our MEF publisher do not support it.
      httpd:
        bindings:
          - oidc:
              client_id: sftpgo
              config_url: "https://auth-${values['global']['ingressBaseUrl']}/auth/realms/qvantel"
              redirect_base_url: "https://sftp-ui-${values['global']['ingressBaseUrl']}"
              scopes: 
                - openid
                - profile
                - email
                - roles
              username_field: "preferred_username"
              implicit_roles: true # until we have proper role from Keycloak
      sftpd:
        enabled_ssh_commands:
          ["md5sum", "sha1sum", "sha256sum", "cd", "pwd", "scp", "rsync"]