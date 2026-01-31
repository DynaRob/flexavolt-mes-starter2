# DigitalOcean Deployment Script for Windows PowerShell
# This script helps deploy the FlexaVolt MES application to DigitalOcean

Write-Host "🚀 FlexaVolt MES Deployment Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "⚠️  .env file not found!" -ForegroundColor Yellow
    Write-Host "Creating .env from template..." -ForegroundColor Yellow
    
    # Generate random tokens
    $fixtureToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
    $printAgentToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
    
    @"
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
FIXTURE_TOKEN=$fixtureToken
PRINT_AGENT_TOKEN=$printAgentToken

# Print Agent Configuration
PRINT_AGENT_ID=AGENT01
"@ | Out-File -FilePath .env -Encoding utf8
    
    Write-Host "✅ Created .env file. Please edit it with your actual values!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press enter after you've updated .env with your values"
}

# Check if doctl is installed
try {
    $null = Get-Command doctl -ErrorAction Stop
} catch {
    Write-Host "⚠️  doctl (DigitalOcean CLI) not found." -ForegroundColor Yellow
    Write-Host "Install it from: https://github.com/digitalocean/doctl/releases" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or deploy via the web console at: https://cloud.digitalocean.com/apps" -ForegroundColor Yellow
    exit 1
}

# Check if authenticated
try {
    $null = doctl auth list 2>&1
} catch {
    Write-Host "🔐 Please authenticate with DigitalOcean:" -ForegroundColor Cyan
    doctl auth init
}

# Deploy using app.yaml
Write-Host "📦 Deploying to DigitalOcean App Platform..." -ForegroundColor Cyan
Write-Host ""

if (Test-Path .do/app.yaml) {
    Write-Host "Using .do/app.yaml configuration..." -ForegroundColor Green
    doctl apps create --spec .do/app.yaml
    Write-Host ""
    Write-Host "✅ Deployment initiated!" -ForegroundColor Green
    Write-Host "Check your app status at: https://cloud.digitalocean.com/apps" -ForegroundColor Cyan
} else {
    Write-Host "❌ .do/app.yaml not found!" -ForegroundColor Red
    exit 1
}
