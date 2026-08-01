# 🐛 FRONTEND AUDIT REPORT - App Martabak Flutter

**Project:** Flutter Mobile App - App Martabak (Kasir POS)
**Repository:** `D:\penting_jangan_dihapus\Kodingan\Fullstack\App-Martabak\frontend`
**Audit Date:** 2026-08-01 (13:42 WITA)
**Auditor:** Verifier Agent
**Tech Stack:** Flutter 3.12, flutter_bloc, Dio, go_router

---

## 📊 EXECUTIVE SUMMARY

| Aspek | Penilaian | Catatan |
|-------|-----------|---------|
| State Management | ⭐⭐⭐⭐ | BLoC pattern applied correctly |
| Error Handling | ⭐⭐⭐ | Error states exist, but silent failures |
| Network Layer | ⭐⭐⭐ | Dio configured, but missing retry/refresh |
| UI/UX | ⭐⭐⭐⭐ | Clean Material design |
| Performance | ⭐⭐ | Background polling drains battery |
| Security | ⭐⭐⭐ | Token storage OK, no refresh mechanism |
| Testing | ⭐ | No widget/integration tests found |

**Findings:**

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 CRITICAL | 1 | New bugs found |
| 🟠 HIGH | 2 | New bugs found |
| 🟡 MEDIUM | 4 | New bugs found |
| 🔵 LOW | 3 | Observations |
| **Total** | **10 issues** | - |

---

## 🔴 CRITICAL BUGS

### BUG-F-001: QR Payment polling continues in background — battery drain

**Severity:** 🔴 CRITICAL (Performance / UX)
**Location:** `lib/features/order/screens/qr_display_screen.dart:51`
**Status:** OPEN
**Type:** Resource leak

**Evidence:**
```dart
void _startPolling() {
  _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    // ...
    final status = await _orderService.getOrderStatus(widget.orderId);
    // Polling continues even when app is in background!
  });
}
```

**Impact:**
- Timer continues running when app is in background
- Drains battery on mobile devices
- API calls waste bandwidth when user is not looking
- On iOS, background execution is restricted by OS

**Recommended Fix:**
```dart
@override
void initState() {
  super.initState();
  // Check if app is in foreground before polling
  _appLifecycleObserver = AppLifecycleObserver(
    onResume: _startPolling,
    onPause: _stopPolling,
  );
 WidgetsBinding.instance.addObserver(_appLifecycleObserver);
}

void _stopPolling() {
  _timer?.cancel();
  _timer = null;
}
```

---

### BUG-F-002: Queue polling continues in background

**Severity:** 🔴 CRITICAL (Performance)
**Location:** `lib/features/queue/screens/queue_screen.dart:43`
**Status:** OPEN
**Type:** Resource leak

**Evidence:**
```dart
void _startAutoRefresh() {
  _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
    if (mounted) {
      context.read<QueueBloc>().add(QueueRefresh());
    }
  });
}
```

**Impact:**
- Same as BUG-F-001
- Polls every 10 seconds even in background

**Recommended Fix:**
Same approach as BUG-F-001.

---

## 🟠 HIGH BUGS

### BUG-F-003: No JWT token refresh mechanism

**Severity:** 🟠 HIGH (Security / Availability)
**Location:** `lib/core/api/api_client.dart`
**Status:** OPEN
**Type:** Missing feature

**Evidence:**
```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  },
  onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      await _storage.deleteAll();  // Just clears tokens!
    }
    return handler.next(error);
  },
));
```

**Impact:**
- Access token expires after 12 hours
- When token expires, user is logged out immediately
- No automatic refresh using refresh token
- User experience: "logged out randomly"
- User must re-login after 12 hours even if they were active

**Backend Reference:**
```python
# config/base.py - SIMPLE_JWT settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=12),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': False,  # Old tokens still valid!
}
```

**Recommended Fix:**
```dart
Future<Response<T>> _handleWithRefresh<T>(DioException error) async {
  if (error.response?.statusCode == 401) {
    // Try to refresh token
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        final response = await _dio.post(
          ApiEndpoints.tokenRefresh,
          data: {'refresh': refreshToken},
        );
        final newAccess = response.data['access'];
        await _storage.write(key: 'access_token', value: newAccess);
        
        // Retry original request
        error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        return _dio.fetch(error.requestOptions);
      } catch (e) {
        // Refresh failed, logout
        await clearTokens();
      }
    }
  }
  throw _handleError(error);
}
```

---

### BUG-F-004: API base URL hardcoded fallback — exposes internal IP

**Severity:** 🟠 HIGH (Security)
**Location:** `lib/core/api/endpoints.dart:2-5`
**Status:** OPEN
**Type:** Information disclosure

**Evidence:**
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.16:8000/api/v1',  // ⚠️ Hardcoded IP!
);
```

**Impact:**
- If app is decompiled, reveals internal network IP `192.168.1.16`
- Attacker knows the server's internal address
- Debug builds ship with this hardcoded value
- Default value should be generic, not an actual IP

**Recommended Fix:**
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',  // Use localhost
);
```

