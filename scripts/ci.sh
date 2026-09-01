#!/usr/bin/env bash
# =============================================================================
# Local CI/CD pipeline — runs entirely on this Mac (no GitHub Actions cost).
#
# Usage:
#   ./scripts/ci.sh              # full pipeline: build → consumer → tests → coverage
#   ./scripts/ci.sh --fast       # skip coverage instrumentation (faster)
#   ./scripts/ci.sh --evals      # full pipeline + live model evaluations
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

FAST=0
RUN_EVALS=0
for arg in "$@"; do
  case $arg in
    --fast)  FAST=1 ;;
    --evals) RUN_EVALS=1 ;;
  esac
done

step() { printf "\n\033[1;36m▶ %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m  ✓ %s\033[0m\n" "$1"; }
fail() { printf "\033[1;31m  ✗ %s\033[0m\n" "$1"; exit 1; }

step "1/5 — swift build (server)"
swift build > /tmp/ci-build.log 2>&1 || { cat /tmp/ci-build.log | grep -E "error:" | head -10; fail "server build"; }
ok "server built"

step "2/5 — swift build (reference consumer)"
swift build --product LocalIntelligenceConsumer > /tmp/ci-consumer.log 2>&1 || { cat /tmp/ci-consumer.log | grep -E "error:" | head -10; fail "consumer build"; }
ok "consumer built"

step "3/5 — swift test"
run_tests() {
  if [ "$FAST" = "1" ]; then
    swift test > /tmp/ci-test.log 2>&1
  else
    swift test --enable-code-coverage > /tmp/ci-test.log 2>&1
  fi
}
# One retry to distinguish transient flakes (FM model warm-up, parallel E2E
# resource contention) from persistent failures. A test failing twice is real.
attempt=1
run_tests
until grep -qE "with 0 failures" /tmp/ci-test.log || [ $attempt -ge 2 ]; do
  echo "  ↻ test run $attempt had failures — retrying once…"
  attempt=$((attempt + 1))
  run_tests
done
TESTS=$(grep -oE "Executed [0-9]+ tests, with [0-9]+ failures" /tmp/ci-test.log | tail -1)
ok "$TESTS"
if ! echo "$TESTS" | grep -q "with 0 failures"; then
  grep -E "failed:" /tmp/ci-test.log | head -10
  fail "test failures persisted across retry"
fi

step "4/5 — coverage report"
if [ "$FAST" = "1" ]; then
  ok "skipped (--fast)"
else
  PROFDATA=".build/debug/codecov/default.profdata"
  TESTBIN="$(swift build --show-bin-path)/LocalIntelligenceMCPTests.xctest/Contents/MacOS/LocalIntelligenceMCPTests"
  xcrun llvm-cov report --instr-profile "$PROFDATA" "$TESTBIN" Sources/LocalIntelligenceMCP > coverage.txt 2>/dev/null \
    || fail "coverage report generation"
  LINE=$(grep "TOTAL" coverage.txt | awk '{print $10}')
  ok "line coverage: $LINE (full report: coverage.txt)"
fi

if [ "$RUN_EVALS" = "1" ]; then
  step "5/5 — live model evaluations"
  ./scripts/run_model_evals.sh || fail "model evals"
  ok "model evals passed"
else
  printf "\n(model evals skipped — run ./scripts/ci.sh --evals)\n"
fi

printf "\n\033[1;32m✔ LOCAL CI PASSED\033[0m\n"
