# App Martabak - Kasir POS dengan GoQris QRIS

Aplikasi kasir martabak dengan Flutter (Android) dan Django (Backend). Mendukung pembayaran GoQris QRIS, manajemen menu, antrian, dan laporan penjualan.

## Production Readiness

| Component | Status | Details |
|-----------|--------|---------|
| Backend | ✅ Ready | 40 bugs fixed (4 audit rounds) |
| Frontend | ✅ Ready | 10 issues fixed |
| Code Quality | ✅ Ready | All linting passed |
| Documentation | ✅ Complete | Full audit trails |

**Production Readiness Score: 90/100**

---

## Features

- **Authentication**: PIN-based login untuk Owner dan Kasir
- **Menu Management**: CRUD menu dengan gambar, kategori, harga
- **Order Processing**: Pembuatan order, kalkulasi total, komisi kasir
- **Queue System**: Display antrian real-time
- **GoQris Payment**: QRIS payment dengan auto-confirmation via Celery
- **Reports**: Laporan harian, top menu, performa kasir, profit
- **Connectivity Monitoring**: Banner saat server unreachable

---

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Backend | Django 5.x + DRF | Latest |
| Database | PostgreSQL | 15+ |
| Task Queue | Celery + Redis | Latest |
| Payment | GoQris QRIS | API v2 |
| Frontend | Flutter | 3.12+ |
| State Management | flutter_bloc | Latest |
| HTTP Client | Dio | Latest |

---

## Project Structure

```
App-Martabak/
├── backend/                    # Django REST API
│   ├── apps/
│   │   ├── accounts/           # User auth, PIN login
│   │   ├── categories/         # Category management
│   │   ├── menus/              # Menu CRUD
│   │   ├── orders/             # Order processing
│   │   ├── goqris/             # GoQris integration
│   │   ├── reports/            # Report endpoints
│   │   └── raw_materials/      # Cost tracking
│   ├── config/                 # Django settings
│   ├── core/                   # Middleware, permissions
│   └── requirements.txt
│
├── frontend/                   # Flutter Mobile App
│   └── lib/
│       ├── core/               # API client, theme, utils
│       ├── features/           # Feature modules (MVC)
│       │   ├── auth/
│       │   ├── menu/
│       │   ├── order/
│       │   ├── queue/
│       │   ├── history/
│       │   ├── reports/
│       │   └── connectivity/
│       └── navigation/         # GoRouter config
│
├── docs/                       # Documentation
│   ├── backend/               # Backend docs & audits
│   ├── frontend/               # Frontend docs & audits
│   └── deployment/             # Deployment guide
│
└── postman/                    # API collection
```

---

## Development Status

### Completed

- [x] Backend implementation (Django + DRF)
- [x] Frontend implementation (Flutter)
- [x] GoQris QRIS payment integration
- [x] Celery background tasks (payment confirmation)
- [x] All bug fixes (40 backend + 10 frontend)
- [x] Flutter analyze: 0 issues
- [x] Documentation complete

### Pending (Post-VPS)

- [ ] Configure domain & SSL
- [ ] Set production environment variables
- [ ] Build APK with production API URL
- [ ] Setup Celery worker on VPS
- [ ] Configure GoQris production API key

---

## Quick Start

### Backend

```bash
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Seed initial data
python manage.py seed_data

# Run server
python manage.py runserver 0.0.0.0:8000
```

### Frontend (Flutter)

```bash
cd frontend

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build debug APK
flutter build apk --debug
```

### Default Credentials

| Role | Username | PIN |
|------|----------|-----|
| Owner | `owner` | `000000` |
| Kasir | `Budi` | `1234` |
| Kasir | `Andi` | `1234` |

---

## API Documentation

See [docs/backend/api-endpoints.md](docs/backend/api-endpoints.md) for full API reference.

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/accounts/pin/` | PIN login |
| GET | `/api/v1/menus/all/` | All menus |
| POST | `/api/v1/orders/` | Create order |
| GET | `/api/v1/orders/queue/` | Queue list |
| GET | `/api/v1/health/` | Health check |

---

## Deployment

See [docs/deployment/README.md](docs/deployment/README.md) for detailed deployment guide.

### Summary

1. Setup VPS with Ubuntu 22.04
2. Install PostgreSQL, Redis, Nginx, Python
3. Configure environment variables
4. Run migrations and seed data
5. Setup Gunicorn + Celery services
6. Configure Nginx with SSL
7. Build Flutter APK with production API URL

---

## Audit Reports

All bugs have been fixed and documented:

| System | Issues Found | Fixed | Status |
|--------|-------------|-------|--------|
| Backend Round 1 | 15 bugs | 15 | ✅ Done |
| Backend Round 2 | 10 bugs | 10 | ✅ Done |
| Backend Round 3 | 8 bugs | 8 | ✅ Done |
| Backend Round 4 | 7 bugs | 7 | ✅ Done |
| Frontend Round 1 | 10 issues | 10 | ✅ Done |
| **Total** | **50 issues** | **50** | **✅ Done** |

See [docs/README.md](docs/README.md) for detailed audit reports.

---

## Environment Variables

### Backend (.env)

```env
# Django
DJANGO_SECRET_KEY=your-secret-key
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=your-domain.com

# Database
DB_NAME=martabak_db
DB_USER=martabak_user
DB_PASSWORD=your-db-password
DB_HOST=localhost
DB_PORT=5432

# Redis / Celery
REDIS_URL=redis://localhost:6379/0
CELERY_BROKER_URL=redis://localhost:6379/0

# GoQris
GOQRIS_API_BASE=https://api.goqris.web.id
GOQRIS_API_KEY=GO_your-api-key

# CORS
CORS_ALLOWED_ORIGINS=https://your-domain.com
```

### Frontend

API Base URL is configurable via `--dart-define`:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.your-domain.com/api/v1
```

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Support

For issues or questions, please refer to the documentation in `docs/` directory.
