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

4. **Library Charts**:
   - `common`: Reusable template helpers for services, deployments, RBAC, ingress, etc.

### Chart Dependencies

Most charts depend on two common utility charts:
- `dockerconfigjson` (v0.1.0): For private registry access
- `cloudserviceaccount` (v0.3.0): For cloud IAM bindings

### Multi-Cloud Support

Charts support three cloud providers through the `global.cloud` value:
- `aws`: Amazon Web Services
- `gcp`: Google Cloud Platform
- `azure`: Microsoft Azure

### Library Chart Development

The repository includes library charts (type: library) that provide reusable templates:
- `common` (v0.1.0): Core template helpers for services, deployments, RBAC, ingress, etc.

**Key Patterns:**
- Library charts use named templates: `{{- define "common.resourcetype" -}}`
- Support N-instance pattern via `{{- range .Values.services }}` for single or multi-service deployments
- Capture contexts as variables in nested loops: `{{- $global := .Values.global -}}`, `{{- range $service := .Values.services }}`
- Always check `.Values.global` existence before accessing nested properties

**Testing:**
- Library charts cannot be installed directly
- Exclude from ct install tests via ct.yaml: `excluded-charts: - common`

## Common Development Commands

### Chart Testing and Validation
```bash
# Lint all charts (uses ct.yaml config)
ct lint --target-branch main --config ct.yaml

# Install/test changed charts (uses ct.yaml config)
ct install --target-branch main --config ct.yaml

# Add self as Helm repository (for dependency resolution)
helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts

# Update Helm dependencies for a chart
helm dependency update charts/[chart-name]

# Template and validate a chart
helm template [release-name] charts/[chart-name] --values charts/[chart-name]/values.yaml
```

**Chart Testing Configuration:**
The repository uses ct.yaml for chart-testing configuration:
- Pass `--config ct.yaml` to ct lint and ct install commands
- Exclude library charts from install tests: `excluded-charts: - common`
- Configure chart repositories for dependency resolution

### Chart Development Workflow
1. Create/modify chart templates in `charts/[chart-name]/templates/`
2. Update `Chart.yaml` version following semantic versioning
3. Test chart rendering: `helm template test-release charts/[chart-name]`
4. If the chart has a `values.schema.json`, regenerate it after any `values.yaml` change: `cd charts/[chart-name] && helm schema --use-helm-docs`
5. Run chart-testing linter: `ct lint --charts charts/[chart-name]`
6. Regenerate `README.md` with `helm-docs` if values changed
7. Update `CHANGELOG` with version and changes

### Maintainers
- Keep the `maintainers` list in each chart's `Chart.yaml` sorted alphabetically by `name`.
- After editing `maintainers`, regenerate the chart's `README.md` with `helm-docs` so its maintainers table stays in sync.

## Values Schema Validation

Charts opt in to `values.schema.json`, which `helm lint` (and therefore `ct lint` on every PR) enforces automatically, and `helm package` ships to consumers. `service-deployment` is the reference implementation.

