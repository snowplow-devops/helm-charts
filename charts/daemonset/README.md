# daemonset

A helm chart to deploy an arbitrary container as a daemonset.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install daemonset snowplow-devops/daemonset
```

## Introduction

This chart attempts to take care of all the most common requirements of launching a long-running service as a daemonset:

- Downloading from private Docker repositories
- Mounting config volumes
- Mounting host volumes
- Configuring secrets
- Binding service-accounts with cloud specific IAM policies

_Note_: This should be a long running process - if you are looking for cron-based execution see our `cron-job` chart.

This chart won't solve for every possible option of deploying a service - it is meant to serve as an opinionated starting point to get something working decently well.  For more flexibility open a PR or fork this chart to suit your specific needs.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install daemonset snowplow-devops/service-deployment
```

## Uninstalling the Chart

To uninstall/delete the `daemonset` release:

```bash
helm delete daemonset
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://snowplow-devops.github.io/helm-charts | cloudserviceaccount | 0.1.0 |
| https://snowplow-devops.github.io/helm-charts | dockerconfigjson | 0.1.0 |

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp) |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `"latest"` |  |
| image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| image.pullPolicy | string | `"IfNotPresent"` | The image pullPolicy to use |
| annotations | object | `{}` | Annotations to be applied to the daemonset |
| config.command | list | `[]` |  |
| config.args | list | `[]` |  |
| config.env | string | `nil` | Map of environment variables to use within the job |
| config.secrets | object | `{}` | Map of secrets that will be exposed as environment variables within the job |
| configMaps | list | `[]` | List of config maps to mount to the deployment |
| hostPaths | list | `[]` | List of host paths to mount to the deployment |
| resources | object | `{}` | Map of resource constraints for the service |
| terminationGracePeriodSeconds | int | `60` | Grace period for termination of the service |
| service.deploy | bool | `true` | Whether to setup service bindings (note: only NodePort is supported) |
| service.port | int | `8000` | Port to bind and expose the service on |
| service.targetPort | int | `80` | The Target Port that the actual application is being exposed on |
| service.protocol | string | `"TCP"` | Protocol that the service leverages (note: TCP or UDP) |
| dockerconfigjson.name | string | `"snowplow-sd-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| cloudserviceaccount.deploy | bool | `false` | Whether to create a service-account |
| cloudserviceaccount.name | string | `"snowplow-sd-service-account"` | Name of the service-account to create |
| cloudserviceaccount.aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| cloudserviceaccount.gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
| clusterrole.deploy | bool | `false` | Whether to create a cluster role |
| clusterole.rules | list | `[]`  | List of PolicyRules to attach to cluster role |
