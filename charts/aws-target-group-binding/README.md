# aws-target-group-binding

A Helm chart for deploying a TargetGroupBinding resource for use with the AWS LoadBalancer Controller.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install aws-target-group-binding snowplow-devops/aws-target-group-binding
```

## Introduction

This chart will provision a TargetGroupBinding resource that can be combined with an externally provisioned AWS Loadbalancer to provide an ingress route into the defined kubernetes service.

## Prerequisite

In order to use this chart you will first require the aws-load-balancer-controller-crds to be installed, this can be done using the chart below.

https://github.com/snowplow-devops/helm-charts/tree/main/charts/aws-load-balancer-controller-crds

```bash
helm upgrade --install aws-load-balancer-controller-crds --namespace kube-system snowplow-devops/aws-load-balancer-controller-crds
```

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install aws-target-group-binding snowplow-devops/aws-target-group-binding
```

## Uninstalling the Chart

To uninstall/delete the `target-group-binding` release:

```bash
helm delete target-group-binding
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceName | string | `"myServiceName"` | Name of the service to add the binding against |
| servicePort | int | `80` | The port the required service is running on |
| targetGroupARN | string | `"arn:1234:5678"` | Amazon Resource Name (ARN) for the TargetGroup you want to use. |
