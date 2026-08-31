#!/usr/bin/env bash
echo "— destructive-looking name without confirm (expect POLICY_DENIED):"
source "$(dirname "$0")/mcp_call.sh" local_automation_execute '{"name":"Delete Old Downloads","input":"note"}'
echo "— same, with explicit confirm (executes or fails honestly):"
source "$(dirname "$0")/mcp_call.sh" local_automation_execute '{"name":"Delete Old Downloads","input":"note","confirm":true}'
