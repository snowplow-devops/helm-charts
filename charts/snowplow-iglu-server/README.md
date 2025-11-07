# snowplow-iglu-server

A helm chart for [Snowplow Iglu Server](https://github.com/snowplow-incubator/iglu-server).

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install snowplow-iglu-server snowplow-devops/snowplow-iglu-server
```

## Introduction

This chart deploys a Snowplow Iglu Server on a Kubernetes cluster using the Helm package manager.  For demonstration purposes the system is deployed with an "in-memory" database.  Configure a "postgres" backend for production use-cases.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install snowplow-iglu-server snowplow-devops/snowplow-iglu-server
```

## Uninstalling the Chart

To uninstall/delete the `snowplow-iglu-server` release:

```bash
helm delete snowplow-iglu-server
```

## Deployment options

The most common settings we expect users to leverage are exposed as inputs under the `service.config.*` key.

If however you need to tune other settings you can also optionally provide a base64 encoded HOCON in the `service.config.hoconBase64`.  It is important to remember however that the settings being defined in the common settings will *always* take precedence over anything you define in the config.

### Backend: Postgres

1. Configure a PostgreSQL backend
  - As an example you can use: https://artifacthub.io/packages/helm/bitnami/postgresql
  - You will need the endpoint, username, password, port and database name
2. Make a copy of `values-local.yaml.tmpl` and call it `values-local.yaml`
3. Sub in the database values from step 1
4. Run: `helm upgrade --install snowplow-iglu-server --values values-local.yaml .`
  - Make sure to target the same namespace as your PostgresDB (assumption is `default`)

You can then port-forward the deployment to access it from your host:

```bash
kubectl port-forward --namespace default svc/snowplow-iglu-server-iglu-app 8080:8080
```

_Note_: This assumes 8080 is available on your host and you have used the default bind port of 8080.

You can then use the Iglu Server as normal leveraging the APIKey you generated earlier and `localhost:8080` as your endpoint (e.g. `curl http://localhost:8080/static/swagger-ui/index.html`).

### AWS (EKS) settings

#### TargetGroup binding

To manage the load balancer externally to the kubernetes cluster you can bind the deployment to an existing TargetGroup ARN.  Its important that the TargetGroup exist ahead of time and that you use the same port as you have used in your `values.yaml`. 

*Note*: Before this will work you will need to install the `aws-load-balancer-controller-crds` and `aws-load-balancer-controller` charts into your EKS cluster.

You will need to fill these targeted fields:

- `global.cloud: "aws"`
- `service.aws.targetGroupARN: "<target_group_arn>"`

### GCP (GKE) settings

#### NetworkEndpointGroup binding

To manage the load balancer externally from the GKE cluster you can bind the deployment onto dynamically assigned Network Endpoint Groups (NEGs).

1. Set the NEG name: `service.gcp.networkEndpointGroupName: <valid_value>`
   - Will default to the Chart release name
2. This will create Zonal NEGs in your account automatically (do not proceed until the NEGs appear - check your deployment events if this doesn't happen!)
3. Create a Load Balancer as usual and map the NEGs created into your backend service (follow the `Create Load Balancer` flow in the GCP Console)

*Note*: The HealthCheck you create should map to the same port you used for the service deployment.

#### Backend: CloudSQL Postgres with proxy

To ease deployment to a GKE cluster you can optionally leverage the built-in CloudSQL proxy - this will create a service deployment exposing your CloudSQL instance within your cluster.

To take advantage of this you will need to bind a service-account to the deployment which, in Terraform, looks something like the following:

```hcl
resource "google_service_account" "snowplow_iglu_server" {
  account_id   = "snowplow-iglu-server"
  display_name = "Snowplow Iglu Server service account"
}

resource "google_service_account_iam_binding" "snowplow_iglu_server_sa_wiu_binding" {
  role = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:<project>.svc.id.goog[<namespace>/<release_name>]",
    "serviceAccount:<project>.svc.id.goog[<namespace>/<release_name>-csp]"
  ]
  service_account_id = google_service_account.snowplow_iglu_server.id
}

resource "google_project_iam_member" "snowplow_iglu_server_sa_cloudsql_client" {
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.snowplow_iglu_server.email}"
}

output "snowplow_iglu_server_sa_account_email" {
  value = google_service_account.snowplow_iglu_server.email
}
```

You can then use the resulting value as an input to `cloudserviceaccount.gcp.serviceAccount` which will allow the CloudSQL deployment to access the database.

You will need to fill these targeted fields:

- `global.cloud: "gcp"`
- `service.gcp.deployProxy: true`
- `service.gcp.proxy.port: <some_value>`
- `service.gcp.proxy.project: <project>`
- `service.gcp.proxy.region: <region>`
- `service.gcp.proxy.instanceName: <db_instance_name>`
- `service.gcp.proxy.ipAddressTypes: <PUBLIC|PRIVATE|PSC>` (optional, defaults to PUBLIC)
- `cloudserviceaccount.deploy: true`
- `cloudserviceaccount.name: <unique_name>`
- `cloudserviceaccount.gcp.serviceAccount: <output_value_from_above>`

*Note*: As the iglu deployment and setup hooks depend on this service it is normal to expect a few initial failures to occur - they should automatically resolve without intervention.

## Database Setup and Teardown Hooks

The chart includes Helm hooks for automated database and user initialization when using PostgreSQL as the backend.

### Setup Hooks

Setup hooks run after installation (`post-install`) and upgrades (`post-upgrade`) to prepare the database environment:

1. **Database Initialization Hook** (`hooks.deploySetupHooks: true`)
   - Creates database user if `hooks.deployDBUser: true`
   - Creates database if `hooks.deployDB: true` 
   - Grants privileges to the user if `hooks.deployDBUserGrants: true`. Required if the database is created separately.
   - Runs with `helm.sh/hook-weight: "1"` (before Iglu Server setup)

2. **Iglu Setup Hook** (automatically runs when `hooks.deploySetupHooks: true`)
   - Initializes Iglu Server database schema and configuration
   - Runs with `helm.sh/hook-weight: "2"` (after database / user initialization)

### Destroy Hooks

Destroy hooks run before deletion (`pre-delete`) to clean up database resources:

- **Database Cleanup Hook** (`hooks.deployDestroyHooks: true`)
  - Drops database if `hooks.destroyDB: true`
  - Drops database user if `hooks.destroyDBUser: true`
  - Requires admin credentials for cleanup operations

### Configuration

To use hooks, you need to provide administrative database credentials:

```yaml
hooks:
  deploySetupHooks: true
  deployDBUser: true
  deployDB: true
  deployDBUserGrants: true
  image:
    repository: "postgres"    # PostgreSQL client image repository
    tag: "15-alpine"          # PostgreSQL client image tag
    pullPolicy: "Always"      # Image pull policy for hook containers
  connectionTimeout: 10       # Connection timeout in seconds for PostgreSQL connections
  defaultDBName: "postgres"   # Database to connect to for admin operations
  secrets:
    admin_username: "postgres"
    admin_password: "your-admin-password"

service:
  config:
    database:
      type: "postgres"
      host: "your-postgres-host"
      port: 5432
      dbname: "iglu_db"  # Database to create/use for Iglu
      secrets:
        username: "iglu_user"  # User to create for Iglu
        password: "iglu-password"
```

### Hook Execution Order

1. **Installation/Upgrade**:
   - Database initialization hook (weight: 1) - Creates user, database, grants permissions
   - Iglu setup hook (weight: 2) - Initializes Iglu schema
   - Main deployment starts

2. **Deletion**:
   - Main deployment stops
   - Database cleanup hook - Drops database and user (if configured)

*Note*: Hooks are only active when `service.config.database.type` is set to `"postgres"`.

## Configuration

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
| global.labels | object | `{}` | Global labels deployed to all resources deployed by the chart |
| hooks.deploySetupHooks | bool | `false` | Whether to run the post-deploy setup hooks to create database and user |
| hooks.deployDestroyHooks | bool | `false` | Whether to run the pre-delete destroy hooks to clean up database and user |
| hooks.deployDBUser | bool | `false` | Whether the setup hook should create the database user |
| hooks.deployDBUserGrants | bool | `false` | Whether the setup hook should grant privileges to the database user |
| hooks.deployDB | bool | `false` | Whether the setup hook should create the database |
| hooks.destroyDBUser | bool | `false` | Whether the destroy hook should drop the database user |
| hooks.destroyDB | bool | `false` | Whether the destroy hook should drop the database |
| hooks.defaultDBName | string | `"postgres"` | Default database name to connect to for administrative operations |
| hooks.image.repository | string | `"postgres"` | PostgreSQL client image repository for hooks |
| hooks.image.tag | string | `"15-alpine"` | PostgreSQL client image tag for hooks |
| hooks.image.pullPolicy | string | `"Always"` | Image pull policy for hook containers |
| hooks.connectionTimeout | int | `10` | Connection timeout in seconds for PostgreSQL connections |
| hooks.secrets.admin_username | string | `""` | Admin username for database operations in hooks |
| hooks.secrets.admin_password | string | `""` | Admin password for database operations in hooks |
| service.annotations | object | `{}` | Map of annotations to add to the service |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.config.database.dbname | string | `""` | Postgres database name |
| service.config.database.host | string | `""` | Postgres database host |
| service.config.database.port | int | `5432` | Postgres database port |
| service.config.database.secrets.password | string | `""` |  |
| service.config.database.secrets.username | string | `""` |  |
| service.config.database.type | string | `"dummy"` | Can be either 'dummy' (in-memory) or 'postgres' |
| service.config.hoconBase64 | string | `""` | Optional Base64 encoded config HOCON (note: will not override above settings) |
| service.config.javaOpts | string | `""` | Optional JAVA_OPTS inputs for the deployed service |
| service.config.patchesAllowed | bool | `false` | Whether to allow schema patching |
| service.config.repoServer.idleTimeout | string | `"65 seconds"` |  |
| service.config.repoServer.maxConnections | int | `16384` |  |
| service.config.repoServer.hsts.enable | bool | `true` | Whether to enable sending HSTS headers (>=0.12.0) |
| service.config.secrets.superApiKey | string | `""` | Lowercase uuidv4 to use as admin apikey of the service (default: auto-generated) |
| service.gcp.deployProxy | bool | `false` | Whether to use CloudSQL Proxy (note: requires GCP service account to be attached) |
| service.gcp.networkEndpointGroupName | string | `""` | Name of the Network Endpoint Group to bind onto |
| service.gcp.proxy.image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| service.gcp.proxy.image.repository | string | `"gcr.io/cloudsql-docker/gce-proxy"` |  |
| service.gcp.proxy.image.tag | string | `"1.31.2"` |  |
| service.gcp.proxy.instanceName | string | `""` | Name of the CloudSQL instance |
| service.gcp.proxy.ipAddressTypes | string | `"PUBLIC"` | IP address types to use (options: PUBLIC, PRIVATE, PSC) |
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
| service.image.tag | string | `"0.10.0-distroless"` |  |
| service.ingress | object | `{}` | A map of ingress rules to deploy |
| service.maxReplicas | int | `4` |  |
| service.minReplicas | int | `1` |  |
| service.port | int | `8080` | Port to bind and expose the service on |
| service.livenessProbe.failureThreshold | int | `3` |  |
| service.livenessProbe.initialDelaySeconds | int | `30` |  |
| service.livenessProbe.periodSeconds | int | `5` |  |
| service.livenessProbe.timeoutSeconds | int | `5` |  |
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
| service.tolerations | list |`[]` | Tolerations labels for pod assignment with matching taints |
| service.topologySpreadConstraints | object | `{}` | Topology Spread Constraints for pod assignment |
