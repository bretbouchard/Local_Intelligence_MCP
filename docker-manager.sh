#!/bin/bash

# Docker MCP Server Management Script
# For easy start/stop from command line

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONTAINER_NAME="local-intelligence-mcp"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"
}

# Check if container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"
}

# Show help
show_help() {
    echo "Docker MCP Server Manager"
    echo "========================="
    echo ""
    echo "Usage: $0 {start|stop|restart|status|logs|stdio|exec|help}"
    echo ""
    echo "Commands:"
    echo "  start    - Start the MCP server container"
    echo "  stop     - Stop the MCP server container"
    echo "  restart  - Restart the MCP server container"
    echo "  status   - Show container status"
    echo "  logs     - Show container logs"
    echo "  stdio    - Start MCP server in stdio mode (for testing)"
    echo "  exec     - Execute MCP server in running container"
    echo "  help     - Show this help message"
    echo ""
    echo "Docker Desktop Management:"
    echo "  - Use Docker Desktop GUI to start/stop the 'local-intelligence-mcp' container"
    echo "  - Container will be visible with name: local-intelligence-mcp"
    echo "  - Labels: mcp.server=true, mcp.name=local-intelligence-mcp"
}

# Start container
start_container() {
    print_header "Starting MCP Server"

    if container_running; then
        print_warning "Container '$CONTAINER_NAME' is already running"
        return 0
    fi

    print_status "Starting container '$CONTAINER_NAME'..."
    docker-compose -f docker-compose-desktop.yml up -d local-intelligence-mcp

    if container_running; then
        print_status "✅ MCP Server started successfully!"
        print_status "Container name: $CONTAINER_NAME"
        print_status "You can now manage it from Docker Desktop"
    else
        print_error "❌ Failed to start MCP Server"
        exit 1
    fi
}

# Stop container
stop_container() {
    print_header "Stopping MCP Server"

    if ! container_exists; then
        print_warning "Container '$CONTAINER_NAME' does not exist"
        return 0
    fi

    if ! container_running; then
        print_warning "Container '$CONTAINER_NAME' is not running"
        return 0
    fi

    print_status "Stopping container '$CONTAINER_NAME'..."
    docker-compose -f docker-compose-desktop.yml down

    if container_running; then
        print_error "❌ Failed to stop MCP Server"
        exit 1
    else
        print_status "✅ MCP Server stopped successfully!"
    fi
}

# Restart container
restart_container() {
    print_header "Restarting MCP Server"
    stop_container
    sleep 2
    start_container
}

# Show status
show_status() {
    print_header "MCP Server Status"

    if container_running; then
        print_status "✅ Container '$CONTAINER_NAME' is RUNNING"

        echo ""
        echo "Container Details:"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        echo ""
        echo "Docker Desktop:"
        echo "- Open Docker Desktop"
        echo "- Look for container: $CONTAINER_NAME"
        echo "- Use start/stop buttons in Docker Desktop GUI"

    elif container_exists; then
        print_warning "⚠️  Container '$CONTAINER_NAME' exists but is STOPPED"
        echo ""
        echo "To start it:"
        echo "  $0 start"
        echo "  Or use Docker Desktop GUI"

    else
        print_error "❌ Container '$CONTAINER_NAME' does not exist"
        echo ""
        echo "To create and start it:"
        echo "  $0 start"
    fi
}

# Show logs
show_logs() {
    print_header "MCP Server Logs"

    if container_exists; then
        docker logs -f --tail 50 "$CONTAINER_NAME"
    else
        print_error "Container '$CONTAINER_NAME' does not exist"
        exit 1
    fi
}

# Start stdio mode (for testing)
start_stdio() {
    print_header "Starting MCP Server in STDIO Mode"
    print_warning "This will start the server for interactive testing"
    print_status "Press Ctrl+C to stop"
    echo ""

    docker-compose -f docker-compose-desktop.yml --profile stdio run --rm local-intelligence-mcp-stdio
}

# Execute MCP server in running container
exec_mcp() {
    print_header "Executing MCP Server in Container"

    if ! container_running; then
        print_error "Container '$CONTAINER_NAME' is not running"
        print_status "Start it first with: $0 start"
        exit 1
    fi

    print_status "Executing MCP server in container '$CONTAINER_NAME'..."
    print_warning "Press Ctrl+C to stop the MCP server (container will keep running)"
    echo ""

    docker exec -i "$CONTAINER_NAME" /usr/local/bin/LocalIntelligenceMCP start-command --log-level info --mcp-mode
}

# Main script logic
case "${1:-help}" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        restart_container
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    stdio)
        start_stdio
        ;;
    exec)
        exec_mcp
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac