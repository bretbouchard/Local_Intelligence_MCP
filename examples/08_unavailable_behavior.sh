#!/usr/bin/env bash
echo "— Voice Control (unsupported by design, never simulated):"
source "$(dirname "$0")/mcp_call.sh" voice_command '{"command":"open Safari"}'
echo "— unknown shortcut (honest failure, didRun=false):"
source "$(dirname "$0")/mcp_call.sh" local_automation_execute '{"name":"This Shortcut Does Not Exist"}'
