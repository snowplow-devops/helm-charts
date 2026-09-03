#!/usr/bin/env bash
# Validate each chart's schema fixtures against its values.schema.json.
#
# Fixtures live in charts/<chart>/tests/schema/:
#   valid-*.yaml    must render cleanly
#   invalid-*.yaml  must be REJECTED, and the error must match the file's
#                   "# expect: <substring>" header
#
# The expect header is the point: a fixture that fails for an unrelated reason
# (a template bug, a typo in the fixture) would otherwise look like a pass and
# silently stop testing the schema.
#
# Usage: scripts/helm-schema-test.sh [chart-dir ...]   (default: all charts
# that have a tests/schema directory)
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

charts=("$@")
if (( ${#charts[@]} == 0 )); then
  charts=()
  for d in charts/*/tests/schema; do
    [[ -d "$d" ]] && charts+=("${d%/tests/schema}")
  done
fi

if (( ${#charts[@]} == 0 )); then
  echo "No charts with tests/schema fixtures found."
  exit 0
fi

pass=0 fail=0

for chart in "${charts[@]}"; do
  dir="$chart/tests/schema"
  [[ -d "$dir" ]] || { echo "no fixtures: $chart"; continue; }

  if [[ ! -f "$chart/values.schema.json" ]]; then
    echo "FAIL  $chart has tests/schema but no values.schema.json"
    (( fail++ )); continue
  fi

  # Subchart tarballs are not tracked in git, so a fresh clone (i.e. CI) has
  # none and every helm template call fails on missing dependencies rather
  # than on the schema. ct does this itself before linting; so must we.
  if grep -q '^dependencies:' "$chart/Chart.yaml" 2>/dev/null; then
    if ! deps="$(helm dependency build "$chart" 2>&1)"; then
      echo "FAIL  $chart -- helm dependency build failed:"
      printf '%s\n' "$deps" | sed 's/^/        /' | head -5
      echo "        (add the repo first: helm repo add snowplow-devops https://snowplow-devops.github.io/helm-charts)"
      (( fail++ )); continue
    fi
  fi

  echo "== $chart"
  for f in "$dir"/*.yaml; do
    [[ -e "$f" ]] || continue
    name="$(basename "$f")"
    out="$(helm template schema-test "$chart" -f "$f" 2>&1)"
    rc=$?

    case "$name" in
      valid-*)
        if (( rc == 0 )); then
          echo "  ok      $name"; (( pass++ ))
        else
          echo "  FAIL    $name -- expected to render, but was rejected:"
          printf '%s\n' "$out" | grep -E '^-|Error' | sed 's/^/            /' | head -5
          (( fail++ ))
        fi
        ;;
      invalid-*)
        expect="$(sed -n 's/^# expect: //p' "$f" | head -1)"
        if [[ -z "$expect" ]]; then
          echo "  FAIL    $name -- missing '# expect: <substring>' header"
          (( fail++ )); continue
        fi
        if (( rc == 0 )); then
          echo "  FAIL    $name -- expected rejection, but it rendered"
          (( fail++ ))
        elif printf '%s' "$out" | grep -qF -- "$expect"; then
          echo "  ok      $name  ($expect)"; (( pass++ ))
        else
          echo "  FAIL    $name -- rejected, but not for the stated reason"
          echo "            expected: $expect"
          printf '%s\n' "$out" | grep -E '^-|Error' | sed 's/^/            actual:   /' | head -3
          (( fail++ ))
        fi
        ;;
      *)
        echo "  FAIL    $name -- fixture must be named valid-*.yaml or invalid-*.yaml"
        (( fail++ ))
        ;;
    esac
  done
done

echo
echo "$pass passed, $fail failed"
(( fail == 0 ))
