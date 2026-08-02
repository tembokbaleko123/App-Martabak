# App Martabak Documentation

Dokumentasi untuk aplikasi kasir martabak dengan GoQris QRIS payment.

## Production Ready ✅

| Component | Status | Score |
|-----------|--------|-------|
| Backend | ✅ Ready | 95/100 |
| Frontend | ✅ Ready | 98/100 |
| Combined | ✅ Ready | 97/100 |

**Total Issues Fixed: 56 (45 backend + 11 frontend) + 8 optimizations**

## Struktur Dokumentasi

```
docs/
├── README.md              # (this file) - overview & navigation
├── FLUTTER.md            # Flutter app documentation
├── agents.md              # Guide untuk AI coding agents
├── COMPREHENSIVE_AUDIT_SUMMARY.md # Final audit summary
├── backend/
│   ├── README.md          # Backend overview
│   ├── setup.md           # Setup & installation
│   ├── api-endpoints.md   # API reference
│   ├── models.md          # Data models
│   ├── BACKEND_AUDIT.md        # Round 1 audit (15 bugs - all fixed)
│   ├── BACKEND_AUDIT_ROUND2.md # Round 2 audit (10 bugs - all fixed)
│   ├── BACKEND_AUDIT_ROUND3.md # Round 3 audit (8 bugs - all fixed)
│   ├── BACKEND_AUDIT_ROUND4.md # Round 4 audit (7 bugs - all fixed)
│   └── BACKEND_AUDIT_ROUND5.md # Round 5 audit (5 bugs - all fixed)
├── frontend/
│   ├── README.md          # Frontend overview
│   ├── FRONTEND_AUDIT.md          # Frontend audit (11 issues)
│   └── FRONTEND_OPTIMIZATION.md   # Frontend optimization (11 tips)
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
- [Backend Audit Report - Round 1](backend/BACKEND_AUDIT.md) — 15 bugs, all fixed
- [Backend Audit Report - Round 2](backend/BACKEND_AUDIT_ROUND2.md) — 10 bugs, all fixed
- [Backend Audit Report - Round 3](backend/BACKEND_AUDIT_ROUND3.md) — 8 bugs, all fixed
- [Backend Audit Report - Round 4](backend/BACKEND_AUDIT_ROUND4.md) — 7 bugs, all fixed
- [Backend Audit Report - Round 5](backend/BACKEND_AUDIT_ROUND5.md) — 5 bugs, all fixed
- [Comprehensive Audit Summary](COMPREHENSIVE_AUDIT_SUMMARY.md) — Final status across all rounds

### Frontend Audit
- [Frontend Audit Report](frontend/FRONTEND_AUDIT.md) — 11 issues
- [Frontend Optimization Report](frontend/FRONTEND_OPTIMIZATION.md) — 11 optimizations

### Other
- [Postman Collection](postman/App-Martabak-API.json)
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
| Frontend | Flutter (Android) | ✅ Complete |
| Backend Bugs | 45 bugs fixed (5 rounds) | ✅ Complete |
| Frontend Bugs | 11 issues fixed | ✅ Complete |
| Frontend Optimizations | 8 optimizations | ✅ Complete |

## Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| Timezone | WITA (Asia/Makassar) | Backend & frontend display |
| Queue Throttle | 6 req/min | Rate limit untuk queue endpoint |

## Audit Summary

### Backend - 45 Bugs Fixed (5 Rounds)

| Round | Issues | Status |
|-------|--------|--------|
| Round 1 | 15 bugs | ✅ Fixed |
| Round 2 | 10 bugs | ✅ Fixed |
| Round 3 | 8 bugs | ✅ Fixed |
| Round 4 | 7 bugs | ✅ Fixed |
| Round 5 | 5 bugs | ✅ Fixed |

### Frontend - 11 Issues Fixed

| Issue | Description | Status |
|-------|-------------|--------|
| F-001 | QR polling background drain | ✅ Fixed |
| F-002 | Queue polling background drain | ✅ Fixed |
| F-003 | No JWT token refresh | ✅ Fixed |
| F-004 | Hardcoded IP in default URL | ✅ Deferred |
| F-005 | History no pagination | ✅ Fixed |
| F-006 | Silent error swallowing | ✅ Fixed |
| F-007 | QR no countdown timer | ✅ Fixed |
| F-008 | No retry mechanism | ✅ Fixed |
| OBS-F-001 | PIN 4 vs 6 digits | ✅ Fixed |
| OBS-F-002 | No connectivity indicator | ✅ Fixed |
| OBS-F-003 | No pull-to-refresh | ✅ Fixed |

### Frontend Optimizations - 8 Done

| # | Optimization | Status |
|---|-------------|--------|
| OPT-001 | Background polling stop (QR) | ✅ Done |
| OPT-002 | Background polling stop (Queue) | ✅ Done |
| OPT-003 | Category tab rebuild | ✅ Done |
| OPT-004 | filteredMenus caching | ✅ Done |
| OPT-005 | Currency formatter | ✅ Done |
| OPT-006 | Menu data caching | ✅ Done |
| OPT-007 | Search debouncing | ✅ Done |
| OPT-008 | OrderDetail refresh | ✅ Done |
| OPT-009 | Service singleton | ✅ Done |
| OPT-010 | History pagination | ✅ Done |
| OPT-011 | Release menu memory | ✅ Done |
