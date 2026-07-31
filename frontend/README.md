# App Martabak - Flutter Frontend

Aplikasi kasir martabak dengan Flutter + GoQris QRIS payment.

## Tech Stack

- Flutter 3.12+
- flutter_bloc (state management)
- dio (HTTP client)
- flutter_secure_storage (JWT tokens)
- qr_flutter (QR code rendering)
- go_router (navigation)

## Setup

1. Install dependencies:
```bash
cd frontend
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Build APK

```bash
cd frontend
flutter build apk --debug
```

## Architecture

Clean Architecture + MVC + BLoC pattern:
- `lib/core/` - Shared utilities, API client, theme
- `lib/data/` - Models and services
- `lib/features/` - Feature modules (each with bloc/screens/widgets)
- `lib/navigation/` - GoRouter configuration

## API Base URL

Default: `http://192.168.1.16:8000/api/v1` (for USB debugging with physical device)

Override at build time:
```bash
flutter build apk --dart-define=API_BASE_URL=http://your-server:8000/api/v1
```

## Documentation

- [Frontend Docs](../docs/frontend/README.md)
- [API Endpoints](../docs/backend/api-endpoints.md)
- [AGENTS.md](../docs/AGENTS.md)
