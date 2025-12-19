# Common Library Chart

A Helm library chart containing common template helpers and resources for Snowplow Helm charts.

## Overview

This library chart provides reusable template helpers and Kubernetes resource definitions that can be shared across multiple Snowplow Helm charts, reducing code duplication and ensuring consistency. It supports both single-service and multi-service deployments.

## Usage

Add this chart as a dependency in your `Chart.yaml`:

```yaml
dependencies:
  - name: common
    version: 0.1.0
    repository: "https://snowplow-devops.github.io/helm-charts"
```

Then use the template definitions in your chart templates:

```yaml
{{- include "common.deployment" . }}
{{- include "common.service" . }}
{{- include "common.ingress" . }}
```

## Template Design

All resource templates support **N instances** by iterating over `.Values.services`. This allows:
- **Single-service charts**: Pass a list with one service
- **Multi-service charts**: Pass a list with multiple services

### Expected Values Structure

```yaml
global:
  cloud: aws  # or gcp, azure
  labels:
    team: platform

services:
  - name: my-service
    image:
      repository: myapp
      tag: v1.0.0
    deployment:
      kind: Deployment
      replicas: 3
    service:
      deploy: true
      port: 8080
    # ... additional configuration

# Optional: Shared ingress for path-based routing to multiple services
sharedIngress:
  - name: my-shared-ingress
    hostname: api.example.com
    certificateIssuer: letsencrypt-prod
    routes:
      - path: /service-a
        serviceName: service-a
        port: 8080
      - path: /service-b
        serviceName: service-b
        port: 8081
```

## Available Template Helpers

### Naming Helpers

- `common.fullname`: Generate full app name (truncated to 50 chars)
- `common.secret.fullname`: Generate secret name based on app fullname
- `common.chart`: Generate chart name and version label

### Label Helpers

- `common.labels`: Generate standard Snowplow labels including global labels

### GCP Helpers

- `common.gcp.networkEndpointGroupName`: Generate GCP Network Endpoint Group name

## Available Resource Templates

### Core Resources

- `common.deployment`: Generate Deployment or StatefulSet resources
- `common.service`: Generate Service resources
- `common.secret`: Generate Secret resources
- `common.configmaps`: Generate ConfigMap resources
- `common.hooks`: Generate Helm hook Jobs with optional secrets and configmaps

### Scaling Resources

- `common.hpa`: Generate HorizontalPodAutoscaler resources
- `common.vpa`: Generate VerticalPodAutoscaler resources

### Storage Resources

- `common.pvc`: Generate PersistentVolumeClaim resources

### Network Resources

- `common.ingress`: Generate Ingress resources (per-service)
- `common.sharedingress`: Generate shared Ingress resources with path-based routing to multiple services
- `common.certificate`: Generate cert-manager Certificate resources
- `common.ipallowlist`: Generate Traefik Middleware for IP allowlisting
- `common.targetgroupbinding`: Generate AWS TargetGroupBinding resources

### RBAC Resources

- `common.role`: Generate Role resources
- `common.rolebinding`: Generate RoleBinding resources
- `common.clusterrole`: Generate ClusterRole resources
- `common.clusterrolebinding`: Generate ClusterRoleBinding resources

## Chart Type

This is a library chart (type: library) and cannot be installed directly. It must be used as a dependency in other charts.
