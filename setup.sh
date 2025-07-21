#!/bin/bash
# setup.sh - Initial setup script for Lokka MCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Lokka MCP Docker Setup${NC}"
echo "=========================="
echo ""

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ Error: This script must be run from the lokka-mcp directory${NC}"
    exit 1
fi

# Step 1: Clone Lokka repository
echo -e "${YELLOW}Step 1: Cloning Lokka repository...${NC}"
if [ ! -d "lokka" ]; then
    git clone https://github.com/merill/lokka.git lokka
    echo -e "${GREEN}✓ Cloned Lokka repository${NC}"
else
    echo -e "${BLUE}ℹ Lokka repository already exists${NC}"
fi

# Step 2: Create .env file if it doesn't exist
echo -e "${YELLOW}Step 2: Setting up environment configuration...${NC}"
if [ ! -f ".env" ]; then
    cp .env.template .env
    echo -e "${GREEN}✓ Created .env file from template${NC}"
    echo -e "${YELLOW}⚠️  Please edit .env file with your Microsoft Entra credentials${NC}"
else
    echo -e "${BLUE}ℹ .env file already exists${NC}"
fi

# Step 3: Make wrapper script executable
chmod +x docker-mcp-wrapper.sh
echo -e "${GREEN}✓ Made docker-mcp-wrapper.sh executable${NC}"

# Step 4: Create Claude Desktop config directory if it doesn't exist
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
if [ -d "$CLAUDE_CONFIG_DIR" ]; then
    echo -e "${YELLOW}Step 3: Claude Desktop configuration...${NC}"
    
    # Create example config
    cat > claude-desktop-config-example.json << EOF
{
  "mcpServers": {
    "Lokka-Microsoft-Docker": {
      "command": "$PWD/docker-mcp-wrapper.sh",
      "args": []
    }
  }
}
EOF
    
    echo -e "${GREEN}✓ Created claude-desktop-config-example.json${NC}"
    echo -e "${YELLOW}ℹ Add this configuration to your Claude Desktop config${NC}"
fi

# Step 5: Display next steps
echo ""
echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Edit .env file with your Microsoft Entra credentials:"
echo "   ${YELLOW}nano .env${NC}"
echo ""
echo "2. Copy Lokka source files to the current directory:"
echo "   ${YELLOW}cp -r lokka/src lokka/package*.json lokka/tsconfig.json .${NC}"
echo ""
echo "3. Build the Docker image:"
echo "   ${YELLOW}docker build -t lokka-mcp:latest .${NC}"
echo ""
echo "4. Start the container:"
echo "   ${YELLOW}docker-compose up -d${NC}"
echo "   or"
echo "   ${YELLOW}./docker-mcp-wrapper.sh start${NC}"
echo ""
echo "5. Configure Claude Desktop with the provided configuration"
echo ""
echo -e "${YELLOW}For detailed setup instructions, see README.md${NC}"