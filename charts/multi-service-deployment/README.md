# multi-service-deployment

A helm chart to deploy multiple services in a single Helm release using the common library chart.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install my-services snowplow-devops/multi-service-deployment
```

## Introduction

This chart allows you to deploy multiple services (1 to N) in a single Helm release, leveraging the `common` library chart for reusable template components. Each service in the deployment can have its own:

- Container image and configuration
- Service bindings and ingress rules
- Auto-scaling policies (HPA/VPA)
- Persistent volumes
- RBAC policies
- Hooks for lifecycle management
- Cloud-specific service account bindings

Additionally, the chart supports **shared ingress** for path-based routing, allowing a single hostname to route different URL paths to different services.

This chart is ideal for deploying microservices that need to be managed together as a cohesive unit, sharing the same release lifecycle.

## Use Cases

### Multiple Services in One Release
Deploy related microservices (frontend, backend, worker) that should be installed, upgraded, and deleted together:

```yaml
services:
  - name: frontend
    image:
      repository: my-frontend
      tag: v1.0.0
    service:
      deploy: true
      port: 80
  - name: backend
    image:
      repository: my-backend
      tag: v1.0.0
    service:
      deploy: true
      port: 3000
  - name: worker
    image:
      repository: my-worker
      tag: v1.0.0
    service:
      deploy: false
```

### Single Service (Alternative to service-deployment)
You can also use this chart to deploy a single service by providing an array with one element:

```yaml
services:
  - name: my-app
    image:
      repository: nginx
      tag: latest
    service:
      deploy: true
      port: 8000
```

### Path-Based Routing with Shared Ingress
Route different URL paths to different services using a single hostname:

```yaml
services:
  - name: api-crud
    image:
      repository: mycompany/api
      tag: v1.0.0
    service:
      deploy: true
      port: 8000

  - name: api-attributes
    image:
      repository: mycompany/api
      tag: v1.0.0
    service:
      deploy: true
      port: 8000

sharedIngress:
  - name: api-router
    hostname: api.example.com
    certificateIssuer: letsencrypt-prod
    routes:
      - path: /api/v1/attributes
        pathType: Prefix
        serviceName: api-attributes
        port: 8000
      - path: /
        pathType: Prefix
        serviceName: api-crud
        port: 8000
```

## Key Differences from service-deployment Chart

| Feature | service-deployment | multi-service-deployment |
|---------|-------------------|--------------------------|
| Number of services | 1 | 1 to N |
| Values structure | Flat (top-level fields) | Array under `services[]` |
| Naming | Uses `fullnameOverride` or Release.Name | Uses service `name` field |
| Templates | Inline templates | Uses `common` library chart |
| Dependencies | dockerconfigjson, cloudserviceaccount | common, dockerconfigjson, cloudserviceaccount |

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install my-services snowplow-devops/multi-service-deployment
```

Install with custom values:

```bash
helm upgrade --install my-services snowplow-devops/multi-service-deployment \
  --values my-values.yaml
```

## Uninstalling the Chart

To uninstall/delete the `my-services` release:

```bash
helm delete my-services
```

## Configuration

### Global Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.cloud | string | `""` | Cloud provider (options: aws, gcp, azure) |
| global.labels | object | `{}` | Labels applied to all resources |
| sharedIngress | array | `[]` | Shared ingress definitions for path-based routing |
| extraObjects | array | `[]` | Extra Kubernetes objects to deploy alongside services |

### Shared Ingress Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sharedIngress[].name | string | **required** | Name of the ingress resource |
| sharedIngress[].hostname | string | **required** | Hostname for the ingress |
| sharedIngress[].certificateIssuer | string | `""` | cert-manager cluster issuer name |
| sharedIngress[].tlsSecretName | string | `""` | Override TLS secret name (default: `{name}-tls`) |
| sharedIngress[].enableTraefik | bool | `true` | Use Traefik ingress class and annotations |
| sharedIngress[].ingressClassName | string | `""` | Custom ingress class (when enableTraefik is false) |
| sharedIngress[].annotations | object | `{}` | Additional annotations for the ingress |
| sharedIngress[].routes | array | **required** | Array of path-based routing rules |
| sharedIngress[].routes[].path | string | **required** | URL path to match |
| sharedIngress[].routes[].pathType | string | `"Prefix"` | Path type: Prefix, Exact, or ImplementationSpecific |
| sharedIngress[].routes[].serviceName | string | **required** | Target service name |
| sharedIngress[].routes[].port | int | **required** | Target service port |

