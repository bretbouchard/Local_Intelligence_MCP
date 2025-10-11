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

#### Docker Integration
```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "docker",
      "args": [
        "exec", "-i", 
        "local-intelligence-mcp", 
        "/usr/local/bin/LocalIntelligenceMCP"
      ]
    }
  }
}
```

### ChatGPT / OpenAI Platform

For OpenAI API integration, use the HTTP transport:

```python
import openai
import requests

# Configure MCP endpoint
MCP_ENDPOINT = "http://localhost:3000"

def call_local_intelligence_mcp(tool_name, arguments):
    """Call Local Intelligence MCP tool via HTTP"""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": arguments
        }
    }
    
    response = requests.post(MCP_ENDPOINT, json=payload)
    return response.json()

# Example usage
result = call_local_intelligence_mcp("text_normalize", {
    "text": "  messy   text  ",
    "removeFillers": True
})
```

### Google AI Studio / Vertex AI

```python
import vertexai
from vertexai.generative_models import GenerativeModel
import requests

class LocalIntelligenceMCPIntegration:
    def __init__(self, project_id, location="us-central1"):
        vertexai.init(project=project_id, location=location)
        self.model = GenerativeModel("gemini-1.5-pro")
        self.mcp_endpoint = "http://localhost:3000"
    
    def process_with_mcp(self, text, processing_pipeline):
        """Process text through Local Intelligence MCP pipeline"""
        result = text
        
        for step in processing_pipeline:
            tool_name = step["tool"]
            arguments = step.get("arguments", {})
            arguments["text"] = result
            
            response = self._call_mcp_tool(tool_name, arguments)
            result = response["result"]["content"][0]["text"]
        
        return result
    
    def _call_mcp_tool(self, tool_name, arguments):
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {"name": tool_name, "arguments": arguments}
        }
        
        response = requests.post(self.mcp_endpoint, json=payload)
        return response.json()

# Example usage
integration = LocalIntelligenceMCPIntegration("your-project-id")

# Define processing pipeline
pipeline = [
    {"tool": "text_normalize", "arguments": {"removeFillers": True}},
    {"tool": "pii_redaction", "arguments": {"policy": "conservative"}},
    {"tool": "summarization", "arguments": {"style": "executive"}}
]

# Process content
processed_text = integration.process_with_mcp("Your input text here", pipeline)
```

## 💻 IDE Integration

### VS Code with GitHub Copilot

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

## 🐳 Docker Deployment

### Production Docker Setup

#### docker-compose.yml
```yaml
version: '3.8'
services:
  local-intelligence-mcp:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: local-intelligence-mcp
    ports:
      - "3000:3000"
    environment:
      - MCP_LOG_LEVEL=info
      - MCP_MAX_CLIENTS=50
      - MCP_REQUEST_TIMEOUT=30
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    volumes:
      - mcp_logs:/app/logs
    networks:
      - mcp_network

volumes:
  mcp_logs:

networks:
  mcp_network:
    driver: bridge
```

#### Environment Configuration

Create `.env` file:

```bash
# Server Configuration
MCP_SERVER_HOST=0.0.0.0
MCP_SERVER_PORT=3000
MCP_MAX_CLIENTS=50

# Logging
MCP_LOG_LEVEL=info
MCP_LOG_FILE=/app/logs/mcp.log

# Features
MCP_ENABLE_TEXT_PROCESSING=true
MCP_ENABLE_PII_REDACTION=true
MCP_ENABLE_CONTENT_ANALYSIS=true
MCP_ENABLE_SUMMARIZATION=true

# Security
MCP_REQUIRE_AUTH=false
MCP_ALLOWED_IPS=127.0.0.1,::1
MCP_MAX_REQUEST_SIZE=10485760

# Performance
MCP_REQUEST_TIMEOUT=30
MCP_WORKER_THREADS=4
MCP_MEMORY_LIMIT=1073741824
```

### Kubernetes Deployment

#### deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-intelligence-mcp
  labels:
    app: local-intelligence-mcp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: local-intelligence-mcp
  template:
    metadata:
      labels:
        app: local-intelligence-mcp
    spec:
      containers:
      - name: local-intelligence-mcp
        image: local-intelligence-mcp:latest
        ports:
        - containerPort: 3000
        env:
        - name: MCP_SERVER_HOST
          value: "0.0.0.0"
        - name: MCP_SERVER_PORT
          value: "3000"
        - name: MCP_LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: local-intelligence-mcp-service
