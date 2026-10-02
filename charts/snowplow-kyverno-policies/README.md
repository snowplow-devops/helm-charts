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
| `policies.ackAcmDnsValidation.evaluation.admission` | `true` | Generate the RecordSet on Certificate admission (CREATE/UPDATE). |
| `policies.ackAcmDnsValidation.evaluation.generateExisting` | `true` | Generate for Certificates that already exist when the policy is installed. |
| `policies.ackAcmDnsValidation.evaluation.synchronize` | `true` | Re-reconcile the generated RecordSet if it is modified or deleted. |
| `policies.disableServiceAccountTokenAutomount.mutate.enabled` | `false` | Patch Pods on CREATE to `spec.automountServiceAccountToken: false`. |
| `policies.disableServiceAccountTokenAutomount.validate.enabled` | `false` | Report or block Pods that do not set it to `false`. |
| `policies.disableServiceAccountTokenAutomount.validate.validationActions` | `[Audit]` | `Audit` (PolicyReport only), `Warn` (admission warning) or `Deny` (block). |
| `policies.disableServiceAccountTokenAutomount.validate.failurePolicy` | `Ignore` | `Fail` makes admission depend on the Kyverno webhook being up. |
| `policies.disableServiceAccountTokenAutomount.validate.background` | `true` | Background-scan already-running Pods into PolicyReports. |
| `policies.disableServiceAccountTokenAutomount.excludedNamespaces` | `[kube-system, kyverno]` | Namespaces exempt from both modes. Emptying it applies the policy cluster-wide. |
| `policies.disableServiceAccountTokenAutomount.exemptionLabel` | `snowplow.io/automount-service-account-token` | Pods labelled `<key>: "true"` are exempt from both modes. `""` removes the escape hatch. |
| `policies.requireResourceLimits.enabled` | `false` | Report or block Pods whose containers do not set `resources.limits` for every `requiredLimits` entry. |
| `policies.requireResourceLimits.requiredLimits` | `[cpu]` | Resource names each container must limit. Add `memory` to extend. |
| `policies.podSecurityRestricted.enabled` | `false` | The Pod Security Standards `restricted` profile, as 15 `pss-*` ValidatingPolicies. |
| `policies.requireImageDigest.enabled` | `false` | Report or block Pods with an image not pinned by digest. |
| `policies.restrictImageRegistries.enabled` | `false` | Report or block Pods with an image from outside `allowedRegistries`. |
| `policies.restrictImageRegistries.allowedRegistries` | `[]` | Registry hosts, optionally with a repository path. Required when enabled. |
| `policies.requireNamespaceNetworkPolicy.enabled` | `false` | Report or block Pods created in a namespace with no NetworkPolicy. Also renders a ClusterRole. |
| `policies.restrictSecretMounts.enabled` | `false` | Report or block Pods that reference a Secret not in `allowedSecrets`. |
| `policies.restrictSecretMounts.allowedSecrets` | `[]` | Exact Secret names Pods may reference. Empty allows none. |
| `policies.<policy>.validationActions` | `[Audit]` | For each policy above. `Audit`, `Warn` or `Deny`. |
| `policies.<policy>.failurePolicy` | `Ignore` | For each policy above. `Fail` makes admission depend on the Kyverno webhook being up. |
| `policies.<policy>.background` | `true` | For each policy above. Background-scan already-running Pods into PolicyReports. |
| `policies.<policy>.excludedNamespaces` | `[kube-system, kyverno]` | For each policy above. Emptying it applies the policy cluster-wide. |
| `policies.<policy>.exemptionLabel` | see [Exemption labels](#exemption-labels) | For each policy above. Pods labelled `<key>: "true"` are exempt. `""` removes the escape hatch. |
| `customPolicies` | `[]` | Data-driven policy families. See below. |

### `ackAcmDnsValidation`

On `Certificate` CREATE/UPDATE, once the ACK ACM controller has populated
`status.domainValidations[]`, this `GeneratingPolicy` creates the DNS-01
validation CNAME as a Route53 `RecordSet` in the hosted zone named by the
Certificate's `hostedZoneAnnotation`. The generated RecordSet carries an
`ownerReference` back to the Certificate so it cascade-deletes.

The Certificate must be labelled `snowplow.io/ack-managed: "true"` and annotated
with the hosted zone ID for the policy to act on it.

### `disableServiceAccountTokenAutomount`

Cloud-agnostic. Stops Pods mounting a ServiceAccount token they do not need. The
two modes are independent and can be enabled together:

- **`mutate`** renders a `MutatingPolicy` that patches Pods on CREATE to
  `spec.automountServiceAccountToken: false`. Nothing else has to change:
  controller-created Pods are patched at admission regardless of what the
  Deployment/StatefulSet template says, so no workload chart needs editing.
- **`validate`** renders a `ValidatingPolicy` that flags (or with
  `validationActions: [Deny]`, blocks) Pods that do not have it set to `false`,
  for ongoing compliance.

With both enabled the mutation runs first in the admission chain, so the
validation sees the patched Pod and passes.

#### What this does and does not break

Cloud identity is **unaffected**. IRSA and Azure Workload Identity inject their
own projected token volumes (`aws-iam-token`, `azure-identity-token`) through
separate webhooks; `automountServiceAccountToken` only governs the default
`kube-api-access-*` volume, so there is no conflict.

In-cluster Kubernetes API clients **are** affected. Anything that builds an
in-cluster client — Kyverno itself, cluster-autoscaler, Karpenter, the AWS Load
Balancer Controller, cert-manager, external-dns, ACK controllers, CoreDNS — loses
its credentials and fails to authenticate. This is why the policies are not
cluster-wide by default: exempt those workloads by namespace
(`excludedNamespaces`) or per Pod (`exemptionLabel`) **before** enabling `mutate`,
and roll out through `validate` with `validationActions: [Audit]` first to find
them.

#### Other caveats

- `automountServiceAccountToken` is immutable on a running Pod, so the mutation
  only takes effect as Pods are recreated. There is no mutate-existing mode.
- The policies match Pods, not workloads. Under `Deny`, a rejected Pod does not
  reject its Deployment — the rollout stalls with events on the ReplicaSet
  instead of failing the `kubectl apply`.
- The validation requires the field to be set to `false` *on the Pod*. A Pod
  that leaves it unset while its ServiceAccount sets
  `automountServiceAccountToken: false` is effectively compliant but will still
  be flagged; enabling `mutate` alongside makes the two agree.
- Namespaces are excluded on the `kubernetes.io/metadata.name` label the API
  server sets on every namespace, so no namespace labelling is needed.
- Emptying `excludedNamespaces` (`[]` or `null`) is not "exclude nothing safely":
  it drops the `namespaceSelector` from the policy entirely, so it applies
  cluster-wide, including `kube-system`. In `mutate` mode that will break
  in-cluster controllers such as CoreDNS as their Pods are recreated. Override it
  to add namespaces, not to clear it.

```yaml
policies:
  disableServiceAccountTokenAutomount:
    mutate:
      enabled: true
    validate:
      enabled: true
      validationActions:
        - Audit
    excludedNamespaces:
      - kube-system
      - kyverno
      - cert-manager
      - karpenter
```

### Pod-validating security policies

The policies below were added together for clusters that run untrusted
workloads, such as AI agents. They share the same shape, and everything in this
section applies to all of them:

- Each renders a `ValidatingPolicy` matching Pod **CREATE**, defaulting to
  `validationActions: [Audit]` and `failurePolicy: Ignore`, with background
  scanning on. Enabling one only produces PolicyReports until it is moved to
  `Deny`, and no running Pod is restarted.
- They match Pods, not workloads. Under `Deny`, a rejected Pod stalls its
  Deployment's rollout with events on the ReplicaSet.
- containers, initContainers and ephemeralContainers are all checked. The one
  exception is `requireResourceLimits`, since ephemeral containers cannot set
  resources.
- `podSecurityRestricted`, `requireImageDigest`, `restrictImageRegistries` and
  `restrictSecretMounts` also match the `pods/ephemeralcontainers`
  subresource, so `kubectl debug` is checked at admission rather than only by
  the next background scan. Under `Deny` a debug container must itself comply:
  for the Pod Security policies use `kubectl debug --profile=restricted`, or
  exempt the Pod. Plain Pod UPDATE is not matched, so label and annotation
  changes on running Pods are never re-validated.
- A missing field is a CEL evaluation error. Kyverno reports an error as an
  `error` result under `Audit` and denies the Pod under `Deny`, whatever
  `failurePolicy` says (`failurePolicy` covers the webhook being unreachable).
  An unguarded expression would therefore block compliant Pods under `Deny`, so
  the expressions guard every field access, and the tests assert zero
  evaluation errors.

#### Exemption labels

| Policy | `exemptionLabel` default |
|--------|--------------------------|
| `requireResourceLimits` | `snowplow.io/skip-resource-limits` |
| `podSecurityRestricted` | `snowplow.io/skip-pod-security` |
| `requireImageDigest` | `snowplow.io/skip-image-digest` |
| `restrictImageRegistries` | `snowplow.io/skip-image-registries` |
| `requireNamespaceNetworkPolicy` | `snowplow.io/skip-namespace-network-policy` |
| `restrictSecretMounts` | `snowplow.io/skip-secret-mounts` |

#### `requireResourceLimits`

Every container and initContainer must set `resources.limits` for each name in
`requiredLimits` (default `cpu`). PID limits are not covered: Kubernetes has no
per-container `pids` resource, so they belong in the kubelet `podPidsLimit`.

#### `podSecurityRestricted`

The Kubernetes [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
`restricted` profile, which includes `baseline`, rendered as one `pss-<control>`
ValidatingPolicy per control so that PolicyReports show which control a Pod
fails. Each control mirrors the matching check in
[`k8s.io/pod-security-admission`](https://github.com/kubernetes/pod-security-admission)
at Kubernetes 1.35, including the Windows and `hostUsers: false` relaxations.
The tests use that library's verdicts as their expected results.

This does not use Kyverno's upstream `pod-security-vpol` policies, which differ
from PSA 1.35 in several places: they miss the AppArmor and probe-host controls,
pass Pods with no seccomp profile, reject `image` volumes and use an older sysctl
allowlist.

It complements Pod Security Admission namespace labels rather than replacing
them. PSA enforces per namespace, with no per-Pod exemption and no reporting.
This reports cluster-wide and honours `exemptionLabel`.

#### `requireImageDigest`

Every image must be pinned by digest: `image@sha256:...` or
`image:tag@sha256:...`. An image reference Kyverno cannot parse is reported as
unpinned rather than admitted. Kyverno's parser also rejects single-character
repository names on registries other than Docker Hub (for example `ghcr.io/x`).

#### `restrictImageRegistries`

Every image must come from an entry in `allowedRegistries`. An image passes if
it matches **any** entry, so give each registry its own entry rather than its own
policy, because separate policies would each reject the other registries' images.

Entries match on whole path segments: `ghcr.io/acme` allows `ghcr.io/acme/app`
but not `ghcr.io/acme-evil/app`. Images are compared after Kyverno normalises
them, so `snowplow/x`, `docker.io/snowplow/x` and `index.docker.io/snowplow/x`
are the same image, and a leading `docker.io` in an entry is treated as
`index.docker.io`. Other spellings of a host, such as `registry-1.docker.io` or
an explicit `:443`, are not normalised and do not match.

```yaml
policies:
  restrictImageRegistries:
    enabled: true
    allowedRegistries:
      - 793733611312.dkr.ecr.eu-central-1.amazonaws.com
      - docker.io/snowplow
```

#### `requireNamespaceNetworkPolicy`

A Pod must be created in a namespace that already contains at least one
NetworkPolicy. It matches Pod creation rather than Namespace creation because a
NetworkPolicy cannot exist before its namespace, so a Namespace check would
reject every new namespace. Whatever creates the namespace must create its
NetworkPolicy before the namespace's first Pod.

- It checks existence only. An allow-all NetworkPolicy satisfies it, so it is
  only useful paired with a default-deny that the namespace's own stack owns.
- Each evaluation lists NetworkPolicies from the API server. Kyverno's chart
  already allows that through its `view` role binding (`createViewRoleBinding`,
  on by default). This policy also renders a ClusterRole granting `get`/`list`
  on `networkpolicies`, aggregated into Kyverno's admission and reports
  controllers, so it keeps working when that binding is turned off.
- A failed lookup is an evaluation error, so under `Deny` it blocks the Pod
  whatever `failurePolicy` says. Moving this policy to `Deny` makes Pod
  creation in the covered namespaces depend on the API server answering the
  lookup.

#### `restrictSecretMounts`

Pods may only reference Secrets named in `allowedSecrets`: secret and projected
secret volumes, `env[].valueFrom.secretKeyRef`, and `envFrom[].secretRef`.
`imagePullSecrets` and CSI `nodePublishSecretRef` are not checked, since the
kubelet consumes them without exposing the Secret to the container. An empty
`allowedSecrets` allows no Secrets at all.

It is an allowlist rather than a check for a credential label for two reasons.
Nothing marks credential Secrets today, and reading a Secret's labels would need
Kyverno to have cluster-wide `get` on Secrets. A Secret missing from the list is
reported rather than silently allowed.

It applies to every Pod outside `excludedNamespaces`, so it suits clusters where
all such Pods are untrusted, such as a dedicated agent cluster. On a shared
cluster it would flag every workload that uses a Secret.

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
  version    = "0.3.0"
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
  reuse `snowplow-kyverno-policies.aggregationClusterRole` for RBAC the admission
  and background controllers need, bump the chart version. That helper does not
  aggregate into the reports controller, so a ValidatingPolicy that looks up
  resources during background scans needs its own ClusterRole, as in
  `templates/generic/require-namespace-network-policy.yaml`. A Pod-validating
  policy should reuse the `podMatchConstraints` and `podMatchConditions` helpers
  and add a test suite (see Testing).
- **Parameterised, want N of them** -> no template change; add `customPolicies[]`
  entries in the consumer's values.

## Testing

Each curated policy has a [`kyverno test`](https://kyverno.io/docs/kyverno-cli/reference/kyverno_test/)
suite in `tests/kyverno/<policy>/`:

| File | Purpose |
|------|---------|
| `chart-values.yaml` | Chart values that enable the policy under test |
| `kyverno-test.yaml` | Expected result (`pass` / `fail` / `skip`) per fixture |
| `resources.yaml` | Fixture Pods, one per code path |
| `context.yaml` | Optional. Cluster objects for `resource.List()` lookups |

The policies are Go templates, so they cannot be tested as committed.
`scripts/kyverno-policy-test.sh` copies each suite to a temp directory, renders
the chart there as `policy.yaml` with `chart-values.yaml`, and runs
`kyverno test` against it. A suite whose values render no policy fails rather
than passing with nothing to test.

```bash
scripts/kyverno-policy-test.sh                                   # every suite
scripts/kyverno-policy-test.sh charts/snowplow-kyverno-policies/tests/kyverno/require-image-digest
```

CI runs every suite in the `schema` job of `.github/workflows/lint-test.yml`,
with the kyverno CLI pinned and checksum-verified. `tests/` is excluded from the
packaged chart by `.helmignore`.
