# traefik-crds

A helm chart for the custom resource definitions behind the [Traefik](https://github.com/traefik/traefik-helm-chart) chart. This allows both pieces to be installed with Helm and avoids needing to use `kubectl` to install the resource definitions, which is important for a fully automated deployment with IaC tooling like Terraform.

The `traefik-crds` chart is meant to be used along with the [Traefik](https://github.com/traefik/traefik-helm-chart) chart. The reason for separating the CRDs outside the Traefik helm release is for safety reasons. If you manage the CRDs within the `traefik` helm release and you uninstall the release, the CRDs will also be uninstalled. If the CRDs are uninstalled, you will lose all instances of IngressRoute, Middleware, and other Traefik resources in your cluster. This helm chart allows both to be managed with helm and provides flexibility of managing the CRDs outside the Traefik helm release.

The chart templates are pulled entirely from Traefik helm chart release: https://github.com/traefik/traefik-helm-chart/tree/v27.0.2/traefik/crds

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install traefik-crds --namespace traefik snowplow-devops/traefik-crds
```

## Uninstalling the Chart

To uninstall/delete the `traefik-crds` release:

```bash
helm delete traefik-crds --namespace traefik
```
