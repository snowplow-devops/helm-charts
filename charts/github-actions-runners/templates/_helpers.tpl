{{/*
Expand the name of the chart.
*/}}
{{- define "github-actions-runners.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name
*/}}
{{- define "github-actions-runners.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create naming structure to be used bt the component name
*/}}
{{- define "github-actions-runners.componentname" -}}
{{- $global := index . 0 -}}
{{- $component := index . 1 | trimPrefix "-" -}}
{{- printf "%s-%s" (include "github-actions-runners.name" $global | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label
*/}}
{{- define "github-actions-runners.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "github-actions-runners.labels" -}}
helm.sh/chart: {{ include "github-actions-runners.chart" . }}
{{ include "github-actions-runners.selectorLabels" . }}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "github-actions-runners.selectorLabels" -}}
app.kubernetes.io/name: {{ include "github-actions-runners.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
