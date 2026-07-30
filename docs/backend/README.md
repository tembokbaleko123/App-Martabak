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

## Related

- [Setup Guide](setup.md)
- [API Endpoints](api-endpoints.md)
- [Data Models](models.md)
