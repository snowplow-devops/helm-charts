{{/*
Expand the name of the chart.
*/}}
{{- define "github_actions_runners.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name
*/}}
{{- define "github_actions_runners.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label
*/}}
{{- define "github_actions_runners.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "github_actions_runners.labels" -}}
helm.sh/chart: {{ include "github_actions_runners.chart" . }}
{{ include "github_actions_runners.selectorLabels" . }}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "github_actions_runners.selectorLabels" -}}
app.kubernetes.io/name: {{ include "github_actions_runners.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
