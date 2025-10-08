# Apple MCP Server API Documentation

## 📚 API Overview

The Apple MCP Server implements the Model Context Protocol (MCP) specification to expose Apple ecosystem capabilities to AI agents. This document provides comprehensive API documentation, examples, and integration guidance.

## 🔧 MCP Protocol Implementation

### Protocol Version
- **Version**: `2024-11-05`
- **Transport**: JSON-RPC 2.0 over HTTP/WebSocket
- **Encoding**: UTF-8 JSON
- **Compression**: Optional gzip support

### Connection Flow

#### 1. Initialize Connection
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {
        "listChanged": true
      },
      "roots": {
        "listChanged": false
      }
    },
    "clientInfo": {
      "name": "AI Assistant",
      "version": "1.0.0"
    }
  },
  "id": "init-1"
}
```

#### 2. Server Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {
        "listChanged": true
      },
      "logging": {
        "level": "info"
      }
    },
    "serverInfo": {
      "name": "Apple MCP Server",
      "version": "1.0.0"
    }
  },
  "id": "init-1"
}
```

#### 3. Initialize Notification
```json
{
  "jsonrpc": "2.0",
  "method": "notifications/initialized"
}
```

## 🛠️ Available Tools

### Tool Discovery

#### List Tools Request
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": "tools-1"
}
```

#### List Tools Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "shortcuts_execute",
        "description": "Execute Apple Shortcuts with configurable parameters and timeout handling",
        "inputSchema": {
          "type": "object",
          "properties": {
            "shortcutName": {
              "type": "string",
              "description": "Name of the shortcut to execute"
            },
            "input": {
              "type": "object",
              "description": "Input parameters for the shortcut",
              "additionalProperties": true
            },
            "timeout": {
              "type": "number",
              "description": "Execution timeout in seconds",
              "default": 30,
              "minimum": 1,
              "maximum": 300
            }
          },
          "required": ["shortcutName"]
        }
      },
      {
        "name": "shortcuts_list",
        "description": "List available Apple Shortcuts with filtering and categorization options",
        "inputSchema": {
          "type": "object",
          "properties": {
            "includeSystemShortcuts": {
              "type": "boolean",
              "description": "Include system-defined shortcuts",
              "default": false
            },
            "categories": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "description": "Filter shortcuts by categories"
            },
            "searchQuery": {
              "type": "string",
              "description": "Search shortcuts by name or description"
            },
            "limit": {
              "type": "number",
              "description": "Maximum number of shortcuts to return",
              "default": 50,
              "minimum": 1,
              "maximum": 200
            }
          }
        }
      },
      {
        "name": "voice_control",
        "description": "Issue Voice Control commands with accessibility support and timeout handling",
        "inputSchema": {
          "type": "object",
          "properties": {
            "command": {
              "type": "string",
              "description": "Voice control command to execute"
            },
            "timeout": {
              "type": "number",
              "description": "Command execution timeout in seconds",
              "default": 30,
              "minimum": 1,
              "maximum": 120
            },
            "accessibility": {
              "type": "boolean",
              "description": "Enable accessibility features",
              "default": true
            },
            "language": {
              "type": "string",
              "description": "Language code for voice recognition",
              "default": "en-US",
              "pattern": "^[a-z]{2}-[A-Z]{2}$"
            }
          },
          "required": ["command"]
        }
      },
      {
        "name": "system_info",
        "description": "Get comprehensive system information with configurable detail levels and security controls",
        "inputSchema": {
          "type": "object",
          "properties": {
            "categories": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": ["device", "performance", "network", "storage", "battery", "accessibility"]
              },
              "description": "System information categories to retrieve",
              "default": ["device"]
            },
            "includeSensitive": {
              "type": "boolean",
              "description": "Include potentially sensitive information",
              "default": false
            },
            "format": {
              "type": "string",
              "enum": ["json", "compact", "detailed"],
              "description": "Output format preference",
              "default": "json"
            }
          }
        }
      },
      {
        "name": "health_check",
        "description": "Perform comprehensive server health monitoring and status reporting",
        "inputSchema": {
          "type": "object",
          "properties": {
            "checks": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": ["memory", "disk", "network", "tools", "security"]
              },
              "description": "Specific health checks to perform",
              "default": ["memory", "tools"]
            },
            "verbose": {
              "type": "boolean",
              "description": "Include detailed diagnostic information",
              "default": false
            }
          }
        }
      },
      {
        "name": "permission_tool",
        "description": "Check and manage permission status for various tools and operations",
        "inputSchema": {
          "type": "object",
          "properties": {
            "action": {
              "type": "string",
              "enum": ["check", "request", "status"],
              "description": "Permission action to perform",
              "default": "check"
            },
            "permission": {
              "type": "string",
              "enum": ["shortcuts", "voiceControl", "systemInfo", "all"],
              "description": "Specific permission to check"
            },
            "details": {
              "type": "boolean",
              "description": "Include detailed permission information",
              "default": false
            }
          },
          "required": ["action", "permission"]
        }
      }
    ]
  },
  "id": "tools-1"
}
```

