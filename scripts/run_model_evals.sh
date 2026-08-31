#!/usr/bin/env bash
# GSD Plan 4.6 — live-model evaluation run (manual; not part of swift test).
# Exercises generation-backed capabilities on this Mac and prints pass/fail
# per eval against versioned thresholds. Deterministic evals run in unit tests.
set -uo pipefail
cd "$(dirname "$0")/.."
BIN=".build/debug/LocalIntelligenceMCP"
[ -x "$BIN" ] || swift build -c debug

fail=0

check() { # name, condition
  if [ "$2" = "1" ]; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi
}

r=$(./examples/mcp_call.sh local_generate '{"prompt":"Reply with exactly: OK"}')
check "generation-responds"      [[ "$r" == OK* ]]

r=$(./examples/mcp_call.sh local_generate '{"prompt":"Return JSON {\"status\": string} for a healthy system.","responseSchema":{"type":"object","properties":{"status":{"type":"string"}},"required":["status"]}}')
check "structured-validates"     [[ "$r" == *"validation"*passed* ]]

r=$(./examples/mcp_call.sh local_generate '{"prompt":"Triage: app crashes on launch","tools":["local_classify"]}')
check "model-tool-classify"      [[ "$r" == OK* ]]

r=$(./examples/mcp_call.sh voice_command '{"command":"open Safari"}')
check "voicecontrol-unsupported" [[ "$r" == *"UNSUPPORTED"* ]]

exit $fail
