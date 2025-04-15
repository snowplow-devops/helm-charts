{{/*
Expand the name of the chart.
*/}}
{{- define "network-policy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "network-policy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "network-policy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "network-policy.labels" -}}
{{- with .Values.labels -}}
{{ toYaml . }}
{{ end -}}
helm.sh/chart: {{ include "network-policy.chart" . }}
{{ include "network-policy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "network-policy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "network-policy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Determine policyTypes based on presence of ingress and egress.
Defaults to ["Ingress", "Egress"] if neither is specified.
*/}}
{{- define "network-policy.policyTypes" -}}
{{- $ingress := .ingress -}}
{{- $egress := .egress -}}
{{- if and (not $ingress) (not $egress) }}
- Ingress
- Egress
{{- else }}
  {{- if $ingress }}
- Ingress
  {{- end }}
  {{- if $egress }}
- Egress
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate the ingress section for the NetworkPolicy if .ingress is defined.
*/}}
{{- define "network-policy.ingress" -}}
{{- $ingress := .ingress -}}
{{- if $ingress }}
ingress:
  {{- if or $ingress.ports $ingress.from }}
  - {{- if $ingress.ports }}
      ports:
        {{- range $ingress.ports }}
        - protocol: {{ .protocol | default "TCP" }}
          port: {{ .port }}
        {{- end }}
    {{- end }}
    {{- if $ingress.from }}
      from:
        {{- range $ingress.from }}
        - {{- if .ipBlock }}
            ipBlock:
              cidr: {{ .ipBlock.cidr }}
              {{- if .ipBlock.except }}
              except: {{ toYaml .ipBlock.except | nindent 14 }}
              {{- end }}
          {{- end }}
          {{- if .podSelector }}
            podSelector:
              matchLabels: {{ toYaml .podSelector | nindent 14 }}
          {{- end }}
          {{- if .namespaceSelector }}
            namespaceSelector:
              matchLabels: {{ toYaml .namespaceSelector | nindent 14 }}
          {{- end }}
        {{- end }}
    {{- end }}
  {{- else }}
  []
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generate the egress section for the NetworkPolicy if .egress is defined.
*/}}
{{- define "network-policy.egress" -}}
{{- $egress := .egress -}}
{{- if $egress }}
egress:
  {{- if or $egress.ports $egress.to }}
  - {{- if $egress.ports }}
      ports:
        {{- range $egress.ports }}
        - protocol: {{ .protocol | default "TCP" }}
          port: {{ .port }}
        {{- end }}
    {{- end }}
    {{- if $egress.to }}
      to:
        {{- range $egress.to }}
        - {{- if .ipBlock }}
            ipBlock:
              cidr: {{ .ipBlock.cidr }}
              {{- if .ipBlock.except }}
              except: {{ toYaml .ipBlock.except | nindent 14 }}
              {{- end }}
          {{- end }}
          {{- if .podSelector }}
            podSelector:
              matchLabels: {{ toYaml .podSelector | nindent 14 }}
          {{- end }}
          {{- if .namespaceSelector }}
            namespaceSelector:
              matchLabels: {{ toYaml .namespaceSelector | nindent 14 }}
          {{- end }}
        {{- end }}
    {{- end }}
  {{- else }}
  []
  {{- end }}
{{- end }}
{{- end }}
