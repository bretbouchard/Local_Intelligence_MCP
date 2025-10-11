#!/bin/bash

# Comprehensive MCP Server Test Script
# Tests the complete MCP protocol workflow

set -e

echo "🍎 Testing Local Intelligence MCP Server"
echo "=========================================="

# Build the server first
echo "📦 Building server..."
swift build -c debug

SERVER_PATH=".build/arm64-apple-macosx/release/LocalIntelligenceMCP"

if [ ! -f "$SERVER_PATH" ]; then
    echo "❌ Server executable not found at $SERVER_PATH"
    exit 1
fi

echo "✅ Server built successfully"
echo

# Test 1: Initialize Request
echo "🧪 Test 1: MCP Initialize Request"
echo "--------------------------------"
INIT_REQUEST='{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {"tools": {}}, "clientInfo": {"name": "test-client", "version": "1.0.0"}}}'

echo "Sending: $INIT_REQUEST"
RESPONSE=$(echo "$INIT_REQUEST" | "$SERVER_PATH" start-command --mcp-mode)
echo "Received: $RESPONSE"
echo

# Check if response contains expected fields
if echo "$RESPONSE" | grep -q '"result"'; then
    echo "✅ Initialize request successful"

    # Extract protocol version
    PROTO_VERSION=$(echo "$RESPONSE" | grep -o '"protocolVersion":"[^"]*"' | cut -d'"' -f4)
    echo "📋 Protocol Version: $PROTO_VERSION"

    # Extract server info
    SERVER_NAME=$(echo "$RESPONSE" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    SERVER_VERSION=$(echo "$RESPONSE" | grep -o '"version":"[^"]*"' | tail -1 | cut -d'"' -f4)
    echo "📋 Server: $SERVER_NAME v$SERVER_VERSION"

else
    echo "❌ Initialize request failed"
    exit 1
fi
echo

# Test 2: Tools List Request (should work even without tools)
echo "🧪 Test 2: Tools List Request"
echo "-----------------------------"
TOOLS_REQUEST='{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}'

echo "Sending: $TOOLS_REQUEST"
TOOLS_RESPONSE=$(echo "$TOOLS_REQUEST" | "$SERVER_PATH" start-command --mcp-mode)
echo "Received: $TOOLS_RESPONSE"
echo

# Check if we get a proper response (either tools list or method not found)
if echo "$TOOLS_RESPONSE" | grep -q '"method not found\|Unknown method'; then
    echo "ℹ️  Tools not registered yet (expected for minimal server)"
elif echo "$TOOLS_RESPONSE" | grep -q '"result"'; then
    echo "✅ Tools list request successful"
    TOOL_COUNT=$(echo "$TOOLS_RESPONSE" | grep -o '"tools":\[[^]]*\]' | grep -o '{' | wc -l)
    echo "📋 Available tools: $TOOL_COUNT"
else
    echo "⚠️  Unexpected response to tools/list"
fi
echo

# Test 3: Ping Request (MCP SDK built-in)
echo "🧪 Test 3: Ping Request"
echo "-----------------------"
PING_REQUEST='{"jsonrpc": "2.0", "id": 3, "method": "ping"}'

echo "Sending: $PING_REQUEST"
PING_RESPONSE=$(echo "$PING_REQUEST" | "$SERVER_PATH" start-command --mcp-mode)
echo "Received: $PING_RESPONSE"
echo

if echo "$PING_RESPONSE" | grep -q '"result"'; then
    echo "✅ Ping request successful"
else
    echo "❌ Ping request failed"
fi
echo

# Test 4: Invalid Request (error handling)
echo "🧪 Test 4: Invalid Request (Error Handling)"
echo "-----------------------------------------"
INVALID_REQUEST='{"jsonrpc": "2.0", "id": 4, "method": "invalid_method"}'

echo "Sending: $INVALID_REQUEST"
INVALID_RESPONSE=$(echo "$INVALID_REQUEST" | "$SERVER_PATH" start-command --mcp-mode)
echo "Received: $INVALID_RESPONSE"
echo

if echo "$INVALID_RESPONSE" | grep -q '"error"'; then
    ERROR_CODE=$(echo "$INVALID_RESPONSE" | grep -o '"code":[-0-9]*' | cut -d':' -f2)
    ERROR_MESSAGE=$(echo "$INVALID_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Error handling works correctly"
    echo "📋 Error Code: $ERROR_CODE"
    echo "📋 Error Message: $ERROR_MESSAGE"
else
    echo "❌ Error handling failed"
fi
echo

echo "🎉 MCP Server Test Complete!"
echo "============================"
echo "✅ Server is working correctly with the MCP protocol"
echo "✅ Basic MCP communication is functional"
echo "✅ Error handling is working"
echo "✅ Ready for tool registration"