## 🔧 Tool Execution

### Execute Tool Request
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "shortcuts_execute",
    "arguments": {
      "shortcutName": "Send Email",
      "input": {
        "to": "user@example.com",
        "subject": "Meeting Reminder",
        "body": "Don't forget our meeting at 2 PM today."
      },
      "timeout": 60
    }
  },
  "id": "execute-1"
}
```

### Tool Execution Response

#### Success Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Shortcut 'Send Email' executed successfully"
      },
      {
        "type": "json",
        "json": {
          "shortcutName": "Send Email",
          "executionTime": 2.34,
          "status": "completed",
          "output": {
            "messageId": "msg-12345",
            "status": "sent"
          }
        }
      }
    ],
    "isError": false
  },
  "id": "execute-1"
}
```

#### Error Response
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "details": "shortcutName is required",
      "validationErrors": [
        {
          "field": "shortcutName",
          "message": "This field is required"
        }
      ]
    }
  },
  "id": "execute-1"
}
```

## 📖 Detailed Tool Examples

### 1. Shortcuts Execute

#### Basic Execution
```json
{
  "method": "tools/call",
  "params": {
    "name": "shortcuts_execute",
    "arguments": {
      "shortcutName": "Play Music"
    }
  }
}
```

#### Advanced Execution with Parameters
```json
{
  "method": "tools/call",
  "params": {
    "name": "shortcuts_execute",
    "arguments": {
      "shortcutName": "Create Calendar Event",
      "input": {
        "title": "Team Meeting",
        "startDate": "2024-12-15T14:00:00Z",
        "duration": 60,
        "attendees": ["alice@example.com", "bob@example.com"],
        "location": "Conference Room A",
        "notes": "Discuss Q4 roadmap"
      },
      "timeout": 120
    }
  }
}
```

### 2. Shortcuts List

#### List All Shortcuts
```json
{
  "method": "tools/call",
  "params": {
    "name": "shortcuts_list",
    "arguments": {
      "includeSystemShortcuts": true,
      "limit": 100
    }
  }
}
```

#### Search Shortcuts
```json
{
  "method": "tools/call",
  "params": {
    "name": "shortcuts_list",
    "arguments": {
      "searchQuery": "email",
      "categories": ["productivity", "communication"],
      "limit": 20
    }
  }
}
```

### 3. Voice Control

#### Simple Command
```json
{
  "method": "tools/call",
  "params": {
    "name": "voice_control",
    "arguments": {
      "command": "Open Safari"
    }
  }
}
```

#### Complex Command with Options
```json
{
  "method": "tools/call",
  "params": {
    "name": "voice_control",
    "arguments": {
      "command": "Open Safari and navigate to apple.com",
      "timeout": 45,
      "accessibility": true,
      "language": "en-US"
    }
  }
}
```

### 4. System Information

#### Basic Device Info
```json
{
  "method": "tools/call",
  "params": {
    "name": "system_info",
    "arguments": {
      "categories": ["device"]
    }
  }
}
```

#### Comprehensive System Info
```json
{
  "method": "tools/call",
  "params": {
    "name": "system_info",
    "arguments": {
      "categories": ["device", "performance", "network", "storage"],
      "includeSensitive": false,
      "format": "detailed"
    }
  }
}
```

### 5. Health Check

#### Basic Health Check
```json
{
  "method": "tools/call",
  "params": {
    "name": "health_check",
    "arguments": {
      "checks": ["memory", "tools"],
      "verbose": false
    }
  }
}
```

#### Comprehensive Health Check
```json
{
  "method": "tools/call",
  "params": {
    "name": "health_check",
    "arguments": {
      "checks": ["memory", "disk", "network", "tools", "security"],
      "verbose": true
    }
  }
}
```

### 6. Permission Management

#### Check Permission Status
```json
{
  "method": "tools/call",
  "params": {
    "name": "permission_tool",
    "arguments": {
      "action": "check",
      "permission": "shortcuts",
      "details": true
    }
  }
}
```

#### Request Permission
```json
{
  "method": "tools/call",
  "params": {
    "name": "permission_tool",
    "arguments": {
      "action": "request",
      "permission": "voiceControl"
    }
  }
}
```

## 🔒 Error Handling

### Error Codes

| Code | Description | Example |
|------|-------------|---------|
| `-32700` | Parse error | Invalid JSON |
| `-32600` | Invalid Request | Missing method |
| `-32601` | Method not found | Unknown tool |
| `-32602` | Invalid params | Required field missing |
| `-32603` | Internal error | Server error |
| `-32000` | Server error | Custom error |

### Error Response Format
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "tool": "shortcuts_execute",
      "field": "shortcutName",
      "validationErrors": [
        {
          "field": "shortcutName",
          "message": "This field is required and must be a non-empty string"
        }
      ],
      "suggestion": "Provide a valid shortcut name"
    }
  },
  "id": "request-id"
}
```

