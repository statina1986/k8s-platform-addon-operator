# vaultPlatformNamespace: vault
vaultPlatform:
  vaultCrdSync:
    enabled: true
    # -- Schedule for reconciliation. Default is "*/5 * * * *" - so every 5 minutes.
    schedule: "*/5 * * * *"
    # -- Selector for namespaces from which sync crd resources.
    namespaceSelector:
      nameSelector:
        matchNames: ["${values['global']['platformNamespace']}"]
    
  
  # -- Enable deployment of vault-secrets-webhook subchart. Depends of value of `global.clusterwideResources` flag
  % if values['global']['clusterwideResources'] == "true":  
  vaultWebhooksEnabled: true
  % else:
  vaultWebhooksEnabled: false
  % endif

  # -- Enable auto unseal with external Cloud secrets service (KMS). See https://developer.hashicorp.com/vault/docs/concepts/seal#auto-unseal
  autoUnseal: false
  # -- Enable auto unseal with local Shamir keys stored in local K8S secret
  k8sUnseal: false
  # -- Creates `vault.{{.Release.Namespace}}.svc` which is expected by Qvantel apps
  useBackwardsCompatibilityService: true
  
  # -- Configuration for underlying vault-secrets-webhook helm-chart. See https://github.com/bank-vaults/vault-secrets-webhook/blob/main/deploy/charts/vault-secrets-webhook/README.md#values
  vault-secrets-webhook:
    image:
      % if 'containerRegistryBase' in values['global']:
      # Original vault-secrets-webhook image is replaced with Qvantel fork https://stash.qvantel.net/projects/CP/repos/qvantel-vault-secrets-webhook/browse
      repository: ${values['global']['containerRegistryBase']}/platform/qvantel-vault-secrets-webhook
      tag: "1.0.0.1_master_e5e0236d8"
      % endif
    vaultEnv:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/bank-vaults/vault-env
      % endif
    certificate:
      useCertManager: true
      generate: false
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['multiZone']['enabled']:
    topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/instance: ${values['global']['helmReleaseNamePrefix']}vault-platform
            app.kubernetes.io/name: vault-secrets-webhook
        maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
    % endif

    # -- This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing.
    configMapFailurePolicy: Fail
    # -- This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing.
    podsFailurePolicy: Fail
    # -- This is important! If Vault is down (or sealed), then webhooks will fail and potentially block everything else in the cluster. "Ignore" is recommended with Vault without auto-unsealing.
    secretsFailurePolicy: Fail

    # Limit Vault secrets to apps namespace only by default
    namespaceSelector:      
      matchExpressions:
        - key: kubernetes.io/metadata.name
          operator: In
          values:
            - ${values['global']['appsNamespace']}
  
  # -- Configuration for underlying vault helm-chart. See https://developer.hashicorp.com/vault/docs/platform/k8s/helm/configuration
  vault:
    global:
      enabled: true
    injector:
      enabled: false
    server:
      % if values['global']['clusterwideResources'] == "false":
      authDelegator:
        enabled: false
      % endif
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/hashicorp/vault
        % endif
      serviceAccount:
        create: false
        name: platform
      affinity: |
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app.kubernetes.io/name: {{ template "vault.name" . }}
                  app.kubernetes.io/instance: "{{ .Release.Name }}"
                  component: server
              topologyKey: kubernetes.io/hostname
      % if values['global']['platformMasters']:
      nodeSelector: |
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      tolerations: |
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['multiZone']['enabled']:
      topologySpreadConstraints: |
        - labelSelector:
            matchLabels:
              app.kubernetes.io/instance: "{{ .Release.Name }}"
              app.kubernetes.io/name: vault
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      % endif
      resources: {}
      readinessProbe:
        enabled: true
        path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
      livenessProbe:
        enabled: true
        path: "/v1/sys/health?standbyok=true&sealedcode=204"
        initialDelaySeconds: 60
      extraVolumes:
        - type: configMap
          name: vault-auto-init-config
          defaultMode: 0777
      extraContainers:
        - name: auto-init-and-unseal-sidecar
          args:
            - /init-script/init.sh
          command:
            - /bin/sh
          env:
            - name: VAULT_K8S_POD_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.name
            - name: VAULT_K8S_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
            - name: VAULT_INIT_NODE
              value: ${values['global']['helmReleaseNamePrefix']}vault-platform-0

          % if 'containerRegistryBase' in values['global']:
          image: ${values['global']['containerRegistryBase']}/platform/platform-k8s-tools-minimal:1.2.0_10_5193dbce5
          % else:
          image: platform.artifactory.qvantel.net/platform/platform-k8s-tools-minimal:1.2.0_10_5193dbce5
          % endif
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /init-script/
              name: userconfig-vault-auto-init-config
      % if values['global']['configurationProfile'] in {'dev'}: 
      ha:
        enabled: false
        replicas: 1
      % else:
      ha:
        enabled: true
        replicas: 3
        raft:
          enabled: true
          setNodeId: true
          additionalConfig: ""
          config: |
            ui = true

            listener "tcp" {
              address = "[::]:8200"
              cluster_address = "[::]:8201"
              tls_disable = "true"
            }

            storage "raft" {
              path = "/vault/data"
                retry_join {
                leader_api_addr = "http://${values['global']['helmReleaseNamePrefix']}vault-platform-0.${values['global']['helmReleaseNamePrefix']}vault-platform-internal:8200"
              }
              retry_join {
                leader_api_addr = "http://${values['global']['helmReleaseNamePrefix']}vault-platform-1.${values['global']['helmReleaseNamePrefix']}vault-platform-internal:8200"
              }
              retry_join {
                leader_api_addr = "http://${values['global']['helmReleaseNamePrefix']}vault-platform-2.${values['global']['helmReleaseNamePrefix']}vault-platform-internal:8200"
              }

              autopilot {
                cleanup_dead_servers = "true"
                last_contact_threshold = "200ms"
                last_contact_failure_threshold = "10m"
                max_trailing_logs = 250000
                min_quorum = 5
                server_stabilization_time = "10s"
              }

            }

            service_registration "kubernetes" {}
            {{ .Values.server.ha.raft.additionalConfig}}
        requests:
          memory: "100Mi"
          cpu: "100m"
        limits:
          memory: "1Gi"
      % endif