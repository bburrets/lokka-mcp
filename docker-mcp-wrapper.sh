#!/bin/bash
# docker-mcp-wrapper.sh
# Wrapper script to run Lokka in Docker for MCP clients

# Set default values
CONTAINER_NAME="${CONTAINER_NAME:-lokka-mcp-server}"
IMAGE_NAME="${IMAGE_NAME:-lokka-mcp:latest}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running" >&2
    exit 1
fi

# Function to start the container if not running
ensure_container_running() {
    if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "Starting Lokka container..." >&2
        docker run -d \
            --name "${CONTAINER_NAME}" \
            --env-file .env \
            --restart unless-stopped \
            -p 3000:3000 \
            "${IMAGE_NAME}"
        
        # Wait for container to be ready
        sleep 2
    fi
}

# Function to execute commands in the container
execute_in_container() {
    ensure_container_running
    docker exec -i "${CONTAINER_NAME}" "$@"
}

# Main execution
case "${1:-}" in
    "start")
        ensure_container_running
        echo "Lokka MCP server is running"
        ;;
    "stop")
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
        echo "Lokka MCP server stopped"
        ;;
    "logs")
        docker logs -f "${CONTAINER_NAME}"
        ;;
    "exec")
        shift
        execute_in_container "$@"
        ;;
    *)
        # Default: pass through to the MCP server
        execute_in_container node build/main.js "$@"
        ;;
esac