#!/bin/bash

# Variables
DOMAIN="deploy-all.app3.in"
APP1_PORT="3001"
APP2_PORT="3002"

# Create Nginx reverse proxy configuration
cat <<EOL > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name $DOMAIN;

    location /app1/ {
        proxy_pass http://localhost:$APP1_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /app2/ {
        proxy_pass http://localhost:$APP2_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Test the Nginx configuration
nginx -t

# Reload Nginx to apply changes
systemctl reload nginx
