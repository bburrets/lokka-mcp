# Lokka MCP Docker Setup

This directory contains a Docker-based setup for running your own enhanced version of the Lokka MCP (Model Context Protocol) server for Microsoft 365 and Azure.

## Prerequisites

- Docker and Docker Compose installed
- Git
- Microsoft Entra (Azure AD) application credentials
- Claude Desktop or another MCP-compatible client

## Quick Start

1. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Configure your Microsoft Entra credentials:**
   ```bash
   # Copy the template to create your .env file
   cp .env.template .env
   
   # Edit .env with your credentials
   nano .env
   ```

3. **Clone and prepare Lokka source:**
   ```bash
   # The setup script already cloned Lokka
   # Copy the necessary files to the current directory
   cp -r lokka/src lokka/package*.json lokka/tsconfig.json .
   ```

4. **Build and run:**
   ```bash
   # Build the Docker image
   docker build -t lokka-mcp:latest .
   
   # Start with Docker Compose (includes Redis and PostgreSQL)
   docker-compose up -d
   
   # Or start standalone
   ./docker-mcp-wrapper.sh start
   ```

## Microsoft Entra Setup

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Microsoft Entra ID → App registrations
3. Create a new registration with:
   - Name: Lokka MCP Docker
   - Redirect URI: `http://localhost:3000`
4. Note your Application (client) ID and Directory (tenant) ID
5. Create a client secret under "Certificates & secrets"
6. Grant necessary Microsoft Graph permissions

## Configuration Options

### Authentication Modes

1. **Service Principal (default)**
   ```env
   TENANT_ID=your-tenant-id
   CLIENT_ID=your-client-id
   CLIENT_SECRET=your-client-secret
   ```

2. **Interactive Authentication**
   ```env
   USE_INTERACTIVE=true
   REDIRECT_URI=http://localhost:3000
   ```

3. **Client Token**
   ```env
   USE_CLIENT_TOKEN=true
   ACCESS_TOKEN=your-token
   ```

### Optional Services

- **Redis**: For caching (enabled in docker-compose.yml)
- **PostgreSQL**: For audit logging (enabled in docker-compose.yml)

## Claude Desktop Integration

Add to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "Lokka-Microsoft-Docker": {
      "command": "/Users/bburrets/Code/lokka-mcp/docker-mcp-wrapper.sh",
      "args": []
    }
  }
}
```

## Development Workflow

1. **Make changes**: Edit files in the lokka source
2. **Rebuild**: `docker build -t lokka-mcp:latest .`
3. **Restart**: `./docker-mcp-wrapper.sh stop && ./docker-mcp-wrapper.sh start`
4. **Check logs**: `./docker-mcp-wrapper.sh logs`

## Useful Commands

```bash
# Start the server
./docker-mcp-wrapper.sh start

# Stop the server
./docker-mcp-wrapper.sh stop

# View logs
./docker-mcp-wrapper.sh logs

# Execute commands in container
./docker-mcp-wrapper.sh exec npm list

# Full stack with Docker Compose
docker-compose up -d
docker-compose down
docker-compose logs -f lokka
```

## Testing

Test your MCP server with the MCP Inspector:

```bash
# First, ensure the container is running
./docker-mcp-wrapper.sh start

# Then test with MCP Inspector
npx @modelcontextprotocol/inspector ./docker-mcp-wrapper.sh
```

## Troubleshooting

1. **Docker not running**: Ensure Docker Desktop is started
2. **Permission denied**: Run `chmod +x docker-mcp-wrapper.sh`
3. **Container won't start**: Check logs with `docker logs lokka-mcp-server`
4. **Authentication issues**: Verify your .env credentials

## Enhancements

This Docker setup allows you to easily add your own enhancements:

1. Edit source files in the cloned lokka directory
2. Add custom modules or middleware
3. Extend the Dockerfile for additional features
4. Use Redis for caching and PostgreSQL for audit logs

## Security Notes

- The container runs as a non-root user
- Filesystem is read-only with specific tmpfs mounts
- Resource limits are enforced
- Secrets are managed via environment variables

## Support

- Original Lokka: https://lokka.dev
- Lokka GitHub: https://github.com/merill/lokka
- MCP Documentation: https://modelcontextprotocol.com