# karpenter

A helm chart for [Karpenter](https://karpenter.sh/), an open-source node provisioning project built for Kubernetes.

The chart is based on the upstream Karpenter chart: https://github.com/aws/karpenter-provider-aws/tree/main/charts/karpenter

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- Karpenter CRDs installed (see `karpenter-crds` chart in this repository)
- An EKS cluster with the necessary IAM permissions for Karpenter

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install the CRDs first:

```bash
helm upgrade --install karpenter-crds --namespace karpenter snowplow-devops/karpenter-crds --create-namespace
```

Install or upgrade the chart with default configuration:

```bash
helm upgrade --install karpenter --namespace karpenter snowplow-devops/karpenter \
  --set settings.clusterName=my-cluster
```

## Uninstalling the Chart

To uninstall/delete the `karpenter` release:

```bash
helm delete karpenter --namespace karpenter
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Overrides the chart's name |
| fullnameOverride | string | `""` | Overrides the chart's computed fullname |
| global.cloud | string | `"aws"` | Cloud provider (always aws for Karpenter) |
| global.labels | object | `{}` | Additional labels to add into metadata |
| additionalLabels | object | `{}` | Additional labels to add into metadata |
| additionalAnnotations | object | `{}` | Additional annotations to add into metadata |
| imagePullPolicy | string | `"IfNotPresent"` | Image pull policy for Docker images |
| imagePullSecrets | list | `[]` | Image pull secrets for Docker images |
| service.annotations | object | `{}` | Additional annotations for the Service |
| serviceAccount.create | bool | `true` | Specifies if a ServiceAccount should be created |
| serviceAccount.name | string | `""` | The name of the ServiceAccount to use |
| serviceAccount.annotations | object | `{}` | Additional annotations for the ServiceAccount |
| additionalClusterRoleRules | list | `[]` | Specifies additional rules for the core ClusterRole |
| serviceMonitor.enabled | bool | `false` | Specifies whether a ServiceMonitor should be created |
| serviceMonitor.additionalLabels | object | `{}` | Additional labels for the ServiceMonitor |
| serviceMonitor.relabelings | list | `[]` | Relabelings for the `http-metrics` endpoint |
| serviceMonitor.metricRelabelings | list | `[]` | Metric relabelings for the `http-metrics` endpoint |
| serviceMonitor.endpointConfig | object | `{}` | Configuration on `http-metrics` endpoint |
| serviceMonitor.sampleLimit | int | `null` | Specifies the sampleLimit for prometheus scrapes |
| replicas | int | `2` | Number of replicas |
| revisionHistoryLimit | int | `10` | The number of old ReplicaSets to retain |
| strategy | object | `{"rollingUpdate":{"maxUnavailable":1}}` | Strategy for updating the pod |
| podLabels | object | `{}` | Additional labels for the pod |
| podAnnotations | object | `{}` | Additional annotations for the pod |
| podDisruptionBudget.name | string | `"karpenter"` | Name of the PodDisruptionBudget |
| podDisruptionBudget.maxUnavailable | int | `1` | Max unavailable pods for the PodDisruptionBudget |
| podSecurityContext | object | `{"fsGroup":65532,"seccompProfile":{"type":"RuntimeDefault"}}` | SecurityContext for the pod |
| priorityClassName | string | `"system-cluster-critical"` | PriorityClass name for the pod |
| terminationGracePeriodSeconds | int | `nil` | Override the default termination grace period |
| hostNetwork | bool | `false` | Bind the pod to the host network |
| schedulerName | string | `"default-scheduler"` | Specify which Kubernetes scheduler should dispatch the pod |
| dnsPolicy | string | `"ClusterFirst"` | Configure the DNS Policy for the pod |
| dnsConfig | object | `{}` | Configure DNS Config for the pod |
| initContainers | list | `[]` | Additional initContainers to run before karpenter container starts |
| nodeSelector | object | `{"kubernetes.io/os":"linux"}` | Node selectors to schedule the pod |
| affinity | object | See `values.yaml` | Affinity rules for scheduling the pod |
| topologySpreadConstraints | list | See `values.yaml` | Topology spread constraints |
| tolerations | list | `[{"key":"CriticalAddonsOnly","operator":"Exists"}]` | Tolerations to allow the pod to be scheduled |
| extraVolumes | list | `[]` | Additional volumes for the pod |
| controller.containerName | string | `"controller"` | Distinguishing container name |
| controller.image.repository | string | `"public.ecr.aws/karpenter/controller"` | Repository path to the controller image |
| controller.image.tag | string | `""` | Tag of the controller image (defaults to appVersion) |
| controller.image.digest | string | `""` | SHA256 digest of the controller image |
| controller.env | list | `[]` | Additional environment variables for the controller pod |
| controller.envFrom | list | `[]` | envFrom configuration for the controller pod |
| controller.securityContext.appArmorProfile | object | `{}` | AppArmor profile for the controller container |
| controller.securityContext.seLinuxOptions | object | `{}` | SELinux options for the controller container |
| controller.securityContext.seccompProfile | object | `{}` | Seccomp profile for the controller container |
| controller.resources | object | `{}` | Resources for the controller container |
| controller.extraVolumeMounts | list | `[]` | Additional volumeMounts for the controller container |
| controller.sidecarContainer | list | `[]` | Additional sidecar containers |
| controller.sidecarVolumeMounts | list | `[]` | Additional volumeMounts for the sidecar |
| controller.metrics.port | int | `8080` | The container port to use for metrics |
| controller.healthProbe.port | int | `8081` | The container port to use for http health probe |
| logLevel | string | `"info"` | Global log level |
| logOutputPaths | list | `["stdout"]` | Log outputPaths |
| logErrorOutputPaths | list | `["stderr"]` | Log errorOutputPaths |
| settings.batchMaxDuration | string | `"10s"` | The maximum length of a batch window |
| settings.batchIdleDuration | string | `"1s"` | The maximum amount of time with no new ending pods |
| settings.preferencePolicy | string | `"Respect"` | How the Karpenter scheduler should treat preferences |
| settings.minValuesPolicy | string | `"Strict"` | How the Karpenter scheduler treats min values |
| settings.clusterCABundle | string | `""` | Cluster CA bundle for TLS configuration |
| settings.clusterName | string | `""` | Cluster name (required) |
| settings.clusterEndpoint | string | `""` | Cluster endpoint |
| settings.isolatedVPC | bool | `false` | Assume we can't reach AWS services without VPC endpoint |
| settings.eksControlPlane | bool | `false` | Discover cluster details from DescribeCluster API |
| settings.vmMemoryOverheadPercent | float | `0.075` | VM memory overhead as a percent |
| settings.interruptionQueue | string | `""` | SQS queue name for interruption events |
| settings.enableZonalShift | bool | `false` | Respect zonal shifts when making node claims |
| settings.reservedENIs | string | `"0"` | Reserved ENIs not included in max-pods calculations |
| settings.ignoreDRARequests | bool | `true` | Ignore pods' DRA requests during scheduling |
| settings.disableClusterStateObservability | bool | `false` | Disable cluster state metrics and events |
| settings.disableDryRun | bool | `false` | Disable dry run validation for EC2NodeClasses |
| settings.amiRefreshInterval | string | `"1m"` | How often Karpenter refreshes AMI data |
| settings.subnetRefreshInterval | string | `"1m"` | How often Karpenter refreshes subnet data |
| settings.featureGates.nodeRepair | bool | `false` | Enable node repair (ALPHA) |
| settings.featureGates.nodeOverlay | bool | `false` | Enable node overlay (ALPHA) |
| settings.featureGates.reservedCapacity | bool | `true` | Enable reserved capacity (BETA) |
| settings.featureGates.spotToSpotConsolidation | bool | `false` | Enable spot-to-spot consolidation (ALPHA) |
| settings.featureGates.staticCapacity | bool | `false` | Enable static capacity (ALPHA) |
| settings.featureGates.capacityBuffer | bool | `false` | Enable capacity buffer (ALPHA) |
