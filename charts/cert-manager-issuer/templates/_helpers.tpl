{{/* vim: set filetype=mustache: */}}
{{/*
Validation functions
*/}}
{{- define "validate-cloud" -}}
{{- if not (or (eq .Values.global.cloud "aws") (eq .Values.global.cloud "gcp") (eq .Values.global.cloud "azure")) -}}
{{- printf "Error: invalid cloud (%s). Allowed values: aws, gcp, azure." .Values.global.cloud | fail -}}
{{- end -}}
{{- end -}}
{{/*
Create a default fully qualified app name.
We truncate at 50 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 50 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- define "app.secret.fullname" -}}
{{ include "app.fullname" . }}-secret
{{- end -}}
{{- define "validate-environment" -}}
{{- if not (or (eq .Values.acme.environment "letsencrypt") (eq .Values.acme.environment "letsencrypt-staging")) -}}
{{- printf "Error: invalid acme.environment (%s). Allowed values: letsencrypt, letsencrypt-staging." .Values.acme.environment | fail -}}
{{- end -}}
{{- end -}}
{{- define "validate-type" -}}
{{- if not (or (eq .Values.issuerType "cluster") (eq .Values.issuerType "namespace")) -}}
{{- printf "Error: invalid issuerType (%s). Allowed values: cluster, namespace." .Values.issuerType | fail -}}
{{- end -}}
{{- end -}}
{{- define "acme.server" -}}
{{- if eq .Values.acme.environment "letsencrypt" -}}
{{- print "https://acme-v02.api.letsencrypt.org/directory" | trim | replace " " "" -}}
{{- else if eq .Values.acme.environment "letsencrypt-staging" -}}
{{- print "https://acme-staging-v02.api.letsencrypt.org/directory" | trim | replace " " "" -}}
{{- end -}}
{{- end -}}
