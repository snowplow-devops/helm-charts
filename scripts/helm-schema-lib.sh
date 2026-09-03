#!/usr/bin/env bash
# Shared helpers for values.schema.json generation.
#
# Sourced by:
#   scripts/helm-schema.sh        - pre-commit hook, writes the schema
#   scripts/helm-schema-check.sh  - CI drift check, verifies only
#
# Keeping the generator version, flags and opt-in rule in one place means the
# hook and CI can never disagree about what a correct schema looks like.

# Pinned generator version. Bump here, in .pre-commit-config.yaml's install
# hint and in .github/workflows/lint-test.yml together, in a single PR that
# also regenerates every committed schema.
SCHEMA_PLUGIN_VERSION="2.6.0"

# --use-helm-docs reuses the existing "# --" comments as schema descriptions,
# which surface as hover text in editors.
SCHEMA_ARGS=(--use-helm-docs)

# Override for testing; normally the installed helm plugin.
HELM_SCHEMA_BIN="${HELM_SCHEMA_BIN:-helm schema}"

schema::require_plugin() {
  if ! $HELM_SCHEMA_BIN --version >/dev/null 2>&1; then
    cat >&2 <<MSG
error: helm 'schema' plugin not installed. Install the pinned version with:

  helm plugin install https://github.com/losisin/helm-values-schema-json --version ${SCHEMA_PLUGIN_VERSION}
MSG
    return 1
  fi

  [[ -n "${HELM_SCHEMA_SKIP_VERSION_CHECK:-}" ]] && return 0

  local installed
  installed="$($HELM_SCHEMA_BIN --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  if [[ "$installed" != "$SCHEMA_PLUGIN_VERSION" ]]; then
    cat >&2 <<MSG
error: helm 'schema' plugin version mismatch (installed ${installed:-unknown}, pinned ${SCHEMA_PLUGIN_VERSION}).
Different versions can emit different schemas, which shows up as CI drift you
cannot reproduce locally. Align with:

  helm plugin uninstall schema
  helm plugin install https://github.com/losisin/helm-values-schema-json --version ${SCHEMA_PLUGIN_VERSION}

Set HELM_SCHEMA_SKIP_VERSION_CHECK=1 to bypass.
MSG
    return 1
  fi
}

# A chart is opted in once values.schema.json is committed. Until then both the
# hook and CI leave it alone, so charts can be adopted one at a time.
schema::is_opted_in() {
  [[ -f "$1/values.schema.json" ]]
}

schema::generate() {
  ( cd "$1" && $HELM_SCHEMA_BIN "${SCHEMA_ARGS[@]}" >/dev/null )
}
