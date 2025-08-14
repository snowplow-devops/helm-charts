{{/*
Expand the name of the chart.
*/}}
{{- define "vertical-pod-autoscaler.name" -}}
{{- default .Chart.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vertical-pod-autoscaler.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.fullnameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vertical-pod-autoscaler.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vertical-pod-autoscaler.labels" -}}
{{- with .Values.global.labels -}}
{{ toYaml . }}
{{ end -}}
helm.sh/chart: {{ include "vertical-pod-autoscaler.chart" . }}
{{- if .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "vertical-pod-autoscaler.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vertical-pod-autoscaler.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vertical-pod-autoscaler.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vertical-pod-autoscaler.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vertical-pod-autoscaler.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get image tag
*/}}
{{- define "vertical-pod-autoscaler.imageTag" -}}
{{- .tag | default .root.Chart.AppVersion }}
{{- end }}

{{/*
Recommender component name
*/}}
{{- define "vertical-pod-autoscaler.recommender.name" -}}
{{ include "vertical-pod-autoscaler.fullname" . }}-recommender
{{- end }}

{{/*
Updater component name
*/}}
{{- define "vertical-pod-autoscaler.updater.name" -}}
{{ include "vertical-pod-autoscaler.fullname" . }}-updater
{{- end }}

{{/*
Admission Controller component name
*/}}
{{- define "vertical-pod-autoscaler.admissionController.name" -}}
{{ include "vertical-pod-autoscaler.fullname" . }}-admission-controller
{{- end }}

{{/*
Generate self-signed certificate for admission controller webhook (only when cert-manager is disabled)
*/}}
{{- define "vertical-pod-autoscaler.admissionController.selfSignedCert" -}}
{{- if not .Values.vpa.admissionController.certManager.enabled -}}
{{- $serviceName := include "vertical-pod-autoscaler.admissionController.name" . -}}
{{- $ca := genCA "vpa-ca" 365 -}}
{{- $altNames := list (printf "%s.%s.svc" $serviceName .Release.Namespace) (printf "%s.%s.svc.cluster.local" $serviceName .Release.Namespace) -}}
{{- $cert := genSignedCert $serviceName nil $altNames 365 $ca -}}
ca.crt: {{ $ca.Cert | b64enc }}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
caBundle: {{ $ca.Cert | b64enc }}
{{- end -}}
{{- end -}}