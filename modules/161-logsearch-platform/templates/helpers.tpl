{{/*
Compute if the prod environment is enabled.
*/}}
{{- define "logsearchPlatform.prodEnabled" -}}
{{- $_ := set . "prodEnabled" (eq (.Values.logsearchPlatform.prod.enabled | toString) "true") -}}
{{- end -}}

{{/*
Compute if the w3-prod logging-setup is enabled.
*/}}
{{- define "logsearchPlatform.windprodloggingEnabled" -}}
{{- $_ := set . "windprodloggingEnabled" (eq (.Values.logsearchPlatform.windprodlogging.enabled | toString) "true") -}}
{{- end -}}

{{/*
Compute if the testing environment is enabled.
*/}}
{{- define "logsearchPlatform.logsearchTestEnvEnabled" -}}
{{- $_ := set . "logsearchTestEnvEnabled" (eq (.Values.logsearchPlatform.logsearchTestEnv.enabled | toString) "true") -}}
{{- end -}}