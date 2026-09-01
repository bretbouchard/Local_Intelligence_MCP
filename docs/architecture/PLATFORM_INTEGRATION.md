# 🔌 Platform Integration Guide

This guide provides comprehensive instructions for integrating Local Intelligence MCP with various AI platforms and development environments.

## 📋 Overview

Local Intelligence MCP supports integration with:

- **AI Assistants**: Claude Desktop, ChatGPT, Google AI Studio
- **IDEs**: VS Code, Cursor, Windsurf, Zed
- **Development Platforms**: GitHub Copilot, JetBrains IDEs
- **Custom Applications**: Direct MCP protocol integration

## 🤖 AI Assistant Integration

### Claude Desktop

#### Configuration Location
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/claude/claude_desktop_config.json`

#### Direct Installation
```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "swift",
      "args": [
        "run",
        "--package-path",
        "/path/to/Local_Intelligence_MCP",
        "LocalIntelligenceMCP"
      ],
      "env": {
        "MCP_LOG_LEVEL": "info"
      }
    }
  }
}
```

#### Extension Configuration

1. **Install MCP Extension** (if available) or configure manually
2. **Update settings.json**:

```json
{
  "mcp.servers": {
    "local-intelligence-mcp": {
      "command": "swift",
      "args": ["run", "LocalIntelligenceMCP"],
      "cwd": "/path/to/Local_Intelligence_MCP",
      "env": {
        "MCP_LOG_LEVEL": "info",
        "MCP_SERVER_PORT": "3000"
      }
    }
  }
}
```

#### Workspace Configuration

Create `.vscode/settings.json`:

```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "./start-mcp-server.sh",
      "env": {
        "MCP_ENABLE_TEXT_PROCESSING": "true",
        "MCP_ENABLE_PII_REDACTION": "true"
      }
    }
  }
}
```

#### Usage Examples

```typescript
// Example of using MCP tools in VS Code
import { MCPClient } from 'mcp-client';

const client = new MCPClient('ws://localhost:3000');

// Normalize text
const normalizedText = await client.callTool('text_normalize', {
  text: 'Your messy text here',
  removeFillers: true
});

// Generate summary
const summary = await client.callTool('summarization', {
  text: normalizedText.result,
  style: 'technical',
  maxLength: 200
});
```

### Cursor IDE

#### Configuration

Add to Cursor's MCP settings:

```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "LocalIntelligenceMCP",
      "args": ["--host", "localhost", "--port", "3000"],
      "cwd": "/path/to/Local_Intelligence_MCP"
    }
  }
}
```

#### Usage in Cursor Rules

Add to your `.cursorrules`:

```markdown
# Local Intelligence MCP Integration
Use Local Intelligence MCP tools for:
- Text normalization: text_normalize
- PII redaction: pii_redaction  
- Content analysis: content_purpose_detector
- Summarization: summarization, focused_summarization

Always process user content through appropriate MCP tools before analysis.
```

### Windsurf

Configuration for Windsurf IDE:

```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "swift",
      "args": ["run", "LocalIntelligenceMCP"],
      "workingDirectory": "/path/to/Local_Intelligence_MCP",
      "environment": {
        "MCP_LOG_LEVEL": "debug"
      }
    }
  }
}
```

### Zed Editor

Add to Zed's configuration:

```json
{
  "assistant": {
    "mcpServers": {
      "local-intelligence-mcp": {
        "command": "swift",
        "args": ["run", "LocalIntelligenceMCP"],
        "env": {
          "MCP_SERVER_PORT": "3000"
        }
      }
    }
  }
}
```

