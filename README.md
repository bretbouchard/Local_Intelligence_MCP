# 🧠 Local Intelligence MCP

A Swift-based, cross-platform Model Context Protocol (MCP) server that extends Apple's on-device Intelligence features to local AI agents in a secure and privacy-preserving way.

Local Intelligence MCP provides text processing, summarization, and contextual analysis tools designed to augment Apple Intelligence capabilities within your own applications — without sharing data externally and without being affiliated with or authored by Apple.

## ✅ Key Points

- **Built independently** using Apple's public frameworks and Model Context Protocol support
- **Integrates with Apple Intelligence** for local inference, privacy, and system-level AI features  
- **Not developed, endorsed, or affiliated** with Apple Inc.
- **Privacy-first architecture**: all analysis runs locally, with optional sandboxed model extensions

## ✨ Features

- **🔧 MCP Protocol Compliance**: Full implementation of the Model Context Protocol specification
- **📝 Text Processing Tools**: 21 professional tools for text analysis, summarization, and content processing
- **🔍 Content Analysis**: Advanced PII detection, intent analysis, and content categorization
- **🛡️ Privacy Preserving**: Built-in PII redaction with audio term preservation
- **🔒 Enterprise-Grade Security**: Comprehensive security testing and protection against attacks
- **🚀 High Performance**: Concurrent request handling with memory optimization
- **🐳 Cross-Platform**: Builds and runs on macOS, Linux, and other platforms
- **📱 Offline Capable**: Core functionality works without network connectivity
- **⚡ Streaming Support**: Handles large documents with efficient streaming processing

## Requirements

- **Swift**: 6.0 or later
- **Platforms**: macOS 12.0+, Linux (Ubuntu 20.04+)
- **Memory**: 512MB minimum, 1GB recommended
- **Storage**: 100MB for installation

## Installation

### Build from Source

```bash
git clone https://github.com/bretbouchard/Local_Intelligence_MCP.git
cd Local_Intelligence_MCP
swift build -c release
```

### Docker Installation

```bash
# Build Docker image
docker build -t local-intelligence-mcp .

# Run the container
docker run -p 3000:3000 local-intelligence-mcp

# Or use docker-compose
docker-compose up -d
```

### Run

```bash
swift run LocalIntelligenceMCP
```

## Configuration

Create a configuration file at `~/.config/local-intelligence-mcp-server/config.json`:

```json
{
  "server": {
    "host": "localhost",
    "port": 8050,
    "maxClients": 10
  },
  "security": {
    "requireAuthentication": false,
    "allowedClients": ["localhost"]
  },
  "features": {
    "shortcuts": { "enabled": true },
    "voiceControl": { "enabled": true },
    "systemInfo": { "enabled": true }
  }
}
```

### Environment Variables

The server can also be configured using environment variables:

```bash
# Override default port
export MCP_SERVER_PORT=8050

# Override host
export MCP_SERVER_HOST=0.0.0.0

# Override max clients
export MCP_MAX_CLIENTS=20

# Enable features
export MCP_ENABLE_SHORTCUTS=true
export MCP_ENABLE_VOICE_CONTROL=true
export MCP_ENABLE_SYSTEM_INFO=true

# Set log level
export MCP_LOG_LEVEL=info
```

## 🛠️ Available MCP Tools

### Text Processing Tools
| Tool | Description | Example Usage |
|------|-------------|-------------|
| `text_normalize` | Clean and standardize text input | `{"text": " messy  text   ", "removeFillers": true}` |
| `text_chunking` | Split large text into manageable chunks | `{"text": "long document...", "maxChunkSize": 1000}` |
| `text_rewrite` | Enhance and restructure content | `{"text": "original text", "style": "professional"}` |
| `pii_redaction` | Detect and redact sensitive information | `{"text": "Contact: john@example.com", "policy": "conservative"}` |

### Content Analysis Tools
| Tool | Description | Example Usage |
|------|-------------|-------------|
| `content_purpose_detector` | Analyze content intent and purpose | `{"text": "meeting notes...", "context": {"domain": "business"}}` |
| `query_analysis` | Extract keywords and intent from queries | `{"query": "find sales reports from last quarter"}` |
| `intent_recognition` | Recognize user intent in text | `{"text": "Please schedule a meeting for tomorrow"}` |

