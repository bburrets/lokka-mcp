// sharepoint-helpers.ts
// Helper functions for SharePoint REST API operations

import { logger } from "./logger.js";

export interface SharePointAttachment {
  FileName: string;
  FileNameAsPath: { DecodedUrl: string };
  ServerRelativePath: { DecodedUrl: string };
  ServerRelativeUrl: string;
}

export interface SharePointListItem {
  __metadata: {
    type: string;
    id: string;
    uri: string;
    etag: string;
  };
  Id: number;
  Title: string;
  [key: string]: any;
}

/**
 * Get the list item entity type full name required for REST API operations
 * @param siteUrl SharePoint site URL
 * @param listTitle List title
 * @param accessToken Access token
 * @returns The entity type full name (e.g., "SP.Data.TasksListItem")
 */
export async function getListItemEntityTypeFullName(
  siteUrl: string,
  listTitle: string,
  accessToken: string
): Promise<string> {
  try {
    const response = await fetch(
      `${siteUrl}/_api/web/lists/getbytitle('${encodeURIComponent(listTitle)}')?$select=ListItemEntityTypeFullName`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Accept': 'application/json;odata=verbose'
        }
      }
    );
    
    if (!response.ok) {
      throw new Error(`Failed to get list metadata: ${response.status}`);
    }
    
    const data = await response.json();
    return data.d.ListItemEntityTypeFullName;
  } catch (error) {
    logger.error("Error getting list item entity type:", error);
    throw error;
  }
}

/**
 * Get SharePoint form digest value for write operations
 * @param siteUrl SharePoint site URL
 * @param accessToken Access token
 * @returns Form digest value
 */
export async function getSharePointFormDigest(siteUrl: string, accessToken: string): Promise<string> {
  try {
    const response = await fetch(`${siteUrl}/_api/contextinfo`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Accept': 'application/json;odata=verbose'
      }
    });
    
    if (!response.ok) {
      throw new Error(`Failed to get form digest: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    return data.d.GetContextWebInformation.FormDigestValue;
  } catch (error) {
    logger.error("Error getting SharePoint form digest:", error);
    throw error;
  }
}

/**
 * Build SharePoint REST API URL
 * @param siteUrl SharePoint site URL
 * @param path API path
 * @returns Complete URL
 */
export function buildSharePointUrl(siteUrl: string, path: string): string {
  // Ensure siteUrl doesn't end with slash and path starts with slash
  const cleanSiteUrl = siteUrl.replace(/\/$/, '');
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  
  // If path already contains _api, use it as is
  if (cleanPath.includes('/_api/')) {
    return `${cleanSiteUrl}${cleanPath}`;
  }
  
  // Otherwise, prepend _api
  return `${cleanSiteUrl}/_api${cleanPath}`;
}

/**
 * Encode special characters in SharePoint list/library names for REST API
 * @param name The name to encode
 * @returns Encoded name safe for REST API URLs
 */
export function encodeSharePointName(name: string): string {
  // SharePoint REST API requires special encoding for certain characters
  return name
    .replace(/ /g, '_x0020_')  // Spaces
    .replace(/-/g, '_x002d_')  // Hyphens
    .replace(/\./g, '_x002e_') // Periods
    .replace(/'/g, '_x0027_')  // Apostrophes
    .replace(/\(/g, '_x0028_') // Left parenthesis
    .replace(/\)/g, '_x0029_') // Right parenthesis
    .replace(/&/g, '_x0026_'); // Ampersand
}

/**
 * Build metadata type string for SharePoint list items
 * @param listTitle The display name of the list
 * @returns The metadata type string
 */
export function buildListItemMetadataType(listTitle: string): string {
  // Remove common prefixes/suffixes and encode
  let cleanTitle = listTitle
    .replace(/^(List|Library|Tracker|Log)\s+/i, '')
    .replace(/\s+(List|Library|Tracker|Log)$/i, '');
  
  // Encode special characters
  cleanTitle = encodeSharePointName(cleanTitle);
  
  // Build the type string
  return `SP.Data.${cleanTitle}ListItem`;
}

/**
 * Convert file content to appropriate format for SharePoint upload
 * @param content File content (string, Buffer, or base64)
 * @param isBase64 Whether the content is base64 encoded
 * @returns Buffer ready for upload
 */
export function prepareFileContent(content: string | Buffer, isBase64: boolean = false): Buffer {
  if (Buffer.isBuffer(content)) {
    return content;
  }
  
  if (isBase64) {
    return Buffer.from(content, 'base64');
  }
  
  return Buffer.from(content, 'utf-8');
}

/**
 * Parse SharePoint error responses
 * @param response The response object
 * @param responseText The response text
 * @returns Formatted error message
 */
export async function parseSharePointError(response: Response, responseText: string): Promise<string> {
  try {
    const errorData = JSON.parse(responseText);
    
    // Check for different error formats
    if (errorData.error) {
      if (errorData.error.message) {
        return errorData.error.message.value || errorData.error.message;
      }
      return JSON.stringify(errorData.error);
    }
    
    if (errorData['odata.error']) {
      if (errorData['odata.error'].message) {
        return errorData['odata.error'].message.value || errorData['odata.error'].message;
      }
      return JSON.stringify(errorData['odata.error']);
    }
    
    return responseText;
  } catch (e) {
    return `${response.status} ${response.statusText}: ${responseText}`;
  }
}

/**
 * Build proper headers for SharePoint REST API requests
 * @param method HTTP method
 * @param token Access token
 * @param formDigest Form digest value (optional)
 * @param additionalHeaders Additional headers to include
 * @returns Headers object
 */
export function buildSharePointHeaders(
  method: string,
  token: string,
  formDigest?: string,
  additionalHeaders?: Record<string, string>
): Record<string, string> {
  const headers: Record<string, string> = {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json;odata=verbose',
    ...additionalHeaders
  };
  
  // Add form digest for write operations
  if (formDigest && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method.toUpperCase())) {
    headers['X-RequestDigest'] = formDigest;
  }
  
  // Add default content type for JSON operations
  if (['POST', 'PUT', 'PATCH'].includes(method.toUpperCase()) && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json;odata=verbose';
  }
  
  return headers;
}

/**
 * Example: Upload attachment with proper error handling
 */
export async function uploadAttachment(
  siteUrl: string,
  listTitle: string,
  itemId: number,
  fileName: string,
  fileContent: string | Buffer,
  token: string,
  formDigest: string
): Promise<SharePointAttachment> {
  const url = `${siteUrl}/_api/web/lists/getbytitle('${encodeURIComponent(listTitle)}')/items(${itemId})/AttachmentFiles/add(FileName='${encodeURIComponent(fileName)}')`;
  
  const headers = buildSharePointHeaders('POST', token, formDigest, {
    'Content-Type': 'application/octet-stream'
  });
  
  const body = prepareFileContent(fileContent, typeof fileContent === 'string');
  
  const response = await fetch(url, {
    method: 'POST',
    headers,
    body
  });
  
  if (!response.ok) {
    const errorText = await response.text();
    const errorMessage = await parseSharePointError(response, errorText);
    throw new Error(`Failed to upload attachment: ${errorMessage}`);
  }
  
  const result = await response.json();
  return result.d;
}