## 🚀 Integration Examples

### Claude Desktop Integration
```json
{
  "mcpServers": {
    "apple-mcp": {
      "command": "/path/to/apple-mcp-server",
      "args": [
        "--config", "/path/to/config.json",
        "--log-level", "info"
      ],
      "env": {
        "APPLE_MCP_LOG_FILE": "/path/to/logs/server.log"
      }
    }
  }
}
```

### Python Client Integration
```python
import asyncio
import json
from websockets.client import connect

async def apple_mcp_client():
    uri = "ws://localhost:8080/mcp"
    async with connect(uri) as websocket:
        # Initialize connection
        init_msg = {
            "jsonrpc": "2.0",
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {"listChanged": True}},
                "clientInfo": {"name": "Python Client", "version": "1.0.0"}
            },
            "id": "init-1"
        }

        await websocket.send(json.dumps(init_msg))
        response = await websocket.recv()
        print(f"Server response: {response}")

        # List tools
        tools_msg = {
            "jsonrpc": "2.0",
            "method": "tools/list",
            "id": "tools-1"
        }

        await websocket.send(json.dumps(tools_msg))
        tools_response = await websocket.recv()
        print(f"Available tools: {tools_response}")

# Run the client
asyncio.run(apple_mcp_client())
```

### Node.js Client Integration
```javascript
const WebSocket = require('ws');

class AppleMCPClient {
    constructor(url = 'ws://localhost:8080/mcp') {
        this.url = url;
        this.ws = null;
        this.requestId = 0;
    }

    async connect() {
        return new Promise((resolve, reject) => {
            this.ws = new WebSocket(this.url);

            this.ws.on('open', () => {
                this.initialize();
                resolve();
            });

            this.ws.on('error', reject);
        });
    }

    initialize() {
        const initMsg = {
            jsonrpc: "2.0",
            method: "initialize",
            params: {
                protocolVersion: "2024-11-05",
                capabilities: { tools: { listChanged: true } },
                clientInfo: { name: "Node.js Client", version: "1.0.0" }
            },
            id: `init-${++this.requestId}`
        };

        this.ws.send(JSON.stringify(initMsg));
    }

    async callTool(toolName, arguments = {}) {
        return new Promise((resolve, reject) => {
            const msg = {
                jsonrpc: "2.0",
                method: "tools/call",
                params: {
                    name: toolName,
                    arguments: arguments
                },
                id: `call-${++this.requestId}`
            };

            const handleMessage = (data) => {
                const response = JSON.parse(data);
                if (response.id === msg.id) {
                    this.ws.removeListener('message', handleMessage);

                    if (response.error) {
                        reject(new Error(response.error.message));
                    } else {
                        resolve(response.result);
                    }
                }
            };

            this.ws.on('message', handleMessage);
            this.ws.send(JSON.stringify(msg));
        });
    }

    async executeShortcut(shortcutName, input = {}) {
        return this.callTool('shortcuts_execute', {
            shortcutName,
            input,
            timeout: 60
        });
    }

    async getSystemInfo(categories = ['device']) {
        return this.callTool('system_info', {
            categories,
            includeSensitive: false
        });
    }
}

// Usage example
async function main() {
    const client = new AppleMCPClient();
    await client.connect();

    // Execute a shortcut
    const result = await client.executeShortcut('Play Music');
    console.log('Shortcut result:', result);

    // Get system information
    const systemInfo = await client.getSystemInfo(['device', 'performance']);
    console.log('System info:', systemInfo);
}

main().catch(console.error);
```

