# cron-job

A helm chart to configure a cron job.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install cron-job snowplow-devops/cron-job
```

## Introduction

This chart creates a cron job of an arbitrary input container and input variables configured on the environment.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install cron-job snowplow-devops/cron-job
```

_Note_: As default the chart simply deploys an example busybox to illustrate running a simple command - take note of the default `values.yaml` and alter to suit your needs!

To see example input you should also dig through the `values.yaml` to understand the full range of options available.

## Uninstalling the Chart

To uninstall/delete the `cron-job` release:

```bash
helm delete cron-job
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.cloud | string | `""` | Cloud specific bindings (options: aws, gcp, azure) |
| global.labels | object | `{}` | Global labels deployed to all resources deployed by the chart |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| suspend | bool | `false` | Whether to suspend scheduled executions |
| schedule | string | `"*/1 * * * *"` |  |
| concurrencyPolicy | string | `"Forbid"` |  |
| restartPolicy | string | `"Never"` |  |
| failedJobsHistoryLimit | int | `1` |  |
| successfulJobsHistoryLimit | int | `1` |  |
| image.repository | string | `"busybox"` |  |
| image.tag | string | `"latest"` |  |
| image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| image.pullPolicy | string | `"IfNotPresent"` | The image pullPolicy to use |
| config.command | list | `[]` |  |
| config.args | list | `[]` |  |
| config.env | object | `{}` | Map of environment variables to use within the job |
| config.secrets | object | `{}` | Map of secrets that will be exposed as environment variables within the job |
| configMaps | list | `[]` | List of config maps to mount to the deployment |
| resources | object | `{}` | Map of resource constraints for the deployment |
| dockerconfigjson.name | string | `"snowplow-cron-job-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
| cloudserviceaccount.deploy | bool | `false` | Whether to create a service-account |
| cloudserviceaccount.name | string | `"snowplow-cron-job-service-account"` | Name of the service-account to create |
| cloudserviceaccount.aws.roleARN | string | `""` | IAM Role ARN to bind to the k8s service account |
| cloudserviceaccount.gcp.serviceAccount | string | `""` | Service Account email to bind to the k8s service account |
| cloudserviceaccount.azure.managedIdentityId | string | `""` | Workload managed identity id to bind to the k8s service account |
| customRole.deploy | bool | `false` | Whether to deploy the custom role and bind it to the cloudserviceaccount |
| customRole.apiGroups | list | `[]` | APIGroups is the name of the APIGroup that contains the resources |
| customRole.resources | list | `[]` | Resources is a list of resources this rule applies to |
| customRole.verbs | list | `[]` | Verbs is a list of Verbs that apply to ALL the ResourceKinds contained in this rule |