### Summarization Tools
| Tool | Description | Example Usage |
|------|-------------|-------------|
| `summarization` | Generate text summaries | `{"text": "long article...", "style": "executive", "maxLength": 200}` |
| `focused_summarization` | Create targeted summaries | `{"text": "document...", "focus": ["key_decisions", "action_items"]}` |
| `enhanced_summarization` | Advanced summarization with analysis | `{"text": "complex document...", "analysisDepth": "deep"}` |

### Extraction Tools
| Tool | Description | Example Usage |
|------|-------------|-------------|
| `tag_generation` | Extract relevant keywords and tags | `{"text": "article about AI and machine learning", "maxTags": 10}` |
| `schema_extraction` | Create structured data from text | `{"text": "contact info...", "schemaType": "person"}` |
| `feedback_analysis` | Analyze user feedback and sentiment | `{"feedback": "Product is great but needs improvement"}` |

### Catalog Tools
| Tool | Description | Example Usage |
|------|-------------|-------------|
| `catalog_summarization` | Analyze catalog content | `{"catalog": [{"title": "Item 1", "description": "..."}]}` |
| `session_notes` | Process session transcripts | `{"transcript": "Meeting discussion...", "sessionType": "meeting"}` |
| `similarity_ranking` | Find similar content | `{"query": "machine learning basics", "documents": [...]}` |

### System Tools
| Tool | Description | Example Usage |
|------|-------------|-------------|
| `health_check` | Server health and status monitoring | `{}` |
| `system_info` | Get system information | `{"categories": ["device", "performance"]}` |
| `capabilities_list` | List available tools and capabilities | `{}` |

### 🔐 Security Features

- **Input Validation**: Comprehensive validation and sanitization of all inputs
- **Permission Enforcement**: Role-based access control with granular permissions
- **Attack Protection**: Protection against injection, timing, and memory attacks
- **Rate Limiting**: Brute force and dictionary attack protection
- **Audit Logging**: Complete security event logging and monitoring
- **Session Management**: Secure session handling with hijacking protection

## 🔌 Platform Integration

Local Intelligence MCP integrates with major AI platforms and development environments. For comprehensive setup instructions, see our [**Platform Integration Guide**](./PLATFORM_INTEGRATION.md).

### Quick Setup Examples

#### Claude Desktop
```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "swift",
      "args": ["run", "--package-path", "/path/to/Local_Intelligence_MCP", "LocalIntelligenceMCP"]
    }
  }
}
```

#### VS Code + GitHub Copilot
```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "swift",
      "args": ["run", "LocalIntelligenceMCP"],
      "cwd": "/path/to/Local_Intelligence_MCP"
    }
  }
}
```

#### Docker Integration
```bash
# Start server
docker-compose up -d

# For Claude Desktop
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "docker",
      "args": ["exec", "-i", "local-intelligence-mcp", "/usr/local/bin/LocalIntelligenceMCP"]
    }
  }
}
```

### Supported Platforms

