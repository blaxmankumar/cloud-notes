# ============================================
# Backend Dockerfile - Node.js + Express
# ============================================

FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files first (better layer caching)
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy the rest of the app
COPY . .

# Expose the API port
EXPOSE 5000

# Healthcheck - Docker will mark container unhealthy if /health fails
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:5000/health || exit 1

# Start the server
CMD ["node", "server.js"]
