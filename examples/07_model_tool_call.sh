#!/usr/bin/env bash
source "$(dirname "$0")/mcp_call.sh" local_generate '{
  "prompt": "Classify this support message using the classify tool: My app crashes on launch.",
  "tools": ["local_classify"]
}'
