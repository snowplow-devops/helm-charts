{{/*
Chart name and version, for the helm.sh/chart label.
*/}}
{{- define "snowplow-kyverno-policies.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels merged with any user-supplied .Values.labels.
User labels win on key collision so Terraform-injected labels are authoritative.
*/}}
{{- define "snowplow-kyverno-policies.labels" -}}
{{- $base := dict "helm.sh/chart" (include "snowplow-kyverno-policies.chart" .) "app.kubernetes.io/managed-by" .Release.Service "app.kubernetes.io/part-of" "kyverno" -}}
{{- $merged := merge (deepCopy (.Values.labels | default dict)) $base -}}
{{- toYaml $merged -}}
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
    app.kubernetes.io/instance: kyverno
    app.kubernetes.io/part-of: kyverno
    rbac.kyverno.io/aggregate-to-background-controller: "true"
    rbac.kyverno.io/aggregate-to-admission-controller: "true"
    {{- with .ctx.Values.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
rules:
  {{- toYaml .rules | nindent 2 }}
{{- end -}}
