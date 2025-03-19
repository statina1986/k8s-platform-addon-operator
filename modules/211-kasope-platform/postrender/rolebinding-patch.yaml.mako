apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${values['global']['helmReleaseNamePrefix']}kasope-platform-cass-operator-leader
  labels: {{ include "k8ssandra-common.labels" . | indent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${values['global']['helmReleaseNamePrefix']}kasope-platform-cass-operator-leader
subjects:
  - kind: ServiceAccount
    name: platform