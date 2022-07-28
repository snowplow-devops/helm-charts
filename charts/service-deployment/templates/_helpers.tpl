{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- define "app.secret.fullname" -}}
{{ include "app.fullname" . }}-secret
{{- end -}}

{{/*
Define the default NEG name for GCP deployments.
*/}}
{{- define "service.gcp.networkEndpointGroupName" -}}
{{- default .Release.Name .Values.service.gcp.networkEndpointGroupName -}}
{{- end -}}
