#!/usr/bin/env bash
# Minimal JSON-RPC-over-stdio driver for Local Intelligence MCP examples.
# Usage: mcp_call.sh '<tool-name>' '<arguments-json>' [binary-path]
# Waits for the actual response (bounded by timeout) instead of fixed sleeps.
set -euo pipefail
BIN="${3:-$(dirname "$0")/../.build/out/Products/Debug/LocalIntelligenceMCP}"
TOOL="$1"
ARGS="$(printf '%s' "$2" | tr '\n' ' ' | tr -s ' ')"

{
  printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"example","version":"1.0"}}}'
  printf '%s\n' '{"jsonrpc":"2.0","method":"notifications/initialized"}'
  printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"$TOOL\",\"arguments\":$ARGS}}"
  sleep 90
} | timeout 100 "$BIN" start-command --mcp-mode 2>/dev/null | python3 -u -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try: msg = json.loads(line)
    except: continue
    if msg.get('id') == 2:
        r = msg.get('result', {})
        print(('OK ' if not r.get('isError') else 'ERR'), r.get('content', [{}])[0].get('text', '')[:2000])
        sys.exit(0)
"
