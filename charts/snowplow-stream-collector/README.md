# snowplow-stream-collector

A helm chart for [Snowplow Stream Collector](https://github.com/snowplow/stream-collector).

## Installing the Chart

Add the repository to Helm:

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
```

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install snowplow-stream-collector snowplow-devops/snowplow-stream-collector
```

## Uninstalling the Chart

To uninstall/delete the `snowplow-stream-collector` release:

```bash
helm delete snowplow-stream-collector
```

## Deployment options

The Collector is designed to run in the public cloud but can also be run in local distributions and has support for a wide-array of backends.  This chart supports all of these available options.

First determine the target you want to send data to and then build a valid config for the Collector - you can [view examples here](https://github.com/snowplow/stream-collector/tree/master/examples).  The default installation writes everything to stdout.

---
*WARNING*: It is recommended to use `port = ${COLLECTOR_PORT}` in your config as then the chart can ensure the correct port is set in your configuration file.  See the example configurations for how this looks.
---

#### Configure end2end TLS

Due to a known issue in AkkaHTTP when handling TLS termination we now embed an NGINX proxy as an _optional_ side-car to the Collector - this replaces terminating TLS directly in the Collector itself and is the safer alternative for the moment.

This also allows us to obfuscate the server being used for the Collector application itself.

To enable TLS you will need to:

1. Set `service.nginx.enable: true`
2. Set `service.ssl.enable: true`
3. Generate and pass both the certificate and private key in base64 encoded format in the appropriate fields

The deployment will then be bound on the defined SSL port and will forward connections to the Collector side-car container directly.

### On-premise deployment

For fast testing and implementations where you do not care about integrating with public-cloud systems.

#### Target: Stdout

The simplest option is `stdout` which will send all events received directly to logging output:

```
helm upgrade --install snowplow-stream-collector .
```

#### Target: Kafka

To test out Kafka support you can spin up a local cluster and then pipe data into it.  We are using the `bitnami` chart to simplify the deployment:

```
# Deploy a default Kafka cluster
helm upgrade --install kafka bitnami/kafka

# Deploy the collector sending data to Kafka
helm upgrade --install snowplow-stream-collector \
  --set service.config.hoconBase64=$(cat examples/kafka.hocon | base64) \
  --set service.image.target=kafka .
```

You can then setup your own Kafka consumer to pull down the data from created topics (good & bad).

### GCP (GKE) settings

#### Network Endpoint Group binding

To manage the load balancer externally to the kubernetes cluster you can bind the deployment to dynamically assigned Network Endpoint Group (NEG).

1. Set the NEG name: `service.gcp.networkEndpointGroupName: <valid_value>`
2. This will create Zonal NEGs in your account automatically (do not proceed until the NEGs appear - check your deployment events if this doesn't happen!)
3. Create a Load Balancer as usual and map the NEGs created into your backend service (follow the `Create Load Balancer` flow in the GCP Console)

_Note_: The HealthCheck you create should map to the same port you used for the service deployment.

#### Target: PubSub

To send data into PubSub you will need to bind a valid GCP service-account to the service deployment.  In Terraform this looks something like the following:

```hcl
resource "google_service_account" "snowplow_stream_collector" {
  account_id   = "snowplow-stream-collector"
  display_name = "Snowplow Stream Collector service account"
}

resource "google_service_account_iam_binding" "snowplow_stream_collector_sa_wiu_binding" {
  role = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:<project>.svc.id.goog[default/snowplow-stream-collector]"
  ]
  service_account_id = google_service_account.snowplow_stream_collector.id
}

resource "google_project_iam_member" "snowplow_stream_collector_sa_pubsub_viewer" {
  role   = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.snowplow_stream_collector.email}"
}

resource "google_project_iam_member" "snowplow_stream_collector_sa_pubsub_publisher" {
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.snowplow_stream_collector.email}"
}

output "snowplow_stream_collector_sa_account_email" {
  value = google_service_account.snowplow_stream_collector.email
}
```

You can then use the resulting value as an input to `serviceAccount.gcp.serviceAccount` which will allow the deployment to access PubSub.

You will need to fill these targeted fields:

- `cloud: "gcp"`
- `serviceAccount.deploy: true`
- `serviceAccount.gcp.serviceAccount: <output_value_from_above>`

### AWS (EKS) settings

#### TargetGroup binding

To manage the load balancer externally to the kubernetes cluster you can bind the deployment to an existing TargetGroup ARN.  Its important that the TargetGroup exist ahead of time and that you use the same port as you have used in your `values.yaml`. 

_Note_: Before this will work you will need to install the `aws-load-balancer-controller-crds` and `aws-load-balancer-controller` charts into your EKS cluster.

You will need to fill these targeted fields:

- `cloud: "aws"`
- `service.aws.targetGroupARN: "<target_group_arn>"`

#### Target: Kinesis and/or SQS

To send data into Kinesis and/or SQS without hardcoded credentials you will need to bind a valid AWS IAM role ARN to the service deployment.  In Terraform this looks something like the following:

```hcl
resource "aws_iam_policy" "snowplow_stream_collector" {
  name = "snowplow-stream-collector"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:DescribeStreamSummary",
        "kinesis:List*",
        "kinesis:Put*",
        "sqs:GetQueueUrl",
        "sqs:SendMessage",
        "sqs:ListQueues"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

module "snowplow_stream_collector" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.7.0"

  create_role = true

  role_name = "snowplow-stream-collector"

  provider_url = var.eks_cluster_url

  role_policy_arns = [
    aws_iam_policy.snowplow_stream_collector.arn
  ]
  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    "system:serviceaccount:default:snowplow-stream-collector"
  ]
}

output "snowplow_stream_collector_role_arn" {
  value = module.snowplow_stream_collector.iam_role_arn
}
```

You can then use the resulting value as an input to `serviceAccount.aws.roleARN` which will allow the deployment to access Kinesis and SQS.

You will need to fill these targeted fields:

- `cloud: "aws"`
- `serviceAccount.deploy: true`
- `serviceAccount.aws.roleARN: <output_value_from_above>`

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cloud | string | `""` | Cloud specific bindings (options: aws, gcp) |
| secrets.docker.email | string | `""` | Email address for user of the private repository |
| secrets.docker.name | string | `"dockerhub"` | Name of the secret to use for the private repository |
| secrets.docker.password | string | `""` | Password for the private repository |
| secrets.docker.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| secrets.docker.username | string | `""` | Username for the private repository |
| service.aws.targetGroupARN | string | `""` | EC2 TargetGroup ARN to bind the service onto |
| service.config.hoconBase64 | string | `""` |  |
| service.config.javaOpts | string | `""` |  |
| service.gcp.networkEndpointGroupName | string | `""` | Name of the Network Endpoint Group to bind onto (default: .Release.Name) |
| service.image.isRepositoryPublic | bool | `true` |  |
| service.image.repository | string | `"snowplow/scala-stream-collector"` |  |
| service.image.tag | string | `"2.5.0"` |  |
| service.image.target | string | `"stdout"` | Which image should be pulled (options: stdout, nsq, kinesis, sqs, kafka or pubsub) |
| service.maxReplicas | int | `4` |  |
| service.minReplicas | int | `1` |  |
| service.nginx.deploy | bool | `false` | Whether to serve request with an NGINX proxy side-car instead of the Collector directly |
| service.nginx.image.isRepositoryPublic | bool | `true` |  |
| service.nginx.image.repository | string | `"nginx"` |  |
| service.nginx.image.tag | string | `"stable-alpine"` |  |
| service.port | int | `8080` | HTTP port to bind and expose the service on |
| service.readinessProbe.failureThreshold | int | `3` |  |
| service.readinessProbe.initialDelaySeconds | int | `5` |  |
| service.readinessProbe.periodSeconds | int | `5` |  |
| service.readinessProbe.successThreshold | int | `2` |  |
| service.readinessProbe.timeoutSeconds | int | `5` |  |
| service.ssl.certificateBase64 | string | `""` | Certificate in PEM form |
| service.ssl.certificatePrivateKeyBase64 | string | `""` | Certificate Private Key in PEM form |
| service.ssl.enable | bool | `false` | Whether to enable the TLS port (requires service.nginx.deploy to be true) |
| service.ssl.port | int | `8443` | HTTPS port to bind and expose the service on |
| service.targetCPUUtilizationPercentage | int | `75` |  |
| service.terminationGracePeriodSeconds | int | `630` |  |
| serviceAccount.aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| serviceAccount.deploy | bool | `false` | Whether to create a service-account |
| serviceAccount.gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
