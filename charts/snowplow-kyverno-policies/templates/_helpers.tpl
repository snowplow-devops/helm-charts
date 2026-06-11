{{/*
Chart name and version, for the helm.sh/chart label.
*/}}
{{- define "snowplow-kyverno-policies.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels. User-supplied .Values.labels are emitted first.
*/}}
{{- define "snowplow-kyverno-policies.labels" -}}
{{- with .Values.labels -}}
{{ toYaml . }}
{{ end -}}
helm.sh/chart: {{ include "snowplow-kyverno-policies.chart" . }}
app.kubernetes.io/name: {{ .Chart.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: kyverno
{{- end -}}

{{/*
Cloud provider, safe against a missing .Values.global.
*/}}
{{- define "snowplow-kyverno-policies.cloud" -}}
{{- with .Values.global -}}{{- .cloud -}}{{- end -}}
{{- end -}}

{{/*
Aggregated ClusterRole for a generate/mutate policy that must act on cluster
resources. Kyverno's background and admission controllers pick up these rules
via the rbac.kyverno.io/aggregate-to-* labels, so the policy can read its
trigger resources and write the resources it generates.
Usage:
  include "snowplow-kyverno-policies.aggregationClusterRole" (dict "name" "kyverno:foo" "rules" $rules "ctx" $)
*/}}
{{- define "snowplow-kyverno-policies.aggregationClusterRole" -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ .name }}
  labels:
    {{- include "snowplow-kyverno-policies.labels" .ctx | nindent 4 }}
    rbac.kyverno.io/aggregate-to-background-controller: "true"
    rbac.kyverno.io/aggregate-to-admission-controller: "true"
rules:
  {{- toYaml .rules | nindent 2 }}
{{- end -}}
