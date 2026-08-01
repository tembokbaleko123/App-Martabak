class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.16:8000/api/v1',
  );

  static const String health = '/health/';
  static const String pinLogin = '/accounts/pin/';
  static const String changePin = '/accounts/change-pin/';
  static const String me = '/accounts/me/';
  static const String loginUsers = '/accounts/login-users/';
  static const String kasirs = '/accounts/kasirs/';
  static const String resetPin = '/accounts/kasirs/{id}/reset-pin/';
  static const String tokenRefresh = '/accounts/token/refresh/';

  static const String categories = '/categories/';
  static const String categoriesAll = '/categories/all/';
  static const String menus = '/menus/';
  static const String menusAll = '/menus/all/';
  static const String menusBulk = '/menus/bulk/';

  static const String orders = '/orders/';
  static const String ordersMe = '/orders/me/';
  static const String ordersQueue = '/orders/queue/';
  static const String orderStatus = '/orders/{id}/status/';
  static const String orderCancel = '/orders/{id}/cancel/';

  static const String reportsDaily = '/reports/daily/';
  static const String reportsTopMenus = '/reports/top-menus/';
  static const String reportsKasirPerformance = '/reports/kasir-performance/';
  static const String reportsProfit = '/reports/profit/';

  static const String settings = '/settings/';

  static const String goqrisProfile = '/goqris/profile/';

  static const String rawMaterialsItems = '/raw-materials/items/';
  static const String rawMaterialsCostEntries = '/raw-materials/cost-entries/';
}
