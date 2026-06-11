#!/bin/bash
# ============================================
# Cloud Notes App - EC2 Setup Script
# ============================================
# Run this on a fresh Ubuntu 22.04 EC2 box to set up everything:
#   - Docker + Compose
#   - Host Nginx
#   - Certbot (Let's Encrypt SSL)
#   - The Cloud Notes app from this repo
#
# Usage:
#   chmod +x deploy/ec2-setup.sh
#   sudo ./deploy/ec2-setup.sh
#
# Prerequisites:
#   - EC2 box with ports 22, 80, 443 open
#   - Route 53 A records pointing aws365.shop AND www.aws365.shop to the EC2 IP
#   - .env file already filled in at the repo root

set -e

DOMAIN="aws365.shop"
WWW_DOMAIN="www.aws365.shop"
EMAIL="info@aws365.shop"   # ← change this before running
APP_DIR="/home/ubuntu/cloud-notes-app"

echo "════════════════════════════════════════════════"
echo "  Cloud Notes EC2 Setup"
echo "  Domain: $WWW_DOMAIN"
echo "════════════════════════════════════════════════"

# ----------------------------------------
# 1. System update
# ----------------------------------------
echo ""
echo "📦 Updating system packages..."
apt update -y && apt upgrade -y

# ----------------------------------------
# 2. Install Docker
# ----------------------------------------
echo ""
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    apt install -y docker.io docker-compose-v2
    systemctl enable --now docker
    usermod -aG docker ubuntu
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# ----------------------------------------
# 3. Install Nginx
# ----------------------------------------
echo ""
echo "🌐 Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl enable --now nginx
    echo "✅ Nginx installed"
else
    echo "✅ Nginx already installed"
fi

# ----------------------------------------
# 4. Install Certbot
# ----------------------------------------
echo ""
echo "🔒 Installing Certbot..."
apt install -y certbot python3-certbot-nginx

# ----------------------------------------
# 5. Start the app containers
# ----------------------------------------
echo ""
echo "🚀 Starting the app..."
cd "$APP_DIR"

if [ ! -f .env ]; then
    echo "❌ No .env file found at $APP_DIR/.env"
    echo "   Copy .env.example to .env and fill in your RDS details first."
    exit 1
fi

docker compose up -d --build

# ----------------------------------------
# 6. Install host Nginx config (HTTP only for now, certbot will add HTTPS)
# ----------------------------------------
echo ""
echo "⚙️  Installing host Nginx config..."

# Temporary HTTP-only config so certbot can validate
cat > /etc/nginx/sites-available/cloudnotes <<EOF
server {
    listen 80;
    server_name $DOMAIN $WWW_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
    }

    location /health {
        proxy_pass http://127.0.0.1:5000/health;
    }
}
EOF

ln -sf /etc/nginx/sites-available/cloudnotes /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ----------------------------------------
# 7. Get SSL certificate
# ----------------------------------------
echo ""
echo "🔐 Requesting SSL certificate from Let's Encrypt..."
certbot --nginx \
    -d "$DOMAIN" \
    -d "$WWW_DOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --redirect

# Replace temp config with the full production one
cp "$APP_DIR/deploy/nginx-host.conf" /etc/nginx/sites-available/cloudnotes
nginx -t && systemctl reload nginx

# ----------------------------------------
# 8. Enable auto-renewal
# ----------------------------------------
echo ""
echo "🔁 Enabling certbot auto-renewal..."
systemctl enable --now certbot.timer

# ----------------------------------------
# Done
# ----------------------------------------
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Setup complete!"
echo "════════════════════════════════════════════════"
echo ""
echo "  Visit: https://$WWW_DOMAIN"
echo ""
echo "  Useful commands:"
echo "    docker compose logs -f             # watch app logs"
echo "    docker compose ps                  # container status"
echo "    sudo nginx -t                      # test nginx config"
echo "    sudo systemctl reload nginx        # apply nginx changes"
echo "    sudo certbot renew --dry-run       # test SSL renewal"
echo ""
