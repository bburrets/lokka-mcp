#!/bin/bash
# test-mcp.sh - Test the MCP server directly

echo "Testing Lokka MCP Server..."

# Build the image if not exists
if ! docker images | grep -q "lokka-mcp"; then
    echo "Building Docker image..."
    docker build -t lokka-mcp:latest .
fi

# Test with a simple echo to see if container starts
echo "Testing container startup..."
docker run --rm --env-file .env lokka-mcp:latest node -e "console.log('Container started successfully')"

echo "Test complete."