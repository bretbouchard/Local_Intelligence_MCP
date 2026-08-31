#!/usr/bin/env bash
source "$(dirname "$0")/mcp_call.sh" local_generate '{
  "prompt": "Return a JSON object describing the resistor: {\"component\": string, \"ohms\": integer}. Component: 10k resistor.",
  "responseSchema": {
    "type": "object",
    "properties": {"component": {"type": "string"}, "ohms": {"type": "integer"}},
    "required": ["component", "ohms"]
  }
}'