---

## 🟡 MEDIUM BUGS

### BUG-F-005: History loads ALL orders without pagination

**Severity:** 🟡 MEDIUM (Performance)
**Location:** `lib/features/history/bloc/history_bloc.dart:19`
**Status:** OPEN
**Type:** Missing feature

**Evidence:**
```dart
Future<void> _onLoad(
  HistoryLoad event,
  Emitter<HistoryState> emit,
) async {
  // ...
  final orders = await _orderService.getMyOrders();  // No pagination!
}
```

**Backend Response:**
- `getMyOrders` uses `paginate_queryset` but frontend ignores pagination
- Only loads page 1
- If kasir has > 20 orders, older orders are not visible

**Recommended Fix:**
```dart
// Add pagination to history
Future<void> _onLoad(
  HistoryLoad event,
  Emitter<HistoryState> emit,
) async {
  emit(HistoryLoading());
  try {
    final allOrders = <OrderListItem>[];
    int page = 1;
    bool hasMore = true;
    
    while (hasMore) {
      final orders = await _orderService.getMyOrders(page: page);
      allOrders.addAll(orders);
      hasMore = orders.length >= 20;
      page++;
    }
    
    final totalAmount = allOrders.fold<int>(0, (sum, o) => sum + o.totalAmount);
    emit(HistoryLoaded(orders: allOrders, totalAmount: totalAmount));
  } catch (e) {
    emit(HistoryError(e.toString()));
  }
}
```

Or add "load more" functionality.

---

### BUG-F-006: Order status check silently ignores errors

**Severity:** 🟡 MEDIUM (Observability)
**Location:** `lib/features/order/bloc/order_bloc.dart:149-162`
**Status:** OPEN
**Type:** Silent failure

**Evidence:**
```dart
Future<void> _onCheckStatus(
  OrderCheckStatus event,
  Emitter<OrderState> emit,
) async {
  try {
    final status = await _orderService.getOrderStatus(event.orderId);
    if (status.status == 'paid') {
      final order = await _orderService.getOrderDetail(event.orderId);
      emit(OrderPaid(order));
    }
  } catch (e) {
    // Ignore status check errors — NO logging!
  }
}
```

**Impact:**
- Network errors are silently swallowed
- If payment verification fails, user sees no feedback
- QR might be marked as paid but UI doesn't update

**Recommended Fix:**
```dart
} catch (e) {
  // Log error but don't crash
  debugPrint('Order status check failed: $e');
  // Optionally emit error state for UI feedback
}
```

---

### BUG-F-007: QR Display has no countdown timer

**Severity:** 🟡 MEDIUM (UX)
**Location:** `lib/features/order/screens/qr_display_screen.dart`
**Status:** OPEN
**Type:** Missing feature

**Evidence:**
- `widget.expiresAt` is received but never displayed
- User sees no countdown to expiration
- QR shows "expired" status but no time remaining

**Current behavior:**
```dart
// expiresAt is stored but only used for isExpired check
final DateTime? expiresAt;  // Not displayed to user
```

**Impact:**
- User doesn't know when QR expires
- Cannot plan their payment time
- Frustrating UX when QR suddenly shows "expired"

**Recommended Fix:**
```dart
Timer? _countdownTimer;
Duration? _timeRemaining;

void _startCountdown() {
  if (widget.expiresAt == null) return;
  
  _updateTimeRemaining();
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    _updateTimeRemaining();
  });
}

void _updateTimeRemaining() {
  if (widget.expiresAt == null) return;
  final remaining = widget.expiresAt!.difference(DateTime.now());
  if (remaining.isNegative) {
    _countdownTimer?.cancel();
    setState(() => _isExpired = true);
  } else {
    setState(() => _timeRemaining = remaining);
  }
}

// In build():
Text(
  'Berlaku selama: ${_formatDuration(_timeRemaining)}',
  style: AppTypography.bodyMedium,
)
```

---

### BUG-F-008: No retry mechanism for failed API calls

**Severity:** 🟡 MEDIUM (Resilience)
**Location:** `lib/core/api/api_client.dart`
**Status:** OPEN
**Type:** Missing feature

**Evidence:**
```dart
Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
  try {
    return await _dio.get<T>(path, queryParameters: queryParameters);
  } on DioException catch (e) {
    throw _handleError(e);  // Immediate failure, no retry
  }
}
```

**Impact:**
- Single network hiccup = failed request
- Poor UX on unstable connections (mobile)
- No automatic retry for transient errors

**Recommended Fix:**
```dart
Future<Response<T>> _retryWithBackoff<T>(
  Future<Response<T>> Function() request,
  {int maxRetries = 3}
) async {
  int attempts = 0;
  while (true) {
    try {
      return await request();
    } on DioException catch (e) {
      attempts++;
      if (attempts >= maxRetries) throw _handleError(e);
      if (_isRetryable(e)) {
        await Future.delayed(Duration(seconds: attempts * 2));
        continue;
      }
      throw _handleError(e);
    }
  }
}

bool _isRetryable(DioException e) {
  return e.type == DioExceptionType.connectionTimeout ||
         e.type == DioExceptionType.receiveTimeout ||
         (e.response?.statusCode == 503);
}
```

