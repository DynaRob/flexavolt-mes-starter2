# DigitalOcean Deployment Guide

This guide covers deploying the FlexaVolt MES application to DigitalOcean App Platform.

## Prerequisites

1. **DigitalOcean Account**: Sign up at [digitalocean.com](https://www.digitalocean.com)
2. **GitHub Repository**: Push your code to GitHub
3. **Supabase Project**: Set up your Supabase project and run migrations
4. **DigitalOcean CLI** (optional): Install `doctl` for command-line deployment

## Option 1: Deploy via DigitalOcean App Platform (Recommended)

### Step 1: Prepare Your Repository

1. Update `.do/app.yaml`:
   - Replace `YOUR_GITHUB_USERNAME/flexavolt-mes-starter2` with your actual GitHub repository
   - Adjust the `region` if needed (default: `nyc`)

2. Push your code to GitHub:
   ```bash
   git add .
   git commit -m "Add DigitalOcean deployment configuration"
   git push origin main
   ```

### Step 2: Create App on DigitalOcean

#### Via Web Console:

1. Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
2. Click **Create App**
3. Connect your GitHub account and select your repository
4. DigitalOcean will detect the `.do/app.yaml` file automatically
5. Review the configuration and click **Next**

#### Via CLI:

```bash
# Install doctl if you haven't already
# Windows: choco install doctl
# Or download from: https://github.com/digitalocean/doctl/releases

# Authenticate
doctl auth init

# Create the app
doctl apps create --spec .do/app.yaml
```

### Step 3: Configure Environment Variables

In the DigitalOcean App Platform dashboard:

1. Go to your app → **Settings** → **App-Level Environment Variables**
2. Add the following **SECRET** variables:
   - `SUPABASE_URL` - Your Supabase project URL
   - `SUPABASE_ANON_KEY` - Your Supabase anonymous key
   - `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service role key (keep this secret!)
   - `FIXTURE_TOKEN` - Generate a secure random token
   - `PRINT_AGENT_TOKEN` - Generate a secure random token

3. Add the following **APP-LEVEL** variable:
   - `BASE_URL` - Your app's public URL (will be set automatically after first deploy, or set manually like `https://your-app.ondigitalocean.app`)

### Step 4: Deploy

1. If using web console, click **Create Resources** or **Deploy**
2. Wait for the build and deployment to complete (usually 5-10 minutes)
3. Your app will be available at `https://your-app-name.ondigitalocean.app`

### Step 5: Verify Deployment

1. Check health endpoint: `https://your-app-name.ondigitalocean.app/health`
2. Test API endpoints as needed
3. Monitor logs in the DigitalOcean dashboard

## Option 2: Deploy via Docker on DigitalOcean Droplet

If you prefer more control, you can deploy using Docker on a Droplet.

### Step 1: Create a Droplet

1. Create a new Droplet (Ubuntu 22.04 recommended)
2. Choose size based on your needs (minimum 1GB RAM recommended)
3. Add SSH keys for secure access

### Step 2: Set Up the Server

SSH into your Droplet:

```bash
ssh root@your-droplet-ip
```

Install Docker and Docker Compose:

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

### Step 3: Clone and Configure

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/flexavolt-mes-starter2.git
cd flexavolt-mes-starter2

# Create .env file
cp .env.example .env
nano .env  # Edit with your actual values
```

### Step 4: Deploy with Docker Compose

```bash
# Build and start services
docker compose --env-file .env up -d --build

# Check status
docker compose ps

# View logs
docker compose logs -f mes-api
```

### Step 5: Set Up Nginx Reverse Proxy (Optional but Recommended)

Install Nginx:

```bash
apt install nginx -y
```

Create Nginx configuration:

```bash
nano /etc/nginx/sites-available/mes-api
```

Add configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
ln -s /etc/nginx/sites-available/mes-api /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### Step 6: Set Up SSL with Let's Encrypt

```bash
apt install certbot python3-certbot-nginx -y
certbot --nginx -d your-domain.com
```

## Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `NODE_ENV` | No | Environment mode | `production` |
| `PORT` | No | Server port (default: 8080) | `8080` |
| `BASE_URL` | Yes | Public URL of your API | `https://api.example.com` |
| `SUPABASE_URL` | Yes | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous key | `eyJ...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Supabase service role key | `eyJ...` |
| `FIXTURE_TOKEN` | Yes | Token for fixture authentication | Random secure string |
| `PRINT_AGENT_TOKEN` | Yes | Token for print agent authentication | Random secure string |
| `PRINT_AGENT_ID` | No | Print agent identifier (default: AGENT01) | `AGENT01` |

## Generating Secure Tokens

You can generate secure random tokens using:

```bash
# Linux/Mac
openssl rand -hex 32

# PowerShell (Windows)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

## Monitoring and Logs

### App Platform:
- View logs in the DigitalOcean dashboard under your app → **Runtime Logs**
- Set up alerts in **Settings** → **Alerts**

### Docker Deployment:
```bash
# View logs
docker compose logs -f mes-api
docker compose logs -f print-agent

# Restart services
docker compose restart mes-api

# Update deployment
git pull
docker compose up -d --build
```

## Troubleshooting

### App Platform Issues:

1. **Build fails**: Check build logs in the dashboard
2. **App won't start**: Verify all environment variables are set correctly
3. **Health check fails**: Ensure `/health` endpoint is accessible

### Docker Issues:

1. **Port already in use**: Change port in `docker-compose.yml` or stop conflicting service
2. **Environment variables not loading**: Ensure `.env` file exists and has correct format
3. **Connection to Supabase fails**: Verify `SUPABASE_URL` and keys are correct

## Cost Estimation

### App Platform:
- **Basic plan**: ~$5/month for basic-xxs instance
- **Standard plan**: ~$12/month for basic-xs instance
- Additional costs for managed databases if used

### Droplet:
- **Basic Droplet**: $4-6/month for 1GB RAM
- **Standard Droplet**: $12/month for 2GB RAM
- More cost-effective for multiple services

## Next Steps

1. Set up monitoring and alerts
2. Configure custom domain
3. Set up CI/CD for automatic deployments
4. Configure database backups (if using managed database)
5. Set up staging environment

## Support

For issues specific to:
- **DigitalOcean**: [DigitalOcean Documentation](https://docs.digitalocean.com/)
- **App Platform**: [App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- **This Application**: Check the main README.md