## 📊 Performance & Limits

### Request Limits
- **Maximum Concurrent Requests**: 100
- **Request Timeout**: 300 seconds (configurable)
- **Maximum Payload Size**: 10MB
- **Rate Limiting**: 60 requests per minute per client

### Tool-Specific Limits
- **Shortcut Execution**: 5 minutes timeout
- **Voice Control**: 2 minutes timeout
- **System Info**: 30 seconds timeout
- **File Operations**: 100MB file size limit

### Performance Characteristics
- **Average Response Time**: <100ms
- **Memory Usage**: <50MB idle, <200MB under load
- **CPU Usage**: <5% idle, <25% under load
- **Concurrent Users**: 10+ simultaneous clients

## 🔧 Configuration

### Server Configuration
```json
{
  "server": {
    "host": "localhost",
    "port": 8080,
    "maxClients": 10,
    "requestTimeout": 300,
    "enableCors": true
  },
  "security": {
    "requireAuthentication": false,
    "allowedClients": ["localhost", "127.0.0.1"],
    "rateLimiting": {
      "enabled": true,
      "requestsPerMinute": 60,
      "burstLimit": 10
    }
  },
  "features": {
    "shortcuts": {
      "enabled": true,
      "maxExecutionTime": 300,
      "allowSystemShortcuts": false
    },
    "voiceControl": {
      "enabled": true,
      "maxExecutionTime": 120,
      "defaultLanguage": "en-US"
    },
    "systemInfo": {
      "enabled": true,
      "allowSensitiveInfo": false,
      "cacheTimeout": 60
    }
  },
  "logging": {
    "level": "info",
    "file": "/var/log/apple-mcp-server.log",
    "maxFileSize": "10MB",
    "maxFiles": 5
  }
}
```

## 🔍 Debugging & Monitoring

### Logging Levels
- **error**: Critical errors and security events
- **warning**: Security warnings and performance issues
- **info**: General operational information
- **debug**: Detailed debugging information

### Health Monitoring
```bash
# Check server health
curl http://localhost:8080/health

# Get server status
curl http://localhost:8080/status

# List available tools
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### Debug Mode
```bash
# Start server with debug logging
apple-mcp-server --log-level debug --config debug.json

# Enable verbose output
apple-mcp-server --verbose --debug
```

---

*API Documentation Version: 1.0.0*
*Last Updated: December 2024*
*Protocol Version: MCP 2024-11-05*