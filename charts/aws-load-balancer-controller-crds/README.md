# aws-load-balancer-controller-crds

A helm chart for the custom resource defintions behind the [aws-load-balancer-controller](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller) chart.  This allows both pieces to be installed with Helm and avoids needing to use `kubectl` to install the resource definition which is important for a fully automated deployment with IaC tooling like Terraform.

The chart templates are pulled entirely from this file: https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/crds/crds.yaml

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install aws-load-balancer-controller-crds --namespace kube-system snowplow-devops/aws-load-balancer-controller-crds
```

## Uninstalling the Chart

To uninstall/delete the `aws-load-balancer-controller-crds` release:

```bash
helm delete aws-load-balancer-controller-crds --namespace kube-system
```
