#!/usr/bin/env bash
# Run each chart's Kyverno policy tests with the kyverno CLI.
#
# Each suite lives in charts/<chart>/tests/kyverno/<suite>/:
#   chart-values.yaml  helm values that turn on the policy under test
#   kyverno-test.yaml  a `kyverno test` manifest whose policies: entry is
#                      policy.yaml
#   resources.yaml     fixture resources, one per code path
#
# The policies are Go templates, so they cannot be tested as committed. The
# suite is copied to a temp dir, the chart is rendered there as policy.yaml
# with chart-values.yaml, and `kyverno test` runs against that copy. Nothing
# rendered is written back into the repo.
#
# A suite whose render produces no Kyverno policy fails, rather than passing
# with nothing to test (e.g. a typo in chart-values.yaml).
#
# Usage: scripts/kyverno-policy-test.sh [suite-dir ...]   (default: every
# charts/*/tests/kyverno/*/ directory)
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

command -v kyverno >/dev/null || { echo "kyverno CLI not found on PATH"; exit 1; }

suites=("$@")
if (( ${#suites[@]} == 0 )); then
  for d in charts/*/tests/kyverno/*/; do
    [[ -f "$d/kyverno-test.yaml" ]] && suites+=("${d%/}")
  done
fi

if (( ${#suites[@]} == 0 )); then
  echo "No Kyverno test suites found."
  exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

pass=0 fail=0

for suite in "${suites[@]}"; do
  chart="${suite%/tests/kyverno/*}"
  name="$(basename "$suite")"
  dir="$work/$name"
  mkdir -p "$dir" && cp "$suite"/* "$dir"/

  if ! out="$(helm template kyverno-test "$chart" -f "$suite/chart-values.yaml" 2>&1)"; then
    echo "FAIL  $suite -- helm template failed:"
    printf '%s\n' "$out" | sed 's/^/        /' | head -5
    (( fail++ )); continue
  fi
  if ! grep -q '^apiVersion: policies.kyverno.io/' <<<"$out"; then
    echo "FAIL  $suite -- chart-values.yaml rendered no Kyverno policy"
    (( fail++ )); continue
  fi
  printf '%s\n' "$out" > "$dir/policy.yaml"

  if out="$(kyverno test "$dir" --remove-color 2>&1)"; then
    echo "ok    $suite  ($(grep -o '[0-9]* tests passed' <<<"$out"))"
    (( pass++ ))
  else
    echo "FAIL  $suite"
    printf '%s\n' "$out" | sed 's/^/        /'
    (( fail++ ))
  fi
done

echo
echo "$pass suites passed, $fail failed"
(( fail == 0 ))
