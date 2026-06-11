# ============================================
# Frontend Dockerfile - React + Vite + Nginx
# ============================================
# Multi-stage build: compile React, then serve static files with Nginx
# Final image is tiny (~25MB) and production-ready

# ---------- Stage 1: Build ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./
RUN npm install

# Copy source and build
COPY . .
RUN npm run build

# ---------- Stage 2: Serve ----------
FROM nginx:alpine

# Copy built static files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx config (proxies /api to backend)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
