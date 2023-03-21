{{/*
Compute if the certificate creation for ingress is enabled.
*/}}
{{- define "certPlatform.certificateEnabled" -}}
{{- $_ := set . "certificateEnabled" (eq (.Values.certPlatform.qvantelWildcard.enabled | toString) "true") -}}
{{- end -}}

{{/*
Compute if the clusterIssuer for ingress is enabled.
*/}}
{{- define "certPlatform.clusterIssuerEnabled" -}}
{{- $_ := set . "clusterIssuerEnabled" (eq (.Values.certPlatform.qvantelSystemsIssuer.enabled | toString) "true") -}}
{{- end -}}