#!/usr/bin/env bash
# CI entrypoint: verify the committed values.schema.json matches what the
# generator produces, for the charts changed in this PR. Never writes.
#
# Scoped with `ct list-changed`, so it inherits the excluded-charts list in
# ct.yaml and only reports on charts the PR actually touches.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
# shellcheck source=scripts/helm-schema-lib.sh
source scripts/helm-schema-lib.sh

schema::require_plugin

TARGET_BRANCH="${TARGET_BRANCH:-main}"
changed="$(ct list-changed --target-branch "$TARGET_BRANCH" --config ct.yaml)"

if [[ -z "$changed" ]]; then
  echo "No charts changed against ${TARGET_BRANCH}."
  exit 0
fi

rc=0
for chart in $changed; do
  if ! schema::is_opted_in "$chart"; then
    echo "skip  $chart (no schema yet)"
    continue
  fi

  schema::generate "$chart"

  if git diff --quiet -- "$chart/values.schema.json"; then
    echo "ok    $chart"
  else
    echo "DRIFT $chart"
    git --no-pager diff -- "$chart/values.schema.json"
    rc=1
  fi
done

if (( rc != 0 )); then
  cat >&2 <<'MSG'

values.schema.json is out of date for the charts marked DRIFT above.
Regenerate and commit, using any one of:

  cd charts/<chart> && helm schema --use-helm-docs
  pre-commit run helm-schema --all-files
  pre-commit install    # once, so this is handled on every future commit
MSG
fi

# Restore the tree so nothing downstream sees generated changes.
git checkout -- . 2>/dev/null || true
exit $rc
