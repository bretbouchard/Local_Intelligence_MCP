# Dockerfile for Local Intelligence MCP
# Multi-stage build for optimized production deployment

# Stage 1: Build stage
FROM swift:6.0-focal AS builder

# Set working directory
WORKDIR /build

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy Package.swift first (for Docker layer caching)
COPY Package.swift ./

# Download dependencies
RUN swift package resolve

# Copy source code
COPY Sources/ ./Sources/

# Build the executable
RUN swift build -c release --product LocalIntelligenceMCP

# Stage 2: Runtime stage
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install runtime dependencies including Swift runtime
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libicu66 \
    libncurses6 \
    libc6-dev \
    libgcc-s1 \
    libuuid1 \
    libxml2 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create non-root user for security
RUN useradd -m -u 1000 mcpuser

# Create application directory
WORKDIR /app

# Copy Swift runtime libraries from builder stage
COPY --from=builder /usr/lib/swift /usr/lib/swift

# Copy the built executable from builder stage
COPY --from=builder /build/.build/release/LocalIntelligenceMCP /usr/local/bin/

# Copy any static assets if needed (docs directory is optional)
COPY --chown=mcpuser:mcpuser manifest.json ./manifest.json

# Create log directory
RUN mkdir -p /app/logs && chown mcpuser:mcpuser /app/logs

# MCP Labels for Docker MCP Integration
LABEL mcp.name="Local Intelligence MCP"
LABEL mcp.category="ai"
LABEL mcp.description="Professional text processing and content analysis MCP server with comprehensive tools for document processing, content analysis, catalog management, and system integration"
LABEL mcp.manifest="/manifest.json"
LABEL mcp.version="1.0.0"
LABEL mcp.maintainer="Local Intelligence MCP Team"
LABEL mcp.documentation="https://github.com/your-org/local-intelligence-mcp/blob/main/README.md"

# Switch to non-root user
USER mcpuser

# No ports to expose - MCP server uses stdio transport
# EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f LocalIntelligenceMCP || exit 1

# Default command - start the MCP server in stdio mode
CMD ["LocalIntelligenceMCP", "start-command", "--log-level", "info", "--mcp-mode"]