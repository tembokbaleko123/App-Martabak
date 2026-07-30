# Frontend Documentation

## Status

**Not started yet.** Flutter app is planned for Phase 7-9.

## Planned Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: flutter_bloc
- **HTTP Client**: dio
- **QR Code**: qr_flutter
- **Secure Storage**: flutter_secure_storage
- **Architecture**: Clean Architecture (lib/data, lib/features, dll)

## Planned Features

### Kasir Mode (4 tabs)
1. **Order Baru** - Create order with menu grid + cart
2. **Antrian** - Shared queue display
3. **Riwayat** - Own order history
4. **Profil** - Change PIN, logout

### Owner Mode (7 tabs)
1. **Dashboard** - Overview stats
2. **Order Baru** - Same as kasir
3. **Antrian** - Same as kasir
4. **Riwayat** - Full order history with filters
5. **Kelola Menu** - CRUD menu items
6. **Kelola Kasir** - CRUD kasir users
7. **Laporan** - Daily sales, kasir performance, top menus
8. **Pengaturan** - Shop name, GoQris config
9. **Profil** - Change PIN, logout

## API Integration

Base URL configured via `--dart-define`:
```dart
final apiBaseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1');
```

### Auth Flow
1. User selects username from grid
2. Enter PIN
3. Store JWT tokens in flutter_secure_storage
4. Attach token to all API requests
5. Handle 401 → auto logout

## File Structure (Planned)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/
│   │   └── api_client.dart
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   └── repositories/
└── features/
    ├── auth/
    ├── menu/
    ├── order/
    ├── queue/
    ├── reports/
    └── settings/
```

## Related

- [API Endpoints](../backend/api-endpoints.md)
- [Deployment Guide](../deployment/README.md)
