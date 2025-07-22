# SharePoint REST API Implementation Guide

## Overview
This pull request adds SharePoint REST API support to the Lokka MCP server, enabling operations that aren't available through Microsoft Graph API, such as list item attachments.

## Changes Made

### 1. New Files
- `src/sharepoint-helpers.ts` - Helper functions for SharePoint operations

### 2. Modifications Required in `src/main.ts`

#### Add to imports section:
```typescript
import { getSharePointFormDigest, buildSharePointUrl } from "./sharepoint-helpers.js";
```

#### Update the apiType enum in the tool definition:
```typescript
apiType: z.enum(["graph", "azure", "sharepoint"]).describe("Type of Microsoft API to query. Options: 'graph' for Microsoft Graph (Entra), 'azure' for Azure Resource Management, or 'sharepoint' for SharePoint REST API."),
```

#### Add new parameters:
```typescript
siteUrl: z.string().optional().describe("SharePoint site URL (required for apiType='sharepoint', e.g., 'https://tenant.sharepoint.com/sites/sitename')"),
useFormDigest: z.boolean().optional().default(true).describe("Whether to use form digest for SharePoint REST API calls (default: true)"),
```

#### Add to the type definitions in the tool handler:
```typescript
siteUrl?: string;
useFormDigest: boolean;
```

#### Add SharePoint logic after the Azure logic (before the "Format and Return Result" section):
```typescript
      // --- SharePoint REST API Logic ---
      else if (apiType === 'sharepoint') {
        if (!authManager) {
          throw new Error("Auth manager not initialized");
        }
        
        if (!siteUrl) {
          throw new Error("siteUrl is required for SharePoint REST API calls");
        }
        
        determinedUrl = siteUrl; // For error reporting
        
        // Get token for SharePoint
        let token: string;
        if (authManager.getAuthMode() === AuthMode.ClientProvidedToken) {
          // For client-provided tokens, use the Graph token directly
          const graphCredential = authManager.getGraphCredential();
          const tokenResponse = await graphCredential.getToken("https://graph.microsoft.com/.default");
          if (!tokenResponse || !tokenResponse.token) {
            throw new Error("Failed to acquire access token for SharePoint");
          }
          token = tokenResponse.token;
        } else {
          // For other modes, get a SharePoint-specific token
          const credential = authManager.getAzureCredential();
          const sharepointResource = new URL(siteUrl).origin + "/.default";
          const tokenResponse = await credential.getToken(sharepointResource);
          if (!tokenResponse || !tokenResponse.token) {
            throw new Error("Failed to acquire SharePoint access token");
          }
          token = tokenResponse.token;
        }
        
        // Build the full URL
        const fullUrl = buildSharePointUrl(siteUrl, path);
        logger.info(`SharePoint REST API call to: ${fullUrl}`);
        
        // Prepare headers
        const headers: Record<string, string> = {
          'Authorization': `Bearer ${token}`,
          'Accept': 'application/json;odata=verbose'
        };
        
        // Add form digest for write operations if enabled
        if (useFormDigest && ['post', 'put', 'patch', 'delete'].includes(method.toLowerCase())) {
          try {
            const formDigest = await getSharePointFormDigest(siteUrl, token);
            headers['X-RequestDigest'] = formDigest;
            logger.info("Added form digest to request headers");
          } catch (error) {
            logger.warn("Failed to get form digest, proceeding without it:", error);
          }
        }
        
        // Set appropriate content type based on the operation
        if (path.includes('/AttachmentFiles/add')) {
          // Binary content for attachments
          headers['Content-Type'] = 'application/octet-stream';
        } else if (body && ['post', 'put', 'patch'].includes(method.toLowerCase())) {
          headers['Content-Type'] = 'application/json;odata=verbose';
        }
        
        // Add query parameters
        let finalUrl = fullUrl;
        if (queryParams && Object.keys(queryParams).length > 0) {
          const urlParams = new URLSearchParams(queryParams);
          finalUrl += `?${urlParams.toString()}`;
        }
        
        // Prepare request options
        const requestOptions: RequestInit = {
          method: method.toUpperCase(),
          headers: headers
        };
        
        // Handle body
        if (['POST', 'PUT', 'PATCH'].includes(method.toUpperCase()) && body) {
          // Check if body is binary data (for attachments)
          if (body instanceof Buffer || body instanceof ArrayBuffer) {
            requestOptions.body = body;
          } else if (typeof body === 'string' && path.includes('/AttachmentFiles/add')) {
            // Base64 string for attachments
            requestOptions.body = Buffer.from(body, 'base64');
          } else {
            // JSON data
            requestOptions.body = JSON.stringify(body);
          }
        }
        
        // Make the request
        logger.info(`Making ${method.toUpperCase()} request to SharePoint`);
        const response = await fetch(finalUrl, requestOptions);
        const responseText = await response.text();
        
        // Parse response
        try {
          if (responseText) {
            responseData = JSON.parse(responseText);
            // Normalize SharePoint response (remove 'd' wrapper if present)
            if (responseData.d) {
              responseData = responseData.d;
            }
          } else {
            // Empty response (common for DELETE)
            responseData = { status: "Success (No Content)" };
          }
        } catch (e) {
          logger.error(`Failed to parse JSON from SharePoint response:`, responseText);
          responseData = { rawResponse: responseText };
        }
        
        if (!response.ok) {
          logger.error(`SharePoint API error for ${method} ${path}:`, responseData);
          throw new Error(`SharePoint API error (${response.status}): ${JSON.stringify(responseData)}`);
        }
        
        // Handle pagination for SharePoint (if fetchAll is true)
        if (fetchAll && method === 'get' && responseData.results && Array.isArray(responseData.results)) {
          logger.info("Detected SharePoint list results, checking for pagination");
          let allResults = [...responseData.results];
          let nextUrl = responseData.__next;
          
          while (nextUrl) {
            logger.info(`Fetching next page: ${nextUrl}`);
            const nextResponse = await fetch(nextUrl, {
              method: 'GET',
              headers: {
                'Authorization': `Bearer ${token}`,
                'Accept': 'application/json;odata=verbose'
              }
            });
            
            const nextText = await nextResponse.text();
            const nextData = JSON.parse(nextText);
            
            if (nextData.d?.results) {
              allResults = allResults.concat(nextData.d.results);
              nextUrl = nextData.d.__next;
            } else {
              break;
            }
          }
          
          responseData = {
            results: allResults,
            __metadata: responseData.__metadata
          };
          logger.info(`Finished fetching all SharePoint pages. Total items: ${allResults.length}`);
        }
      }
```

