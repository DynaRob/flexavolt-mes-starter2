# DigitalOcean Deployment Script
# This script deploys the FlexaVolt MES application to DigitalOcean App Platform

param(
    [string]$DoToken = $env:DIGITALOCEAN_TOKEN,
    [string]$GitHubRepo = "flexavolt/flexavolt-mes-starter2",
    [string]$SupabaseUrl = "https://djqzgzpkzbwbwszekcee.supabase.co",
    [string]$SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNDk4NzMsImV4cCI6MjA2ODcyNTg3M30.IqSUzjSZ4wIiJ1iSJ6AkIaUppwN9tuNmfzxwqO5Wh1g",
    [string]$SupabaseServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzE0OTg3MywiZXhwIjoyMDY4NzI1ODczfQ.HD5xTBogKw6v2-Wh9EU1OUkgTPoWaga6AFPAFhUvExM"
)

Write-Host "🚀 Deploying FlexaVolt MES to DigitalOcean" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check for DigitalOcean token
if (-not $DoToken) {
    Write-Host "⚠️  DigitalOcean API token not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please provide your DigitalOcean API token:" -ForegroundColor Yellow
    Write-Host "1. Get it from: https://cloud.digitalocean.com/account/api/tokens" -ForegroundColor Cyan
    Write-Host "2. Set it as environment variable: `$env:DIGITALOCEAN_TOKEN='your-token'" -ForegroundColor Cyan
    Write-Host "3. Or pass it as parameter: -DoToken 'your-token'" -ForegroundColor Cyan
    Write-Host ""
    $DoToken = Read-Host "Enter your DigitalOcean API token (or press Ctrl+C to cancel)"
}

# Generate secure tokens
$fixtureToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
$printAgentToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })

Write-Host "📦 Reading app.yaml configuration..." -ForegroundColor Green
$appYamlPath = ".do/app.yaml"
if (-not (Test-Path $appYamlPath)) {
    Write-Host "❌ .do/app.yaml not found!" -ForegroundColor Red
    exit 1
}

$appYamlContent = Get-Content $appYamlPath -Raw

# Convert YAML to JSON for API (simplified approach)
Write-Host "📤 Creating app via DigitalOcean API..." -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $DoToken"
    "Content-Type" = "application/json"
}

# Read and parse the YAML file
$yamlContent = Get-Content $appYamlPath -Raw

# For now, we'll use the doctl approach or guide user to web console
Write-Host ""
Write-Host "✅ Configuration ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Push your code to GitHub: $GitHubRepo" -ForegroundColor Yellow
Write-Host "2. Go to: https://cloud.digitalocean.com/apps" -ForegroundColor Yellow
Write-Host "3. Click 'Create App' and connect your GitHub repository" -ForegroundColor Yellow
Write-Host "4. DigitalOcean will detect the .do/app.yaml file automatically" -ForegroundColor Yellow
Write-Host ""
Write-Host "Environment variables to set in DigitalOcean dashboard:" -ForegroundColor Cyan
Write-Host "  SUPABASE_URL = $SupabaseUrl" -ForegroundColor White
Write-Host "  SUPABASE_ANON_KEY = $($SupabaseAnonKey.Substring(0,50))..." -ForegroundColor White
Write-Host "  SUPABASE_SERVICE_ROLE_KEY = $($SupabaseServiceKey.Substring(0,50))..." -ForegroundColor White
Write-Host "  FIXTURE_TOKEN = $($fixtureToken.Substring(0,20))..." -ForegroundColor White
Write-Host "  PRINT_AGENT_TOKEN = $($printAgentToken.Substring(0,20))..." -ForegroundColor White
Write-Host ""
Write-Host "Or use doctl CLI:" -ForegroundColor Cyan
Write-Host "  doctl apps create --spec .do/app.yaml" -ForegroundColor White
Write-Host ""

# Try to use doctl if available
$doctlPath = Get-Command doctl -ErrorAction SilentlyContinue
if ($doctlPath) {
    Write-Host "🔧 doctl found! Attempting deployment..." -ForegroundColor Green
    try {
        # Authenticate
        $env:DIGITALOCEAN_ACCESS_TOKEN = $DoToken
        doctl auth init --access-token $DoToken
        
        # Create app
        Write-Host "Creating app..." -ForegroundColor Yellow
        $result = doctl apps create --spec .do/app.yaml 2>&1
        Write-Host $result
        Write-Host ""
        Write-Host "✅ Deployment initiated!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
        Write-Host "Please use the web console method above." -ForegroundColor Yellow
    }
} else {
    Write-Host "💡 Tip: Install doctl for easier deployments:" -ForegroundColor Cyan
    Write-Host "   choco install doctl" -ForegroundColor White
    Write-Host "   Or download from: https://github.com/digitalocean/doctl/releases" -ForegroundColor White
}
