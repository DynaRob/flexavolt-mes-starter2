# Direct DigitalOcean API Deployment Script
# Deploys using DigitalOcean REST API

param(
    [Parameter(Mandatory=$true)]
    [string]$DoToken,
    [string]$GitHubRepo = "flexavolt/flexavolt-mes-starter2"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying to DigitalOcean App Platform" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Supabase credentials (from TRACS firmware)
$supabaseUrl = "https://djqzgzpkzbwbwszekcee.supabase.co"
$supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNDk4NzMsImV4cCI6MjA2ODcyNTg3M30.IqSUzjSZ4wIiJ1iSJ6AkIaUppwN9tuNmfzxwqO5Wh1g"
$supabaseServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzE0OTg3MywiZXhwIjoyMDY4NzI1ODczfQ.HD5xTBogKw6v2-Wh9EU1OUkgTPoWaga6AFPAFhUvExM"

# Generate secure tokens
$fixtureToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
$printAgentToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })

Write-Host "📖 Reading app.yaml..." -ForegroundColor Green
$appYaml = Get-Content ".do/app.yaml" -Raw

# Parse GitHub repo
$repoParts = $GitHubRepo -split "/"
$githubOwner = $repoParts[0]
$githubRepo = $repoParts[1]

Write-Host "📦 Building app spec..." -ForegroundColor Green

# Build the app spec JSON
$appSpec = @{
    name = "flexavolt-mes"
    region = "nyc"
    services = @(
        @{
            name = "mes-api"
            github = @{
                repo = $GitHubRepo
                branch = "main"
                deploy_on_push = $true
            }
            source_dir = "/"
            build_command = "npm install && npm run build"
            run_command = "npm --workspace packages/mes-api run start"
            environment_slug = "node-js"
            instance_count = 1
            instance_size_slug = "basic-xxs"
            http_port = 8080
            health_check = @{
                http_path = "/health"
            }
            envs = @(
                @{ key = "NODE_ENV"; value = "production" },
                @{ key = "PORT"; value = "8080" },
                @{ key = "BASE_URL"; scope = "RUN_AND_BUILD_TIME"; type = "APP_LEVEL" },
                @{ key = "SUPABASE_URL"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $supabaseUrl },
                @{ key = "SUPABASE_ANON_KEY"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $supabaseAnonKey },
                @{ key = "SUPABASE_SERVICE_ROLE_KEY"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $supabaseServiceKey },
                @{ key = "FIXTURE_TOKEN"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $fixtureToken },
                @{ key = "PRINT_AGENT_TOKEN"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $printAgentToken }
            )
        }
    )
    workers = @(
        @{
            name = "print-agent"
            github = @{
                repo = $GitHubRepo
                branch = "main"
                deploy_on_push = $true
            }
            source_dir = "/"
            build_command = "npm install && npm run build"
            run_command = "npm --workspace packages/print-agent run start"
            environment_slug = "node-js"
            instance_count = 1
            instance_size_slug = "basic-xxs"
            envs = @(
                @{ key = "BASE_URL"; scope = "RUN_AND_BUILD_TIME"; type = "APP_LEVEL" },
                @{ key = "PRINT_AGENT_ID"; value = "AGENT01" },
                @{ key = "PRINT_AGENT_TOKEN"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $printAgentToken }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Write-Host "📤 Creating app on DigitalOcean..." -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $DoToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/apps" -Method Post -Headers $headers -Body $appSpec
    
    Write-Host ""
    Write-Host "✅ App created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "App ID: $($response.app.id)" -ForegroundColor Cyan
    Write-Host "App URL: https://cloud.digitalocean.com/apps/$($response.app.id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The app will be deployed automatically from your GitHub repository." -ForegroundColor Yellow
    Write-Host "Monitor progress at: https://cloud.digitalocean.com/apps/$($response.app.id)" -ForegroundColor Yellow
    
} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "1. Invalid API token" -ForegroundColor White
    Write-Host "2. GitHub repository not accessible" -ForegroundColor White
    Write-Host "3. Repository doesn't exist or is private" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Deploy via web console at https://cloud.digitalocean.com/apps" -ForegroundColor Cyan
    exit 1
}
