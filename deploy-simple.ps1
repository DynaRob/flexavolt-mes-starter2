$doToken = "dop_v1_ada915e563f3d9f8a5ed284a7393443751c988365eb34f276ab0b38c56442fec"
$githubRepo = "DynaRob/flexavolt-mes-starter2"
$supabaseUrl = "https://djqzgzpkzbwbwszekcee.supabase.co"
$supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNDk4NzMsImV4cCI6MjA2ODcyNTg3M30.IqSUzjSZ4wIiJ1iSJ6AkIaUppwN9tuNmfzxwqO5Wh1g"
$supabaseServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzE0OTg3MywiZXhwIjoyMDY4NzI1ODczfQ.HD5xTBogKw6v2-Wh9EU1OUkgTPoWaga6AFPAFhUvExM"
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
