#!/bin/bash

# SharePoint Testing Script for Lokka MCP Server
# This script helps you test the new SharePoint REST API functionality

set -e

echo "🧪 SharePoint Implementation Testing Script"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "Docker is running ✓"

# Check if environment file exists
if [ ! -f ".env" ]; then
    print_warning "No .env file found. Creating a template..."
    
    cat > .env << 'EOF'
# Microsoft Entra App Configuration (Required)
# Get these from your Azure Portal > App Registrations
TENANT_ID=your-tenant-id-here
CLIENT_ID=your-client-id-here
CLIENT_SECRET=your-client-secret-here

# Authentication Mode (Choose one - uncomment the one you want)
# USE_INTERACTIVE=true
# USE_CLIENT_TOKEN=true
# USE_CERTIFICATE=true

# Optional: Graph API Version
USE_GRAPH_BETA=true

# Node.js Configuration
NODE_ENV=development
EOF
    
    print_warning "Please edit .env file with your Microsoft Entra credentials before proceeding"
    print_status "You can edit it with: nano .env"
    exit 1
fi

print_status "Environment file found ✓"

# Check if required environment variables are set
source .env
if [ -z "$TENANT_ID" ] || [ -z "$CLIENT_ID" ] || [ "$TENANT_ID" = "your-tenant-id-here" ]; then
    print_error "Please configure your TENANT_ID and CLIENT_ID in .env file"
    exit 1
fi

print_status "Environment variables configured ✓"

# Build the Docker image
print_status "Building Docker image with SharePoint support..."
docker build -t lokka-mcp:sharepoint-test . > /dev/null 2>&1
print_success "Docker image built successfully"

# Function to test MCP server startup
test_server_startup() {
    print_status "Testing server startup..."
    
    # Test basic container startup
    if docker run --rm --env-file .env lokka-mcp:sharepoint-test node -e "console.log('✓ Container starts successfully')" > /dev/null 2>&1; then
        print_success "Container startup test passed"
    else
        print_error "Container startup test failed"
        return 1
    fi
}

# Function to create a test container
create_test_container() {
    print_status "Creating test container..."
    
    # Stop any existing test container
    docker stop lokka-sharepoint-test > /dev/null 2>&1 || true
    docker rm lokka-sharepoint-test > /dev/null 2>&1 || true
    
    # Create and start new container
    docker run -d \
        --name lokka-sharepoint-test \
        --env-file .env \
        -p 3001:3000 \
        lokka-mcp:sharepoint-test > /dev/null
    
    # Wait for container to start
    sleep 5
    
    if docker ps | grep -q lokka-sharepoint-test; then
        print_success "Test container created and running"
        print_status "Container logs:"
        docker logs lokka-sharepoint-test
        return 0
    else
        print_error "Failed to create test container"
        docker logs lokka-sharepoint-test 2>/dev/null || true
        return 1
    fi
}

# Function to show SharePoint testing examples
show_testing_examples() {
    print_status "SharePoint Testing Examples"
    echo
    echo "Now you can test SharePoint functionality using a MCP client like Claude Desktop."
    echo
    echo "📝 Example SharePoint API calls:"
    echo
    echo "1. Get SharePoint site information:"
    echo '{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web",
  "queryParams": {
    "$select": "Title,Description,Url"
  }
}'
    echo
    echo "2. Get list items:"
    echo '{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web/lists/getbytitle('\''Your List Name'\'')/items",
  "fetchAll": true
}'
    echo
    echo "3. Add attachment to list item:"
    echo '{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "post",
  "path": "/web/lists/getbytitle('\''Your List Name'\'')/items(1)/AttachmentFiles/add(FileName='\''test.txt'\'')",
  "body": "SGVsbG8gV29ybGQ="
}'
    echo
    echo "4. Get list attachments:"
    echo '{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web/lists/getbytitle('\''Your List Name'\'')/items(1)/AttachmentFiles"
}'
    echo
}

# Function to show Claude Desktop configuration
show_claude_config() {
    print_status "Claude Desktop Configuration"
    echo
    echo "Add this to your Claude Desktop configuration (~/.claude_desktop_config.json):"
    echo
    echo '{
  "mcpServers": {
    "lokka-sharepoint": {
      "command": "docker",
      "args": [
        "exec", "-i", "lokka-sharepoint-test",
        "node", "build/main.js"
      ]
    }
  }
}'
    echo
    print_warning "Note: Make sure the container 'lokka-sharepoint-test' is running first!"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up test container..."
    docker stop lokka-sharepoint-test > /dev/null 2>&1 || true
    docker rm lokka-sharepoint-test > /dev/null 2>&1 || true
    print_success "Cleanup complete"
}

# Main execution
main() {
    case "${1:-}" in
        "build")
            print_status "Building Docker image only..."
            docker build -t lokka-mcp:sharepoint-test .
            print_success "Build complete"
            ;;
        "start")
            test_server_startup
            create_test_container
            show_testing_examples
            show_claude_config
            ;;
        "stop")
            cleanup
            ;;
        "logs")
            if docker ps | grep -q lokka-sharepoint-test; then
                docker logs -f lokka-sharepoint-test
            else
                print_error "Test container is not running"
            fi
            ;;
        "shell")
            if docker ps | grep -q lokka-sharepoint-test; then
                print_status "Opening shell in test container..."
                docker exec -it lokka-sharepoint-test /bin/sh
            else
                print_error "Test container is not running"
            fi
            ;;
        *)
            echo "Usage: $0 {build|start|stop|logs|shell}"
            echo
            echo "Commands:"
            echo "  build  - Build the Docker image with SharePoint support"
            echo "  start  - Start test container and show examples"
            echo "  stop   - Stop and remove test container"
            echo "  logs   - Show container logs (follow mode)"
            echo "  shell  - Open shell in running container"
            echo
            echo "Example workflow:"
            echo "  1. $0 build"
            echo "  2. Edit .env file with your credentials"
            echo "  3. $0 start"
            echo "  4. Test with Claude Desktop or MCP client"
            echo "  5. $0 stop (when done)"
            ;;
    esac
}

main "$@" 