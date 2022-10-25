{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 40 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "transformer.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 40 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Define resource names for the CloudSQL proxy service.
*/}}
{{- define "transformer.cloudsqlproxy.name" -}}
{{ include "transformer.fullname" . }}-csp
{{- end -}}
{{- define "transformer.cloudsqlproxy.host" -}}
{{ include "transformer.cloudsqlproxy.name" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Define the name of the setup hooks.
*/}}
{{- define "transformer.hooks.name" -}}
{{ include "transformer.fullname" . }}-hooks
{{- end -}}

{{/*
Define resource names for the Iglu service.
*/}}
{{- define "transformer.app.name" -}}
{{ include "transformer.fullname" . }}-app
{{- end -}}
{{- define "transformer.app.secret.name" -}}
{{ include "transformer.fullname" . }}-secret
{{- end -}}
{{- define "transformer.app.config.name" -}}
{{ include "transformer.fullname" . }}-config
{{- end -}}

{{/*
Define default values for required values.
*/}}
{{- define "transformer.service.config.superApiKey" -}}
{{- default uuidv4 .Values.service.config.secrets.superApiKey | lower -}}
{{- end -}}
{{- define "transformer.service.config.database.type" -}}
{{- default "dummy" .Values.service.config.database.type | lower -}}
{{- end -}}
{{- define "transformer.service.targetCPUUtilizationPercentage" -}}
{{- mul .Values.service.targetCPUUtilizationPercentage .Values.service.minReplicas }}
{{- end -}}
{{- define "transformer.service.gcp.networkEndpointGroupName" -}}
{{- default .Release.Name .Values.service.gcp.networkEndpointGroupName -}}
{{- end -}}
{{- define "transformer.service.config.checksum" -}}
{{- printf "%s-%s-%s" (include "transformer.service.config.superApiKey" .) .Values.service.config.database.secrets.password .Values.service.config.database.secrets.username | sha256sum -}}
{{- end -}}
