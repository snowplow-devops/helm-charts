{{/*
Expand the name of the chart.
*/}}
{{- define "githubActionsRunners.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name
*/}}
{{- define "githubActionsRunners.fullname" -}}
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
Create naming structure to be used bt the component name
*/}}
{{- define "githubActionsRunners.componentname" -}}
{{- $global := index . 0 -}}
{{- $component := index . 1 | trimPrefix "-" -}}
{{- printf "%s-%s" (include "githubActionsRunners.name" $global | trunc (sub 62 (len $component) | int) | trimSuffix "-" ) $component | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label
*/}}
{{- define "githubActionsRunners.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "githubActionsRunners.labels" -}}
helm.sh/chart: {{ include "githubActionsRunners.chart" . }}
{{ include "githubActionsRunners.selectorLabels" . }}
{{- if .Chart.AppVersion -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "githubActionsRunners.selectorLabels" -}}
app.kubernetes.io/name: {{ include "githubActionsRunners.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
