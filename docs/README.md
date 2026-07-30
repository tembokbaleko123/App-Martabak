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
│   └── models.md          # Data models
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
