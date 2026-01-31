# Complete DigitalOcean Deployment Script
# This script will deploy your FlexaVolt MES application to DigitalOcean

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   FlexaVolt MES - DigitalOcean Deployment                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check for DigitalOcean API Token
Write-Host "Step 1: Checking for DigitalOcean API Token..." -ForegroundColor Yellow
$doToken = $env:DIGITALOCEAN_TOKEN
if (-not $doToken) {
    Write-Host "  ⚠️  Token not found in environment variables" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please get your DigitalOcean API token from:" -ForegroundColor Cyan
    Write-Host "  https://cloud.digitalocean.com/account/api/tokens" -ForegroundColor White
    Write-Host ""
    $doToken = Read-Host "  Enter your DigitalOcean API token"
    if (-not $doToken) {
        Write-Host "  ❌ Token is required. Exiting." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✅ Token found in environment" -ForegroundColor Green
}
Write-Host ""

# Step 2: Check GitHub repository
Write-Host "Step 2: Checking GitHub repository..." -ForegroundColor Yellow
$githubRepo = "flexavolt/flexavolt-mes-starter2"  # Update this with your actual repo
Write-Host "  Repository: $githubRepo" -ForegroundColor White
Write-Host "  ⚠️  Make sure this repository exists and is accessible" -ForegroundColor Yellow
Write-Host ""

# Step 3: Supabase credentials (from your TRACS firmware)
Write-Host "Step 3: Using Supabase credentials from TRACS firmware..." -ForegroundColor Yellow
$supabaseUrl = "https://djqzgzpkzbwbwszekcee.supabase.co"
$supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNDk4NzMsImV4cCI6MjA2ODcyNTg3M30.IqSUzjSZ4wIiJ1iSJ6AkIaUppwN9tuNmfzxwqO5Wh1g"
$supabaseServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzE0OTg3MywiZXhwIjoyMDY4NzI1ODczfQ.HD5xTBogKw6v2-Wh9EU1OUkgTPoWaga6AFPAFhUvExM"
Write-Host "  ✅ Supabase URL: $supabaseUrl" -ForegroundColor Green
Write-Host ""

# Step 4: Generate secure tokens
Write-Host "Step 4: Generating secure tokens..." -ForegroundColor Yellow
$fixtureToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
$printAgentToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
Write-Host "  ✅ Tokens generated" -ForegroundColor Green
Write-Host ""

# Step 5: Build app specification
Write-Host "Step 5: Building app specification..." -ForegroundColor Yellow

$appSpec = @{
    spec = @{
        name = "flexavolt-mes"
        region = "nyc"
        services = @(
            @{
                name = "mes-api"
                github = @{
                    repo = $githubRepo
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
                    repo = $githubRepo
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
    }
}

$jsonSpec = $appSpec | ConvertTo-Json -Depth 10

# Step 6: Deploy to DigitalOcean
Write-Host "Step 6: Deploying to DigitalOcean..." -ForegroundColor Yellow
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $doToken"
    "Content-Type" = "application/json"
}

try {
    Write-Host "  📤 Sending request to DigitalOcean API..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/apps" -Method Post -Headers $headers -Body $jsonSpec
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   ✅ DEPLOYMENT SUCCESSFUL!                               ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "App Information:" -ForegroundColor Cyan
    Write-Host "  App ID: $($response.app.id)" -ForegroundColor White
    Write-Host "  App Name: $($response.app.spec.name)" -ForegroundColor White
    Write-Host "  Region: $($response.app.spec.region)" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Monitor deployment: https://cloud.digitalocean.com/apps/$($response.app.id)" -ForegroundColor White
    Write-Host "  2. Your app will be available at: https://$($response.app.spec.name)-*.ondigitalocean.app" -ForegroundColor White
    Write-Host "  3. The deployment will start automatically from your GitHub repository" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: First deployment may take 5-10 minutes." -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║   ❌ DEPLOYMENT FAILED                                    ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor White
    
    if ($_.ErrorDetails.Message) {
        try {
            $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host ""
            Write-Host "API Error:" -ForegroundColor Yellow
            Write-Host "  $($errorJson.message)" -ForegroundColor White
            if ($errorJson.errors) {
                foreach ($err in $errorJson.errors) {
                    Write-Host "  - $($err.field): $($err.message)" -ForegroundColor White
                }
            }
        } catch {
            Write-Host "  $($_.ErrorDetails.Message)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify your API token is valid" -ForegroundColor White
    Write-Host "  2. Ensure GitHub repository exists and is accessible" -ForegroundColor White
    Write-Host "  3. Check that the repository is not private (or connect GitHub in DO dashboard)" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Deploy via web console:" -ForegroundColor Cyan
    Write-Host "  https://cloud.digitalocean.com/apps" -ForegroundColor White
    Write-Host ""
    exit 1
}
