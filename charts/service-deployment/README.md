# service-deployment

A helm chart to deploy a generic deployment with optional service bindings.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install service-deployment snowplow-devops/service-deployment
```

## Introduction

This chart attempts to take care of all the most common requirements of launching a long-running service that requires auto-scaling:

- Downloading from private Docker repositories
- Auto-scaling pods based on CPU usage
- Mounting config volumes
- Configuring secrets
- Binding service-accounts with cloud specific IAM policies

_Note_: This should be a long running process - if you are looking for cron-based execution see our `cron-job` chart.

This chart won't solve for every possible option of deploying a service - it is meant to serve as an opinionated starting point to get something working decently well.  For more flexibility open a PR or fork this chart to suit your specific needs.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install service-deployment snowplow-devops/service-deployment
```

## Uninstalling the Chart

To uninstall/delete the `service-deployment` release:

```bash
helm delete service-deployment
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp) |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `"latest"` |  |
| image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| config.command | list | `[]` |  |
| config.args | list | `[]` |  |
| config.env | string | `nil` | Map of environment variables to use within the job |
| config.secrets | object | `{}` | Map of secrets that will be exposed as environment variables within the job |
| configMaps | list | `[]` | List of config maps to mount to the deployment |
| resources | object | `{}` | Map of resource constraints for the service |
| readinessProbe.httpGet.path | string | `""` | Path for health checks to be performed (note: set to "" to disable) |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `5` |  |
| readinessProbe.timeoutSeconds | int | `5` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.successThreshold | int | `2` |  |
| terminationGracePeriodSeconds | int | `60` | Grace period for termination of the service |
| hpa.deploy | bool | `true` | Whether to deploy HPA rules |
| hpa.minReplicas | int | `1` | Minimum number of pods to deploy |
| hpa.maxReplicas | int | `20` | Maximum number of pods to deploy |
| hpa.averageCPUUtilization | int | `75` | Average CPU utilization before auto-scaling starts |
| service.deploy | bool | `true` | Whether to setup service bindings (note: only NodePort is supported) |
| service.port | int | `80` | Port to bind and expose the service on |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.gcp.networkEndpointGroupName | string | `""` | Name of the Network Endpoint Group to bind onto |
| dockerconfigjson.name | string | `"snowplow-sd-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| cloudserviceaccount.deploy | bool | `false` | Whether to create a service-account |
| cloudserviceaccount.name | string | `"snowplow-sd-service-account"` | Name of the service-account to create |
| cloudserviceaccount.aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| cloudserviceaccount.gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
