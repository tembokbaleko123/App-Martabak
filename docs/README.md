# App Martabak Documentation

Dokumentasi untuk aplikasi kasir martabak dengan GoQris QRIS payment.

## Struktur Dokumentasi

```
docs/
├── README.md              # (this file) - overview & navigation
├── FLUTTER.md            # Flutter app documentation
├── agents.md              # Guide untuk AI coding agents
├── backend/
│   ├── README.md          # Backend overview
│   ├── setup.md           # Setup & installation
│   ├── api-endpoints.md   # API reference
│   ├── models.md          # Data models
│   ├── BACKEND_AUDIT.md        # 🐛 Round 1 audit (15 bugs - all fixed)
│   ├── BACKEND_AUDIT_ROUND2.md # 🐛 Round 2 audit (10 NEW bugs - all fixed)
│   ├── BACKEND_AUDIT_ROUND3.md # 🐛 Round 3 audit (8 NEW bugs - all fixed)
│   └── BACKEND_AUDIT_ROUND4.md # 🐛 Round 4 audit (7 NEW bugs - all fixed)
├── frontend/
│   ├── README.md          # Frontend overview
│   └── FRONTEND_AUDIT.md # 🐛 Frontend audit (10 NEW issues)
├── deployment/
│   └── README.md          # Deployment guide
└── postman/
    └── README.md          # Postman collection guide
```

## Quick Links

### Flutter (Frontend)
- [Flutter App Documentation](FLUTTER.md) — Clean Architecture + MVC, BLoC, UI/UX guidelines
- [Frontend README](frontend/README.md) — Frontend overview

### Backend
- [Backend Setup](backend/setup.md)
- [API Endpoints](backend/api-endpoints.md)
- [Data Models](backend/models.md)
- ✅ **[Backend Audit Report - Round 1](backend/BACKEND_AUDIT.md)** — 15 bugs, all fixed
- ✅ **[Backend Audit Report - Round 2](backend/BACKEND_AUDIT_ROUND2.md)** — 10 bugs, all fixed
- ✅ **[Backend Audit Report - Round 3](backend/BACKEND_AUDIT_ROUND3.md)** — 8 bugs, all fixed
- ✅ **[Backend Audit Report - Round 4](backend/BACKEND_AUDIT_ROUND4.md)** — 7 bugs, all fixed

### Other
- [Postman Collection](../postman/App-Martabak-API.json)
- [Deployment Guide](deployment/README.md)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Tech Stack

| Layer | Technology | Status |
|-------|------------|--------|
| Backend | Django 5.x + DRF | ✅ Complete |
| Database | PostgreSQL | ✅ Complete |
| Task Queue | Celery + Redis | ✅ Complete |
| Payment | GoQris QRIS | ✅ Complete |
| Frontend | Flutter (Android) | 🚧 In Progress |
| Backend Bugs | 40 bugs fixed | ✅ Complete |

## Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| Timezone | WITA (Asia/Makassar) | Backend & frontend display |
| Queue Throttle | 6 req/min | Rate limit untuk queue endpoint |
