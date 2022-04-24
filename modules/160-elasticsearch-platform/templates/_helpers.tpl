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
{{- $_ := set . "logsearchEnabled" (eq (.Values.elasticsearchPlatform.smartsearch.enabled | toString) "true") -}}
{{- end -}}