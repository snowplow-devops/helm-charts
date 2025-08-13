# vertical-pod-autoscaler

A Helm Chart to deploy Vertical Pod Autoscaler components for automatic resource recommendations and scaling.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install vertical-pod-autoscaler snowplow-devops/vertical-pod-autoscaler
```

## Introduction

This chart deploys the Kubernetes Vertical Pod Autoscaler (VPA) which automatically adjusts CPU and memory resource requests for containers based on actual usage patterns. VPA helps optimize resource allocation and can improve cluster utilization.

The chart includes three main components:
- **Recommender**: Monitors resource usage and generates recommendations
- **Updater**: Evicts pods to apply new resource recommendations  
- **Admission Controller**: Applies recommendations to new pods automatically

Key features:
- Configurable deployment modes (recommender-only or full VPA)
- cert-manager integration for secure webhook communication
- Comprehensive RBAC configuration following Kubernetes VPA standards
- Flexible resource and scheduling configuration per component

_Note_: VPA requires a metrics server to be running in your cluster and should not be used alongside Horizontal Pod Autoscaler (HPA) on the same resource dimensions.

## Prerequisites

- Kubernetes cluster with RBAC enabled
- [cert-manager](https://cert-manager.io/) installed for TLS certificate management
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server) running in the cluster
- Cluster admin permissions for RBAC creation

## Installing the Chart

Install or upgrade the chart with default configuration:

```bash
helm upgrade --install vertical-pod-autoscaler snowplow-devops/vertical-pod-autoscaler \
  --namespace kube-system
```

Install in recommender-only mode (recommendations without automatic updates):

```bash
helm upgrade --install vertical-pod-autoscaler snowplow-devops/vertical-pod-autoscaler \
  --namespace kube-system \
  --set vpa.updater.enabled=false \
  --set vpa.admissionController.enabled=false
```

Install with custom cert-manager issuer:

```bash
helm upgrade --install vertical-pod-autoscaler snowplow-devops/vertical-pod-autoscaler \
  --namespace kube-system \
  --set vpa.admissionController.certificate.issuerName=my-cluster-issuer \
  --set vpa.admissionController.certificate.issuerKind=ClusterIssuer
