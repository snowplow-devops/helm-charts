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
ServiceAccount name for the observer-kubernetes pods.

The observer-kubernetes pods need BOTH the k8s API ClusterRole (to read pod
metrics) AND AWS credentials (to write metrics to Timestream). When
cloudserviceaccount is deployed (e.g. DS4, where AWS auth is via IRSA), reuse
that ServiceAccount so the observer inherits its Timestream IRSA role —
otherwise the pod falls back to the node role and gets a Timestream 403
(QA-1038). When cloudserviceaccount is not deployed (sandbox/local, where AWS
creds are injected directly), use the component's own ServiceAccount.
*/}}
{{- define "avalanche.observerKubernetes.serviceAccountName" -}}
{{- if .Values.cloudserviceaccount.deploy -}}
{{- required "cloudserviceaccount.name is required when cloudserviceaccount.deploy is true (observer-kubernetes reuses that ServiceAccount; an empty name yields an empty serviceAccountName and ClusterRoleBinding subject)" .Values.cloudserviceaccount.name -}}
{{- else -}}
{{- printf "%s-observer-kubernetes" (include "avalanche.fullname" .) -}}
{{- end -}}
{{- end }}

{{/*
ServiceAccount name for the observer-prometheus pod.

Unlike observer-kubernetes, this observer only scrapes an HTTP /metrics
endpoint — it needs NO k8s API ClusterRole, only AWS credentials to write to
Timestream. When cloudserviceaccount is deployed (e.g. DS4, IRSA), reuse that
ServiceAccount so the pod inherits its Timestream IRSA role. When it is not
deployed (sandbox/local, where AWS creds are injected directly), this returns
empty so the Deployment falls back to the default ServiceAccount — it must NOT
reuse the observer-kubernetes SA, which only exists when observerKubernetes is
enabled (QA-1121).
*/}}
{{- define "avalanche.observerPrometheus.serviceAccountName" -}}
{{- if .Values.cloudserviceaccount.deploy -}}
{{- required "cloudserviceaccount.name is required when cloudserviceaccount.deploy is true (observer-prometheus reuses that ServiceAccount for its Timestream IRSA role)" .Values.cloudserviceaccount.name -}}
{{- end -}}
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
Resolve component resources: per-component override wins, otherwise the value
from the active sizing preset (`.Values.presets.<sizingPreset>.<component>.resources`).
A non-empty `<component>.resources` map counts as an override.

Usage:
  resources:
    {{- include "avalanche.componentResources" (dict "ctx" . "component" "injector") | nindent 12 }}
*/}}
{{- define "avalanche.componentResources" -}}
{{- $ctx := .ctx -}}
{{- $component := .component -}}
{{- $override := (index $ctx.Values $component "resources") | default dict -}}
{{- if gt (len $override) 0 -}}
{{- toYaml $override -}}
{{- else -}}
{{- $preset := include "avalanche.presetComponent" (dict "ctx" $ctx "component" $component) | fromYaml -}}
{{- if not (hasKey $preset "resources") -}}
{{- fail (printf "avalanche: sizingPreset %q component %q is missing a 'resources' block" $ctx.Values.sizingPreset $component) -}}
{{- end -}}
{{- toYaml $preset.resources -}}
{{- end -}}
{{- end }}

{{/*
Resolve component replicas: per-component override wins (any non-zero integer),
otherwise the value from the active sizing preset.

Usage:
  replicas: {{ include "avalanche.componentReplicas" (dict "ctx" . "component" "injector") }}
*/}}
{{- define "avalanche.componentReplicas" -}}
{{- $ctx := .ctx -}}
{{- $component := .component -}}
{{- $override := (index $ctx.Values $component "replicas") | default 0 -}}
{{- if gt ($override | int) 0 -}}
{{- $override | int -}}
{{- else -}}
{{- $preset := include "avalanche.presetComponent" (dict "ctx" $ctx "component" $component) | fromYaml -}}
{{- if not (hasKey $preset "replicas") -}}
{{- fail (printf "avalanche: sizingPreset %q component %q is missing 'replicas'" $ctx.Values.sizingPreset $component) -}}
{{- end -}}
{{- $preset.replicas | int -}}
{{- end -}}
{{- end }}

{{/*
Resolve injector workers: `.Values.injector.config.workers` override wins (any
non-zero integer), otherwise the value from the active sizing preset.

Usage in configmap.yaml:
  workers: {{ include "avalanche.injectorWorkers" . }}
*/}}
{{- define "avalanche.injectorWorkers" -}}
{{- $override := .Values.injector.config.workers | default 0 -}}
{{- if gt ($override | int) 0 -}}
{{- $override | int -}}
{{- else -}}
{{- $preset := include "avalanche.presetComponent" (dict "ctx" . "component" "injector") | fromYaml -}}
{{- if not (hasKey $preset "workers") -}}
{{- fail (printf "avalanche: sizingPreset %q injector block is missing 'workers'" .Values.sizingPreset) -}}
{{- end -}}
{{- $preset.workers | int -}}
{{- end -}}
{{- end }}

{{/*
Look up a component's block in the active sizing preset, returned as YAML
(callers pipe through fromYaml). Fails fast with a clear, actionable message
if the sizingPreset name — or the component within it — is unknown, instead of
a nil dereference deep in a template.
*/}}
{{- define "avalanche.presetComponent" -}}
{{- $ctx := .ctx -}}
{{- $component := .component -}}
{{- $preset := index $ctx.Values.presets $ctx.Values.sizingPreset -}}
{{- if not $preset -}}
{{- fail (printf "avalanche: unknown sizingPreset %q — valid presets: %s" $ctx.Values.sizingPreset (keys $ctx.Values.presets | sortAlpha | join ", ")) -}}
{{- end -}}
{{- $block := index $preset $component -}}
{{- if not $block -}}
{{- fail (printf "avalanche: sizingPreset %q has no entry for component %q" $ctx.Values.sizingPreset $component) -}}
{{- end -}}
{{- toYaml $block -}}
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

