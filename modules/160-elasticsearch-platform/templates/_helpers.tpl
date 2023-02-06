{{/*
Compute if the smartseacrh is enabled.
*/}}
{{- define "elasticsearchPlatform.smartsearchEnabled" -}}
{{- $_ := set . "smartsearchEnabled" (eq (.Values.elasticsearchPlatform.smartsearch.enabled | toString) "true") -}}
{{- end -}}

{{/*
Compute if the logsearch is enabled.
*/}}
{{- define "elasticsearchPlatform.logsearchEnabled" -}}
{{- $_ := set . "logsearchEnabled" (eq (.Values.elasticsearchPlatform.logsearch.enabled | toString) "true") -}}
{{- end -}}
Compute if the snapshot is enabled.
*/}}
{{- define "elasticsearchPlatform.logsearchBackupEnabled" -}}
{{- $_ := set . "logsearchBackupEnabled" (eq (.Values.elasticsearchPlatform.logsearchBackup.enabled | toString) "true") -}}
{{- end -}}
Compute if the testing environment is enabled.
*/}}
{{- define "elasticsearchPlatform.logsearchTestEnvEnabled" -}}
{{- $_ := set . "logsearchTestEnvEnabled" (eq (.Values.elasticsearchPlatform.logsearchTestEnv.enabled | toString) "true") -}}
{{- end -}}