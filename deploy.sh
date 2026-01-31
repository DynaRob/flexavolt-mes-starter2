#!/bin/bash

# DigitalOcean Deployment Script
# This script helps deploy the FlexaVolt MES application to DigitalOcean

set -e

echo "🚀 FlexaVolt MES Deployment Script"
echo "===================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "Creating .env from template..."
    cat > .env << EOF
# Node Environment
NODE_ENV=production

# Server Configuration
PORT=8080
BASE_URL=https://your-app.ondigitalocean.app

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Security Tokens
FIXTURE_TOKEN=$(openssl rand -hex 32)
PRINT_AGENT_TOKEN=$(openssl rand -hex 32)

# Print Agent Configuration
PRINT_AGENT_ID=AGENT01
EOF
    echo "✅ Created .env file. Please edit it with your actual values!"
    echo ""
    read -p "Press enter after you've updated .env with your values..."
fi

# Check if doctl is installed
if ! command -v doctl &> /dev/null; then
    echo "⚠️  doctl (DigitalOcean CLI) not found."
    echo "Install it from: https://github.com/digitalocean/doctl/releases"
    echo ""
    echo "Or deploy via the web console at: https://cloud.digitalocean.com/apps"
    exit 1
fi

# Check if authenticated
if ! doctl auth list &> /dev/null; then
    echo "🔐 Please authenticate with DigitalOcean:"
    doctl auth init
fi

# Deploy using app.yaml
echo "📦 Deploying to DigitalOcean App Platform..."
echo ""

if [ -f .do/app.yaml ]; then
    echo "Using .do/app.yaml configuration..."
    doctl apps create --spec .do/app.yaml
    echo ""
    echo "✅ Deployment initiated!"
    echo "Check your app status at: https://cloud.digitalocean.com/apps"
else
    echo "❌ .do/app.yaml not found!"
    exit 1
fi