### Service Configuration

Each service in the `services` array supports all configuration options from the `service-deployment` chart:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| services[].name | string | **required** | Name of the service (used for all resource names) |
| services[].image | object | **required** | Container image configuration |
| services[].image.repository | string | **required** | Container image repository |
| services[].image.tag | string | **required** | Container image tag |
| services[].image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| services[].image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| services[].config | object | `{}` | Configuration (command, args, env, secrets) |
| services[].resources | object | `{}` | Resource requests and limits |
| services[].service.deploy | bool | `true` | Whether to create a Service |
| services[].service.port | int | `8000` | Service port |
| services[].service.targetPort | int | `80` | Container target port |
| services[].service.ingress | object | `{}` | Ingress configuration |
| services[].hpa.deploy | bool | `true` | Whether to deploy HPA |
| services[].hpa.minReplicas | int | `1` | Minimum replicas |
| services[].hpa.maxReplicas | int | `20` | Maximum replicas |
| services[].vpa.enabled | bool | `false` | Whether to enable VPA |
| services[].deployment.kind | string | `"Deployment"` | Deployment kind (Deployment or StatefulSet) |
| services[].deployment.replicas | int | `1` | Number of replicas (when HPA disabled) |
| services[].persistentVolume.enabled | bool | `false` | Whether to create PVC |
| services[].hooks | object | `{}` | Helm hooks configuration |
| services[].rbac.role.deploy | bool | `false` | Whether to create Role |
| services[].rbac.clusterRole.deploy | bool | `false` | Whether to create ClusterRole |

For a complete list of configuration options, see the [values.yaml](./values.yaml) file.

## Examples

### Example 1: Frontend and Backend with Ingress

```yaml
global:
  cloud: aws
  labels:
    environment: production

services:
  - name: frontend
    image:
      repository: mycompany/frontend
      tag: v2.1.0
      isRepositoryPublic: false
    service:
      deploy: true
      port: 80
      targetPort: 8080
      ingress:
        main:
          hostname: example.com
          enableTraefik: true
    hpa:
      deploy: true
      minReplicas: 2
      maxReplicas: 10
    dockerconfigjson:
      name: frontend-dockerhub
      username: myuser
      password: mypassword

  - name: backend
    image:
      repository: mycompany/backend
      tag: v2.1.0
      isRepositoryPublic: false
    config:
      env:
        DATABASE_HOST: postgres.default.svc.cluster.local
      secrets:
        DATABASE_PASSWORD: supersecret
    service:
      deploy: true
      port: 3000
      targetPort: 3000
    hpa:
      deploy: true
      minReplicas: 3
      maxReplicas: 15
    cloudserviceaccount:
      deploy: true
      name: backend-sa
      aws:
        roleARN: arn:aws:iam::123456789012:role/backend-role
```

### Example 2: Microservices with Persistent Storage

```yaml
services:
  - name: api
    image:
      repository: myapp/api
      tag: latest
    service:
      deploy: true
      port: 8080

  - name: database
    image:
      repository: postgres
      tag: "14"
    config:
      env:
        POSTGRES_DB: mydb
      secrets:
        POSTGRES_PASSWORD: dbpassword
    service:
      deploy: true
      port: 5432
      targetPort: 5432
    deployment:
      kind: StatefulSet
    hpa:
      deploy: false
    deployment:
      replicas: 1
    persistentVolume:
      enabled: true
      size: 20Gi
      mountPath: /var/lib/postgresql/data
      storageClass: fast-ssd
```

### Example 3: Single Service with Hooks

```yaml
services:
  - name: myapp
    image:
      repository: nginx
      tag: latest
    service:
      deploy: true
      port: 80
    hooks:
      db-migrate:
        enabled: true
        image: myapp/migrations:latest
        hookPhase: pre-install
        hookDeletePolicy: hook-succeeded
        script: |
          echo "Running database migrations..."
          npm run migrate
        env:
          DATABASE_URL: postgres://db:5432/myapp
```

## Notes

- Each service's `name` field must be unique within the release
- Service names are used for all Kubernetes resource names (Deployment, Service, etc.)
- Global labels are applied to all resources across all services
- Each service can have its own dockerconfigjson and cloudserviceaccount configuration
- The chart uses the `common` library for all template logic, ensuring consistency

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://snowplow-devops.github.io/helm-charts | common | 0.3.0 |
