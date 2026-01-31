# GitHub Repository Setup Script
# This script will create a GitHub repository and push your code

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   GitHub Repository Setup                                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check for GitHub token
Write-Host "Step 1: Checking for GitHub authentication..." -ForegroundColor Yellow
$githubToken = $env:GITHUB_TOKEN

if (-not $githubToken) {
    Write-Host "  ⚠️  GitHub token not found in environment" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  You need a GitHub Personal Access Token to create a repository." -ForegroundColor Cyan
    Write-Host "  Get one from: https://github.com/settings/tokens" -ForegroundColor White
    Write-Host ""
    Write-Host "  Required permissions:" -ForegroundColor Yellow
    Write-Host "    - repo - Full control of private repositories" -ForegroundColor White
    Write-Host ""
    $githubToken = Read-Host "  Enter your GitHub Personal Access Token"
    if (-not $githubToken) {
        Write-Host "  ❌ Token is required. Exiting." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✅ GitHub token found in environment" -ForegroundColor Green
}
Write-Host ""

# Step 2: Get GitHub username
Write-Host "Step 2: Getting GitHub username..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $githubToken"
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "FlexaVolt-Deployment"
}

try {
    $userResponse = Invoke-RestMethod -Uri "https://api.github.com/user" -Method Get -Headers $headers
    $githubUsername = $userResponse.login
    Write-Host "  ✅ Authenticated as: $githubUsername" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Authentication failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorMsg = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "  Details: $($errorMsg.message)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Please check your GitHub token and try again." -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Step 3: Check if repository already exists
Write-Host "Step 3: Checking if repository exists..." -ForegroundColor Yellow
$repoName = "flexavolt-mes-starter2"
$repoFullName = "$githubUsername/$repoName"

try {
    $repoResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoFullName" -Method Get -Headers $headers -ErrorAction SilentlyContinue
    Write-Host "  ⚠️  Repository already exists: $repoFullName" -ForegroundColor Yellow
    Write-Host "  Using existing repository..." -ForegroundColor Yellow
    $repoExists = $true
} catch {
    Write-Host "  Repository does not exist. Will create it..." -ForegroundColor Green
    $repoExists = $false
}
Write-Host ""

# Step 4: Create repository if it doesn't exist
if (-not $repoExists) {
    Write-Host "Step 4: Creating GitHub repository..." -ForegroundColor Yellow
    $repoData = @{
        name = $repoName
        description = "FlexaVolt MES Starter Kit - Manufacturing Execution System"
        private = $false
        auto_init = $false
    } | ConvertTo-Json

    try {
        $newRepo = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $repoData
        Write-Host "  ✅ Repository created: $repoFullName" -ForegroundColor Green
        Write-Host "  URL: $($newRepo.html_url)" -ForegroundColor Cyan
    } catch {
        Write-Host "  ❌ Failed to create repository!" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            $errorMsg = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "  Details: $($errorMsg.message)" -ForegroundColor Red
        }
        exit 1
    }
    Write-Host ""
} else {
    Write-Host "Step 4: Using existing repository..." -ForegroundColor Yellow
    Write-Host ""
}

# Step 5: Check if git remote is already set
Write-Host "Step 5: Setting up Git remote..." -ForegroundColor Yellow
$currentRemote = git remote get-url origin 2>$null

if ($currentRemote) {
    Write-Host "  Remote already exists: $currentRemote" -ForegroundColor Yellow
    $updateRemote = Read-Host "  Update to new repository? [y/n]"
    if ($updateRemote -eq "y") {
        git remote set-url origin "https://$githubToken@github.com/$repoFullName.git"
        Write-Host "  ✅ Remote updated" -ForegroundColor Green
    } else {
        Write-Host "  Keeping existing remote" -ForegroundColor Yellow
    }
} else {
    git remote add origin "https://$githubToken@github.com/$repoFullName.git"
    Write-Host "  ✅ Remote added" -ForegroundColor Green
}
Write-Host ""

# Step 6: Push code to GitHub
Write-Host "Step 6: Pushing code to GitHub..." -ForegroundColor Yellow
try {
    # Ensure we're on main branch
    $currentBranch = git branch --show-current
    if ($currentBranch -ne "main") {
        git branch -M main
        Write-Host "  Renamed branch to 'main'" -ForegroundColor Yellow
    }

    Write-Host "  Pushing to GitHub..." -ForegroundColor Cyan
    git push -u origin main 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    Write-Host ""
    Write-Host "  ✅ Code pushed successfully!" -ForegroundColor Green
    Write-Host "  Repository: https://github.com/$repoFullName" -ForegroundColor Cyan
} catch {
    Write-Host "  ❌ Failed to push code!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  You may need to push manually:" -ForegroundColor Yellow
    Write-Host "    git push -u origin main" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ GitHub Setup Complete!                               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Repository: https://github.com/$repoFullName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Deploy to DigitalOcean" -ForegroundColor Yellow
Write-Host "  Run: .\setup-and-deploy.ps1" -ForegroundColor White
Write-Host ""
