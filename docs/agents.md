# Guide untuk AI Coding Agent

## Project Overview

App Martabak adalah aplikasi kasir martabak dengan:
- Backend: Django 5.x + DRF + PostgreSQL
- Frontend: Flutter (Android)
- Payment: GoQris QRIS

## Key Files Reference

### Backend Structure
```
backend/
├── config/                 # Django settings
│   ├── base.py            # Base settings (imported by dev/prod)
│   ├── dev.py             # Development settings
│   ├── prod.py            # Production settings
│   ├── celery.py          # Celery configuration
│   └── urls.py             # URL routing
├── apps/
│   ├── accounts/          # User authentication (PIN + JWT)
│   ├── menus/             # Menu management
│   ├── orders/            # Order processing
│   ├── goqris/            # GoQris payment integration
│   ├── reports/            # Report endpoints
│   ├── raw_materials/     # Profit tracking (cost entries)
│   └── settings_app/      # App settings singleton
├── core/
│   ├── middleware.py      # Request logging
│   ├── permissions.py     # IsOwner, IsKasir, IsOwnerOrReadOnly
│   ├── exceptions.py      # Custom exception handler
│   └── pagination.py      # Standard pagination
├── .env                    # Environment variables
└── requirements.txt        # Python dependencies
```

### Key Files
| Purpose | File |
|---------|------|
| Auth PIN login | `apps/accounts/views.py` |
| Order creation | `apps/orders/serializers.py` |
| GoQris service | `apps/goqris/services.py` |
| Seed data | `apps/accounts/management/commands/seed_data.py` |
| Reset PIN | `apps/accounts/management/commands/reset_pin.py` |
| JWT config | `config/base.py` (SIMPLE_JWT) |

## Phase Progress

| Phase | Status | Documentation |
|-------|--------|---------------|
| 1. Database & Models | ✅ Complete | `docs/backend/models.md` |
| 2. PIN Authentication | ✅ Complete | `docs/backend/api-endpoints.md` |
| 3. Menu Management API | ✅ Complete | `docs/backend/api-endpoints.md` |
| 4. Order & Cart API | ✅ Complete | `docs/backend/api-endpoints.md` |
| 5. GoQris Payment | ✅ Complete | `docs/backend/api-endpoints.md` |
| 6. Reports | ✅ Complete | `docs/backend/api-endpoints.md` |
| 7. Profit Tracking | ✅ Complete | `docs/backend/api-endpoints.md` |
| 8. Flutter App | ⏳ Pending | `docs/frontend/README.md` |

## Default Test Credentials

| Role | Username | PIN |
|------|----------|-----|
| Owner | `owner` | `000000` |
| Kasir | `Budi` | `1234` |
| Kasir | `Andi` | `1234` |

## Commands

```bash
# Run backend
cd backend
.venv\Scripts\python manage.py runserver

# Run Celery worker (optional - for background tasks)
.venv\Scripts\celery -A config worker -l info

# Seed data
.venv\Scripts\python manage.py seed_data

# Reset PIN kasir (default PIN: 1234)
.venv\Scripts\python manage.py reset_pin <username>
.venv\Scripts\python manage.py reset_pin owner --pin=000000

# Create migrations
.venv\Scripts\python manage.py makemigrations

# Apply migrations
.venv\Scripts\python manage.py migrate
```

## GoQris Configuration

1. Daftar di https://goqris.web.id dan dapat API key
2. Set di `.env`:
   ```
   GOQRIS_API_KEY=GO_your_api_key
   ```
3. Set project name via API:
   ```bash
   PATCH /api/v1/settings/
   {"goqris_project_name": "Nama Toko Anda"}
   ```
4. Cek status GoQris:
   ```bash
   GET /api/v1/goqris/profile/
   ```

## Coding Conventions

- **Comments**: Bahasa Indonesia
- **Identifiers**: English
- **Config**: Use `python-dotenv` (NOT `django-environ`)
- **Auth**: JWT via `djangorestframework-simplejwt`
- **Password hashing**: bcrypt
- **Custom User Model**: `accounts.Kasir`

## Environment Variables

See `docs/backend/setup.md` for full list.

## API Base URL

Development: `http://localhost:8000/api/v1`

## Related Documentation

- [Backend Setup](backend/setup.md)
- [API Endpoints](backend/api-endpoints.md)
- [Data Models](backend/models.md)
- [Postman Collection](../postman/App-Martabak-API.json)
- [Deployment Guide](deployment/README.md)
