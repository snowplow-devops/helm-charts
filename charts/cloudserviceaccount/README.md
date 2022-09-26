# cloudserviceaccount

A helm chart which can create a ServiceAccount with cloud specific bindings.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install cloudserviceaccount snowplow-devops/cloudserviceaccount
```

## Introduction

This chart creates a service account with cloud specific bindings to allow IAM from the Cloud provider to be mapped onto a deployed service.

_Note_: Requires setting `global.cloud` to either `aws` or `gcp`.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install cloudserviceaccount snowplow-devops/cloudserviceaccount
```

## Uninstalling the Chart

To uninstall/delete the `cloudserviceaccount` release:

```bash
helm delete cloudserviceaccount
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| deploy | bool | `false` | Whether to create a service-account |
| name | string | `"my-service-account"` | Name of the service-account to create |
| aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
| secrets | list | `[]` | List of secrets allowed to be used by pods running using this ServiceAccount |
