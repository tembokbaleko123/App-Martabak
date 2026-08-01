# Flutter App Documentation — App Martabak

**Project:** Aplikasi kasir martabak dengan GoQris QRIS payment  
**Platform:** Android only  
**Framework:** Flutter 3.44.x  
**State Management:** flutter_bloc  
**Architecture:** Clean Architecture + MVC  
**Target:** Production-ready POS app untuk lapak martabak

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Architecture](#3-architecture)
4. [Folder Structure](#4-folder-structure)
5. [Coding Conventions](#5-coding-conventions)
6. [State Management](#6-state-management)
7. [API Integration](#7-api-integration)
8. [UI/UX Guidelines](#8-ux-guidelines)
9. [Features & Screens](#9-features--screens)
10. [Libraries Reference](#10-libraries-reference)
11. [Setup & Development](#11-setup--development)
12. [Build & Deployment](#12-build--deployment)

---

## 1. Project Overview

### 1.1 Purpose

Aplikasi kasir mobile untuk lapak martabak dengan fitur:
- Input order cepat (kategori → menu → qty → catatan)
- 2 Metode pembayaran: GoQris QRIS + Cash (Tunai)
- Generate QRIS dinamis via GoQris
- Auto-detect pembayaran GoQris (polling)
- Antrian shared (semua kasir bisa lihat pesanan aktif)
- Riwayat per kasir
- Laporan harian (owner)
- Laporan profit (owner)

### 1.2 Target Users

| Persona | Akses | Device | Goal |
|---------|-------|--------|------|
| **Budi (Kasir)** | Login PIN kasir | HP/tablet di lapak | Input order cepat, lihat antrian |
| **Andi (Kasir)** | Login PIN kasir | HP/tablet di lapak | Sama seperti Budi |
| **Pak Hartono (Owner)** | Login PIN owner | HP/tablet | Review laporan, atur menu, tambah kasir |

> **Note:** Pembeli bukan user app — mereka hanya scan QRIS dari layar device kasir.

### 1.3 Tech Stack Summary

```
┌──────────────────────────────────────────────────────────┐
│                    Flutter App Layer                      │
├──────────────────────────────────────────────────────────┤
│  UI (Screens, Widgets)                                   │
│    ↓                                                      │
│  Controllers (BLoC / State Management)                   │
│    ↓                                                      │
│  Models (Data Classes)                                    │
│    ↓                                                      │
│  Repositories (Data Access Layer)                         │
│    ↓                                                      │
│  Services (API Client, Storage)                          │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Tech Stack

### 2.1 Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.0.0
  equatable: ^2.0.7

  # HTTP Client
  dio: ^5.7.0

  # Secure Storage (JWT tokens)
  flutter_secure_storage: ^9.2.2

  # QR Code Rendering
  qr_flutter: ^4.1.0

  # Utilities
  intl: ^0.20.1           # Currency & date formatting
  google_fonts: ^6.2.1    # Typography

  # UI Enhancements
  shimmer: ^3.0.0          # Loading skeleton
  flutter_animate: ^4.5.2   # Micro-animations
  badges: ^3.1.2           # Badge on icons
```

### 2.2 Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
```

### 2.3 Reference: awesome-flutter

Inspirasi dan reference library dari [Solido/awesome-flutter](https://github.com/Solido/awesome-flutter):

| Category | Library | Usage |
|----------|---------|-------|
| State Management | flutter_bloc | BLoC pattern |
| HTTP | dio | API calls |
| Storage | flutter_secure_storage | JWT storage |
| QR | qr_flutter | QR rendering |
| UI Helpers | flutter_animate | Animations |
| UI Helpers | shimmer | Loading states |
| Forms | reactive_forms | Form handling |
| Navigation | go_router | Declarative routing |
| DI | get_it | Service locator |
| Utils | freezed | Immutable classes |
| Utils | json_serializable | JSON parsing |

---

## 3. Architecture

### 3.1 Clean Architecture + MVC

Project ini menggunakan **Clean Architecture** dengan **MVC pattern**:

```
Clean Architecture Layers:
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Screens   │  │  Widgets    │  │  Controllers│   │
│  │  (Views)    │  │ (Components)│  │   (BLoC)    │   │
│  └─────────────┘  └─────────────┘  └─────────────┘   │
├─────────────────────────────────────────────────────────┤
│                     DOMAIN                              │
│  ┌─────────────┐  ┌─────────────┐                     │
│  │   Models    │  │ Repositories│                     │
│  │  (Entities) │  │ (Interfaces)│                     │
│  └─────────────┘  └─────────────┘                     │
├─────────────────────────────────────────────────────────┤
│                      DATA                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Services  │  │ Repositories│  │   Models    │   │
│  │  (API, DB)  │  │  (Impl)     │  │   (DTO)     │   │
│  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 3.2 MVC Pattern Mapping

| MVC Component | Flutter Implementation | Responsibility |
|--------------|----------------------|----------------|
| **Model** | `models/` + `repositories/` | Data structure, business logic, data access |
| **View** | `screens/` + `widgets/` | UI rendering, user interaction |
| **Controller** | `bloc/` (BLoC pattern) | State management, business logic orchestration |

### 3.3 Clean Architecture Principles

1. **Separation of Concerns** — Setiap layer punya tanggung jawab jelas
2. **Dependency Inversion** — High-level modules gak зависит на low-level modules
3. **DRY (Don't Repeat Yourself)** — Shared code di `core/` atau `shared/`
4. **Single Responsibility** — 1 class = 1 responsibility
5. **Refactor Often** — Kode harus selalu di-refactor agar tidak bejibun

---

## 4. Folder Structure

```
frontend/lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
│
├── core/                        # SHARED — reusable code
│   ├── api/
│   │   ├── api_client.dart     # Dio singleton + interceptors
│   │   ├── endpoints.dart       # API endpoint constants
│   │   └── exceptions.dart      # Custom API exceptions
│   │
│   ├── theme/
│   │   ├── app_theme.dart      # Material 3 theme
│   │   ├── app_colors.dart     # Brand colors (martabak)
│   │   ├── app_typography.dart # Text styles
│   │   └── app_spacing.dart    # Spacing constants
│   │
│   ├── utils/
│   │   ├── currency_formatter.dart  # Rp format
│   │   ├── date_formatter.dart      # Date/time format (WITA timezone)
│   │   ├── debouncer.dart           # Debounce utility
│   │   └── validators.dart          # Input validation
│   │
│   ├── constants/
│   │   ├── app_constants.dart  # App-wide constants
│   │   └── storage_keys.dart   # Secure storage keys
│   │
│   └── errors/
│       ├── failures.dart       # Failure classes (Either pattern)
│       └── exceptions.dart      # Custom exceptions
│
├── shared/                      # SHARED — reusable widgets
│   ├── widgets/
│   │   ├── app_button.dart     # Primary/secondary buttons
│   │   ├── app_card.dart       # Card component
│   │   ├── app_text_field.dart # Text input component
│   │   ├── loading_indicator.dart  # Loading states
│   │   ├── error_widget.dart   # Error display
│   │   ├── empty_state.dart    # Empty state display
│   │   └── pin_input.dart      # PIN input widget
│   │
│   └── extensions/
│       ├── context_extensions.dart  # BuildContext helpers
│       ├── string_extensions.dart   # String utilities
│       └── datetime_extensions.dart # DateTime utilities
│
├── data/                        # DATA LAYER
│   ├── models/                  # DTO (Data Transfer Objects)
│   │   ├── user_model.dart
│   │   ├── menu_model.dart
│   │   ├── order_model.dart
│   │   └── ...
│   │
│   ├── repositories/           # Repository implementations
│   │   ├── auth_repository_impl.dart
│   │   ├── menu_repository_impl.dart
│   │   └── ...
│   │
│   └── services/
│       ├── auth_service.dart   # Auth API calls
│       ├── menu_service.dart   # Menu API calls
│       ├── order_service.dart  # Order API calls
│       └── storage_service.dart # Secure storage wrapper
│
├── features/                    # FEATURE MODULES (MVC)
│   ├── auth/
│   │   ├── models/             # Auth-related models
│   │   │   └── user_model.dart
│   │   │
│   │   ├── bloc/              # CONTROLLER (BLoC)
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   │
│   │   ├── screens/           # VIEW (Screens)
│   │   │   ├── login_screen.dart
│   │   │   └── pin_setup_screen.dart
│   │   │
│   │   ├── widgets/           # VIEW (Feature-specific widgets)
│   │   │   ├── user_grid.dart
│   │   │   └── pin_keypad.dart
│   │   │
│   │   └── repositories/      # DOMAIN (Repository interface)
│   │       └── auth_repository.dart
│   │
│   ├── menu/
│   │   ├── models/
│   │   ├── bloc/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── repositories/
│   │
│   ├── order/
│   │   ├── models/
│   │   ├── bloc/
│   │   ├── screens/
│   │   │   ├── order_screen.dart
│   │   │   ├── cart_sheet.dart
│   │   │   └── qr_display_screen.dart
│   │   ├── widgets/
│   │   │   ├── menu_grid.dart
│   │   │   ├── menu_card.dart
│   │   │   ├── cart_item_tile.dart
│   │   │   └── category_tab.dart
│   │   └── repositories/
│   │
│   ├── queue/
│   │   ├── models/
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── history/
│   │   ├── models/
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── reports/
│   │   ├── models/
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   ├── settings/
│   │   ├── models/
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   │
│   └── profile/
│       ├── models/
│       ├── bloc/
│       ├── screens/
│       └── widgets/
│
└── navigation/                  # Navigation configuration
    ├── app_router.dart          # GoRouter setup
    └── route_names.dart         # Route constants
```

### 4.1 Structure Principles

| Principle | Implementation |
|-----------|----------------|
| **Feature-First** | Code dikelompokkan per feature, bukan per type |
| **Layer Separation** | Setiap feature punya models/bloc/screens/widgets/repositories |
| **Shared Code** | Common code di `core/` dan `shared/` |
| **Scalable** | Mudah menambah feature baru tanpa mengubah struktur |
| **Testable** | Tiap layer bisa di-test secara terpisah |

---

## 5. Coding Conventions

### 5.1 File Naming

```dart
// Files: snake_case
auth_bloc.dart
auth_event.dart
auth_state.dart
user_model.dart
login_screen.dart
pin_input.dart

// Classes: PascalCase
class AuthBloc {}
class LoginScreen {}
class PinInput {}
```

### 5.2 Architecture Per Feature (MVC)

Setiap feature mengikuti pattern:

```
feature_name/
├── models/           # Model (data structures)
│   └── model_name.dart
├── bloc/             # Controller (state management)
│   ├── bloc_name_bloc.dart
│   ├── bloc_name_event.dart
│   └── bloc_name_state.dart
├── screens/          # View (screens/pages)
│   └── screen_name_screen.dart
├── widgets/          # View (reusable widgets for this feature)
│   └── widget_name.dart
└── repositories/     # Model (repository interface)
    └── repository_name_repository.dart
```

### 5.3 Naming Conventions

```dart
// BLoC naming
class AuthBloc extends Bloc<AuthEvent, AuthState> {}
class AuthEvent {}
class AuthState {}

// Event naming: past tense / imperative
class LoginSubmitted extends AuthEvent {}
class LogoutRequested extends AuthEvent {}

// State naming: adjective / noun
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthError extends AuthState {}

// Repository naming
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String username, String pin);
}
class AuthRepositoryImpl implements AuthRepository {}
```

### 5.4 DRY Principles

**DO (Wajib):**
```dart
// ✅ Shared widget untuk UI component
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  // ... common button implementation
}

// ✅ Shared theme colors
class AppColors {
  static const primary = Color(0xFFD2691E);
  static const secondary = Color(0xFFFFC107);
}

// ✅ Shared extensions
extension BuildContextX on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

**DON'T:**
```dart
// ❌ Copy-paste code
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFD2691E),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: onPressed,
  child: Text('Submit'),
)

// ✅ Shared button
AppButton.primary(label: 'Submit', onPressed: onPressed)
```

### 5.5 Refactoring Guidelines

**When to Refactor:**
- Fungsi lebih dari 30 baris
- File lebih dari 200 baris
- Duplicated code muncul 2+ kali
- Nested conditional lebih dari 2 level
- Class punya lebih dari 5 responsibilities

**How to Refactor:**
1. Extract method untuk logic yang berulang
2. Extract widget untuk UI component
3. Extract class untuk tanggung jawab yang berbeda
4. Gunakan extension untuk helper methods
5. Gunakan mixin untuk shared behavior

### 5.6 Comments

```dart
// ✅ Good: explains WHY, not WHAT
// Using debouncer to prevent rapid API calls while user is typing
final debouncer = Debouncer(milliseconds: 300);

// ❌ Bad: redundant comment
// This function creates a new order
Future<Order> createOrder() {}

// ✅ Good: complex business logic explanation
// QR expires after 15 minutes. We poll every 5 seconds to check payment status.
// Stop polling when: paid, expired, or user cancels.
```

---

## 6. State Management

### 6.1 BLoC Pattern

Menggunakan **flutter_bloc** dengan pattern:

```dart
// EVENT: User actions
@immutable
abstract class OrderEvent {}
class AddItemToCart extends OrderEvent {}
class RemoveItemFromCart extends OrderEvent {}
class SubmitOrder extends OrderEvent {}

// STATE: UI state
@immutable
abstract class OrderState {}
class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrderCartUpdated extends OrderState {
  final List<CartItem> items;
  final int total;
}
class OrderSuccess extends OrderState {
  final Order order;
}
class OrderError extends OrderState {
  final String message;
}
```

### 6.2 State Management Flow

```
User Action
    ↓
Event Created
    ↓
BLoC receives Event
    ↓
Business Logic
    ↓
Repository/Service Call
    ↓
Emit New State
    ↓
UI Rebuilds
```

### 6.3 BLoC per Feature

| Feature | BLoC | Responsibility |
|---------|------|----------------|
| Auth | `AuthBloc` | Login, logout, session management |
| Menu | `MenuBloc` | Fetch menu, filter by category |
| Order | `OrderBloc` | Cart management, order creation |
| Queue | `QueueBloc` | Polling queue status |
| History | `HistoryBloc` | Order history, filtering |
| Reports | `ReportsBloc` | Daily reports, profit reports |
| Settings | `SettingsBloc` | App settings, GoQris config |

---

## 7. API Integration

### 7.1 API Client Setup

```dart
// core/api/api_client.dart
class ApiClient {
  final Dio _dio;
  
  ApiClient() : _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Attach JWT token
        final token = StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 → trigger logout
        if (error.response?.statusCode == 401) {
          // Navigate to login
        }
        return handler.next(error);
      },
    ));
  }
}
```

### 7.2 API Endpoints Reference

**Base URL:** `http://localhost:8000/api/v1` (dev) / `https://api.martabak.com/api/v1` (prod)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/accounts/pin/` | Public | Login dengan PIN |
| GET | `/accounts/me/` | JWT | Get current user |
| POST | `/accounts/change-pin/` | JWT | Ganti PIN |
| GET | `/menus/` | Public | List menu aktif |
| GET | `/menus/all/` | JWT Owner | List semua menu |
| POST | `/menus/` | JWT Owner | Tambah menu |
| PATCH | `/menus/{id}/` | JWT Owner | Edit menu |
| DELETE | `/menus/{id}/` | JWT Owner | Soft delete menu |
| POST | `/orders/` | JWT | Buat order baru |
| GET | `/orders/` | JWT | List orders |
| GET | `/orders/{id}/` | JWT | Detail order |
| GET | `/orders/{id}/status/` | JWT | Cek status |
| POST | `/orders/{id}/cancel/` | JWT Owner | Batalkan order |
| GET | `/orders/queue/` | JWT | Antrian shared (6 req/min throttle) |
| GET | `/reports/daily/` | JWT Owner | Laporan harian |
| GET | `/reports/profit/` | JWT Owner | Laporan profit |
| GET | `/settings/` | JWT Owner | Get settings |
| PATCH | `/settings/` | JWT Owner | Update settings |

### 7.3 Timezone Handling

Backend menggunakan **WITA (Asia/Makassar, UTC+8)** untuk semua timestamp.

**Frontend DateTime Handling:**

```dart
// date_formatter.dart - WITA timezone support
class DateFormatter {
  // Konversi datetime string ke WITA (dari offset +07 atau +08)
  static DateTime parseToWita(String dateStr) {
    final dt = DateTime.parse(dateStr);
    const witaOffset = Duration(hours: 8);
    final diff = witaOffset - dt.timeZoneOffset;
    return dt.add(diff);
  }

  // Format datetime dengan label WITA
  static String formatWita(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')} '
           '${_months[dateTime.month - 1]} '
           '${dateTime.year}, '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')} WITA';
  }
}
```

**Order Model WITA Getters:**

```dart
class OrderModel {
  // Raw datetime dari API
  final DateTime createdAt;

  // WITA getters untuk display
  DateTime get createdAtWita => DateFormatter.parseToWita(createdAt.toIso8601String());
  DateTime? get paidAtWita => paidAt != null ? DateFormatter.parseToWita(paidAt!.toIso8601String()) : null;
  DateTime? get expiresAtWita => expiresAt != null ? DateFormatter.parseToWita(expiresAt!.toIso8601String()) : null;
}
```

**Usage in UI:**

```dart
// ✅ Display WITA datetime
Text(DateFormatter.formatWita(order.createdAtWita))

// ✅ Display WITA time only
Text(DateFormatter.formatWitaTime(order.createdAtWita))
```

### 7.4 Error Handling

```dart
// Either<Failure, Success> pattern
class Failure {
  final String message;
  final int? statusCode;
}

Future<Either<Failure, Order>> createOrder(OrderRequest request) async {
  try {
    final response = await _apiClient.post('/orders/', data: request.toJson());
    return Right(Order.fromJson(response.data));
  } on DioException catch (e) {
    return Left(Failure(
      message: _mapDioError(e),
      statusCode: e.response?.statusCode,
    ));
  }
}
```

---

## 8. UI/UX Guidelines

### 8.1 Brand Colors (Martabak Theme)

```dart
class AppColors {
  // Primary: Coklat Martabak
  static const primary = Color(0xFFD2691E);      // Chocolate
  static const primaryLight = Color(0xFFE8A665);
  static const primaryDark = Color(0xFF8B4513);
  
  // Secondary: Emas/Amber
  static const secondary = Color(0xFFFFC107);
  static const secondaryLight = Color(0xFFFFD54F);
  static const secondaryDark = Color(0xFFFFA000);
  
  // Neutrals
  static const background = Color(0xFFFFF8F0);  // Cream white
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5F0E8);
  
  // Text
  static const textPrimary = Color(0xFF2D1B0E);
  static const textSecondary = Color(0xFF5D4037);
  static const textHint = Color(0xFF8D6E63);
  
  // Semantic
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFF9800);
  static const info = Color(0xFF2196F3);
}
```

### 8.2 Typography

```dart
class AppTypography {
  // Headlines: Big numbers (dashboard, totals)
  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  // Titles: Screen titles, card headers
  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body: Normal text
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  
  // Labels: Buttons, tabs
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
```

### 8.3 Spacing System

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  // Border radius
  static const radiusSm = 8;
  static const radiusMd = 12;
  static const radiusLg = 16;
  static const radiusXl = 24;
}
```

### 8.4 Touch Targets

Minimum touch target: **48x48 dp** (Google Material guidelines)

Untuk tombol aksi utama (Bayar Sekarang): **56dp height minimum**

### 8.5 Screen Layout Patterns

**Kasir Mode (4 tabs):**
```
┌─────────────────────────────────┐
│  [AppBar: "Martabak Pak Harto"] │  ← Shop name from settings
├─────────────────────────────────┤
│                                 │
│      CONTENT AREA               │
│      (scrollable)               │
│                                 │
├─────────────────────────────────┤
│  [🏠]  [📋]  [🕐]  [👤]        │  ← Bottom nav, 4 tabs
│  Order  Queue  History  Profile │
└─────────────────────────────────┘
```

**Owner Mode (7 tabs):**
```
┌─────────────────────────────────┐
│  [AppBar: Dashboard]            │
├─────────────────────────────────┤
│  [📊][📋][🕐][📜][🍽️][👥][⚙️] │  ← Bottom nav, 7 tabs
│  Dash Order Queue Menu Kasir Report Set │
└─────────────────────────────────┘
```

---

## 9. Features & Screens

### 9.1 Feature: Auth

**Screens:**
- `LoginScreen` — Grid user selection + PIN input
- `PinSetupScreen` — Initial PIN setup (first login)

**Widgets:**
- `UserGrid` — Grid of kasir avatars/names
- `PinKeypad` — Numeric keypad for PIN input
- `PinDots` — Visual PIN dots indicator

**BLoC:** `AuthBloc`
- Events: `LoginRequested`, `LogoutRequested`, `CheckSession`
- States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthError`

### 9.2 Feature: Menu

**Screens:**
- (Integrated into OrderScreen with category tabs)

**Widgets:**
- `CategoryTab` — Tab bar for manis/telur/tipis
- `MenuGrid` — Grid of `MenuCard` widgets
- `MenuCard` — Individual menu item card

**BLoC:** `MenuBloc`
- Events: `LoadMenus`, `FilterByCategory`
- States: `MenuLoading`, `MenuLoaded`, `MenuError`

### 9.3 Feature: Order

**Screens:**
- `OrderScreen` — Main order entry screen
- `CartSheet` — Bottom sheet showing cart items
- `QrDisplayScreen` — QRIS display with polling

**Widgets:**
- `CartItemTile` — Individual cart item with +/- controls
- `PaymentMethodToggle` — Toggle between GoQris/Cash
- `QrCodeWidget` — QR code display with countdown

**BLoC:** `OrderBloc`
- Events: `AddItem`, `RemoveItem`, `UpdateQty`, `SubmitOrder`, `CheckPaymentStatus`
- States: `OrderInitial`, `OrderCartUpdated`, `OrderSubmitting`, `OrderQrGenerated`, `OrderPaid`

### 9.4 Feature: Queue

**Screens:**
- `QueueScreen` — Shared queue display

**Widgets:**
- `QueueItemCard` — Order card with status indicator
- `QueueFilter` — Filter by status

**BLoC:** `QueueBloc`
- Events: `LoadQueue`, `RefreshQueue`
- States: `QueueLoading`, `QueueLoaded`, `QueueError`

### 9.5 Feature: History

**Screens:**
- `HistoryScreen` — Order history with date filter

**Widgets:**
- `OrderHistoryTile` — Order summary tile
- `DateFilterChip` — Quick date filters

**BLoC:** `HistoryBloc`
- Events: `LoadHistory`, `FilterByDate`
- States: `HistoryLoading`, `HistoryLoaded`, `HistoryError`

### 9.6 Feature: Reports (Owner Only)

**Screens:**
- `ReportsScreen` — Dashboard with summary
- `DailyReportScreen` — Detailed daily report
- `ProfitReportScreen` — Profit/loss report

**Widgets:**
- `StatCard` — Big number display card
- `TopMenuList` — Top selling menu items
- `KasirPerformanceTable` — Kasir stats table

**BLoC:** `ReportsBloc`
- Events: `LoadDailyReport`, `LoadProfitReport`
- States: `ReportsLoading`, `ReportsLoaded`, `ReportsError`

### 9.7 Feature: Settings (Owner Only)

**Screens:**
- `SettingsScreen` — App settings

**Widgets:**
- `SettingsTile` — Individual setting item
- `GoQrisStatusBadge` — GoQris connection status

**BLoC:** `SettingsBloc`
- Events: `LoadSettings`, `UpdateSettings`
- States: `SettingsLoading`, `SettingsLoaded`, `SettingsError`

### 9.8 Feature: Profile

**Screens:**
- `ProfileScreen` — User profile, change PIN, logout

**Widgets:**
- `ProfileHeader` — Avatar + name display
- `PinChangeForm` — Form to change PIN

**BLoC:** `ProfileBloc`
- Events: `LoadProfile`, `ChangePinRequested`
- States: `ProfileLoading`, `ProfileLoaded`, `PinChangeSuccess`

---

## 10. Libraries Reference

### 10.1 From awesome-flutter

**State Management:**
- [flutter_bloc](https://bloclibrary.dev) — BLoC pattern implementation
- [equatable](https://pub.dev/packages/equatable) — Value equality

**HTTP & Networking:**
- [dio](https://pub.dev/packages/dio) — HTTP client with interceptors
- [connectivity_plus](https://pub.dev/packages/connectivity_plus) — Network status

**Storage:**
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) — Encrypted storage for JWT
- [shared_preferences](https://pub.dev/packages/shared_preferences) — Simple key-value storage

**UI Components:**
- [qr_flutter](https://pub.dev/packages/qr_flutter) — QR code rendering
- [shimmer](https://pub.dev/packages/shimmer) — Loading skeleton
- [flutter_animate](https://pub.dev/packages/flutter_animate) — Declarative animations
- [badges](https://pub.dev/packages/badges) — Badge on icons
- [sliding_up_panel](https://pub.dev/packages/sliding_up_panel) — Sliding panel

**Navigation:**
- [go_router](https://pub.dev/packages/go_router) — Declarative routing

**Utilities:**
- [intl](https://pub.dev/packages/intl) — Internationalization, formatting
- [google_fonts](https://pub.dev/packages/google_fonts) — Google Fonts
- [freezed](https://pub.dev/packages/freezed) — Immutable classes
- [json_serializable](https://pub.dev/packages/json_serializable) — JSON code generation

### 10.2 Not Used (Avoid)

- ~~Provider~~ — Terlalu simple untuk app ini
- ~~get_it~~ — Overkill, DI tidak diperlukan untuk app ini
- ~~Riverpod~~ — flutter_bloc sudah cukup
- ~~GetX~~ — Tidak cocok untuk clean architecture

---

## 11. Setup & Development

### 11.1 Prerequisites

```bash
# Flutter SDK 3.44.x
flutter --version

# Android SDK
flutter doctor

# Node.js (untuk advanced tooling jika diperlukan)
node --version
```

### 11.2 Installation

```bash
# Navigate to frontend directory
cd frontend

# Get dependencies
flutter pub get

# Run app
flutter run
```

### 11.3 Environment Configuration

```bash
# Create .env file
cp .env.example .env

# Set API base URL
API_BASE_URL=http://localhost:8000/api/v1
```

### 11.4 Build Commands

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Build with custom API URL
flutter build apk --release --dart-define=API_BASE_URL=https://api.martabak.com/api/v1
```

---

## 12. Build & Deployment

### 12.1 Build APK

```bash
# Debug APK (for testing)
flutter build apk --debug

# Release APK (for production)
flutter build apk --release

# APK location
# frontend/build/app/outputs/flutter-apk/app-release.apk
```

### 12.2 Build with Environment

```bash
# Development
flutter build apk --debug \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=DEBUG_MODE=true

# Production
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.martabak.com/api/v1 \
  --dart-define=DEBUG_MODE=false
```

### 12.3 Readable APK

```bash
# Untuk testing di device langsung
flutter build apk --debug

# Install via ADB
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 12.4 ProGuard (Release)

ProGuard sudah dikonfigurasi otomatis oleh Flutter. Untuk custom rules, edit:
```
android/app/proguard-rules.pro
```

---

## Appendix A: Quick Reference

### A.1 Common Commands

```bash
# Setup
flutter pub get
flutter analyze

# Development
flutter run
flutter run -d <device_id>

# Build
flutter build apk --debug
flutter build apk --release

# Test
flutter test
flutter test --coverage
```

### A.2 Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Fix issues automatically
dart fix --apply
```

### A.3 Git Workflow

```bash
# Create feature branch
git checkout -b feat/order-flow

# Commit (conventional commits)
git commit -m "feat(order): add order creation with cart"

# Push
git push origin feat/order-flow
```

---

## Appendix B: Troubleshooting

### B.1 Common Issues

| Issue | Solution |
|-------|----------|
| `flutter pub get` failed | Check internet connection, run `flutter doctor` |
| Build failed | Run `flutter clean`, then `flutter pub get` |
| API connection failed | Check `API_BASE_URL` in environment |
| Token expired | Clear app data, re-login |

### B.2 Debug Mode

```dart
// Check if debug mode
const isDebug = bool.fromEnvironment('DEBUG_MODE', defaultValue: true);

// Log only in debug mode
if (isDebug) {
  print('API Response: $response');
}
```

---

## Appendix C: Related Documentation

- [Backend API Documentation](../backend/api-endpoints.md)
- [Backend Setup Guide](../backend/setup.md)
- [Data Models](../backend/models.md)
- [Deployment Guide](../deployment/README.md)
- [Backend Audit Reports](../backend/BACKEND_AUDIT*.md)

---

## Appendix D: Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-07-31 | 1.0.0 | Initial Flutter documentation |
| 2026-07-31 | 1.0.1 | Added Clean Architecture + MVC pattern |
| 2026-07-31 | 1.0.2 | Added BLoC state management pattern |

---

**Last Updated:** 2026-07-31  
**Author:** Mavis (Documentation Agent)  
**Version:** 1.0.2
