{{/*
Compute if the awsEnabled is enabled.
*/}}
{{- define "istioPrivateIngress.awsEnabled" -}}
{{- $_ := set . "awsEnabled" (eq (.Values.istioPrivateIngress.aws.enabled | toString) "true") -}}
{{- end -}}