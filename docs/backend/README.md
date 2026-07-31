# Backend Documentation

## Overview

Django 5.x + Django REST Framework backend untuk aplikasi kasir martabak.

## Tech Stack

- **Framework**: Django 5.x + DRF
- **Database**: PostgreSQL
- **Cache/Queue**: Redis + Celery
- **Auth**: JWT (djangorestframework-simplejwt)
- **Password Hashing**: bcrypt

## App Structure

```
apps/
├── accounts/          # User authentication & management
├── menus/             # Menu CRUD
├── orders/            # Order processing & GoQris integration
├── goqris/            # GoQris payment service
├── reports/           # Reporting endpoints
├── raw_materials/     # Profit tracking (cost entries)
└── settings_app/      # App settings singleton
```

## Quick Start

```bash
cd backend

# Activate venv
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Seed initial data
python manage.py seed_data

# Run server
python manage.py runserver
```

## Configuration

Environment variables are in `.env` file. See [setup.md](setup.md) for details.

## Bug Audit Status

| Audit | Bugs | Status |
|-------|------|--------|
| Round 1 | 15 bugs | ✅ All Fixed |
| Round 2 | 10 bugs | ✅ All Fixed |
| Round 3 | 8 bugs | ✅ All Fixed |
| **Total** | **33 bugs** | **✅ All Fixed** |

- [BACKEND_AUDIT.md](BACKEND_AUDIT.md) - Round 1 audit (15 bugs)
- [BACKEND_AUDIT_ROUND2.md](BACKEND_AUDIT_ROUND2.md) - Round 2 audit (10 bugs)
- [BACKEND_AUDIT_ROUND3.md](BACKEND_AUDIT_ROUND3.md) - Round 3 audit (8 bugs)

## Related

- [Setup Guide](setup.md)
- [API Endpoints](api-endpoints.md)
- [Data Models](models.md)
- [Bug Audit Report](BACKEND_AUDIT.md)
