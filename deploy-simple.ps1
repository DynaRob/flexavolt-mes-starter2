# Get tokens from environment variables
$doToken = $env:DIGITALOCEAN_TOKEN
$githubRepo = $env:GITHUB_REPO ?? "DynaRob/flexavolt-mes-starter2"
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
                build_command = "npm install; npm run build"
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
                    repo = $githubRepo
                    branch = "main"
                    deploy_on_push = $true
                }
                source_dir = "/"
                build_command = "npm install; npm run build"
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

Write-Host "Deploying to DigitalOcean..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/apps" -Method Post -Headers $headers -Body $jsonSpec
    Write-Host "SUCCESS! App ID: $($response.app.id)" -ForegroundColor Green
    Write-Host "Monitor at: https://cloud.digitalocean.com/apps/$($response.app.id)" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}
