# Backend Setup Guide

## Prerequisites

- Python 3.10+
- PostgreSQL 14+
- Redis (optional, for Celery)

## Installation

### 1. Clone & Setup Virtual Environment

```bash
cd backend

# Create venv (use .venv as per user preference)
python -m venv .venv

# Activate
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```env
# Django
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# Database PostgreSQL
DB_NAME=martabak_terangbulan
DB_USER=postgres
DB_PASSWORD=your-db-password
DB_HOST=localhost
DB_PORT=5432

# Redis / Celery
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# GoQris Payment
GOQRIS_API_BASE=https://api.goqris.web.id
GOQRIS_API_KEY=GO_your-api-key
```

### 3. Setup PostgreSQL Database

```sql
-- Create database
CREATE DATABASE martabak_terangbulan;

-- Create user (optional)
CREATE USER postgres WITH PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE martabak_terangbulan TO postgres;
```

### 4. Run Migrations

```bash
.venv\Scripts\python manage.py migrate
```

### 5. Seed Initial Data

```bash
.venv\Scripts\python manage.py seed_data
```

This creates:
- 1 Owner (username: `owner`, PIN: `000000`)
- 2 Kasir (username: `Budi` & `Andi`, PIN: `1234`)
- 10 Menu items
- Default settings

### 6. Run Development Server

```bash
.venv\Scripts\python manage.py runserver
```

API available at: `http://localhost:8000/api/v1/`

## Running with Celery (Background Tasks)

### Start Redis (if not running)

```bash
redis-server
```

### Start Celery Worker

```bash
.venv\Scripts\celery -A config worker -l info
```

## Project Structure

```
backend/
├── config/
│   ├── __init__.py
│   ├── base.py          # Base settings
│   ├── dev.py           # Development config
│   ├── prod.py          # Production config
│   ├── celery.py        # Celery config
│   ├── urls.py          # URL routing
│   └── wsgi.py          # WSGI entry point
├── apps/
│   ├── accounts/        # User auth
│   ├── menus/           # Menu management
│   ├── orders/          # Orders
│   ├── goqris/          # Payment
│   ├── reports/         # Reports
│   ├── raw_materials/   # Profit tracking (cost entries)
│   └── settings_app/    # Settings
├── core/
│   ├── middleware.py    # Request logging
│   ├── permissions.py   # Custom permissions
│   ├── exceptions.py    # Exception handler
│   └── pagination.py    # Pagination
├── .env                 # Environment variables
└── requirements.txt    # Dependencies
```

## Troubleshooting

### Error: `relation does not exist`

Run migrations:
```bash
python manage.py migrate
```

### Error: `permission denied for database`

Grant database permissions to PostgreSQL user.

### Error: `Redis connection refused`

Start Redis server:
```bash
redis-server
```

## GoQris Configuration

### 1. Register at GoQris
1. Daftar di https://goqris.web.id
2. Dapatkan API key dari menu Pengaturan

### 2. Set Environment Variable
Tambahkan ke `.env`:
```env
GOQRIS_API_KEY=GO_your_api_key
```

### 3. Set Project Name via API
```bash
# Login as owner
POST /api/v1/accounts/pin/
{"username": "owner", "pin": "000000"}

# Set project name (use token from login response)
PATCH /api/v1/settings/
Authorization: Bearer <token>
{"goqris_project_name": "Nama Toko Anda"}
```

### 4. Verify GoQris Status
```bash
GET /api/v1/goqris/profile/
Authorization: Bearer <token>
```

Response:
```json
{
    "status": "active",
    "data": {
        "name": "John Doe",
        "plan": "Free Plan",
        "usage": 1,
        "limit": 5
    }
}
```

### Notes
- Free Plan: 5 transaksi/hari
- QR string muncul saat scan QRIS akan menampilkan project name yang sudah diset

## Related

- [API Endpoints](api-endpoints.md)
- [Data Models](models.md)