```

## Uninstalling the Chart

To uninstall/delete the `vertical-pod-autoscaler` release:

```bash
helm delete vertical-pod-autoscaler
```

**Note**: ClusterRoles and ClusterRoleBindings will remain and need to be cleaned up manually if desired:

```bash
kubectl delete clusterroles,clusterrolebindings -l app.kubernetes.io/name=vertical-pod-autoscaler
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources |
| global.labels | object | `{}` | Global labels applied to all resources |
| imagePullSecrets | list | `[]` | Image pull secrets for all VPA components |
| podSecurityContext.runAsGroup | int | `65534` | Group ID to run containers |
| podSecurityContext.runAsNonRoot | bool | `true` | Run containers as non-root user |
| podSecurityContext.runAsUser | int | `65534` | User ID to run containers |
| priorityClassName | string | `""` | Priority class for VPA pods |
| rbac.create | bool | `true` | Create RBAC resources |
| securityContext.allowPrivilegeEscalation | bool | `false` | Allow privilege escalation |
| securityContext.capabilities.drop | list | `["ALL"]` | Capabilities to drop |
| securityContext.readOnlyRootFilesystem | bool | `true` | Use read-only root filesystem |
| serviceAccount.annotations | object | `{}` | Annotations for ServiceAccount |
| serviceAccount.create | bool | `true` | Create ServiceAccount |
| serviceAccount.name | string | `""` | Name of ServiceAccount to use |
| vpa.admissionController.affinity | object | `{}` | Affinity rules for admission controller pods |
| vpa.admissionController.certificate.create | bool | `true` | Create a Certificate resource for the admission webhook |
| vpa.admissionController.certificate.issuerKind | string | `"ClusterIssuer"` | Kind of issuer |
| vpa.admissionController.certificate.issuerName | string | `"letsencrypt"` | What issuer to use for the Certificate |
| vpa.admissionController.enabled | bool | `true` | Enable VPA Admission Controller component |
| vpa.admissionController.extraArgs | list | `[]` | Additional arguments for admission controller |
| vpa.admissionController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the Admission Controller |
| vpa.admissionController.image.repository | string | `"registry.k8s.io/autoscaling/vpa-admission-controller"` | Image repository for the Admission Controller |
| vpa.admissionController.image.tag | string | `""` | Image tag for the Admission Controller; defaults to .Chart.AppVersion |
| vpa.admissionController.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/health-check","port":"metrics","scheme":"HTTP"},"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}` | Liveness probe configuration for admission controller |
| vpa.admissionController.nodeSelector | object | `{}` | Node selector for admission controller pods |
| vpa.admissionController.readinessProbe | object | `{"failureThreshold":120,"httpGet":{"path":"/health-check","port":"metrics","scheme":"HTTP"},"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}` | Readiness probe configuration for admission controller |
| vpa.admissionController.replicas | int | `1` | Number of admission controller replicas |
| vpa.admissionController.resources.limits | object | `{}` | Resource limits for admission controller |
| vpa.admissionController.resources.requests.cpu | string | `"50m"` | CPU request for admission controller |
| vpa.admissionController.resources.requests.memory | string | `"200Mi"` | Memory request for admission controller |
| vpa.admissionController.tls.caBundle | string | `""` | CA bundle for webhook |
| vpa.admissionController.tls.secretName | string | `""` | Secret name containing TLS certificates |
| vpa.admissionController.tolerations | list | `[]` | Tolerations for admission controller pods |
| vpa.recommender.affinity | object | `{}` | Affinity rules for recommender pods |
| vpa.recommender.enabled | bool | `true` | Enable VPA Recommender component |
| vpa.recommender.extraArgs | list | `[]` | Additional arguments for recommender |
| vpa.recommender.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the Recommender |
| vpa.recommender.image.repository | string | `"registry.k8s.io/autoscaling/vpa-recommender"` | Image repository for the Recommender |
| vpa.recommender.image.tag | string | `""` | Image tag for the Recommender; defaults to .Chart.AppVersion |
| vpa.recommender.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/health-check","port":"metrics","scheme":"HTTP"},"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}` | Liveness probe configuration for recommender |
| vpa.recommender.nodeSelector | object | `{}` | Node selector for recommender pods |
| vpa.recommender.readinessProbe | object | `{"failureThreshold":120,"httpGet":{"path":"/health-check","port":"metrics","scheme":"HTTP"},"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}` | Readiness probe configuration for recommender |
| vpa.recommender.replicas | int | `1` | Number of recommender replicas |
| vpa.recommender.resources.limits | object | `{}` | Resource limits for recommender |
| vpa.recommender.resources.requests.cpu | string | `"50m"` | CPU request for recommender |
| vpa.recommender.resources.requests.memory | string | `"500Mi"` | Memory request for recommender |
| vpa.recommender.tolerations | list | `[]` | Tolerations for recommender pods |
| vpa.updater.affinity | object | `{}` | Affinity rules for updater pods |
| vpa.updater.enabled | bool | `true` | Enable VPA Updater component |
| vpa.updater.extraArgs | list | `[]` | Additional arguments for updater |
| vpa.updater.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the Updater |
| vpa.updater.image.repository | string | `"registry.k8s.io/autoscaling/vpa-updater"` | Image repository for the Updater |
| vpa.updater.image.tag | string | `""` | Image tag for the Updater; defaults to .Chart.AppVersion |
| vpa.updater.livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/health-check","port":"metrics","scheme":"HTTP"},"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}` | Liveness probe configuration for updater |
| vpa.updater.nodeSelector | object | `{}` | Node selector for updater pods |
| vpa.updater.readinessProbe | object | `{"failureThreshold":120,"httpGet":{"path":"/health-check","port":"metrics","scheme":"HTTP"},"periodSeconds":5,"successThreshold":1,"timeoutSeconds":3}` | Readiness probe configuration for updater |
| vpa.updater.replicas | int | `1` | Number of updater replicas |
| vpa.updater.resources.limits | object | `{}` | Resource limits for updater |
| vpa.updater.resources.requests.cpu | string | `"50m"` | CPU request for updater |
| vpa.updater.resources.requests.memory | string | `"500Mi"` | Memory request for updater |
| vpa.updater.tolerations | list | `[]` | Tolerations for updater pods |

## Usage

### Basic VPA Resource

Create a VPA resource to automatically manage resource requests for a deployment:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  updatePolicy:
    updateMode: "Auto"  # Options: Auto, Recreation, Initial, Off
```

### Monitoring

Check VPA recommendations:

```bash
kubectl get vpa my-app-vpa -o yaml
kubectl describe vpa my-app-vpa
```

Check VPA component status:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=vertical-pod-autoscaler
kubectl logs -n kube-system -l app.kubernetes.io/component=recommender
```

For detailed operational guidance, troubleshooting, and advanced configuration, see [docs.md](./docs.md).