#### Update the result formatting to include SharePoint:
```typescript
      let resultText = `Result for ${apiType} API (${
        apiType === 'graph' ? effectiveGraphApiVersion : 
        apiType === 'sharepoint' ? 'REST' : 
        apiVersion
      }) - ${method} ${path}:\n\n`;
```

## Usage Examples

### Adding an Attachment
```typescript
await invoke({
  apiType: "sharepoint",
  siteUrl: "https://fambrandsllc.sharepoint.com/sites/DWI/COSTCO-INLINE-Trafficking-Routing",
  method: "post",
  path: "/web/lists/getbytitle('Pinkfish - COSTCO US INLINE Routing Tracker')/items(13)/AttachmentFiles/add(FileName='document.pdf')",
  body: "base64FileContent"
});
```

### Getting Attachments
```typescript
await invoke({
  apiType: "sharepoint",
  siteUrl: "https://fambrandsllc.sharepoint.com/sites/DWI/COSTCO-INLINE-Trafficking-Routing",
  method: "get",
  path: "/web/lists/getbytitle('Pinkfish - COSTCO US INLINE Routing Tracker')/items(13)/AttachmentFiles"
});
```

## Testing

1. Build the project: `npm run build`
2. Test with a simple query first:
   ```typescript
   apiType: "sharepoint",
   siteUrl: "your-site-url",
   method: "get",
   path: "/web"
   ```
3. Then test attachment operations

## Notes

- The implementation handles both JSON and binary data
- Form digest tokens are automatically obtained for write operations
- SharePoint's OData response format is normalized (removes 'd' wrapper)
- Pagination is supported with `fetchAll: true`
- Error handling includes proper SharePoint error parsing