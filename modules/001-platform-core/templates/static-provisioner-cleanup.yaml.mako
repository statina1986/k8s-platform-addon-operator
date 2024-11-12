{{- if .Values.platformCore.cleanUpControllerEnabled }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-volume-node-cleanup-controller
  namespace: 
spec:
  replicas: 1
  selector:
    matchLabels:
      app: local-volume-node-cleanup
  template:
    metadata:
        labels:
          app: local-volume-node-cleanup
    spec:
      serviceAccount: platform
      tolerations:
          - key: "${values['global']['localStorageKey']}"
            value: "${values['global']['localStorageValue']}"
            operator: "Equal"
            effect: "NoSchedule"
% if values['global']['localStorage']:
      nodeSelector:
        ${values['global']['localStorageKey']}: ${values['global']['localStorageValue']}
% endif
      containers:
      - name: local-volume-node-cleanup-controller
% if 'containerRegistryBase' in values['global']:
        image: ${values['global']['containerRegistryBase']}/k8s-staging-sig-storage/local-volume-node-cleanup:canary
% else:
        image: gcr.io/k8s-staging-sig-storage/local-volume-node-cleanup:canary
% endif
        args:
          - "--storageclass-names=nvme-ssd"
          - "--pvc-deletion-delay=60s"
          - "--stale-pv-discovery-interval=10s"
        ports:
          - name: metrics
            containerPort: 8080
---
{{- end }}