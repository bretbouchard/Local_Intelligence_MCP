#!/usr/bin/env bash
# GSD Plan 4.6 — live-model evaluation run (manual; not part of swift test).
# Exercises generation-backed capabilities on this Mac and prints pass/fail
# per eval. Deterministic evals run in unit tests.
set -uo pipefail
cd "$(dirname "$0")/.."

swift build -c debug >/dev/null 2>&1 || swift build >/dev/null 2>&1
BIN="$(swift build --show-bin-path 2>/dev/null)/LocalIntelligenceMCP"
[ -x "$BIN" ] || { echo "server binary not found"; exit 1; }

fail=0
check() {
  local name="$1" condition="$2"
  if eval "$condition"; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    fail=1
  fi
}

r=$(./examples/mcp_call.sh local_generate '{"prompt":"Reply with exactly: OK"}' "$BIN")
check "generation-responds"      '[[ "$r" == OK* ]]'

r=$(./examples/mcp_call.sh local_generate '{"prompt":"Return JSON {\"status\": string} for a healthy system.","responseSchema":{"type":"object","properties":{"status":{"type":"string"}},"required":["status"]}}' "$BIN")
check "structured-validates"     '[[ "$r" == *validation*passed* ]]'

r=$(./examples/mcp_call.sh local_generate '{"prompt":"Triage: app crashes on launch","tools":["local_classify"]}' "$BIN")
check "model-tool-classify"      '[[ "$r" == OK* ]]'

r=$(./examples/mcp_call.sh voice_command '{"command":"open Safari"}' "$BIN")
check "voicecontrol-unsupported" '[[ "$r" == *UNSUPPORTED* ]]'

exit $fail
