# Complete Setup: GitHub + DigitalOcean Deployment
# This script sets up GitHub repository and deploys to DigitalOcean

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Complete Setup: GitHub + DigitalOcean                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check for GitHub token
$githubToken = $env:GITHUB_TOKEN
if (-not $githubToken) {
    Write-Host "GitHub Personal Access Token required" -ForegroundColor Yellow
    Write-Host "Get one from: https://github.com/settings/tokens" -ForegroundColor Cyan
    Write-Host "Required scope: 'repo' - Full control of private repositories" -ForegroundColor Yellow
    Write-Host ""
    $githubToken = Read-Host "Enter your GitHub Personal Access Token"
    if (-not $githubToken) {
        Write-Host "GitHub token is required. Exiting." -ForegroundColor Red
        exit 1
    }
    $env:GITHUB_TOKEN = $githubToken
}

# Run GitHub setup
Write-Host ""
Write-Host "=== Setting up GitHub ===" -ForegroundColor Cyan
& ".\setup-github.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub setup failed. Please fix the issue and try again." -ForegroundColor Red
    exit 1
}

# Run DigitalOcean deployment
Write-Host ""
Write-Host "=== Deploying to DigitalOcean ===" -ForegroundColor Cyan
& ".\setup-and-deploy.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Complete Setup Successful!                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