**Tooling** — [losisin/helm-values-schema-json](https://github.com/losisin/helm-values-schema-json), pinned:
```bash
helm plugin install https://github.com/losisin/helm-values-schema-json --version 2.6.0
```
The version appears in three places that must move together: `SCHEMA_PLUGIN_VERSION` in `scripts/helm-schema-lib.sh`, the comment in `.pre-commit-config.yaml`, and the install step in `.github/workflows/lint-test.yml`. Mismatched versions produce CI drift that cannot be reproduced locally, so the scripts refuse to run on a mismatch.

### Adopting a new chart

1. `cd charts/[chart-name] && helm schema --use-helm-docs` — bootstrapping is manual; the pre-commit hook skips charts with no committed schema, which is what allows charts to be adopted one at a time.
2. Render with real overrides and fix anything wrongly rejected (see traps below), re-running `helm schema --use-helm-docs` after each `values.yaml` edit.
3. Add `tests/schema/valid-values.yaml` and `tests/schema/invalid-values.yaml`, plus a `.helmignore` containing `tests/` so fixtures are not packaged.
4. `./scripts/helm-schema-test.sh` must pass.
5. Bump `Chart.yaml`, regenerate `README.md` with `helm-docs`, add a `CHANGELOG` entry.

### `values.schema.json` is a build artifact

Never hand-edit it. The pre-commit hook and the CI `schema` job regenerate it from `values.yaml`, so manual edits are silently overwritten and CI fails on the diff. All constraints belong in `values.yaml` as inline `# @schema` annotations, which are reproduced on every regeneration:

```yaml
port:  # @schema type: [integer, "null"]
```

Use the **trailing** form with **two spaces** before the `#`. `ct lint` bundles a stricter yamllint than the repo's own hook and fails on one space. A comment that begins `# @schema` is parsed as an annotation, so ordinary comments must not start that way. Only a subset of keywords is supported — `type`, `additionalProperties`, `$ref` and similar; `if`/`then` and `properties` are rejected by the generator.

### Traps when generating a schema

The generator infers types from default values, so a default that shows only one valid form produces a schema that rejects the others. Check these before committing:

- **Kubernetes IntOrString fields** — probe ports, `service.targetPort`, `maxUnavailable`/`maxSurge`, PDB `minAvailable`/`maxUnavailable`. A default of `80` infers `integer` and rejects a named port; `"25%"` infers `string` and rejects `3`.
- **Declared-but-empty keys** — `env:` with no value infers `null`, rejecting any map. Annotate `type: [object, "null"]`.
- **Keys used by templates but only documented in comments** — e.g. `persistentVolume.storageClass`. These get no schema entry and stay unvalidated; a strict schema would reject them outright.
- **Keys absent from `values.yaml` entirely** — e.g. `containerSecurityContext.runAsUser`. Unvalidated, any type passes. Adding them to `values.yaml` gives validation, but where a template does `toYaml` over the parent map a `null` default renders as an explicit `null` in the manifest, changing `checksum/values` and rolling pods.

Keep schemas **permissive** (no `additionalProperties: false`) for charts that pass through free-form maps such as `resources`, `hooks`, `affinity`, `topologySpreadConstraints`, `podLabels`, `service.ingress` and `extraObjects`. `additionalProperties: false` also rejects keys a caller currently passes, which breaks existing deployments.

### Fixtures

`charts/[chart-name]/tests/schema/` holds `valid-*.yaml` (must render) and `invalid-*.yaml` (must be rejected). An invalid fixture needs an `# expect: <substring>` header and the error must match it — otherwise a fixture that fails for an unrelated reason, such as a template bug or a typo in the fixture, reads as a pass and stops testing anything.

```yaml
# expect: livenessProbe.httpGet.port: Invalid type. Expected: [integer,null], given: string
livenessProbe:
  httpGet:
    port: "8080"
```

Run with `./scripts/helm-schema-test.sh` (all charts with fixtures) or pass chart directories as arguments.

### Automation

| | Role |
|---|---|
| `scripts/helm-schema-lib.sh` | pinned version, flags, opt-in rule — shared |
| `scripts/helm-schema.sh` | pre-commit hook — **writes** the schema |
| `scripts/helm-schema-check.sh` | CI drift check — **verifies** only, scoped by `ct list-changed` |
| `scripts/helm-schema-test.sh` | runs the fixtures |

The pre-commit hook rewrites the schema and lets pre-commit fail the commit, so the regenerated file appears in the diff you review rather than being staged silently. It requires `pre-commit install`, which is per-developer, so the CI `schema` job is the actual gate. Subchart tarballs are not tracked in git, so anything running `helm template` in CI must `helm dependency build` first.

## File Structure Patterns

### Standard Chart Structure
```
charts/[chart-name]/
├── Chart.yaml          # Chart metadata and dependencies
├── README.md           # Chart documentation
├── values.yaml         # Default configuration values
├── values.schema.json  # Generated from values.yaml - never hand-edit (if adopted)
├── .helmignore         # Excludes tests/ from the package (if fixtures exist)
├── tests/schema/       # valid-*.yaml / invalid-*.yaml schema fixtures (if adopted)
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

### Template Best Practices

**Context Safety:**
- Always check parent objects exist before accessing nested properties:
```yaml
{{- if .Values.global }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}
```

**Nested Loops:**
- Capture outer contexts as named variables to avoid incorrect `$` references:
```yaml
{{- $global := .Values.global -}}
{{- range $service := .Values.services }}
  # Use $service.name, not $.name
{{- end }}
```

**Hostname Sanitization:**
- Replace dots with dashes for Kubernetes DNS-1123 compliance:
```yaml
name: {{ .hostname | replace "." "-" }}
secretName: {{ .hostname | replace "." "-" }}-tls
```

**Other Best Practices:**
- **YAML Formatting**: Use `nindent` (not `indent`) to ensure proper newline + indentation
- **Boolean Defaults**: Use `| default true` not `| default "true"`
- **RBAC**: ServiceAccount subjects do not use `apiGroup:` field (only Role/ClusterRole do)

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
