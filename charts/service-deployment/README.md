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
- Setting up persistent-volumes and binding them

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
| affinity | object | `{}` | Affinity supports podAffinity, podAntiAffinity, or nodeAffinity |
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
| deployment.kind | string | `"Deployment"` | Can be either a "Deployment" or "StatefulSet" |
| deployment.podLabels | object | `{}` | Map of labels that will be added to each pod in the deployment |
| deployment.scaleToZero | bool | `false` | When enabled, disables the HPA and scales the deployment to zero replicas |
| deployment.strategy | object | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"}` | How to replace existing pods with new ones |
| deployment.strategy.rollingUpdate.maxSurge | string | `"25%"` | The maximum number or precent of pods that can be created in addition to the current number of pods during the rolling update. Can be set as number "5" for 5 additional pods |
| deployment.strategy.rollingUpdate.maxUnavailable | string | `"25%"` | The max number or percent of pods that can be unavailable during rolling update. Can be set as number "3" for 3 pods unavailable |
| deployment.strategy.type | string | `"RollingUpdate"` | Change to "Recreate" if all pods should be killed before new ones are created |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| dockerconfigjson.name | string | `"snowplow-sd-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp , azure) |
| global.labels | object | `{}` | Global labels deployed to all resources deployed by the chart |
| hpa.metrics | object | `[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":75}}}]` | Metrics for HPA configuration |
| hpa.behavior | object | `{}` |  |
| hpa.deploy | bool | `true` | Whether to deploy HPA rules |
| hpa.maxReplicas | int | `20` | Maximum number of pods to deploy |
| hpa.minReplicas | int | `1` | Minimum number of pods to deploy |
| image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| image.pullPolicy | string | `"IfNotPresent"` | The image pullPolicy to use |
| image.repository | string | `"nginx"` |  |
| image.tag | string | `"latest"` |  |
| livenessProbe | object | `{"exec":{"command":[]},"failureThreshold":3,"httpGet":{"path":"","port":""},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":1,"timeoutSeconds":5}` | livenessProbe is enabled if httpGet.path or exec.command are present |
| livenessProbe.exec.command | list | `[]` | Command/arguments to execute to determine liveness |
| livenessProbe.httpGet.path | string | `""` | Path for health checks to be performed to determine liveness |
| persistentVolume.accessModes | list | `["ReadWriteOnce"]` | Access modes to allow (note: this will impact HPA rules if the volume cannot be bound to all containers when deployment.kind is "Deployment") |
| persistentVolume.annotations | object | `{}` | Persistent Volume annotations |
| persistentVolume.enabled | bool | `false` | Whether to deploy a persistent-volume (note: when deployment.kind is "StatefulSet" one volume will be created per replica) |
| persistentVolume.labels | object | `{}` | Persistent Volume labels |
| persistentVolume.mountPath | string | `"/data"` | Persistent Volume mount root path |
| persistentVolume.size | string | `"8Gi"` | Persistent Volume size |
| persistentVolume.statefulSetRetentionPolicy | object | `{"whenDeleted":"Retain","whenScaled":"Delete"}` | Sets the retention policies for the volumes created in "StatefulSet" mode |
| persistentVolume.statefulSetRetentionPolicy.whenDeleted | string | `"Retain"` | What to do with volumes when the StatefulSet is deleted |
| persistentVolume.statefulSetRetentionPolicy.whenScaled | string | `"Delete"` | What to do with volumes when scaling occurs |
| persistentVolume.subPath | string | `""` | Subdirectory of Persistent Volume to mount |
| priorityClassName | string | `""` | PriorityClassName for pods |
| readinessProbe | object | `{"exec":{"command":[]},"failureThreshold":3,"httpGet":{"path":""},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":2,"timeoutSeconds":5}` | readinessProbe is enabled if httpGet.path or exec.command are present |
| readinessProbe.exec.command | list | `[]` | Command/arguments to execute to determine readiness |
| readinessProbe.httpGet.path | string | `""` | Path for health checks to be performed to determine readiness |
| replicas | int | `1` | Number of replicas to deploy when HPA is disabled (`hpa.deploy: false`) |
| resources | object | `{}` | Map of resource constraints for the service |
| service.annotations | object | `{}` | Map of annotations to add to the service |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.deploy | bool | `true` | Whether to setup service bindings (note: only NodePort is supported) |
| service.gcp.networkEndpointGroupName | string | `""` | Name of the Network Endpoint Group to bind onto |
| service.ingress | object | `{}` | A map of ingress rules to deploy |
| service.port | int | `8000` | Port to bind and expose the service on |
| service.protocol | string | `"TCP"` | Protocol that the service leverages (note: TCP or UDP) |
| service.targetPort | int | `80` | The Target Port that the actual application is being exposed on |
| terminationGracePeriodSeconds | int | `60` | Grace period for termination of the service |
| tolerations | list |`[]` | Tolerations labels for pod assignment with matching taints |
| topologySpreadConstraints | object | `{}` | Topology Spread Constraints for pod assignment |
