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
| cloudserviceaccount.aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| cloudserviceaccount.azure.managedIdentityId | string | `""` | Workload managed identity id to bind to the k8s service account |
| cloudserviceaccount.deploy | bool | `false` | Whether to create a service-account |
| cloudserviceaccount.gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
| cloudserviceaccount.name | string | `"snowplow-sd-service-account"` | Name of the service-account to create |
| config.args | list | `[]` |  |
| config.command | list | `[]` |  |
| config.env | string | `nil` | Map of environment variables to use within the job |
| config.secrets | object | `{}` | Map of secrets that will be exposed as environment variables within the job |
| config.secretsB64 | object | `{}` | Map of base64-encoded secrets that will be exposed as environment variables within the job |
| configMaps | list | `[]` | List of config maps to mount to the deployment |
| deployment.scaleToZero | bool | `false` | When enabled, disables the HPA and scales the deployment to zero replicas |
| deployment.strategy.type | string | `RollingUpdate` | Specifies how to replace old pods by new ones |
| deployment.strategy.rollingUpdate.maxUnavailable | string | `25%` | Specifies the maximum number of pods that can be unavailable during the rolling update |
| deployment.strategy.rollingUpdate.maxSurge | string | `25%` | Specifies the maximum number of pods that can be created in addition to the current number of pods during the rolling update |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| dockerconfigjson.name | string | `"snowplow-sd-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp , azure) |
| hpa.averageCPUUtilization | int | `75` | Average CPU utilization before auto-scaling starts |
| hpa.behavior | object | `{}` |  |
| hpa.deploy | bool | `true` | Whether to deploy HPA rules |
| hpa.maxReplicas | int | `20` | Maximum number of pods to deploy |
| hpa.minReplicas | int | `1` | Minimum number of pods to deploy |
| image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| image.pullPolicy | string | `"IfNotPresent"` | The image pullPolicy to use |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `"latest"` |  |
| livenessProbe | object | `{"exec":{"command":[]},"failureThreshold":3,"httpGet":{"path":"","port":""},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":2,"timeoutSeconds":5}` | livenessProbe is enabled if httpGet.path or exec.command are present |
| livenessProbe.exec.command | list | `[]` | Command/arguments to execute to determine liveness |
| livenessProbe.httpGet.path | string | `""` | Path for health checks to be performed to determine liveness |
| readinessProbe | object | `{"exec":{"command":[]},"failureThreshold":3,"httpGet":{"path":""},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":2,"timeoutSeconds":5}` | readinessProbe is enabled if httpGet.path or exec.command are present |
| readinessProbe.exec.command | list | `[]` | Command/arguments to execute to determine readiness |
| readinessProbe.httpGet.path | string | `""` | Path for health checks to be performed to determine readiness |
| resources | object | `{}` | Map of resource constraints for the service |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.deploy | bool | `true` | Whether to setup service bindings (note: only NodePort is supported) |
| service.gcp.networkEndpointGroupName | string | `""` | Name of the Network Endpoint Group to bind onto |
| service.ingress | object | `{}` | A map of ingress rules to deploy |
| service.port | int | `8000` | Port to bind and expose the service on |
| service.protocol | string | `"TCP"` | Protocol that the service leverages (note: TCP or UDP) |
| service.targetPort | int | `80` | The Target Port that the actual application is being exposed on |
| terminationGracePeriodSeconds | int | `60` | Grace period for termination of the service |
| priorityClassName | string | `""` | `priorityClassName` for pods |
| affinity | object | `{}` | Map of affinity constraints that will be used when scheduling pods |
