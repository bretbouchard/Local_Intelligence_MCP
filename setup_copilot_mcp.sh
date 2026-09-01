#!/bin/bash

echo "🔧 Setting up Local Intelligence MCP for Claude/Copilot"
echo "======================================================"

# Detect OS and set config path
OS=$(uname -s)
case $OS in
    "Darwin")
        CONFIG_DIR="$HOME/Library/Application Support/Claude"
        ;;
    "Linux")
        CONFIG_DIR="$HOME/.config/claude"
        ;;
    "CYGWIN"*|"MINGW"*|"MSYS"*)
        CONFIG_DIR="$APPDATA/Claude"
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

CONFIG_FILE="$CONFIG_DIR/mcp_servers.json"

echo "📁 MCP Config Directory: $CONFIG_DIR"
echo "📄 MCP Config File: $CONFIG_FILE"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ MCP config file exists"
    # Backup existing config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📋 Backup created: $CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
else
    echo "📄 Creating new MCP config file"
    echo '{"mcpServers": {}}' > "$CONFIG_FILE"
fi

# Build if needed and resolve the executable path
if [ ! -x ".build/debug/LocalIntelligenceMCP" ] && [ ! -x "$(pwd)/.build/release/LocalIntelligenceMCP" ]; then
    echo "🔨 Building server (swift build)..."
    swift build || { echo "❌ Build failed"; exit 1; }
fi
LOCAL_EXECUTABLE="$(swift build --show-bin-path 2>/dev/null)/LocalIntelligenceMCP"
if [ ! -f "$LOCAL_EXECUTABLE" ]; then
    echo "❌ Server executable not found at $LOCAL_EXECUTABLE — run 'swift build' first"
    exit 1
fi
echo "✅ Local executable found: $LOCAL_EXECUTABLE"

SERVER_CONFIG=$(cat <<INNER
    "local-intelligence-mcp": {
      "command": "$LOCAL_EXECUTABLE",
      "args": ["start-command", "--mcp-mode"],
      "description": "Local Intelligence MCP - truthful Apple-local capabilities over stdio"
    }
INNER
)

echo ""
echo "🔧 Adding MCP server configuration..."

# Use Python to properly merge JSON
python3 << EOF
import json
import sys

config_file = "$CONFIG_FILE"
server_config = $SERVER_CONFIG

try:
    with open(config_file, 'r') as f:
        config = json.load(f)

    if 'mcpServers' not in config:
        config['mcpServers'] = {}

    # Parse the server config
    import re
    server_json = re.search(r'\{.*\}', server_config, re.DOTALL).group(0)
    server_data = json.loads(server_json)

    # Add or update the server
    config['mcpServers'].update(server_data)

    # Write back to file
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)

    print("✅ MCP server configuration added successfully")

except Exception as e:
    print(f"❌ Error updating config: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Setup Complete!"
    echo "=================="
    echo ""
    echo "📋 Configuration added to: $CONFIG_FILE"
    echo ""
    echo "🔄 Next Steps:"
    echo "1. Restart Claude Desktop"
    echo "2. Check MCP servers list in Claude settings"
    echo "3. Look for 'Local Intelligence MCP' in the list"
    echo ""
    echo "🧪 Test with these prompts:"
    echo "- 'What system information can you access?'"
    echo "- 'List available Apple shortcuts'"
    echo "- 'Check voice control status'"
    echo ""
    echo "✅ Using local build (faster startup)"
else
    echo "❌ Setup failed. Please check the configuration manually."
fi