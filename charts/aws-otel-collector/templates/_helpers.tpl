{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aws-otel-collector.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aws-otel-collector.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aws-otel-collector.chart" -}}
{{- printf "%s-%s" .Release.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aws-otel-collector.labels" -}}
helm.sh/chart: {{ include "aws-otel-collector.chart" . }}
{{ include "aws-otel-collector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aws-otel-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aws-otel-collector.name" . }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aws-otel-collector.serviceAccountName" -}}
  {{ default (include "aws-otel-collector.fullname" .) .Values.serviceAccount.name }}
{{- end -}}