spec:
  selector:
    app: local-intelligence-mcp
  ports:
  - protocol: TCP
    port: 3000
    targetPort: 3000
  type: ClusterIP
```

## 🔧 Custom Integration

### Direct MCP Protocol

For custom applications, use the MCP protocol directly:

```javascript
// WebSocket connection
const ws = new WebSocket('ws://localhost:3000');

// Initialize connection
ws.send(JSON.stringify({
  jsonrpc: "2.0",
  method: "initialize",
  params: {
    protocolVersion: "2024-11-05",
    capabilities: {
      tools: { listChanged: true }
    },
    clientInfo: {
      name: "MyApp",
      version: "1.0.0"
    }
  },
  id: 1
}));

// Call a tool
function callTool(name, arguments) {
  return new Promise((resolve) => {
    const id = Date.now();
    
    ws.onmessage = (event) => {
      const response = JSON.parse(event.data);
      if (response.id === id) {
        resolve(response);
      }
    };
    
    ws.send(JSON.stringify({
      jsonrpc: "2.0",
      method: "tools/call",
      params: { name, arguments },
      id
    }));
  });
}

// Example usage
callTool('text_normalize', {
  text: 'Your text here',
  removeFillers: true
}).then(result => {
  console.log('Normalized text:', result.result);
});
```

### HTTP REST API

For HTTP-based integration:

```bash
# Initialize connection
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "curl", "version": "1.0"}
    },
    "id": 1
  }'

# Call a tool
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "text_normalize",
      "arguments": {
        "text": "Your text here",
        "removeFillers": true
      }
    },
    "id": 2
  }'
```

## 🚀 Performance Optimization

### Connection Pooling

```python
import asyncio
import aiohttp

class MCPConnectionPool:
    def __init__(self, max_connections=10):
        self.session = aiohttp.ClientSession(
            connector=aiohttp.TCPConnector(limit=max_connections)
        )
        self.endpoint = "http://localhost:3000"
    
    async def call_tool(self, tool_name, arguments):
        payload = {
            "jsonrpc": "2.0",
            "id": asyncio.current_task().get_name(),
            "method": "tools/call",
            "params": {"name": tool_name, "arguments": arguments}
        }
        
        async with self.session.post(self.endpoint, json=payload) as response:
            return await response.json()
    
    async def close(self):
        await self.session.close()
```

### Batch Processing

```python
async def batch_process_texts(texts, processing_pipeline):
    """Process multiple texts in parallel"""
    pool = MCPConnectionPool(max_connections=20)
    
    async def process_single_text(text):
        result = text
        for step in processing_pipeline:
            result = await pool.call_tool(step["tool"], {
                **step.get("arguments", {}),
                "text": result
            })
            result = result["result"]["content"][0]["text"]
        return result
    
    # Process all texts in parallel
    tasks = [process_single_text(text) for text in texts]
    results = await asyncio.gather(*tasks)
    
    await pool.close()
    return results
```

## 🔍 Testing Your Integration

### Health Check
```bash
# Test server health
curl http://localhost:3000/health

# Test MCP protocol
echo '{"jsonrpc": "2.0", "id": 1, "method": "ping"}' | nc localhost 3000
```

### Tool Verification
```bash
# List available tools
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'

# Test specific tool
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "health_check",
      "arguments": {}
    },
    "id": 2
  }'
```

## 🛠️ Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if server is running: `ps aux | grep LocalIntelligenceMCP`
   - Verify port: `lsof -i :3000`
   - Check logs: `docker logs local-intelligence-mcp`

2. **Tool Not Found**
   - List available tools to verify names
   - Check server capabilities and enabled features
   - Verify MCP protocol version compatibility

3. **Timeout Errors**
   - Increase timeout in client configuration
   - Check server load and resource usage
   - Consider using batch processing for large requests

### Debug Mode

Enable debug logging:

```bash
MCP_LOG_LEVEL=debug swift run LocalIntelligenceMCP
```

Or in Docker:

```bash
docker run -e MCP_LOG_LEVEL=debug local-intelligence-mcp
```

## 📚 Additional Resources

- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Local Intelligence MCP API Documentation](./API.md)
- [Docker Setup Guide](./DOCKER_SETUP_GUIDE.md)
- [Security Documentation](./SECURITY.md)

For more help, please visit our [GitHub Issues](https://github.com/bretbouchard/Local_Intelligence_MCP/issues) page.