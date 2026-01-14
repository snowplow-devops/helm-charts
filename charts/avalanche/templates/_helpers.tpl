{{/*
Expand the name of the chart.
*/}}
{{- define "avalanche.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "avalanche.fullname" -}}
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
{{- define "avalanche.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Snowplow labels - follows helm-charts convention
*/}}
{{- define "snowplow.labels" -}}
{{- with .Values.global.labels -}}
{{ toYaml . }}
{{ end -}}
helm.sh/chart: {{ include "avalanche.chart" . }}
{{- if .Chart.Version }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "avalanche.selectorLabels" -}}
app.kubernetes.io/name: {{ include "avalanche.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels
*/}}
{{- define "avalanche.componentLabels" -}}
{{ include "snowplow.labels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
NATS URL
*/}}
{{- define "avalanche.natsUrl" -}}
nats://{{ include "avalanche.fullname" . }}-nats:{{ .Values.nats.service.clientPort }}
{{- end }}

{{/*
Image name helper - supports both local and registry images
If images.registry is empty, uses local image format: repository:tag
If images.registry is set, uses registry format: registry/repository:tag
*/}}
{{- define "avalanche.image" -}}
{{- $registry := .images.registry -}}
{{- $repository := .image.repository -}}
{{- $tag := .image.tag -}}
{{- if hasPrefix "nats" $repository -}}
{{- printf "%s:%s" $repository $tag -}}
{{- else if eq $registry "" -}}
{{- printf "%s:%s" $repository $tag -}}
{{- else -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Database environment variables
*/}}
{{- define "avalanche.databaseEnv" -}}
{{- if .Values.database.type }}
- name: AVALANCHE_DB_TYPE
  value: {{ .Values.database.type | quote }}
{{- if eq .Values.database.type "influxdb" }}
- name: AVALANCHE_INFLUXDB_URL
  value: {{ .Values.database.influxdb.url | quote }}
- name: AVALANCHE_INFLUXDB_TOKEN
{{- if .Values.database.influxdb.token }}
  value: {{ .Values.database.influxdb.token | quote }}
{{- else }}
  valueFrom:
    secretKeyRef:
      name: {{ include "avalanche.fullname" . }}-db-credentials
      key: influxdb-token
      optional: true
{{- end }}
- name: AVALANCHE_INFLUXDB_ORG
  value: {{ .Values.database.influxdb.org | quote }}
- name: AVALANCHE_INFLUXDB_BUCKET
  value: {{ .Values.database.influxdb.bucket | quote }}
- name: AVALANCHE_INFLUXDB_MEASURE_METRICS
  value: "correlator_stats_phase"
- name: AVALANCHE_INFLUXDB_MEASURE_WINDOW_METRICS
  value: "correlator_stats_window"
- name: AVALANCHE_INFLUXDB_MEASURE_RUN_METRICS
  value: "correlator_stats_run"
{{- end }}
{{- if eq .Values.database.type "timestream" }}
- name: AVALANCHE_TIMESTREAM_DATABASE
  value: {{ .Values.database.timestream.database | quote }}
- name: AVALANCHE_TIMESTREAM_REGION
  value: {{ .Values.database.timestream.region | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
AWS environment variables
*/}}
{{- define "avalanche.awsEnv" -}}
{{- if .Values.aws.region }}
- name: AWS_REGION
  value: {{ .Values.aws.region | quote }}
{{- end }}
{{- if .Values.aws.accessKeyId }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "avalanche.fullname" . }}-aws-credentials
      key: access-key-id
      optional: true
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "avalanche.fullname" . }}-aws-credentials
      key: secret-access-key
      optional: true
{{- if .Values.aws.sessionToken }}
- name: AWS_SESSION_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "avalanche.fullname" . }}-aws-credentials
      key: session-token
      optional: true
{{- end }}
{{- end }}
{{- end }}

