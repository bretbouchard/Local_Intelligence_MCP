# 🐳 Docker MCP Server Setup Guide

## ✅ **What We've Accomplished**

Your MCP server now has a **consistent container name** and can be **managed from Docker Desktop**!

- **Container Name**: `local-intelligence-mcp` (no more random names!)
- **Docker Desktop Ready**: Start/stop from GUI
- **Persistent**: Container stays running until you stop it
- **MCP Compatible**: Works with any MCP client

## 🚀 **How to Use**

### **Option 1: Docker Desktop GUI (Easiest)**

1. **Open Docker Desktop**
2. **Look for container**: `local-intelligence-mcp`
3. **Use the start/stop buttons** in Docker Desktop
4. **Status**: You'll see it running with status "Up X minutes (healthy)"

### **Option 2: Command Line Management**

```bash
# Start the server
./docker-manager.sh start

# Check status
./docker-manager.sh status

# Stop the server
./docker-manager.sh stop

# Restart the server
./docker-manager.sh restart

# View logs
./docker-manager.sh logs
```

### **Option 3: MCP Client Configuration**

For **Claude Desktop** or other MCP clients, use this configuration:

```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "docker",
      "args": ["exec", "-i", "local-intelligence-mcp", "/usr/local/bin/LocalIntelligenceMCP", "start-command", "--log-level", "info", "--mcp-mode"]
    }
  }
}
```

**Alternative (uses the manager script):**
```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "./docker-manager.sh",
      "args": ["exec"]
    }
  }
}
```

## 📋 **Setup Steps**

### **1. Initial Setup (One-time)**
```bash
# The container is already running!
./docker-manager.sh status
```

### **2. For MCP Client Integration**
Add the configuration above to your MCP client (like Claude Desktop).

### **3. Start/Stop Management**
- **Docker Desktop**: Use the GUI buttons
- **Command Line**: Use `./docker-manager.sh start/stop`

## 🔍 **Verification**

```bash
# Check container is running
./docker-manager.sh status

# Test MCP functionality
echo '{"jsonrpc": "2.0", "id": 1, "method": "ping"}' | ./docker-manager.sh exec

# Expected response:
# {"id":1,"jsonrpc":"2.0","result":{}}
```

## 🎯 **Key Benefits**

✅ **Consistent Naming**: Always `local-intelligence-mcp`
✅ **Docker Desktop Integration**: Start/stop from GUI
✅ **Persistent Container**: Stays running until stopped
✅ **Easy Management**: Simple command-line tools
✅ **MCP Compliant**: Works with any MCP client
✅ **Production Ready**: Proper labels and configuration

## 📱 **Docker Desktop Instructions**

1. **Open Docker Desktop**
2. **Go to "Containers" tab**
3. **Find `local-intelligence-mcp`** in the list
4. **Click the start/stop buttons** as needed
5. **View logs** by clicking on the container name
6. **Check status** in the Status column

## 🏆 **Summary**

Your MCP server now has:
- **Fixed container name**: `local-intelligence-mcp`
- **Docker Desktop management**: GUI start/stop control
- **MCP client compatibility**: Ready for Claude Desktop integration
- **Easy command-line tools**: `./docker-manager.sh`

**The random naming issue is completely solved!** 🎉