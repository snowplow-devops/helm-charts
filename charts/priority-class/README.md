# priority-class

A Helm chart to deploy generic priority classes for all tiers.

## TL;DR

```bash
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts
helm install priority-class snowplow-devops/priority-class
```

## Introduction

This chart attempts to take care of deploying a set of generic priority classes that cover all use cases for pod prioritization

- **Critical** - Used for mission critical priority pods that preempt all other priority classes
- **High** - High priority pods that preempt medium and low priority pods
- **Medium** - Medium priority pods to be used as default with  `globalDefault: true`
- **Low** - Lowest priority pods

## Installing the Chart

Install or upgrading the chart with default configuration:

```bash
helm upgrade --install priority-class snowplow-devops/priority-class
```

## Uninstalling the Chart

To uninstall/delete the `priority-class` release:

```bash
helm delete priority-class
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Overrides the name given to the deployment resources (default: .Release.Name) |
| fullnameOverride | string | `""` | Overrides the full-name given to the deployment resources (default: .Release.Name) |
| labels | object | `{}` | labels deployed to all priority classes deployed by the chart |
