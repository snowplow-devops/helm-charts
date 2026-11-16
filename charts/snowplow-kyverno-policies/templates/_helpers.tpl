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

{{/*
Shared matchConstraints for the service-account-token automount policies: Pod
CREATE, minus any excluded namespaces. Namespaces are excluded on the
kubernetes.io/metadata.name label the API server sets on every namespace, so no
labelling of the namespaces themselves is required.
Usage:
  include "snowplow-kyverno-policies.automountMatchConstraints" .Values.policies.disableServiceAccountTokenAutomount
*/}}
{{- define "snowplow-kyverno-policies.automountMatchConstraints" -}}
resourceRules:
  - apiGroups:
      - ""
    apiVersions:
      - v1
    operations:
      - CREATE
    resources:
      - pods
{{- with .excludedNamespaces }}
namespaceSelector:
  matchExpressions:
    - key: kubernetes.io/metadata.name
      operator: NotIn
      values:
        {{- toYaml . | nindent 8 }}
{{- end }}
{{- end -}}

{{/*
Generic matchConstraints for a Pod-validating curated policy: Pod CREATE, minus
any excluded namespaces (matched on the kubernetes.io/metadata.name label).
With ephemeralContainers true it also matches UPDATE of the
pods/ephemeralcontainers subresource, which is how `kubectl debug` adds a
container to a running Pod; without it a debug container is only caught by
background scans. Plain Pod UPDATE is deliberately not matched, so label and
annotation changes on running Pods are never re-validated.
Usage:
  include "snowplow-kyverno-policies.podMatchConstraints" (dict "policy" .Values.policies.<policy> "ephemeralContainers" true)
*/}}
{{- define "snowplow-kyverno-policies.podMatchConstraints" -}}
resourceRules:
  - apiGroups:
      - ""
    apiVersions:
      - v1
    operations:
      - CREATE
    resources:
      - pods
{{- if .ephemeralContainers }}
  - apiGroups:
      - ""
    apiVersions:
      - v1
    operations:
      - UPDATE
    resources:
      - pods/ephemeralcontainers
{{- end }}
{{- with .policy.excludedNamespaces }}
namespaceSelector:
  matchExpressions:
    - key: kubernetes.io/metadata.name
      operator: NotIn
      values:
        {{- toYaml . | nindent 8 }}
{{- end }}
{{- end -}}

{{/*
Shared matchConditions for every Pod policy, the service-account-token
automount policies included. Skips Pods that carry the policy's own
exemptionLabel, or the chart-wide globalExemptionLabel, set to "true". Each
label renders as its own condition and an empty label renders nothing, so with
both empty the result is empty and callers must guard the matchConditions key.
Usage:
  include "snowplow-kyverno-policies.podMatchConditions" (dict "policy" .Values.policies.<policy> "root" $)
*/}}
{{- define "snowplow-kyverno-policies.podMatchConditions" -}}
{{- with .policy.exemptionLabel }}
- name: pod-not-exempt
  expression: >-
    !has(object.metadata.labels) ||
    !('{{ . }}' in object.metadata.labels) ||
    object.metadata.labels['{{ . }}'] != 'true'
{{- end }}
{{- with .root.Values.globalExemptionLabel }}
- name: pod-not-globally-exempt
  expression: >-
    !has(object.metadata.labels) ||
    !('{{ . }}' in object.metadata.labels) ||
    object.metadata.labels['{{ . }}'] != 'true'
{{- end }}
{{- end -}}
