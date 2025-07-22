# 🧪 SharePoint Implementation Testing Guide

This guide walks you through testing the new SharePoint REST API functionality in your Lokka MCP Docker setup.

## 🚀 Quick Start

### Prerequisites

- ✅ Docker and Docker Compose installed
- ✅ Microsoft Entra (Azure AD) application with SharePoint permissions
- ✅ SharePoint site access
- ✅ Claude Desktop or another MCP-compatible client

### 1. Run the Testing Script

We've created a comprehensive testing script for you:

```bash
# Show available commands
./test-sharepoint.sh

# Build the Docker image with SharePoint support
./test-sharepoint.sh build

# Start the test container and show examples
./test-sharepoint.sh start

# View container logs
./test-sharepoint.sh logs

# Stop the test container
./test-sharepoint.sh stop
```

## 🔧 Manual Setup (Alternative)

### Step 1: Configure Environment

Make sure your `.env` file contains the required Microsoft Entra credentials:

```bash
# Microsoft Entra App Configuration
TENANT_ID=your-tenant-id
CLIENT_ID=your-client-id
CLIENT_SECRET=your-client-secret

# Choose your authentication mode
USE_INTERACTIVE=true
# or USE_CLIENT_TOKEN=true
# or default to Client Credentials

# Optional settings
USE_GRAPH_BETA=true
NODE_ENV=development
```

### Step 2: Build and Run

```bash
# Build the Docker image
docker build -t lokka-mcp:sharepoint-test .

# Run the container
docker run -d \
  --name lokka-sharepoint-test \
  --env-file .env \
  -p 3001:3000 \
  lokka-mcp:sharepoint-test
```

## 📋 SharePoint Testing Examples

### Basic Site Information

Test basic connectivity by getting site information:

```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web",
  "queryParams": {
    "$select": "Title,Description,Url,Created"
  }
}
```

### List Operations

#### Get All Lists
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web/lists",
  "queryParams": {
    "$select": "Title,Id,ItemCount"
  }
}
```

#### Get List Items
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web/lists/getbytitle('Your List Name')/items",
  "queryParams": {
    "$select": "Id,Title,Created,Modified"
  },
  "fetchAll": true
}
```

### Attachment Operations

#### Get List Item Attachments
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "get",
  "path": "/web/lists/getbytitle('Your List Name')/items(1)/AttachmentFiles"
}
```

#### Add Attachment to List Item
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "post",
  "path": "/web/lists/getbytitle('Your List Name')/items(1)/AttachmentFiles/add(FileName='test.txt')",
  "body": "SGVsbG8gU2hhcmVQb2ludCBmcm9tIExva2th"
}
```

Note: The `body` should be base64-encoded content. The example above is "Hello SharePoint from Lokka" encoded in base64.

#### Delete Attachment
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "delete",
  "path": "/web/lists/getbytitle('Your List Name')/items(1)/AttachmentFiles('test.txt')"
}
```

### Advanced Examples

#### Create List Item
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "post",
  "path": "/web/lists/getbytitle('Your List Name')/items",
  "body": {
    "__metadata": {
      "type": "SP.Data.YourListNameListItem"
    },
    "Title": "New Item from Lokka",
    "Description": "Created via SharePoint REST API"
  }
}
```

#### Update List Item
```json
{
  "apiType": "sharepoint",
  "siteUrl": "https://yourtenant.sharepoint.com/sites/yoursite",
  "method": "patch",
  "path": "/web/lists/getbytitle('Your List Name')/items(1)",
  "body": {
    "__metadata": {
      "type": "SP.Data.YourListNameListItem"
    },
    "Title": "Updated Item Title"
  }
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Authentication Errors
**Error**: "Failed to acquire SharePoint access token"

**Solutions**:
- Verify your Microsoft Entra app has SharePoint permissions
- Check that `TENANT_ID`, `CLIENT_ID`, and `CLIENT_SECRET` are correct
- Ensure your app has been granted admin consent for SharePoint permissions

#### 2. Site Access Errors
**Error**: "Access denied" or "Site not found"

**Solutions**:
- Verify the `siteUrl` is correct and accessible
- Check that your app/user has permissions to the SharePoint site
- Test with a simpler path first (e.g., just `/web`)

#### 3. List Not Found Errors
**Error**: "List 'Your List Name' does not exist"

**Solutions**:
- Verify the list name is exactly correct (case-sensitive)
- Use `/web/lists` first to see all available lists
- Try using the list GUID instead of the title

#### 4. Form Digest Errors
**Error**: "The security validation for this page is invalid"

**Solutions**:
- The server automatically handles form digest tokens
- If issues persist, try setting `useFormDigest: false`
- Check that your authentication token has write permissions

### Debugging Commands

```bash
# View container logs
./test-sharepoint.sh logs

# Open shell in container for debugging
./test-sharepoint.sh shell

# Check container status
docker ps | grep lokka-sharepoint-test

# View detailed container information
docker inspect lokka-sharepoint-test
```

## 🔒 Required SharePoint Permissions

Your Microsoft Entra application needs these permissions:

### Application Permissions (for Client Credentials)
- `Sites.Read.All` - Read access to all sites
- `Sites.ReadWrite.All` - Read/write access to all sites
- `Sites.FullControl.All` - Full control (if needed for advanced operations)

### Delegated Permissions (for Interactive/Token modes)
- `Sites.Read.All` - Read access to all sites user can access
- `Sites.ReadWrite.All` - Read/write access to sites user can access
- `AllSites.Read` - Read access to all sites
- `AllSites.Write` - Write access to all sites

## 🎯 Claude Desktop Integration

Add this configuration to your Claude Desktop settings (`~/.claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "lokka-sharepoint": {
      "command": "docker",
      "args": [
        "exec", "-i", "lokka-sharepoint-test",
        "node", "build/main.js"
      ]
    }
  }
}
```

Then restart Claude Desktop and you should see the Lokka-Microsoft tool available with SharePoint support.

## 📊 Testing Checklist

- [ ] ✅ Docker image builds successfully
- [ ] ✅ Container starts without errors
- [ ] ✅ Authentication works (test with `/web` call)
- [ ] ✅ Can retrieve site information
- [ ] ✅ Can list SharePoint lists
- [ ] ✅ Can read list items
- [ ] ✅ Can retrieve attachments
- [ ] ✅ Can add attachments (if write permissions available)
- [ ] ✅ Error handling works correctly
- [ ] ✅ Claude Desktop integration works

## 🎉 Success Indicators

You'll know SharePoint integration is working when:

1. **Container starts successfully** - No authentication errors in logs
2. **Site queries work** - You can retrieve basic site information
3. **List operations work** - You can browse and query SharePoint lists
4. **Attachment operations work** - You can view and manipulate attachments
5. **Claude Desktop integration** - The tool appears and responds correctly

## 📞 Need Help?

If you encounter issues:

1. Check the container logs: `./test-sharepoint.sh logs`
2. Verify your SharePoint permissions in Azure Portal
3. Test with simpler operations first (basic site info)
4. Check the SHAREPOINT_IMPLEMENTATION.md for technical details
5. Ensure your SharePoint site URL is accessible and correct

Happy testing! 🚀 