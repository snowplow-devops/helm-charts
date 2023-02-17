{{/*
Expand the name of the chart.
*/}}
{{- define "spark-thrift-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "spark-thrift-server.fullname" -}}
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
{{- define "spark-thrift-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "spark-thrift-server.labels" -}}
helm.sh/chart: {{ include "spark-thrift-server.chart" . }}
{{ include "spark-thrift-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "spark-thrift-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spark-thrift-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "spark-thrift-server.serviceAccountName" -}}
{{- default (include "spark-thrift-server.fullname" .) .Values.serviceAccount.name }}
{{- end }}


{{/*
Build the list of maven packages to be added at run time
*/}}
{{- define "spark-thrift-server.sparkPackages" -}}
{{- $local := list -}}
{{- if .Values.spark.enableDelta -}}
{{- $local = printf "io.delta:delta-core_2.12:%s" .Values.spark.deltaVersion | append $local -}}
{{- end -}}
{{- join "," $local -}}
{{- end }}
