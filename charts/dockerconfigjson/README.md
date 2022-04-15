# dockerconfigjson

A helm chart to configure a secret for pulling a container image from a private repository.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install dockerconfigjson snowplow-devops/dockerconfigjson
```

## Introduction

This chart creates a secret which can be referenced to allow pulling images from private repositories.

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install dockerconfigjson snowplow-devops/dockerconfigjson
```

## Uninstalling the Chart

To uninstall/delete the `dockerconfigjson` release:

```bash
helm delete dockerconfigjson
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `"dockerhub"` | Name of the secret to use for the private repository |
| username | string | `""` | Username for the private repository |
| password | string | `""` | Password for the private repository |
| server | string | `"https://index.docker.io/v1/"` | Repository server URL |
| email | string | `""` | Email address for user of the private repository |
