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
│   ├── categories/         # Category management (flexible, owner CRUD)
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

### Backend — All Complete ✅

| Phase | Status | Documentation |
|-------|--------|---------------|
| 1. Database & Models | ✅ Complete | `docs/backend/models.md` |
| 2. PIN Authentication | ✅ Complete | `docs/backend/api-endpoints.md` |
| 3. Menu Management API | ✅ Complete | `docs/backend/api-endpoints.md` |
| 4. Order & Cart API | ✅ Complete | `docs/backend/api-endpoints.md` |
| 5. GoQris Payment | ✅ Complete | `docs/backend/api-endpoints.md` |
| 6. Reports | ✅ Complete | `docs/backend/api-endpoints.md` |
| 7. Profit Tracking | ✅ Complete | `docs/backend/api-endpoints.md` |
| **Backend Bugs Fixed** | ✅ 45 bugs | 5 audit rounds |

### Frontend — All Complete ✅

| Phase | Status | Documentation |
|-------|--------|---------------|
| Flutter Documentation | ✅ Complete | `docs/FLUTTER.md` |
| Flutter Scaffolding | ✅ Complete | `frontend/` |
| Auth Feature | ✅ Complete | Flutter implementation |
| Order Feature | ✅ Complete | Flutter implementation |
| Menu Feature | ✅ Complete | Flutter implementation |
| Queue Feature | ✅ Complete | Flutter implementation |
| Reports Feature | ✅ Complete | Flutter implementation |
| **Frontend Issues Fixed** | ✅ 11 issues | 8 optimizations |

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

## Timezone Configuration

- **Backend:** `TIME_ZONE = 'Asia/Makassar'` (WITA, UTC+8)
- **Celery:** `CELERY_TIMEZONE = 'Asia/Makassar'`
- **Frontend:** Konversi ke WITA saat display datetime

## Throttling

| Endpoint | Rate | Scope |
|----------|------|-------|
| `/orders/queue/` | 6/minute | Per user |
| Login | 20/minute | Per IP |

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

## Flutter Architecture

Project Flutter menggunakan **Clean Architecture + MVC** pattern. Lihat `docs/FLUTTER.md` untuk detail lengkap.

### Frontend Structure
```
frontend/lib/
├── core/                    # Shared: API client, theme, utils
├── shared/                  # Shared: widgets, extensions
├── data/                    # Data layer: models, repositories, services
├── features/               # Feature modules (MVC per feature)
│   ├── auth/              # Auth feature
│   ├── menu/              # Menu feature
│   ├── order/             # Order feature
│   ├── queue/             # Queue feature
│   ├── history/           # History feature
│   ├── reports/           # Reports feature
│   └── profile/           # Profile feature
└── navigation/             # GoRouter configuration
```

### Flutter Coding Rules (WAJIB DIIKUTI)

1. **Clean Architecture + MVC**
   - Model: `models/` + `repositories/`
   - View: `screens/` + `widgets/`
   - Controller: `bloc/`

2. **DRY (Don't Repeat Yourself)**
   - Shared code di `core/` atau `shared/`
   - Buat widget reusable untuk komponen UI yang sering dipakai
   - Pakai extensions untuk helper methods

3. **Refactor Sering**
   - File max 200 baris
   - Fungsi max 30 baris
   - Kalau duplicated code muncul 2+, extract ke shared

4. **Feature-First Structure**
   - Setiap feature punya folder sendiri: `models/bloc/screens/widgets/repositories`
   - Gak boleh mixed (semua models di 1 folder)

5. **State Management: flutter_bloc**
   - Pakai BLoC pattern untuk semua state management
   - Tiap feature punya BLoC sendiri

6. **Libraries Reference**
   - Pakai libraries dari [awesome-flutter](https://github.com/Solido/awesome-flutter)
   - flutter_bloc, dio, flutter_secure_storage, qr_flutter, shimmer, flutter_animate

## Related Documentation

### Flutter
- [Flutter App Documentation](FLUTTER.md) — **WAJIB BACA** sebelum coding Flutter
- [Frontend README](frontend/README.md)

### Backend
- [Backend Setup](backend/setup.md)
- [API Endpoints](backend/api-endpoints.md)
- [Data Models](backend/models.md)
- [Postman Collection](postman/App-Martabak-API.json)
- [Deployment Guide](deployment/README.md)
