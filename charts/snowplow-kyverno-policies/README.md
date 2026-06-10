# snowplow-kyverno-policies

Snowplow-authored [Kyverno](https://kyverno.io/) policies for Kubernetes clusters,
packaged as a single Helm release per cluster. The chart targets Kyverno's
CEL-based policy API (`policies.kyverno.io/v1`: `ValidatingPolicy`,
`MutatingPolicy`, `GeneratingPolicy`, ...), not the legacy `kyverno.io/v1`
`ClusterPolicy`.

## Prerequisites

This chart only ships policies and the RBAC they need. It does **not** install
Kyverno or any CRDs. The cluster must already have:

- Kyverno installed with its CRDs (`crds.install=true`), and the background
  controller enabled (it reconciles `GeneratingPolicy`).
- For `ackAcmDnsValidation`: the ACK ACM and Route53 controllers installed.

With default values the chart renders **nothing**, so installing it on a cluster
without these prerequisites is a safe no-op.

## How it is organised

Kyverno policies sit on a spectrum from "static logic" to "pure data", and the
chart treats those cases differently rather than forcing one model:

| Mechanism | Use for | Where it lives |
|-----------|---------|----------------|
| **Curated catalog** (`policies.*`) | Opinionated, logic-heavy policies (lots of CEL). Reviewed and versioned as first-class templates, toggled on/off. | `templates/<cloud>/<name>.yaml` |
| **Data-driven families** (`customPolicies[]`) | N parameterised policies of a kind, where the difference between instances is pure data. No template change to add another. | `templates/generic/custom-policies.yaml` |

Cloud-specific curated policies are gated on both their `enabled` flag **and**
`global.cloud`, so enabling an AWS policy on a non-AWS cluster is a no-op.

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `global.cloud` | `""` | `aws` / `gcp` / `azure`. Gates cloud-specific curated policies. |
| `labels` | `{}` | Extra labels applied to every rendered object. |
| `policies.ackAcmDnsValidation.enabled` | `false` | AWS-only. Bridge ACK ACM `Certificate` validation to ACK Route53 `RecordSet`. |
| `policies.ackAcmDnsValidation.hostedZoneAnnotation` | `snowplow.io/hosted-zone-id` | Certificate annotation carrying the target hosted zone ID. |
| `policies.ackAcmDnsValidation.ttl` | `60` | TTL (seconds) for the generated validation RecordSet. |
| `customPolicies` | `[]` | Data-driven policy families. See below. |

### `ackAcmDnsValidation`

On `Certificate` CREATE/UPDATE, once the ACK ACM controller has populated
`status.domainValidations[]`, this `GeneratingPolicy` creates the DNS-01
validation CNAME as a Route53 `RecordSet` in the hosted zone named by the
Certificate's `hostedZoneAnnotation`. The generated RecordSet carries an
`ownerReference` back to the Certificate so it cascade-deletes.

The Certificate must be labelled `snowplow.io/ack-managed: "true"` and annotated
with the hosted zone ID for the policy to act on it.

### `customPolicies`

Each entry renders one policy of the given `kind`. The chart supplies the
`apiVersion`, name, and standard labels; you supply the `spec` verbatim. For
generating/mutating policies that act on cluster resources, add `rbac.rules` and
the chart renders an aggregated `ClusterRole` for Kyverno's controllers.

```yaml
customPolicies:
  - kind: MutatingPolicy
    name: add-team-label
    spec:
      matchConstraints:
        resourceRules:
          - apiGroups: [""]
            apiVersions: ["v1"]
            operations: ["CREATE"]
            resources: ["pods"]
      mutations: []   # supply the Kyverno spec verbatim
  - kind: GeneratingPolicy
    name: my-generator
    spec: {}
    rbac:
      rules:
        - apiGroups: ["route53.services.k8s.aws"]
          resources: ["recordsets"]
          verbs: ["get", "list", "watch", "create", "update", "delete"]
```

## Consuming from Terraform

`helm_release` should reference the published chart and pin a version:

```hcl
resource "helm_release" "kyverno_policies" {
  name       = "snowplow-kyverno-policies"
  repository = "https://snowplow-devops.github.io/helm-charts"
  chart      = "snowplow-kyverno-policies"
  version    = "0.1.0"
  namespace  = "kyverno"

  values = [
    yamlencode({
      global = { cloud = "aws" }
      policies = {
        ackAcmDnsValidation = { enabled = var.enable_ack_acm_dns_validation }
      }
      labels = {
        "snowplow.io/tf_module"         = local.module_name
        "snowplow.io/tf_module_version" = local.module_version
      }
    })
  ]

  cleanup_on_fail = true
  wait            = false
}
```

> The policies are cluster-scoped regardless of `namespace`; the generated
> RecordSet is created in the triggering Certificate's namespace.

## Adding a new policy

- **Logic-heavy / opinionated** -> add `templates/<cloud>/<name>.yaml`, gate it on
  a new `policies.<name>.enabled` flag (and `global.cloud` if cloud-specific),
  reuse `snowplow-kyverno-policies.aggregationClusterRole` for any RBAC, bump the chart
  version.
- **Parameterised, want N of them** -> no template change; add `customPolicies[]`
  entries in the consumer's values.
