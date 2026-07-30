# Deployment Guide

## Prerequisites

- VPS with Ubuntu 22.04
- Domain/subdomain pointed to VPS IP
- GoQris account and API key

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Mobile    │────▶│   Nginx     │────▶│  Gunicorn   │
│   App       │     │   (SSL)     │     │  (Django)   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │  PostgreSQL │
                                        └─────────────┘
```

## Step 1: Server Setup

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Install Dependencies
```bash
# PostgreSQL
sudo apt install postgresql postgresql-contrib

# Python & pip
sudo apt install python3 python3-pip python3-venv

# Redis (for Celery)
sudo apt install redis-server

# Nginx
sudo apt install nginx

# Certbot for SSL
sudo apt install certbot python3-certbot-nginx
```

## Step 2: Database Setup

### Create PostgreSQL Database
```bash
sudo -u postgres psql

CREATE DATABASE martabak_db;
CREATE USER martabak_user WITH PASSWORD 'your-strong-password';
GRANT ALL PRIVILEGES ON DATABASE martabak_db TO martabak_user;
\q
```

## Step 3: Application Setup

### Create Application User
```bash
sudo useradd -m -s /bin/bash martabak
sudo mkdir -p /var/www/martabak
sudo chown martabak:martabak /var/www/martabak
```

### Upload Code
```bash
# Clone or upload your code to /var/www/martabak/
cd /var/www/martabak

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Configure Environment
Create `/var/www/martabak/.env`:
```env
DJANGO_SECRET_KEY=your-production-secret-key
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=your-domain.com

DB_NAME=martabak_db
DB_USER=martabak_user
DB_PASSWORD=your-db-password
DB_HOST=localhost
DB_PORT=5432

REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

GOQRIS_API_BASE=https://api.goqris.web.id
GOQRIS_API_KEY=GO_your-api-key
```

### Run Migrations
```bash
source .venv/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py seed_data
```

## Step 4: Gunicorn Setup

### Create systemd service
Create `/etc/systemd/system/martabak.service`:
```ini
[Unit]
Description=Martabak Gunicorn
After=network.target

[Service]
User=martabak
Group=www-data
WorkingDirectory=/var/www/martabak
Environment="PATH=/var/www/martabak/.venv/bin"
ExecStart=/var/www/martabak/.venv/bin/gunicorn \
    --workers 3 \
    --bind unix:/var/www/martabak/martabak.sock \
    config.wsgi:application

[Install]
WantedBy=multi-user.target
```

### Start Gunicorn
```bash
sudo systemctl daemon-reload
sudo systemctl start martabak
sudo systemctl enable martabak
```

## Step 5: Celery Setup

### Create Celery systemd service
Create `/etc/systemd/system/martabak-celery.service`:
```ini
[Unit]
Description=Martabak Celery
After=network.target redis-server.target

[Service]
User=martabak
Group=www-data
WorkingDirectory=/var/www/martabak
Environment="PATH=/var/www/martabak/.venv/bin"
ExecStart=/var/www/martabak/.venv/bin/celery -A config worker -l info

[Install]
WantedBy=multi-user.target
```

### Start Celery
```bash
sudo systemctl daemon-reload
sudo systemctl start martabak-celery
sudo systemctl enable martabak-celery
```

## Step 6: Nginx Configuration

Create `/etc/nginx/sites-available/martabak`:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/martabak/martabak.sock;
    }

    location /static/ {
        alias /var/www/martabak/staticfiles/;
    }
}
```

### Enable site
```bash
sudo ln -s /etc/nginx/sites-available/martabak /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl reload nginx
```

## Step 7: SSL Certificate

```bash
sudo certbot --nginx -d your-domain.com
```

## Step 8: Verify Deployment

```bash
# Check services
sudo systemctl status martabak
sudo systemctl status martabak-celery
sudo systemctl status nginx

# Test API
curl https://your-domain.com/api/v1/health/
```

## Maintenance

### Update Application
```bash
cd /var/www/martabak
git pull
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart martabak
sudo systemctl restart martabak-celery
```

### Backup Database
```bash
pg_dump -U martabak_user martabak_db > backup_$(date +%Y%m%d).sql
```

### View Logs
```bash
# Gunicorn logs
sudo journalctl -u martabak -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Related

- [Backend Setup](../backend/setup.md)
- [API Endpoints](../backend/api-endpoints.md)
