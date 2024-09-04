# snowplow-pipeline-rabbitmq

## DISCLAIMER

This Chart and guide is completely experimental and not officially supported for Production workloads.  It is an attempt at building a lightweight Kubernetes first pipeline as opposed to our traditional cloud first approach.

## Introduction

This chart helps to deploy a Snowplow Pipeline entirely contained within a Kubernetes cluster.  This is an _example_ approach and should not be used in production without due diligence on all of the settings - but for PoC purposes it should be perfect!

To get a basic working pipeline you will need to deploy:

1. RabbitMQ cluster: Will be used as our queue layer between applications
2. Snowplow Collector: Provides the entrypoint for events to be collected
3. Snowplow Enrich: Application which consumes raw Collector events and turns them into good/bad events

After Enrich you will have a set of good + bad data in different RabbitMQ queues that can then be consumed by your tool of choice.

## 1. Setting up the prerequisites

To begin with you must have access to a Kubernetes cluster - if you are using macOS / Windows the easiest way to do this is with [Docker Desktop](https://docs.docker.com/desktop/kubernetes/) which now has a built-in Kubernetes cluster.

You will also need the [Helm tool available](https://helm.sh/docs/intro/install/) on your command-line.  As of time of writing this guide the version being used:

```bash
> helm version
version.BuildInfo{Version:"v3.9.0", GitCommit:"7ceeda6c585217a19a1131663d8cd1f7d641b2a7", GitTreeState:"clean", GoVersion:"go1.18.2"}
```

Now that you have everything prepared you can start installing a pipeline!

## 2. Setting up RabbitMQ

For this we are going to leverage the excellent Bitnami Chart which is readily available and use that as our test bed - there are hundreds of options to tune here for a production grade cluster but for our purposes the defaults will work just fine!

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install RabbitMQ
helm install rmq1 \
  --set auth.username=admin,auth.password=secretpassword,auth.erlangCookie=secretcookie \
    bitnami/rabbitmq
```

_Note_: You will need the username and password for later steps so do take note of them!

This step should dump out a good bit of information which you should save for later - specifically we are going to want to know how to portForward the management portal so we can inspect whats happening and the endpoint within the cluster so we can point our applications at the cluster.

```bash
# Endpoint + Port for sending and pulling data
RabbitMQ can be accessed within the cluster on port 5672 at rmq1-rabbitmq.default.svc.cluster.local
# Command to execute to expose management portal
kubectl port-forward --namespace default svc/rmq1-rabbitmq 15672:15672
```

## 3. Lets deploy a pipeline

if you are following the guide exactly then you should see two preconfigured config files inside `/configs` - one for the Collector and one for Enrich.  We have already taken the liberty of base64 encoding these and adding them to the `values.yaml` - if you want to change any settings you should update your values accordingly.

These configs are pointing at `rmq1-rabbitmq.default.svc.cluster.local:5672` and will use the following queue names:

- "raw-queue"
- "bad-1-queue"
- "enriched-queue"

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm repo update

# Deploy the pipeline
helm install pipeline snowplow-devops/snowplow-pipeline-rabbitmq 
```








### How to: expose the Collector to the internet?

As default the Collector service is not exposed externally to the Kubernetes cluster - we default to only using NodePort - binding a Load Balancer / external routing is left to the implementor to deal with.  For local testing port forwarding the service is recommended as a way to interact with the Collector.

However if are running an EKS (AWS) or GKE (GCP) cluster we do expose bindings that can map onto an existing AWS Target Group or GCP Network Endpoint Group (NEG) to allow you to route traffic from the internet into the exposed service.  You will need to set `global.cloud` to `aws` or `gcp` and follow the instructions below for your specific cloud.

_Note_: If you have feedback on this please open an issue on this repository for how this could be simplified!

#### GKE (GCP) NetworkEndpointGroup

To manage the Collector load balancer externally from the GKE cluster you can bind the deployment onto dynamically assigned Network Endpoint Groups (NEGs).

1. Set the NEG name: `collector.service.gcp.networkEndpointGroupName: <valid_value>`
  - Will default to the Chart release name
2. This will create Zonal NEGs in your account automatically (do not proceed until the NEGs appear - check your deployment events if this doesn't happen!)
3. Create a Load Balancer as usual and map the NEGs created into your backend service (follow the `Create Load Balancer` flow in the GCP Console)

*Note*: The HealthCheck you create should map to the same port you used for the Collector deployment.

#### EKS (AWS) TargetGroup

To manage the Collector load balancer externally to the Kubernetes cluster you can bind the deployment to an existing TargetGroup ARN.  Its important that the TargetGroup exist ahead of time and that you use the same port as you have used in your `values.yaml`. 

*Note*: Before this will work you will need to install the `aws-load-balancer-controller-crds` and `aws-load-balancer-controller` charts into your EKS cluster.

You will need to fill these targeted fields:

- `service.aws.targetGroupARN: "<target_group_arn>"`
