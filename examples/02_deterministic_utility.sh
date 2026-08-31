#!/usr/bin/env bash
source "$(dirname "$0")/mcp_call.sh" local_summarize '{"text":"The session started late. We tracked vocals for two hours. The compressor settings were dialed in. A rough mix was printed.","sentenceLimit":2}'
source "$(dirname "$0")/mcp_call.sh" local_extract '{"text":"Contact studio@example.com by 2026-09-01 or visit https://studio.example."}'