---

## 🔵 LOW / OBSERVATIONS

### OBS-F-001: Login PIN input is 6 digits but backend accepts 4 digits

**Severity:** 🔵 LOW (Inconsistency)
**Location:** `lib/features/auth/screens/login_screen.dart:125` vs `backend/apps/accounts/serializers.py:94`
**Status:** Known issue (BUG-M-057 backend)

**Evidence:**
```dart
PinInput(
  length: 6,  // Frontend: 6 digits
  onCompleted: _onPinCompleted,
),
```

```python
# Backend: min_length=4
pin = serializers.CharField(max_length=6, min_length=4, write_only=True)
```

**Impact:** Minor UX inconsistency.

---

### OBS-F-002: No connectivity indicator

**Severity:** 🔵 LOW (UX)
**Location:** General
**Status:** OPEN

**Evidence:** No offline mode detection or connectivity banner.

**Recommended Fix:** Add connectivity observer to show offline banner.

---

### OBS-F-003: No pull-to-refresh on History screen

**Severity:** 🔵 LOW (UX)
**Location:** `lib/features/history/screens/history_screen.dart`
**Status:** OPEN

**Evidence:** `HistoryScreen` uses `ListView` but doesn't support pull-to-refresh.

**Recommended Fix:** Wrap in `RefreshIndicator`.

---

## 📊 FRONTEND-RELATED BACKEND BUGS

The following backend bugs directly impact frontend UX:

| Backend Bug | Frontend Impact | Fix Priority |
|------------|-----------------|--------------|
| BUG-M-054 | QR payments never auto-confirm (Celery Beat not configured) | HIGH |
| BUG-M-056 | PIN validation different on frontend (6-digit) vs backend | LOW |
| BUG-M-057 | Kasir can be created with 4-digit PIN, but login requires 6 | LOW |
| BUG-M-060 | my_orders endpoint has N+1 query, slow loading | MEDIUM |

---

## 🎯 COMBINED STATUS (Backend + Frontend)

| System | Bugs Found | Fixed | Open |
|--------|-----------|-------|------|
| Backend (4 rounds) | 39 bugs | 33 | 6 |
| Frontend (Round 1) | 10 issues | 0 | 10 |
| **Total** | **49 issues** | **33** | **16** |

**Estimated Production Readiness:**
- Backend: 65/100
- Frontend: 55/100
- Combined: ~60/100

---

## 📋 RECOMMENDED FIXES (Priority Order)

| Priority | Issue | Severity | Fix Time | Impact |
|----------|-------|----------|----------|--------|
| 1 | BUG-F-001 + F-002 | 🔴 CRITICAL | 30 min | Battery drain |
| 2 | BUG-F-003 | 🟠 HIGH | 60 min | Token expiry UX |
| 3 | BUG-F-004 | 🟠 HIGH | 5 min | Security hardening |
| 4 | BUG-F-007 | 🟡 MEDIUM | 30 min | UX improvement |
| 5 | BUG-F-006 | 🟡 MEDIUM | 10 min | Error visibility |
| 6 | BUG-F-008 | 🟡 MEDIUM | 45 min | Network resilience |
| 7 | BUG-F-005 | 🟡 MEDIUM | 45 min | Scalability |
| 8 | OBS-F-002 + F-003 | 🔵 LOW | 30 min | UX polish |

**Total estimated fix time:** ~4 hours

---

## 📎 APPENDIX

### Files Analyzed

| File | Key Findings |
|------|-------------|
| `lib/core/api/api_client.dart` | Token refresh missing, no retry |
| `lib/core/api/endpoints.dart` | Hardcoded IP in default URL |
| `lib/data/services/order_service.dart` | Pagination not used |
| `lib/features/order/bloc/order_bloc.dart` | Silent error swallowing |
| `lib/features/order/screens/qr_display_screen.dart` | Background polling |
| `lib/features/queue/screens/queue_screen.dart` | Background polling |
| `lib/features/history/bloc/history_bloc.dart` | No pagination |
| `lib/features/reports/bloc/reports_bloc.dart` | Date formatting OK |
| `lib/navigation/app_router.dart` | Auth redirect OK |
| `pubspec.yaml` | Dependencies OK, no mockito |

### Architecture Assessment

**Strengths:**
- Clean BLoC pattern for state management
- Separation of concerns (services, models, blocs)
- GoRouter for navigation
- Equatable for state comparison
- Dio for HTTP with interceptors

**Weaknesses:**
- No token refresh mechanism
- Background polling without lifecycle awareness
- No retry/backoff for network errors
- No pagination support
- No offline mode
- Limited error visibility

---

*End of Frontend Audit Report*

**Audit Date:** 2026-08-01 13:42 WITA
**Auditor:** Verifier Agent
**Total Issues Found:** 10
**Recommended Priority Fixes:** 8
