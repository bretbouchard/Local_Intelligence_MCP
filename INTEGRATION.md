# 🤖 AI Assistant Integration Guide

Complete guide for making your Apple MCP Server discoverable and usable by popular AI assistants and platforms.

## 📋 Table of Contents

- [Supported AI Assistants](#supported-ai-assistants)
- [Universal MCP Configuration](#universal-mcp-configuration)
- [Platform-Specific Integration](#platform-specific-integration)
- [Discovery and Testing](#discovery-and-testing)
- [Troubleshooting](#troubleshooting)

## 🤖 Supported AI Assistants

### ✅ Native MCP Support
- **Claude Desktop** (Anthropic) - Native MCP protocol support
- **ChatGPT** (OpenAI) - Via MCP plugins
- **Cursor** - Native MCP support
- **Continue.dev** - Native MCP support
- **Windsurf** - Native MCP support
- **Tabnine** - Native MCP support
- **Codeium** - Native MCP support
- **Aider** - Native MCP support

### 🔌 Plugin-Based Support
- **VS Code Extensions** - Via MCP extension
- **Obsidian** - Via MCP plugin
- **Logseq** - Via MCP plugin
- **Roam Research** - Via MCP plugin

## 🔧 Universal MCP Configuration

### Basic MCP Server Configuration (Port 8050)

All MCP-compatible assistants can connect using this standard configuration:

```json
{
  "mcpServers": {
    "apple-mcp": {
      "command": "/path/to/apple-mcp-server",
      "args": ["--config", "/path/to/config.json"],
      "env": {
        "MCP_SERVER_PORT": "8050"
      }
    }
  }
}
```

### Direct Connection Example

```json
{
  "mcpServers": {
    "apple-mcp": {
      "command": "/path/to/apple-mcp-server",
      "env": {
        "MCP_SERVER_PORT": "8050",
        "MCP_ENABLE_SHORTCUTS": "true",
        "MCP_ENABLE_VOICE_CONTROL": "true",
        "MCP_ENABLE_SYSTEM_INFO": "true"
      }
    }
  }
}
```

## 🚀 Platform-Specific Integration

### Claude Desktop (Anthropic)

1. **Open Claude Desktop Settings**
2. **Go to "Developer" → "Edit Config"**
3. **Add to your `claude_desktop_config.json`:**

```json
{
  "mcpServers": {
    "apple-mcp": {
      "command": "/path/to/apple-mcp-server",
      "args": ["--config", "/path/to/config.json"],
      "env": {
        "MCP_SERVER_PORT": "8050",
        "MCP_ENABLE_SHORTCUTS": "true",
        "MCP_ENABLE_VOICE_CONTROL": "true",
        "MCP_ENABLE_SYSTEM_INFO": "true"
      }
    }
  }
}
```

4. **Restart Claude Desktop**

### Cursor IDE

1. **Open Cursor Settings** (Cmd/Ctrl + ,)
2. **Go to "Extensions" → "MCP Servers"**
3. **Click "Add MCP Server"**
4. **Use this configuration:**

```json
{
  "name": "Apple MCP Server",
  "command": "/path/to/apple-mcp-server",
  "args": ["--config", "/path/to/config.json"],
  "env": {
    "MCP_SERVER_PORT": "8050"
  }
}
```

### Continue.dev

1. **Open Continue.dev Settings**
2. **Go to "MCP Servers"**
3. **Add New Server:**

```json
{
  "name": "Apple MCP Server",
  "command": "/path/to/apple-mcp-server",
  "args": ["--config", "/path/to/config.json"],
  "env": {
    "MCP_SERVER_PORT": "8050"
  }
}
```

### VS Code Extensions

#### Option 1: Using MCP Extension
1. **Install "MCP" extension from marketplace**
2. **Open VS Code Settings** (Cmd/Ctrl + ,)
3. **Go to Extensions → MCP → Servers**
4. **Add Server Configuration**

#### Option 2: Using Continue.dev Extension
1. **Install "Continue.dev" extension**
2. **Use the Continue.dev MCP configuration above**

## 🔍 Discovery and Testing

### Verify Server is Running

```bash
# Check if server is accessible
curl http://localhost:8050/health

# Test MCP endpoint
curl -X POST http://localhost:8050/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### Test with Claude Desktop

1. **Start your server:**
```bash
cd /path/to/apple-mcp-server
./AppleMCPServer --port 8050
```

2. **In Claude Desktop, ask:**
   - "What Apple Shortcuts do I have available?"
   - "Execute the shortcut named 'Send Message'"
   - "Get my system information"

3. **Expected behavior:** Claude should discover and use your MCP tools

### Test with Other Assistants

#### ChatGPT (via Plugin)
- **Install MCP plugin** from plugin marketplace
- **Configure using the universal configuration above**
- **Ask about Apple capabilities**

#### Cursor
- **Configure using Cursor's MCP server settings**
- **Test with "Show me my available Apple Shortcuts"**

## 📚 Documentation to Share with AI Assistant Users

### Quick Start Guide (Share This)

```
🍎 Apple MCP Server - Quick Start Guide

📋 WHAT IT DOES:
- Execute Apple Shortcuts through AI assistants
- Control Voice Commands for accessibility
- Get system information securely
- All with enterprise-grade security

🚀 GETTING STARTED:
1. Server runs on port 8050
2. Configure your AI assistant (see integration guide)
3. Start using Apple ecosystem capabilities!

🛠️ AVAILABLE TOOLS:
- shortcuts_execute - Run Apple Shortcuts
- shortcuts_list - Discover available shortcuts
- voice_control - Issue voice commands
- system_info - Get device information
- health_check - Monitor server health
- permission_tool - Manage permissions

🔧 CONFIGURATION:
- Default port: 8050
- Environment: MCP_SERVER_PORT=8050
- Config file: ~/.config/apple-mcp-server/config.json

🔒 SECURITY FEATURES:
- Input validation and sanitization
- Permission-based access control
- Rate limiting and attack protection
- Comprehensive audit logging
- Memory-safe Swift 6 implementation

📚 FOR DETAILED SETUP:
See: https://github.com/bretbouchard/apple_intelligence_mcp
```

### One-Paragraph Summary (Share This)

```
The Apple MCP Server exposes Apple ecosystem capabilities (Shortcuts, Voice Control, system information) to AI assistants through the Model Context Protocol. Run it on port 8050 and configure your AI assistant to start using Apple Shortcuts, voice commands, and system information securely with enterprise-grade security features including comprehensive testing and attack surface protection.
```

## 🌐 Sharing Your MCP Server

### GitHub Repository
- **URL**: https://github.com/bretbouchard/apple_intelligence_mcp
- **Star**: ⭐ to show support
- **Fork**: 🍴 to customize for your needs

### Community Resources
- **Issues**: Report bugs or request features
- **Discussions**: Ask questions and share experiences
- **Documentation**: Complete API and security guides

### Social Media Posts

#### Twitter/X (280 chars)
```
🍎 Just launched: Apple MCP Server! 🚀

Exposes Apple Shortcuts, Voice Control, and system info to AI assistants through MCP protocol.

Features:
- ✅ 400+ security tests
- ✅ OWASP Top 10 coverage
- ✅ Swift 6 memory safety
- ✅ Configurable port (8050)

🔗 https://github.com/bretbouchard/apple_intelligence_mcp

#AppleMCP #Swift #AI #Shortcuts #VoiceControl
```

#### LinkedIn Post
```
Excited to share the Apple MCP Server - a Swift-based bridge between AI assistants and Apple ecosystem capabilities!

🔧 Key Features:
- Execute Apple Shortcuts via AI
- Voice Control with accessibility support
- System information access
- Enterprise-grade security (400+ tests)
- OWASP Top 10 coverage
- Swift 6 concurrency model

🤖 Compatible with Claude Desktop, Cursor, Continue.dev, and other MCP-compatible AI assistants.

🔗 Repository: https://github.com/bretbouchard/apple_intelligence_mcp
📚 Documentation: Complete API and security guides included

#AppleIntelligence #MCP #Swift #AI #macOS #Shortcuts #VoiceControl
```

#### Discord/Slack Message
```
🎉 Apple MCP Server is live!

🍎 What it does: Connects AI assistants to Apple ecosystem
🚀 How: Through Model Context Protocol (MCP)
🔧 Default port: 8050 (fully configurable)

🛠️ Try it:
curl http://localhost:8050/health

🔗 GitHub: https://github.com/bretbouchard/apple_intelligence_mcp

Compatible with Claude Desktop, Cursor, Continue.dev, and more!
```

## 🔧 Advanced Configuration Examples

### Production Deployment
```json
{
  "mcpServers": {
    "apple-mcp": {
      "command": "/usr/local/bin/apple-mcp-server",
      "args": [
        "--config", "/etc/apple-mcp-server/production.json"
      ],
      "env": {
        "MCP_SERVER_PORT": "8050",
        "MCP_SERVER_HOST": "0.0.0.0",
        "MCP_REQUIRE_AUTH": "false",
        "MCP_LOG_LEVEL": "info"
      }
    }
  }
}
```

### Development Setup
```json
{
  "mcpServers": {
    "apple-mcp": {
      "command": "swift run AppleMCPServer",
      "cwd": "/path/to/apple-mcp-server",
      "env": {
        "MCP_SERVER_PORT": "8050",
        "MCP_LOG_LEVEL": "debug"
      }
    }
  }
}
```

## 🐛 Troubleshooting

### Common Issues

#### Server Not Found
```
❌ Error: "Connection refused"
✅ Solution: Ensure server is running: ./AppleMCPServer --port 8050
✅ Verify port: lsof -i :8050
```

#### Tool Not Available
```
❌ Error: "Tool not found"
✅ Solution: Check server health: curl http://localhost:8050/health
✅ Verify features enabled in configuration
```

#### Permission Denied
```
❌ Error: "Access denied"
✅ Solution: Check macOS permissions for Shortcuts/Voice Control
✅ Grant permissions in System Preferences
```

### Debug Mode

Enable debug logging:
```bash
export MCP_LOG_LEVEL=debug
./AppleMCPServer --port 8050
```

### Health Check
```bash
# Comprehensive health check
curl -X POST http://localhost:8050/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"health_check","arguments":{"verbose":true}},"id":1}'
```

## 📞 Getting Help

- **Issues**: https://github.com/bretbouchard/apple_intelligence_mcp/issues
- **Discussions**: https://github.com/bretbouchard/apple_intelligence_mcp/discussions
- **Documentation**: https://github.com/bretbouchard/apple_intelligence_mcp

---

**🚀 Your Apple MCP Server is now ready for AI assistant integration!**

The server runs on **port 8050** by default and is fully configurable. Share this guide with your community to help others discover and use your MCP server!