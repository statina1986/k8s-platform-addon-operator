{{/* We override template from k8ssandra-common in order to fix limitations with ServiceAccount creation. */}}

{{- define "k8ssandra-common.serviceAccount" -}}
{{- if .Values.serviceAccount.create }}

apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "k8ssandra-common.serviceAccountName" . }}
  labels: {{ include "k8ssandra-common.labels" . | indent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- if semverCompare ">=1.24-0" .Capabilities.KubeVersion.GitVersion }}
secrets:
  - name: {{ include "k8ssandra-common.serviceAccountName" . }}-token
{{- end }}
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
{{ toYaml .Values.imagePullSecrets }}
{{- end }}

{{- end }}
{{- end }}