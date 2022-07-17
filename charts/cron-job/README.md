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

## Uninstalling the Chart

To uninstall/delete the `cron-job` release:

```bash
helm delete cron-job
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| job.schedule | string | `"*/1 * * * *"` |  |
| job.concurrencyPolicy | string | `"Forbid"` |  |
| job.failedJobsHistoryLimit | int | `1` |  |
| job.successfulJobsHistoryLimit | int | `1` |  |
| job.image.repository | string | `"busybox"` |  |
| job.image.tag | string | `"latest"` |  |
| job.image.isRepositoryPublic | bool | `true` | Whether the repository is public |
| job.config.command | list | `[]` |  |
| job.config.args | list | `[]` |  |
| job.config.env | object | `{}` |  |
| job.config.secrets | object | `{}` |  |
| dockerconfigjson.name | string | `"snowplow-cron-job-dockerhub"` | Name of the secret to use for the private repository |
| dockerconfigjson.username | string | `""` | Username for the private repository |
| dockerconfigjson.password | string | `""` | Password for the private repository |
| dockerconfigjson.server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| dockerconfigjson.email | string | `""` | Email address for user of the private repository |
