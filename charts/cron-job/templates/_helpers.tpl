{{/* vim: set filetype=mustache: */}}

{{/*
Define a common name prefix for all created objects.
*/}}
{{- define "job.prefix" -}}
{{ .Release.Name }}-job
{{- end -}}

{{/*
Define resource names.
*/}}
{{- define "job.app.name" -}}
{{ include "job.prefix" . }}-app
{{- end -}}
{{- define "job.app.secret.name" -}}
{{ include "job.prefix" . }}-secret
{{- end -}}
