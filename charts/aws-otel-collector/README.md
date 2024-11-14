# aws-otel-collector

A helm chart for [AWS-open-telemetry-collector](https://github.com/aws-observability/aws-otel-collector).

The deployment is based largely on this [Kubernetes Manifest](https://github.com/aws-observability/aws-otel-collector/blob/main/deployment-template/eks/otel-container-insights-infra.yaml) but with some specific changes to reduce the cost foot-print of the exported metrics from EKS.  Focusing in on reporting only:

1. CPU Utilization: For individual named pods + aggregate over the service
2. Memory: For individual named pods + aggregate over the service
3. Number of pods for a particular service

Further reading on this system:

- https://aws.amazon.com/blogs/containers/cost-savings-by-customizing-metrics-sent-by-container-insights-in-amazon-eks/
- https://aws-otel.github.io/docs/getting-started/container-insights/eks-infra#configure-metrics-sent-by-cloudwatch-embedded-metric-format-exporter

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install aws-otel-collector --namespace kube-system snowplow-devops/aws-otel-collector
```

## Uninstalling the Chart

To uninstall/delete the `aws-otel-collector` release:

```bash
helm delete aws-otel-collector --namespace kube-system
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterName | string | `""` | Sets cluster name for log groups and kube label for prometheus metric dimensions |
| nameOverride | string | `""` | Overrides the name given to the deployment (default: .Release.Name) |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| image.repository | string | `"public.ecr.aws/aws-observability/aws-otel-collector"` | Image to use for deploying |
| image.tag | string | `"v0.33.1"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| kube_state_metrics_enabled | bool | `false` | Whether to collect kube-state-metrics |
| performance_log_retention_in_days | int | `30` | The retention for performance log group |
| prometheus_log_retention_in_days | int | `30` | The retention for prometheus log group|
| resources.limits.cpu | string | `""` |  |
| resources.limits.memory | string | `"200Mi"` |  |
| resources.requests.cpu | string | `"20m"` |  |
| resources.requests.memory | string | `"100Mi"` |  |
| serviceAccount.create | bool | `true` | Whether to create a service account or not |
| serviceAccount.name | string | `""` | The name of the service account to create or use |
| serviceAccount.annotations | object | `{}` | Optional annotations to be applied to service account |
| tags | object | `{}`| Tags to apply to log groups |
