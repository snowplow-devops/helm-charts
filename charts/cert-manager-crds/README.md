# cert-manager-crds

A helm chart for the custom resource defintions behind the [cert-manager](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager) chart.  This allows both pieces to be installed with Helm and avoids needing to use `kubectl` to install the resource definition which is important for a fully automated deployment with IaC tooling like Terraform.

The `cert-manager-crds` chart is meant to be used along with the [cert-manager](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager) chart. The reason for separating the CRDS outside the cert-manager helm release is for safety reasons, as it is the [recommended approach](https://cert-manager.io/docs/installation/helm/#3-install-customresourcedefinitions) to install CRDS with `kubectl`. If you manage the CRDS within the `cert-manager` helm release and you uninstall the release, the CRDs will also be uninstalled. If the CRDS are uninstalled, you will loose all instances of Certificate resources in your cluster. This helm chart will allow both to be managed with helm and provides flexibility of managing the CRDS outside the cert-manager helm release. 

The chart templates are pulled entirely from cert-manager release downloads: https://github.com/cert-manager/cert-manager/releases/download/v{RELEASE_VERSION}/cert-manager.crds.yaml

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install cert-manager-crds --namespace cert-manager snowplow-devops/cert-manager-crds
```

## Uninstalling the Chart

To uninstall/delete the `cert-manager-crds` release:

```bash
helm delete cert-manager-crds --namespace cert-manager
```

