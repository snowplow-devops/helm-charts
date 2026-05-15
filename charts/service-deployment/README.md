# service-deployment

![Version: 0.41.0](https://img.shields.io/badge/Version-0.41.0-informational?style=flat-square)

A Helm Chart to setup a generic deployment with optional service/hpa/vpa bindings

**Homepage:** <https://github.com/snowplow-devops/helm-charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| jbeemster | <jbeemster@users.noreply.github.com> | <https://github.com/jbeemster> |

## Source Code

* <https://github.com/snowplow-devops/helm-charts>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://snowplow-devops.github.io/helm-charts | cloudserviceaccount | 0.3.0 |
| https://snowplow-devops.github.io/helm-charts | dockerconfigjson | 0.1.0 |

## Values

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
| config.sharedNamespaceConfigMaps | list | `[]` | List of configMaps from other deployments within the    same namespace - to reference and mount in the deployment |
| config.workingDir | string | `""` | Optional working directory for the container process. Useful when readOnlyRootFilesystem is true and the app writes to its CWD; point at a writable mount declared via extraVolumes / extraVolumeMounts. |
| configMaps | list | `[]` | List of config maps to mount to the deployment |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration These defaults follow kubesec.io best practices for hardened deployments.  runAsUser / runAsGroup are intentionally not pinned. Different container images bake in different non-root USER directives, and forcing a specific UID can prevent the image's user from accessing its own files. The image's USER directive selects the runtime UID; runAsNonRoot: true still enforces the non-root invariant. Override per-deployment if you need a specific UID.  readOnlyRootFilesystem defaults to false so existing deployments are not broken on upgrade; set it to true per-deployment once writable paths (e.g. /tmp) are mounted as emptyDirs. |
| deployment.kind | string | `"Deployment"` | Can be either a "Deployment" or "StatefulSet" |
| deployment.podAnnotations | object | `{}` | Map of annotations that will be added to each pod in the deployment |
| deployment.podLabels | object | `{}` | Map of labels that will be added to each pod in the deployment |
| deployment.replicas | int | `1` |  |
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
| extraObjects | list | `[]` | Extra Kubernetes objects to deploy alongside the service This allows for additional resources like Middleware, NetworkPolicy, etc. |
| extraVolumeMounts | list | `[]` | Additional volume mounts to attach to the container. Pair with extraVolumes above. |
| extraVolumes | list | `[]` | Additional volumes to attach to the pod spec. Useful with readOnlyRootFilesystem: true — declare writable scratch space (e.g. emptyDir on /tmp) without disabling the hardened default. |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp , azure) |
| global.labels | object | `{}` |  |
| hooks | object | `{}` |  |
| hpa.behavior | object | `{}` |  |
| hpa.deploy | bool | `true` | Whether to deploy HPA rules |
| hpa.maxReplicas | int | `20` | Maximum number of pods to deploy |
| hpa.metrics | list | `[{"resource":{"name":"cpu","target":{"averageUtilization":75,"type":"Utilization"}},"type":"Resource"}]` | Default average CPU utilization before auto-scaling starts |
| hpa.minReplicas | int | `1` | Minimum number of pods to deploy |
| image.pullPolicy | string | `"IfNotPresent"` | The image pullPolicy to use |
| image.repository | string | `"nginxinc/nginx-unprivileged"` |  |
| image.tag | string | `"stable"` |  |
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
| podDisruptionBudget.enabled | bool | `false` | Whether to deploy a PodDisruptionBudget |
| podDisruptionBudget.minAvailable | int | `1` | Minimum number (or percentage) of pods that must remain available. Mutually exclusive with maxUnavailable. |
| priorityClassName | string | `""` | PriorityClassName for pods |
| readinessProbe | object | `{"exec":{"command":[]},"failureThreshold":3,"httpGet":{"path":""},"initialDelaySeconds":5,"periodSeconds":5,"successThreshold":2,"timeoutSeconds":5}` | readinessProbe is enabled if httpGet.path or exec.command are present |
| readinessProbe.exec.command | list | `[]` | Command/arguments to execute to determine readiness |
| readinessProbe.httpGet.path | string | `""` | Path for health checks to be performed to determine readiness |
| resources | object | `{}` | Map of resource constraints for the service |
| securityContext | object | `{}` | Pod security context configuration This is particularly useful when using persistent volumes with non-root container users Setting fsGroup ensures that mounted volumes have the correct group ownership |
| service.additionalPorts | list | `[]` | Additional ports to expose on the Kubernetes Service |
| service.annotations | object | `{}` | Map of annotations to add to the service |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.basicAuth | object | `{"enabled":false,"users":""}` | Basic authentication configuration |
| service.basicAuth.enabled | bool | `false` | Enable basic authentication |
| service.basicAuth.users | string | `""` | htpasswd-formatted users string (bcrypt hash, e.g. "user:$2y$05$...") |
| service.deploy | bool | `true` | Whether to setup service bindings (note: only NodePort is supported) |
| service.gcp.networkEndpointGroupName | string | `""` | Name of the Network Endpoint Group to bind onto |
| service.ingress | object | `{}` | A map of ingress rules to deploy |
| service.ingressIPAllowlist | list | `[]` | List of IP addresses to restrict ingress traffic to |
| service.port | int | `8000` | Port to bind and expose the service on |
| service.protocol | string | `"TCP"` | Protocol that the service leverages (note: TCP or UDP) |
| service.rateLimit | object | `{"average":100,"burst":200,"enabled":false,"period":"1m","sourceCriterion":{"enabled":false,"ipStrategy":{"depth":1,"excludedIPs":[]},"requestHeaderName":"","type":"ipStrategy"}}` | Rate limiting configuration WARNING: These defaults are conservative and intended for testing. For production use, adjust based on your service's expected traffic patterns. Current defaults: 100 requests per minute = ~4.3M requests/month per IP (or total if global) |
| service.rateLimit.average | int | `100` | Average number of requests per period |
| service.rateLimit.burst | int | `200` | Burst size - maximum number of requests allowed in a burst |
| service.rateLimit.enabled | bool | `false` | Enable rate limiting |
| service.rateLimit.period | string | `"1m"` | Time period for rate limiting (e.g., "1m", "1s", "1h") |
| service.rateLimit.sourceCriterion | object | `{"enabled":false,"ipStrategy":{"depth":1,"excludedIPs":[]},"requestHeaderName":"","type":"ipStrategy"}` | Source-based rate limiting configuration |
| service.rateLimit.sourceCriterion.enabled | bool | `false` | Enable source-based rate limiting (false = global rate limit for entire service) |
| service.rateLimit.sourceCriterion.ipStrategy | object | `{"depth":1,"excludedIPs":[]}` | Configuration for IP-based rate limiting (when type is "ipStrategy") |
| service.rateLimit.sourceCriterion.ipStrategy.depth | int | `1` | Depth of IP extraction for X-Forwarded-For header (1 = direct, 2 = behind 1 proxy) |
| service.rateLimit.sourceCriterion.ipStrategy.excludedIPs | list | `[]` | List of IPs/CIDRs that bypass rate limiting entirely (e.g., internal networks, monitoring) |
| service.rateLimit.sourceCriterion.requestHeaderName | string | `""` | Header name to use for rate limiting (required when type is "requestHeaderName") |
| service.rateLimit.sourceCriterion.type | string | `"ipStrategy"` | Type of source criterion: "ipStrategy" (default), "requestHeaderName", or "requestHost" |
| service.targetPort | int | `80` | The Target Port that the actual application is being exposed on |
| terminationGracePeriodSeconds | int | `60` | Grace period for termination of the service |
| tolerations | list | `[]` | Allow the scheduler to schedule pods with matching taints  more details here: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| topologySpreadConstraints | object | `{}` | topologySpreadConstraints control how Pods are  spread across your cluster among failure-domains such as regions, zones, nodes, and other user-defined topology domains.  more details here: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/ |
| vpa.enabled | bool | `false` | Whether to deploy VPA rules |
| vpa.spec | object | `{}` | VPA resource specification (accepts any valid VPA spec fields) |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
