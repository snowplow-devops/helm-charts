# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a collection of Helm Charts for deploying Snowplow micro-services and additional add-ons for public cloud-based Kubernetes services. The charts are distributed via the Helm repository at `https://snowplow-devops.github.io/helm-charts`.

## Architecture

### Chart Categories

1. **Core Service Charts**:
   - `service-deployment`: Generic deployment with optional service/HPA bindings
   - `snowplow-iglu-server`: Snowplow Iglu Server for schema management
   - `daemonset`: Arbitrary container deployment as a daemonset
   - `cron-job`: Scheduled job execution

2. **Infrastructure Charts**:
   - `aws-load-balancer-controller-crds`: AWS Load Balancer Controller CRDs
   - `aws-otel-collector`: AWS OpenTelemetry Collector
   - `cert-manager-crds` & `cert-manager-issuer`: Certificate management
   - `network-policy`: Kubernetes network policies
   - `priority-class`: Kubernetes priority classes

3. **Utility Charts**:
   - `cloudserviceaccount`: Cloud IAM service account bindings
   - `dockerconfigjson`: Docker registry authentication
   - `github-actions-runners`: Self-hosted GitHub Actions runners
   - `cluster-warmer`: Cluster warming functionality

### Chart Dependencies

Most charts depend on two common utility charts:
- `dockerconfigjson` (v0.1.0): For private registry access
- `cloudserviceaccount` (v0.3.0): For cloud IAM bindings

### Multi-Cloud Support

Charts support three cloud providers through the `global.cloud` value:
- `aws`: Amazon Web Services
- `gcp`: Google Cloud Platform  
- `azure`: Microsoft Azure

## Common Development Commands

### Chart Testing and Validation
```bash
# Lint all charts
ct lint --target-branch main

# Install/test changed charts
ct install --target-branch main

# Add self as Helm repository (for dependency resolution)
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts

# Update Helm dependencies for a chart
helm dependency update charts/[chart-name]

# Template and validate a chart
helm template [release-name] charts/[chart-name] --values charts/[chart-name]/values.yaml
```

### Chart Development Workflow
1. Create/modify chart templates in `charts/[chart-name]/templates/`
2. Update `Chart.yaml` version following semantic versioning
3. Test chart rendering: `helm template test-release charts/[chart-name]`
4. Run chart-testing linter: `ct lint --charts charts/[chart-name]`
5. Update `CHANGELOG` with version and changes

## File Structure Patterns

### Standard Chart Structure
```
charts/[chart-name]/
├── Chart.yaml          # Chart metadata and dependencies
├── README.md           # Chart documentation
├── values.yaml         # Default configuration values
└── templates/
    ├── _helpers.tpl    # Template helpers (if needed)
    ├── NOTES.txt       # Post-install notes (if needed)
    └── [resource].yaml # Kubernetes resource templates
```

### Template Conventions
- Use `app.fullname` helper for consistent naming
- Include `snowplow.labels` for standard labels
- Support multi-cloud deployments via `global.cloud` value
- Follow Kubernetes naming conventions (max 50-63 chars)

### Values File Patterns
- `global.cloud`: Cloud provider specification
- `global.labels`: Labels applied to all resources
- `fullnameOverride`: Override default resource naming
- `image`: Container image configuration
- `config`: Application-specific configuration

## Chart-Specific Notes

### service-deployment
The most comprehensive chart, supporting:
- Generic deployments with extensive configuration options
- Database bootstrap jobs (new feature)
- Multi-cloud ingress and load balancer bindings
- HPA, PVC, and certificate management
- ConfigMaps, secrets, and environment variable injection

### snowplow-iglu-server  
Deploys Snowplow's schema registry service with:
- Multi-cloud support (AWS, GCP, Azure templates)
- PostgreSQL backend configuration
- Cloud SQL Proxy support for GCP

## Release Process

Charts are automatically released via GitHub Actions when changes are merged to `main`. The workflow:
1. Runs chart-testing (lint and install) on pull requests
2. Packages and publishes charts to GitHub Pages on merge
3. Updates the Helm repository index

## Testing

The repository uses [chart-testing](https://github.com/helm/chart-testing) for validation:
- Lint testing runs on every PR
- Install testing runs in a Kind cluster
- Python 3.8 and Helm v3.8.1 are used in CI
