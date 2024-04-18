{{/*
Compute if the prod environment is enabled.
*/}}
{{- define "elasticsearchPlatform.prodEnabled" -}}
{{- $_ := set . "prodEnabled" (eq (.Values.elasticsearchPlatform.prod.enabled | toString) "true") -}}
{{- end -}}

{{/*
Compute if the w3-prod logging-setup is enabled.
*/}}
{{- define "elasticsearchPlatform.windprodloggingEnabled" -}}
{{- $_ := set . "windprodloggingEnabled" (eq (.Values.elasticsearchPlatform.windprodlogging.enabled | toString) "true") -}}
{{- end -}}

{{/*
Compute if the testing environment is enabled.
*/}}
{{- define "elasticsearchPlatform.logsearchTestEnvEnabled" -}}
{{- $_ := set . "logsearchTestEnvEnabled" (eq (.Values.elasticsearchPlatform.logsearchTestEnv.enabled | toString) "true") -}}
{{- end -}}
