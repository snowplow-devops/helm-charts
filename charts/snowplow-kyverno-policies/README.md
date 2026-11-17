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
| `globalExemptionLabel` | `""` | Opt-in. When set (for example `snowplow.io/kyverno-exempt`), Pods labelled `<key>: "true"` are exempt from every Pod policy, on top of each policy's own `exemptionLabel`, including policies in `Deny` mode. |
| `policies.ackAcmDnsValidation.enabled` | `false` | AWS-only. Bridge ACK ACM `Certificate` validation to ACK Route53 `RecordSet`. |
| `policies.ackAcmDnsValidation.hostedZoneAnnotation` | `snowplow.io/hosted-zone-id` | Certificate annotation carrying the target hosted zone ID. |
| `policies.ackAcmDnsValidation.ttl` | `60` | TTL (seconds) for the generated validation RecordSet. |
| `policies.ackAcmDnsValidation.evaluation.admission` | `true` | Generate the RecordSet on Certificate admission (CREATE/UPDATE). |
| `policies.ackAcmDnsValidation.evaluation.generateExisting` | `true` | Generate for Certificates that already exist when the policy is installed. |
| `policies.ackAcmDnsValidation.evaluation.synchronize` | `true` | Re-reconcile the generated RecordSet if it is modified or deleted. |
| `policies.disableServiceAccountTokenAutomount.mutate.enabled` | `false` | Patch Pods on CREATE to `spec.automountServiceAccountToken: false`. |
| `policies.disableServiceAccountTokenAutomount.mutate.failurePolicy` | `Ignore` | `Fail` blocks every Pod CREATE in the matched namespaces while the Kyverno webhook is unavailable. |
| `policies.disableServiceAccountTokenAutomount.mutate.removeTokenVolume` | `false` | Also remove the `kube-api-access-*` token volume and its mounts. Without it the token stays mounted. See [Removing the token](#removing-the-token). |
| `policies.disableServiceAccountTokenAutomount.validate.enabled` | `false` | Report or block Pods that do not set it to `false`. |
| `policies.disableServiceAccountTokenAutomount.validate.validationActions` | `[Audit]` | `Audit` (PolicyReport only), `Warn` (admission warning) or `Deny` (block). |
| `policies.disableServiceAccountTokenAutomount.validate.failurePolicy` | `Ignore` | `Fail` makes admission depend on the Kyverno webhook being up. |
| `policies.disableServiceAccountTokenAutomount.validate.background` | `true` | Background-scan already-running Pods into PolicyReports. |
| `policies.disableServiceAccountTokenAutomount.validate.checkMountedToken` | `false` | Fail Pods where a container mounts a `kube-api-access-*` volume, instead of checking the field. Under `Deny` requires `mutate.removeTokenVolume`. |
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
  `spec.automountServiceAccountToken: false`, and with `removeTokenVolume` also
  removes the token itself (see [Removing the token](#removing-the-token)).
  Controller-created Pods are patched at admission regardless of what the
  Deployment/StatefulSet template says, so no workload chart needs editing.
- **`validate`** renders a `ValidatingPolicy` that flags (or with
  `validationActions: [Deny]`, blocks) Pods that do not have it set to `false`,
  or with `checkMountedToken`, Pods that still mount the token, for ongoing
  compliance.

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

#### Opting a workload out

There are four ways to keep the token for a workload that needs the Kubernetes
API. Use the narrowest one that fits. Labels can be set by anyone who can create
the Pod; a `PolicyException` can be restricted to cluster admins.

| Option | Scope | Use it when |
|--------|-------|-------------|
| `excludedNamespaces` | Every Pod in the namespace | The whole namespace is cluster infrastructure (controllers, operators). Set in this chart's values. |
| `exemptionLabel` on the Pod | One workload, this policy only | You control the workload's Pod template, for example through its chart's `podLabels` value. |
| `globalExemptionLabel` on the Pod | One workload, every Pod policy in this chart | Off by default. Only if the cluster sets it and the workload must also skip the other policies. Prefer the per-policy label. |
| `PolicyException` | Workloads selected by a CEL condition | You cannot label the Pods, for example a third-party chart without a `podLabels` value, Helm hook Jobs, or Jobs created by a CronJob. |

**Label.** Put the label on the Pod template, not only on the Deployment,
CronJob or other controller. Kyverno checks it both on the Pod and, through
autogen, on the controller's `spec.template`:

```yaml
# e.g. a chart's podLabels value, or spec.template.metadata.labels
snowplow.io/automount-service-account-token: "true"
```

The label is the default `exemptionLabel`. It exempts the Pod from both
`mutate` and `validate`, and it has no effect on clusters without Kyverno, so it
is safe to set unconditionally. If a cluster sets `globalExemptionLabel`, that
label works the same way but exempts the Pod from every Pod policy.

**PolicyException.** Kyverno must have PolicyExceptions enabled
(`features.policyExceptions.enabled` in the Kyverno chart). Restrict them to a
namespace that workload owners cannot write to
(`features.policyExceptions.namespace`), otherwise anyone who can create Pods
in a namespace can also exempt them. Reference both policies, so an exempted
workload is not rejected once `validate` moves to `Deny`, and keep the condition
as narrow as possible:

```yaml
apiVersion: policies.kyverno.io/v1beta1
kind: PolicyException
metadata:
  name: my-namespace-my-release
  namespace: kyverno   # the namespace set in features.policyExceptions.namespace
spec:
  policyRefs:
    - name: disable-automount-service-account-token
      kind: MutatingPolicy
    - name: require-service-account-token-automount-disabled
      kind: ValidatingPolicy
  matchConditions:
    - name: release-workloads
      # Guard every field access with has(). An evaluation error counts as a
      # policy error, so an unguarded expression can block Pod creation.
      expression: >-
        request.namespace == 'my-namespace' &&
        has(object.metadata.labels) &&
        object.metadata.labels['app.kubernetes.io/instance'] == 'my-release'
```

As with the policies themselves, an exception only affects Pods created after
it exists. Recreate the workload's Pods to pick it up.

#### Removing the token

The ServiceAccount admission plugin runs before any webhook. By the time Kyverno
sees a Pod, the plugin has already added the `kube-api-access-<random>` projected
volume and mounted it into every container. Setting
`automountServiceAccountToken: false` at that point changes the field but not
the mount, so with the defaults the token is still there.

- **`mutate.removeTokenVolume: true`** also removes that volume, and every
  `volumeMount` of it from `containers` and `initContainers`. Ephemeral
  containers cannot be set on Pod CREATE, and one added later through
  `kubectl debug` has no token volume left to mount. Only projected volumes named `kube-api-access-*` are
  removed. IRSA (`aws-iam-token`), EKS Pod Identity (`eks-pod-identity-token`)
  and Azure Workload Identity (`azure-identity-token`) tokens are left alone,
  so cloud credentials keep working.
- **`validate.checkMountedToken: true`** makes the validation check what is
  actually mounted: it fails a Pod where any container mounts a
  `kube-api-access-*` volume, and passes one that mounts none, whatever the
  field says. That also fixes the ServiceAccount-level case in the caveats below.

Both default to `false`, so upgrading to 0.4.0 does not change behaviour.
Mutating webhooks run before validating ones, so with both on a Pod is
validated after its token is removed and passes. Under `Deny`,
`checkMountedToken` without `removeTokenVolume` would reject every Pod in
scope, so the chart refuses to render that combination.

With both on and `Deny`, mind the `failurePolicy` interaction. With the default
`Ignore` on both webhooks, a Kyverno outage skips both and Pods are admitted
with their token, so nothing is blocked. If only the mutation call fails (it
errors or times out) while the validation call succeeds, the token is still
mounted and that Pod is denied; its controller retries. In other words `Deny`
fails closed on a failed mutation but still fails open on an outage. Setting
the mutation's `failurePolicy` to `Fail` is not recommended: it blocks every Pod
in scope whenever Kyverno is unavailable. Use `Audit` instead of `Deny` if Pods
must never be rejected by this policy.

Turn `removeTokenVolume` on only once every workload in scope that calls the
Kubernetes API has an opt-out (`exemptionLabel`, `excludedNamespaces`, a
PolicyException or, if the cluster sets it, `globalExemptionLabel`), because from then on those Pods
really lose the token as they are recreated.

#### Other caveats

- `automountServiceAccountToken` is immutable on a running Pod, so the mutation
  only takes effect as Pods are recreated. There is no mutate-existing mode.
- The policies match Pods, not workloads. Under `Deny`, a rejected Pod does not
  reject its Deployment — the rollout stalls with events on the ReplicaSet
  instead of failing the `kubectl apply`.
- Without `checkMountedToken`, the validation requires the field to be set to
  `false` *on the Pod*. A Pod that leaves it unset while its ServiceAccount sets
  `automountServiceAccountToken: false` is effectively compliant but will still
  be flagged; enabling `mutate` alongside makes the two agree. It also passes a
  Pod that sets the field but still mounts the token, which is what every Pod
  looks like after a `mutate` without `removeTokenVolume`.
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
- Enabling any of `podSecurityRestricted`, `requireImageDigest`,
  `restrictImageRegistries` or `restrictSecretMounts` also renders a ClusterRole
  granting `get`/`list`/`watch` on `pods/ephemeralcontainers`, aggregated into
  Kyverno's reports controller. Those policies match that subresource, and
  without the permission they never report Ready.
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

If `globalExemptionLabel` is set (it is off by default), every Pod policy,
`disableServiceAccountTokenAutomount` included, also skips Pods labelled with it
set to `"true"`, even in `Deny` mode. Prefer the per-policy label: it exempts a
Pod from one policy instead of all of them.

| Policy | `exemptionLabel` default |
|--------|--------------------------|
| `disableServiceAccountTokenAutomount` | `snowplow.io/automount-service-account-token` |
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
  `templates/generic/require-namespace-network-policy.yaml`. A policy that
  matches `pods/ephemeralcontainers` must be added to the condition in
  `templates/generic/ephemeral-containers-rbac.yaml`. A Pod-validating
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
| `patched.yaml` | Optional. Expected Pods after a MutatingPolicy (`patchedResources`) |

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
