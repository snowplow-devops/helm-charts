# karpenter-crds

A helm chart for the custom resource definitions behind [Karpenter](https://karpenter.sh/). This allows the CRDs to be installed with Helm and avoids needing to use `kubectl` to install the resource definitions, which is important for a fully automated deployment with IaC tooling like Terraform.

The CRDs are stored under `templates/` so they render as regular manifest chunks that are compatible with `helm template` consumers (e.g. Terraform `data "helm_template"`). They are pulled entirely from the upstream Karpenter chart: https://github.com/aws/karpenter-provider-aws/tree/main/charts/karpenter/crds

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrade the chart:

```bash
helm upgrade --install karpenter-crds --namespace karpenter snowplow-devops/karpenter-crds --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `karpenter-crds` release:

```bash
helm delete karpenter-crds --namespace karpenter
```

Note: Because the CRDs are stored under `templates/`, deleting this release will also delete the CRDs and any custom resources that use them.
