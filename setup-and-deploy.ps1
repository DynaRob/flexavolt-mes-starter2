# Complete setup and deployment script
# This will help set up GitHub and deploy to DigitalOcean

# Get credentials from environment variables
$doToken = $env:DIGITALOCEAN_TOKEN
$supabaseUrl = $env:SUPABASE_URL ?? "https://djqzgzpkzbwbwszekcee.supabase.co"
$supabaseAnonKey = $env:SUPABASE_ANON_KEY
$supabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $doToken) {
    Write-Host "ERROR: DIGITALOCEAN_TOKEN environment variable not set" -ForegroundColor Red
    exit 1
}
if (-not $supabaseAnonKey) {
    Write-Host "ERROR: SUPABASE_ANON_KEY environment variable not set" -ForegroundColor Red
    exit 1
}
if (-not $supabaseServiceKey) {
    Write-Host "ERROR: SUPABASE_SERVICE_ROLE_KEY environment variable not set" -ForegroundColor Red
    exit 1
}
$fixtureToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
$printAgentToken = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })

Write-Host "=== FlexaVolt MES Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub remote exists
Write-Host "Checking Git repository..." -ForegroundColor Yellow
$gitRemote = git remote get-url origin 2>$null
if (-not $gitRemote) {
    Write-Host "  No GitHub remote found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To deploy, you need to:" -ForegroundColor Cyan
    Write-Host "  1. Create a GitHub repository" -ForegroundColor White
    Write-Host "  2. Push this code to GitHub" -ForegroundColor White
    Write-Host "  3. Then run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "OR deploy via web console:" -ForegroundColor Cyan
    Write-Host "  https://cloud.digitalocean.com/apps" -ForegroundColor White
    Write-Host ""
    Write-Host "The web console will let you connect GitHub and deploy directly." -ForegroundColor Yellow
    exit 0
}

# Extract GitHub repo from remote URL
if ($gitRemote -match "github.com[:/]([^/]+)/([^/]+?)(?:\.git)?$") {
    $githubUser = $matches[1]
    $githubRepo = $matches[2]
    $fullRepo = "$githubUser/$githubRepo"
    Write-Host "  Found GitHub repo: $fullRepo" -ForegroundColor Green
} else {
    Write-Host "  Could not parse GitHub repo from: $gitRemote" -ForegroundColor Red
    Write-Host "  Please ensure your remote is set correctly" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Deploying to DigitalOcean..." -ForegroundColor Green

$appSpec = @{
    spec = @{
        name = "flexavolt-mes"
        region = "nyc"
        services = @(
            @{
                name = "mes-api"
                github = @{
                    repo = $fullRepo
                    branch = "main"
                    deploy_on_push = $true
                }
                source_dir = "/"
                build_command = "npm ci && npm run build"
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
                    @{ key = "BASE_URL"; scope = "RUN_AND_BUILD_TIME"; type = "GENERAL" },
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
                    repo = $fullRepo
                    branch = "main"
                    deploy_on_push = $true
                }
                source_dir = "/"
                build_command = "npm ci && npm run build"
                run_command = "npm --workspace packages/print-agent run start"
                environment_slug = "node-js"
                instance_count = 1
                instance_size_slug = "basic-xxs"
                envs = @(
                    @{ key = "BASE_URL"; scope = "RUN_AND_BUILD_TIME"; type = "GENERAL" },
                    @{ key = "PRINT_AGENT_ID"; value = "AGENT01" },
                    @{ key = "PRINT_AGENT_TOKEN"; scope = "RUN_AND_BUILD_TIME"; type = "SECRET"; value = $printAgentToken }
                )
            }
        )
    }
}

$jsonSpec = $appSpec | ConvertTo-Json -Depth 10

$headers = @{
    "Authorization" = "Bearer $doToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/apps" -Method Post -Headers $headers -Body $jsonSpec
    Write-Host ""
    Write-Host "✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "App ID: $($response.app.id)" -ForegroundColor Cyan
    Write-Host "Monitor at: https://cloud.digitalocean.com/apps/$($response.app.id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your app will be available shortly at:" -ForegroundColor Yellow
    Write-Host "  https://flexavolt-mes-*.ondigitalocean.app" -ForegroundColor White
    Write-Host ""
    Write-Host "First deployment takes 5-10 minutes." -ForegroundColor Yellow
} catch {
    Write-Host ""
    Write-Host "❌ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorMsg = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "Details: $($errorMsg.message)" -ForegroundColor Red
        if ($errorMsg.message -like "*GitHub*") {
            Write-Host ""
            Write-Host "GitHub repository issue. Solutions:" -ForegroundColor Yellow
            Write-Host "  1. Make sure the repo exists: $fullRepo" -ForegroundColor White
            Write-Host "  2. Connect GitHub in DigitalOcean dashboard first" -ForegroundColor White
            Write-Host "  3. Or deploy via web console: https://cloud.digitalocean.com/apps" -ForegroundColor White
        }
    }
}
