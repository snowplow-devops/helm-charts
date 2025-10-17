{{/* vim: set filetype=mustache: */}}
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

{{/*
Define the default NEG name for GCP deployments.
*/}}
{{- define "service.gcp.networkEndpointGroupName" -}}
{{- default .Release.Name .Values.service.gcp.networkEndpointGroupName -}}
{{- end -}}

{{/*
Create chart name and version to use as chart label.
*/}}
{{- define "service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Snowplow labels
*/}}
{{- define "snowplow.labels" -}}
{{- with .Values.global.labels -}}
{{ toYaml . }}
{{ end -}}
helm.sh/chart: {{ include "service.chart" . }}
{{- if .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Generate Traefik middleware list for ingress annotations
Usage: {{ include "service.traefik.middlewares" . }}
*/}}
{{- define "service.traefik.middlewares" -}}
{{- $middlewares := list -}}
{{- if $.Values.service.ingressIPAllowlist -}}
  {{- $middlewares = append $middlewares (printf "%s-%s-ipallowlist@kubernetescrd" $.Release.Namespace (include "app.fullname" $)) -}}
{{- end -}}
{{- if $.Values.service.rateLimit.enabled -}}
  {{- $middlewares = append $middlewares (printf "%s-%s-rate-limit@kubernetescrd" $.Release.Namespace (include "app.fullname" $)) -}}
{{- end -}}
{{- if $middlewares -}}
{{- join ", " $middlewares | quote -}}
{{- end -}}
{{- end }}
