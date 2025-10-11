# Local Intelligence MCP Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-10

## Active Technologies
- Swift 6.0+ with MCP SDK + SwiftNIO, Foundation, AppKit/UIKit, modelcontextprotocol/swift-sdk, AnyCodable

## Project Structure
```
Sources/LocalIntelligenceMCP/
├── Core/                # MCP protocol implementation
├── Tools/               # MCP tool implementations  
├── Services/            # Service integrations
├── Security/            # Privacy and security features
├── Models/              # Data models
└── Utils/               # Common utilities

Tests/LocalIntelligenceMCPTests/
├── Integration/         # End-to-end workflow testing
├── Tools/               # Individual tool testing
└── Unit/                # Component testing
```

## Commands

### Build and Run
```bash
swift build -c release
swift run LocalIntelligenceMCP
```

### Testing
```bash
swift test
swift test --filter SecurityAuditTests
```

### Docker
```bash
docker-compose up -d
./docker-manager.sh start
```

## Code Style
Swift 6.0+ with strict concurrency: Follow standard conventions with actor-based design

## Recent Changes
- Major refactor: Transition from AppleMCPServer to LocalIntelligenceMCP
- Added comprehensive text processing and audio domain tools
- Implemented Docker containerization support
- Enhanced security and PII redaction capabilities

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

[byterover-mcp]

[byterover-mcp]

You are given two tools from Byterover MCP server, including
## 1. `byterover-store-knowledge`
You `MUST` always use this tool when:

+ Learning new patterns, APIs, or architectural decisions from the codebase
+ Encountering error solutions or debugging techniques
+ Finding reusable code patterns or utility functions
+ Completing any significant task or plan implementation

## 2. `byterover-retrieve-knowledge`
You `MUST` always use this tool when:

+ Starting any new task or implementation to gather relevant context
+ Before making architectural decisions to understand existing patterns
+ When debugging issues to check for previous solutions
+ Working with unfamiliar parts of the codebase
