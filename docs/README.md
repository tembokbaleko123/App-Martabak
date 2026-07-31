# App Martabak Documentation

Dokumentasi untuk aplikasi kasir martabak dengan GoQris QRIS payment.

## Struktur Dokumentasi

```
docs/
├── README.md              # (this file) - overview & navigation
├── agents.md              # Guide untuk AI coding agents
├── backend/
│   ├── README.md          # Backend overview
│   ├── setup.md           # Setup & installation
│   ├── api-endpoints.md   # API reference
│   ├── models.md          # Data models
│   ├── BACKEND_AUDIT.md        # 🐛 Round 1 audit (15 bugs - all fixed)
│   ├── BACKEND_AUDIT_ROUND2.md # 🐛 Round 2 audit (10 NEW bugs - all fixed)
│   └── BACKEND_AUDIT_ROUND3.md # 🐛 Round 3 audit (8 NEW bugs)
├── frontend/
│   └── README.md          # Frontend overview
├── deployment/
│   └── README.md          # Deployment guide
└── postman/
    └── README.md          # Postman collection guide
```

## Quick Links

- [Backend Setup](backend/setup.md)
- [API Endpoints](backend/api-endpoints.md)
- [Data Models](backend/models.md)
- ✅ **[Backend Audit Report - Round 1](backend/BACKEND_AUDIT.md)** — 15 bugs, all fixed
- ✅ **[Backend Audit Report - Round 2](backend/BACKEND_AUDIT_ROUND2.md)** — 10 bugs, all fixed
- 🐛 **[Backend Audit Report - Round 3](backend/BACKEND_AUDIT_ROUND3.md)** — 8 NEW bugs (1 high)
- [Postman Collection](../postman/App-Martabak-API.json)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Django 5.x + DRF |
| Database | PostgreSQL |
| Task Queue | Celery + Redis |
| Payment | GoQris QRIS |
| Frontend | Flutter (planned) |
