{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 40 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "iglu.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 40 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Define resource names for the CloudSQL proxy service.
*/}}
{{- define "iglu.cloudsqlproxy.name" -}}
{{ include "iglu.fullname" . }}-csp
{{- end -}}
{{- define "iglu.cloudsqlproxy.host" -}}
{{ include "iglu.cloudsqlproxy.name" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Define the name of the setup hooks.
*/}}
{{- define "iglu.hooks.name" -}}
{{ include "iglu.fullname" . }}-hooks
{{- end -}}

{{/*
Define resource names for the Iglu service.
*/}}
{{- define "iglu.app.name" -}}
{{ include "iglu.fullname" . }}-app
{{- end -}}
{{- define "iglu.app.secret.name" -}}
{{ include "iglu.fullname" . }}-secret
{{- end -}}
{{- define "iglu.app.config.name" -}}
{{ include "iglu.fullname" . }}-config
{{- end -}}

{{/*
Define default values for required values.
*/}}
{{- define "iglu.service.config.superApiKey" -}}
{{- default uuidv4 .Values.service.config.secrets.superApiKey | lower -}}
{{- end -}}
{{- define "iglu.service.config.database.type" -}}
{{- default "dummy" .Values.service.config.database.type | lower -}}
{{- end -}}
{{- define "iglu.service.targetCPUUtilizationPercentage" -}}
{{- mul .Values.service.targetCPUUtilizationPercentage .Values.service.minReplicas }}
{{- end -}}

{{/*
Create chart name and version to use as chart label.
*/}}
{{- define "iglu.service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Snowplow labels
*/}}
{{- define "snowplow.labels" -}}
{{- with .Values.global.labels -}}
{{ toYaml . }}
{{ end -}}
helm.sh/chart: {{ include "iglu.service.chart" . }}
{{- if .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
PostgreSQL connection parameters for hooks
*/}}
{{- define "iglu.hooks.psql.connection" -}}
PGCONNECT_TIMEOUT={{ .Values.hooks.connectionTimeout }}  psql -h "${CONFIG_FORCE_iglu_database_host}" -U "${CONFIG_FORCE_iglu_database_admin_username}" -p "${CONFIG_FORCE_iglu_database_port}"
{{- end }}
