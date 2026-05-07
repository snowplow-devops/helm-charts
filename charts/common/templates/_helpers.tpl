{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 50 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 50 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 50 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the secret fullname from the app fullname.
*/}}
{{- define "common.secret.fullname" -}}
{{ include "common.fullname" . }}-secret
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Snowplow standard labels
*/}}
{{- define "common.labels" -}}
{{- if .Values.global }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}
helm.sh/chart: {{ include "common.chart" . }}
{{- if .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Define the default NEG name for GCP deployments.
*/}}
{{- define "common.gcp.networkEndpointGroupName" -}}
{{- default .Release.Name .Values.service.gcp.networkEndpointGroupName -}}
{{- end -}}

{{/*
Generate Traefik middleware list for ingress annotations.
Usage: {{ include "common.traefik.middlewares" (dict "service" $service "namespace" $.Release.Namespace) }}
*/}}
{{- define "common.traefik.middlewares" -}}
{{- $service := .service -}}
{{- $namespace := .namespace -}}
{{- $middlewares := list -}}
{{- if $service.service.ingressIPAllowlist -}}
  {{- $middlewares = append $middlewares (printf "%s-%s-ipallowlist@kubernetescrd" $namespace $service.name) -}}
{{- end -}}
{{- if and $service.service.rateLimit $service.service.rateLimit.enabled -}}
  {{- $middlewares = append $middlewares (printf "%s-%s-rate-limit@kubernetescrd" $namespace $service.name) -}}
{{- end -}}
{{- if $middlewares -}}
{{- join ", " $middlewares | quote -}}
{{- end -}}
{{- end }}

