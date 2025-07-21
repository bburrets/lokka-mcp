# Multi-stage build for optimal image size
FROM node:20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm install --save-dev typescript @types/node

# Copy source code
COPY src/ ./src/

# Build the application
RUN npm run build

# Runtime stage
FROM node:20-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user with a higher UID/GID to avoid conflicts
RUN addgroup -g 1001 lokka && \
    adduser -D -u 1001 -G lokka lokka

# Set working directory
WORKDIR /app

# Copy package files and install production dependencies only
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/build ./build

# Change ownership to non-root user
RUN chown -R lokka:lokka /app

# Switch to non-root user
USER lokka

# Expose MCP server port (adjust if needed)
EXPOSE 3000

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Run the MCP server
CMD ["node", "build/main.js"]