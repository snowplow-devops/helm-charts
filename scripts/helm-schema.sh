#!/usr/bin/env bash
# pre-commit entrypoint: regenerate values.schema.json for every chart whose
# values.yaml is staged.
#
# Charts with no committed schema are skipped, so this stays inert until a
# chart is deliberately opted in by committing its first schema.
#
# The regenerated file is intentionally NOT staged automatically: the schema
# encodes hand-authored "# @schema" type decisions and should appear in the
# diff you review. pre-commit blocks the commit, you `git add` and commit again.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
# shellcheck source=scripts/helm-schema-lib.sh
source scripts/helm-schema-lib.sh

schema::require_plugin

for values in "$@"; do
  chart="$(dirname "$values")"
  if ! schema::is_opted_in "$chart"; then
    echo "skip  $chart (no schema yet)"
    continue
  fi
  schema::generate "$chart"
  echo "regen $chart"
done
