# Frontend Documentation

## Status

**Implemented** - Flutter app is complete with all features.
**Bug Audit:** 10/10 issues fixed (see [FRONTEND_AUDIT.md](FRONTEND_AUDIT.md))

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: flutter_bloc
- **HTTP Client**: dio (with retry & token refresh)
- **QR Code**: qr_flutter
- **Secure Storage**: flutter_secure_storage
- **Architecture**: Clean Architecture + MVC + BLoC

## Features

### Kasir Mode (4 bottom nav tabs)
1. **Order Baru** - Create order with menu grid + cart + QRIS/cash checkout
2. **Antrian** - Shared queue display (with lifecycle-aware polling)
3. **Riwayat** - Own order history (with infinite scroll pagination)
4. **Profil** - Change PIN, logout

### Owner Mode
Same 4 bottom nav tabs + Management menu in Profil:
- Kelola Menu - CRUD menu items
- Kelola Kasir - CRUD kasir users + reset PIN
- Laporan - Daily sales, kasir performance, top menus
- Pengaturan - Shop name, GoQris status
- **Bahan Baku & Laba** - Cost entry tracking + profit calculation

## API Integration

Base URL configured via `--dart-define`:
```dart
final apiBaseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1');
```

### Auth Flow
1. User selects username from grid (fetched from `/accounts/login-users/`)
2. Enter PIN (6 digits)
3. Store JWT tokens in flutter_secure_storage
4. Attach token to all API requests
5. Handle 401 → **auto token refresh**
6. Handle network errors → **auto retry with backoff**

## File Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   └── endpoints.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   └── utils/
│       └── currency_formatter.dart
├── shared/
│   └── widgets/
├── data/
│   ├── models/
│   └── services/
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   ├── menu/
│   ├── order/
│   ├── queue/
│   ├── history/
│   ├── reports/
│   ├── profile/
│   ├── settings/
│   └── raw_materials/
└── navigation/
    ├── app_router.dart
    └── route_names.dart
```

## Related

- [API Endpoints](../backend/api-endpoints.md)
- [Backend Setup](../backend/setup.md)
- [AGENTS.md](../AGENTS.md)
