# Quick Deployment Guide

## ✅ What's Ready

- ✅ DigitalOcean API token configured
- ✅ Supabase credentials configured  
- ✅ All deployment files created
- ✅ Code committed to local Git

## 🚀 Deploy Now (Easiest Method)

### Option 1: Web Console (Recommended - No GitHub needed initially)

1. **Go to DigitalOcean App Platform:**
   https://cloud.digitalocean.com/apps

2. **Click "Create App"**

3. **Choose "GitHub" as source:**
   - Click "GitHub" 
   - Authorize DigitalOcean to access your GitHub
   - If you don't have a GitHub repo yet, you can create one during this process

4. **Create GitHub Repository (if needed):**
   - Click "Create New Repository"
   - Name: `flexavolt-mes-starter2`
   - Make it private or public (your choice)
   - Click "Create"

5. **Or select existing repository:**
   - If you already have the repo, select it
   - Select branch: `main`

6. **DigitalOcean will detect `.do/app.yaml`:**
   - It should automatically load the configuration
   - Review the settings

7. **Set Environment Variables:**
   In the "Environment Variables" section, add these as SECRETS:
   - `SUPABASE_URL` = `https://djqzgzpkzbwbwszekcee.supabase.co`
   - `SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNDk4NzMsImV4cCI6MjA2ODcyNTg3M30.IqSUzjSZ4wIiJ1iSJ6AkIaUppwN9tuNmfzxwqO5Wh1g`
   - `SUPABASE_SERVICE_ROLE_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcXpnenBremJ3YndzemVrY2VlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzE0OTg3MywiZXhwIjoyMDY4NzI1ODczfQ.HD5xTBogKw6v2-Wh9EU1OUkgTPoWaga6AFPAFhUvExM`
   - `FIXTURE_TOKEN` = (generate random secure string)
   - `PRINT_AGENT_TOKEN` = (generate random secure string)

8. **Deploy:**
   - Click "Create Resources"
   - Wait 5-10 minutes for first deployment

### Option 2: Set Up GitHub First, Then Deploy

If you prefer to set up GitHub first:

```powershell
# 1. Create GitHub repository (via web or GitHub CLI)
#    Go to: https://github.com/new
#    Name: flexavolt-mes-starter2

# 2. Add remote and push
cd D:\FLEXA_BUILD\flexavolt-mes-starter2
git remote add origin https://github.com/YOUR_USERNAME/flexavolt-mes-starter2.git
git branch -M main
git push -u origin main

# 3. Then run deployment script
.\setup-and-deploy.ps1
```

## 📋 Environment Variables Reference

All these are already configured in the deployment scripts:

| Variable | Value | Type |
|----------|-------|------|
| `SUPABASE_URL` | `https://djqzgzpkzbwbwszekcee.supabase.co` | SECRET |
| `SUPABASE_ANON_KEY` | (configured) | SECRET |
| `SUPABASE_SERVICE_ROLE_KEY` | (configured) | SECRET |
| `FIXTURE_TOKEN` | (auto-generated) | SECRET |
| `PRINT_AGENT_TOKEN` | (auto-generated) | SECRET |
| `BASE_URL` | (auto-set by DO) | GENERAL |

## ⚡ Fastest Path

**Just go to:** https://cloud.digitalocean.com/apps
- Click "Create App"
- Connect GitHub (or create repo during setup)
- DigitalOcean will auto-detect `.do/app.yaml`
- Add environment variables
- Deploy!

The web console is the easiest because it handles GitHub connection automatically.
