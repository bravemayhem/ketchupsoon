#!/bin/bash

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js to use this MCP server."
    exit 1
fi

# Make the script executable if it isn't already
if [[ ! -x "./sequential-thinking-mcp.js" ]]; then
    chmod +x ./sequential-thinking-mcp.js
fi

# Start the sequential thinking MCP server
node ./sequential-thinking-mcp.js 