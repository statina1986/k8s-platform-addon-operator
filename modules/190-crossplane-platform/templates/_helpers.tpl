{{/*
Compute if the jetAwsProviderEnabled is enabled.
*/}}
{{- define "crossplanePlatform.jetAwsProviderEnabled" -}}
{{- $_ := set . "jetAwsProviderEnabled" (eq (.Values.awsPlatform.crossplaneJetAwsProvider.enabled | toString) "true") -}}
{{- end -}}