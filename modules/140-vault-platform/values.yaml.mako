# vaultPlatformNamespace: vault
vaultPlatform:
  autoUnseal: false
  useBackwardsCompatibilityService: true
  vault-secrets-webhook:
    certificate:
      useCertManager: true
      generate: false
    % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes.
    nodeSelector:
      dedicated-nodes: platform-masters
    % endif
    tolerations:
      - key: "dedicated-nodes"
        value: "platform-masters"
        operator: "Equal"
        effect: "NoSchedule"
    topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/instance: vault-platform
            app.kubernetes.io/name: vault
        maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
  vault:
    global:
      enabled: true
    injector:
      enabled: false
    server:
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
      % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run on dedicated platform-masters nodes.
      nodeSelector: |
        dedicated-nodes: platform-masters
      % endif
      tolerations: |
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      topologySpreadConstraints: |
        - labelSelector:
            matchLabels:
              app.kubernetes.io/instance: vault-platform
              app.kubernetes.io/name: vault
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      resources:
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
        - name: auto-init-sidecar
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
          image: artifactory.qvantel.net/k8s-platform-tools:latest
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - mountPath: /init-script/
              name: userconfig-vault-auto-init-config
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
                leader_api_addr = "http://vault-platform-0.vault-platform-internal:8200"
              }
              retry_join {
                leader_api_addr = "http://vault-platform-1.vault-platform-internal:8200"
              }
              retry_join {
                leader_api_addr = "http://vault-platform-2.vault-platform-internal:8200"
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
