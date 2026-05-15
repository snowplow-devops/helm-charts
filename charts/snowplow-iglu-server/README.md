# snowplow-iglu-server

![Version: 0.18.0](https://img.shields.io/badge/Version-0.18.0-informational?style=flat-square) ![AppVersion: 0.13.0](https://img.shields.io/badge/AppVersion-0.13.0-informational?style=flat-square)

A Helm Chart to deploy the Snowplow Iglu Server project

**Homepage:** <https://github.com/snowplow-devops/helm-charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| jbeemster | <jbeemster@users.noreply.github.com> | <https://github.com/jbeemster> |

## Source Code

* <https://github.com/snowplow-devops/helm-charts>
* <https://github.com/snowplow-incubator/iglu-server>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://snowplow-devops.github.io/helm-charts | cloudserviceaccount | 0.3.0 |
| https://snowplow-devops.github.io/helm-charts | dockerconfigjson | 0.1.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cloudserviceaccount.aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| cloudserviceaccount.deploy | bool | `false` | Whether to create a service-account |
| cloudserviceaccount.gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
| cloudserviceaccount.name | string | `"snowplow-iglu-server-service-account"` | Name of the service-account to create |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| dockerconfigjson.name | string | `"snowplow-iglu-server-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp, azure) |
| global.labels | object | `{}` |  |
| hooks.connectionTimeout | int | `10` | Connection timeout in seconds for PostgreSQL connections |
| hooks.defaultDBName | string | `"postgres"` | Default database name and admin credentials for hooks to use |
| hooks.deployDB | bool | `false` |  |
| hooks.deployDBUser | bool | `false` |  |
| hooks.deployDBUserGrants | bool | `false` |  |
| hooks.deployDestroyHooks | bool | `false` |  |
| hooks.deploySetupHooks | bool | `false` | Whether to run the post-deploy setup hooks to create database and user |
| hooks.destroyDB | bool | `false` |  |
| hooks.destroyDBUser | bool | `false` | Whether to run the pre-delete destroy hooks to drop database and user |
| hooks.image | object | `{"pullPolicy":"Always","repository":"postgres","tag":"15-alpine"}` | PostgreSQL client image configuration for hooks |
| hooks.secrets.admin_password | string | `""` |  |
| hooks.secrets.admin_username | string | `""` |  |
| service.annotations | object | `{}` | Map of annotations to add to the service. |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.config.database.dbname | string | `""` | Postgres database name |
| service.config.database.host | string | `""` | Postgres database host |
| service.config.database.port | int | `5432` | Postgres database port |
| service.config.database.secrets.password | string | `""` |  |
| service.config.database.secrets.username | string | `""` |  |
| service.config.database.type | string | `"dummy"` | Can be either 'dummy' (in-memory) or 'postgres' |
| service.config.env | object | `{"ACCEPT_LIMITED_USE_LICENSE":"no"}` | Map of additional environment variables to use within the deployment |
| service.config.hoconBase64 | string | `""` | Optional Base64 encoded config HOCON (note: will not override above settings) |
| service.config.javaOpts | string | `""` | Optional JAVA_OPTS inputs for the deployed service |
| service.config.patchesAllowed | bool | `false` | Whether to allow schema patching |
| service.config.repoServer.hsts.enable | bool | `true` |  |
| service.config.repoServer.idleTimeout | string | `"65 seconds"` |  |
| service.config.repoServer.maxConnections | int | `16384` |  |
| service.config.secrets.superApiKey | string | `""` | Lowercase uuidv4 to use as admin apikey of the service (default: auto-generated) |
| service.containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context configuration These defaults follow kubesec.io best practices for hardened deployments.  runAsUser is pinned to 65534 (nobody) because the upstream snowplow/iglu-server distroless image declares USER nobody — a non-numeric value that the kubelet cannot verify against runAsNonRoot. Pinning the numeric UID lets runAsNonRoot pass without changing the runtime user.  readOnlyRootFilesystem defaults to false so existing deployments are not broken on upgrade; set it to true per-deployment once writable paths (e.g. /tmp) are mounted as emptyDirs. |
| service.extraVolumeMounts | list | `[]` | Additional volume mounts to attach to the container. Pair with extraVolumes above. |
| service.extraVolumes | list | `[]` | Additional volumes to attach to the pod spec. Useful with readOnlyRootFilesystem: true — declare writable scratch space (e.g. emptyDir on /tmp) without disabling the hardened default. |
| service.gcp.deployProxy | bool | `false` | Whether to use CloudSQL Proxy (note: requires GCP service account to be attached) |
| service.gcp.proxy.image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| service.gcp.proxy.image.repository | string | `"gcr.io/cloudsql-docker/gce-proxy"` |  |
| service.gcp.proxy.image.tag | string | `"1.31.2"` |  |
| service.gcp.proxy.instanceName | string | `""` | Name of the CloudSQL instance |
| service.gcp.proxy.ipAddressTypes | string | `"PUBLIC"` | IP address types to use (options: PUBLIC, PRIVATE, PSC; default: PUBLIC) |
| service.gcp.proxy.port | int | `38000` | Port to bind proxy onto |
| service.gcp.proxy.project | string | `""` | Project where CloudSQL instance is deployed |
| service.gcp.proxy.region | string | `""` | Region where CloudSQL instance is deployed |
| service.gcp.proxy.resources.limits.cpu | string | `"100m"` |  |
| service.gcp.proxy.resources.limits.memory | string | `"256Mi"` |  |
| service.gcp.proxy.resources.requests.cpu | string | `"50m"` |  |
| service.gcp.proxy.resources.requests.memory | string | `"128Mi"` |  |
| service.image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| service.image.pullPolicy | string | `"IfNotPresent"` | The image pullPolicy to use |
| service.image.repository | string | `"snowplow/iglu-server"` |  |
| service.image.tag | string | `"0.12.0-distroless"` |  |
| service.ingress | object | `{}` | A map of ingress rules to deploy |
| service.ingressIPAllowlist | list | `[]` | List of IP addresses to restrict ingress traffic to |
| service.livenessProbe.failureThreshold | int | `3` |  |
| service.livenessProbe.initialDelaySeconds | int | `30` |  |
| service.livenessProbe.periodSeconds | int | `5` |  |
| service.livenessProbe.timeoutSeconds | int | `5` |  |
| service.maxReplicas | int | `4` |  |
| service.minReplicas | int | `1` |  |
| service.podDisruptionBudget.enabled | bool | `false` | Whether to deploy a PodDisruptionBudget |
| service.podDisruptionBudget.minAvailable | int | `1` | Minimum number (or percentage) of pods that must remain available. Mutually exclusive with maxUnavailable. |
| service.port | int | `8080` | Port to bind and expose the service on |
| service.readinessProbe.failureThreshold | int | `3` |  |
| service.readinessProbe.initialDelaySeconds | int | `5` |  |
| service.readinessProbe.periodSeconds | int | `5` |  |
| service.readinessProbe.successThreshold | int | `2` |  |
| service.readinessProbe.timeoutSeconds | int | `5` |  |
| service.resources.limits.cpu | string | `"746m"` |  |
| service.resources.limits.memory | string | `"900Mi"` |  |
| service.resources.requests.cpu | string | `"400m"` |  |
| service.resources.requests.memory | string | `"512Mi"` |  |
| service.targetCPUUtilizationPercentage | int | `75` |  |
| service.terminationGracePeriodSeconds | int | `630` |  |
| service.tolerations | list | `[]` | Allow the scheduler to schedule pods with matching taints  more details here: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| service.topologySpreadConstraints | object | `{}` | topologySpreadConstraints control how Pods are  spread across your cluster among failure-domains such as regions, zones, nodes, and other user-defined topology domains.  more details here: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/ |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