| Platform | Status | Configuration |
|----------|--------|---------------|
| **Claude Desktop** | ✅ Full Support | [Setup Guide](./PLATFORM_INTEGRATION.md#claude-desktop) |
| **VS Code + Copilot** | ✅ Full Support | [Setup Guide](./PLATFORM_INTEGRATION.md#vs-code-with-github-copilot) |
| **Cursor IDE** | ✅ Full Support | [Setup Guide](./PLATFORM_INTEGRATION.md#cursor-ide) |
| **Windsurf** | ✅ Full Support | [Setup Guide](./PLATFORM_INTEGRATION.md#windsurf) |
| **Google AI Studio** | ✅ HTTP Integration | [Setup Guide](./PLATFORM_INTEGRATION.md#google-ai-studio--vertex-ai) |
| **ChatGPT/OpenAI** | ✅ HTTP Integration | [Setup Guide](./PLATFORM_INTEGRATION.md#chatgpt--openai-platform) |
| **JetBrains IDEs** | 🔄 Coming Soon | Custom MCP Plugin |
| **Zed Editor** | ✅ Basic Support | [Setup Guide](./PLATFORM_INTEGRATION.md#zed-editor) |

For detailed instructions, troubleshooting, and advanced configurations, see the [**Platform Integration Guide**](./PLATFORM_INTEGRATION.md).

## 🔧 Quick Start Guide

### 1. Build and Run Locally

```bash
git clone https://github.com/bretbouchard/Local_Intelligence_MCP.git
cd Local_Intelligence_MCP
swift build -c release
swift run LocalIntelligenceMCP
```

### 2. Docker Quick Start

```bash
# Using the management script
./docker-manager.sh start

# Or manually
docker-compose up -d
```

### 3. Verify Installation

```bash
# Test MCP endpoint
echo '{"jsonrpc": "2.0", "id": 1, "method": "ping"}' | nc localhost 3000

# Or using curl
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}'
```

## 🔧 Troubleshooting

### Common Issues

#### MCP Server Not Starting

```bash
# Check if port is in use
lsof -i :3000

# Check Swift installation
swift --version

# Run with debug logging
MCP_LOG_LEVEL=debug swift run LocalIntelligenceMCP
```

#### Connection Issues

```bash
# Test connectivity
telnet localhost 3000

# Check server health
curl http://localhost:3000/health

# Verify MCP protocol
echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0.0"}}}' | nc localhost 3000
```

#### Docker Issues

```bash
# Check container status
docker ps -a | grep local-intelligence-mcp

# View container logs
docker logs local-intelligence-mcp

# Restart container
docker restart local-intelligence-mcp
```

#### Tool Not Found Errors

```bash
# List available tools
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list"}' | nc localhost 3000

# Check specific tool
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "health_check", "arguments": {}}}' | nc localhost 3000
```

### FAQ

**Q: Which platforms are supported?**
A: macOS 12.0+, Linux (Ubuntu 20.04+), and Docker containers on any platform.

**Q: Can I run multiple instances?**
A: Yes, use different ports with `MCP_SERVER_PORT` environment variable.

**Q: How do I update to the latest version?**
A: `git pull && swift build -c release`

**Q: Is there a GUI interface?**
A: No, this is an MCP server designed to integrate with AI assistants and IDEs.

**Q: How do I report issues?**
A: Please use the [GitHub Issues](https://github.com/bretbouchard/Local_Intelligence_MCP/issues) page.

## Development

### Project Structure

```
Sources/LocalIntelligenceMCP/
├── Core/                # MCP protocol implementation
├── Tools/               # MCP tool implementations
├── Services/            # Apple API integrations
├── Security/            # Privacy and security features
├── Models/              # Data models
└── Utils/               # Common utilities
```

### 🧪 Testing

This project includes a comprehensive test suite with **400+ test methods** covering:

#### Test Categories

- **Unit Tests**: Individual component testing with 200+ methods
- **Integration Tests**: End-to-end workflow testing with 20+ methods
- **Performance Tests**: Concurrent load testing with 10+ methods
- **Security Tests**: Attack surface analysis with 22+ methods

#### Running Tests

```bash
# Run all tests
swift test

# Run specific test categories
swift test --filter SecurityAuditTests
swift test --filter ConcurrencyTests
swift test --filter EndToEndTests

# Run with verbose output
swift test --verbose

# Run specific test
swift test --filter testSecurityAudit_MaliciousParameterInjection
```

#### Test Coverage

- **Security Testing**: Comprehensive validation against OWASP Top 10
- **Performance Testing**: Load testing up to 100 concurrent requests
- **Integration Testing**: Complete user story workflows
- **Model Testing**: All data models with edge case validation

### Code Style

This project uses SwiftLint and SwiftFormat for consistent code style:

```bash
# Install tools (if not already installed)
brew install swiftlint swiftformat

# Run linting
swiftlint

# Format code
swiftformat .
```

## 🔒 Security and Privacy

### 🛡️ Security Features
- **Comprehensive Input Validation**: Protection against injection attacks
- **Role-Based Access Control**: Granular permission enforcement
- **Attack Surface Protection**: Defense against timing, memory, and concurrency attacks
- **Rate Limiting**: Brute force and dictionary attack prevention
- **Session Security**: Hijacking and privilege escalation protection
- **Audit Logging**: Complete security event monitoring and logging

### 🛡️ Privacy Features
- No persistent storage of sensitive user data
- Apple Keychain integration for secure credential storage
- Memory-safe Swift 6 implementation with strict concurrency
- Information disclosure prevention
- Zero-knowledge architecture for sensitive operations

### 🧪 Security Testing
The server includes **22 comprehensive security tests** covering:
- Input validation and sanitization testing
- Authentication and authorization testing
- Attack surface analysis and penetration testing
- Dictionary attack protection verification
- Timing attack vulnerability detection
- Memory exhaustion protection testing
- Concurrency abuse resistance validation
- Race condition vulnerability detection
- Information disclosure analysis
- Protocol abuse prevention

**Total Security Test Coverage**: 300+ security scenarios across all attack vectors

## 📚 API Documentation

### MCP Protocol Endpoints

#### Server Information
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {
        "listChanged": true
      }
    }
  }
}
```

#### Tool List
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "result": {
    "tools": [
      {
        "name": "shortcuts_execute",
        "description": "Execute Apple Shortcuts",
        "inputSchema": {
          "type": "object",
          "properties": {
            "shortcutName": {"type": "string"},
            "input": {"type": "object"},
            "timeout": {"type": "number", "default": 30}
          },
          "required": ["shortcutName"]
        }
      }
    ]
  }
}
```

### Tool Usage Examples

#### Execute Shortcut
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
        "body": "Don't forget our meeting at 2 PM"
      },
      "timeout": 60
    }
  }
}
```

#### Get System Information
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "system_info",
    "arguments": {
      "categories": ["device", "performance", "network"],
      "includeSensitive": false
    }
  }
}
```

#### Voice Control Command
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "voice_control",
    "arguments": {
      "command": "Open Safari and go to apple.com",
      "timeout": 30,
      "accessibility": true
    }
  }
}
```

### Response Format

#### Success Response
```json
{
  "jsonrpc": "2.0",
  "id": "request-id",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Shortcut executed successfully"
      }
    ],
    "isError": false
  }
}
```

#### Error Response
```json
{
  "jsonrpc": "2.0",
  "id": "request-id",
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": {
      "details": "shortcutName is required"
    }
  }
}
```

## 🏗️ Architecture

### Swift 6 Concurrency Model
- **Actor-based Design**: Thread-safe concurrent operations
- **Strict Concurrency**: Compile-time data race prevention
- **Async/Await**: Modern asynchronous programming patterns
- **Task Groups**: Structured concurrency for complex operations

### Security Architecture
- **Zero-Trust Security**: All inputs validated and sanitized
- **Layered Defense**: Multiple security controls at each layer
- **Fail-Safe Defaults**: Secure by default configuration
- **Audit Trail**: Complete logging of security events

### Performance Characteristics
- **Concurrent Request Handling**: 100+ simultaneous requests
- **Memory Efficiency**: Optimized memory usage patterns
- **Low Latency**: Sub-100ms response times for most operations
- **Resource Management**: Automatic cleanup and resource pooling

## Constitution

This project follows the [Local Intelligence MCP Constitution](docs/constitution.md) which defines core principles:

1. **MCP Protocol Compliance** - Strict adherence to MCP standards
2. **Security & Privacy First** - User data protection as priority
3. **Swift-Native Implementation** - Native Apple platform development
4. **Tool-Based Architecture** - Modular, independently testable design
5. **Offline-First Design** - Core functionality works offline

## 📚 Documentation

### Core Documentation
- [**Platform Integration Guide**](./PLATFORM_INTEGRATION.md) - Comprehensive setup for all platforms
- [**API Documentation**](./API.md) - Complete MCP protocol implementation details
- [**Docker Setup Guide**](./DOCKER_SETUP_GUIDE.md) - Containerized deployment instructions
- [**Security Documentation**](./SECURITY.md) - Security features and privacy protection

### Development Documentation  
- [**Constitution**](./specs/constitution.md) - Core principles and technical constraints
- [**Error Handling Guide**](./docs/ERROR_HANDLING_AND_LOGGING_GUIDE.md) - Logging and error management
- [**Platform APIs Research**](./docs/local_intelligence_platform_apis_research.md) - Technical implementation details

### Quick Reference
- [**Claude Integration Example**](./CLAUDE_example.md) - Claude Desktop specific examples
- [**Gemini Integration Example**](./GEMINI_example.md) - Google AI Studio integration
- [**Cursor Rules Example**](./.cursorrules_example.md) - IDE-specific configuration examples

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the constitution and code style guidelines
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Support

- [Issues](https://github.com/bretbouchard/Local_Intelligence_MCP/issues)
- [Discussions](https://github.com/bretbouchard/Local_Intelligence_MCP/discussions)
- [Documentation](https://github.com/bretbouchard/Local_Intelligence_MCP/tree/main/docs)

<p align="center">
  <a href="https://ko-fi.com/bretbouchard" target="_blank">
    <img src="https://cdn.ko-fi.com/cdn/kofi3.png?v=3" alt="Support me on Ko-fi" height="45" style="margin-right:10px;">
  </a>  
  <a href="https://buymeacoffee.com/bretbouchard" target="_blank">
    <img src="https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png" alt="Buy Me a Coffee" height="45">
  </a>
</p>