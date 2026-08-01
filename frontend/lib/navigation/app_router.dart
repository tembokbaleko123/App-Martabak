import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/models/user_model.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/order/screens/order_screen.dart';
import '../features/order/screens/order_detail_screen.dart';
import '../features/order/screens/qr_display_screen.dart';
import '../features/queue/screens/queue_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/menu/screens/menu_manage_screen.dart';
import '../features/menu/screens/kasir_manage_screen.dart';
import '../features/raw_materials/screens/raw_materials_screen.dart';
import '../features/raw_materials/screens/add_cost_entry_screen.dart';
import '../features/raw_materials/screens/cost_entry_detail_screen.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: RouteNames.login,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoginRoute = state.matchedLocation == RouteNames.login;

        if (authState is AuthAuthenticated) {
          if (isLoginRoute) {
            return authState.user.isOwner ? RouteNames.ownerHome : RouteNames.kasirHome;
          }
        } else if (authState is AuthUnauthenticated) {
          if (!isLoginRoute) {
            return RouteNames.login;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            final user = context.read<AuthBloc>().state;
            if (user is AuthAuthenticated) {
              return MainShell(user: user.user, child: child);
            }
            return child;
          },
          routes: [
            GoRoute(
              path: RouteNames.kasirHome,
              redirect: (context, state) => RouteNames.order,
            ),
            GoRoute(
              path: RouteNames.ownerHome,
              redirect: (context, state) => RouteNames.order,
            ),
            GoRoute(
              path: RouteNames.order,
              builder: (context, state) => const OrderScreen(),
            ),
            GoRoute(
              path: RouteNames.queue,
              builder: (context, state) => const QueueScreen(),
            ),
            GoRoute(
              path: RouteNames.history,
              builder: (context, state) => const HistoryScreen(),
            ),
            GoRoute(
              path: RouteNames.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: RouteNames.menuManage,
              builder: (context, state) => const MenuManageScreen(),
            ),
            GoRoute(
              path: RouteNames.kasirManage,
              builder: (context, state) => const KasirManageScreen(),
            ),
            GoRoute(
              path: RouteNames.reports,
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: RouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '${RouteNames.order}/qr',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return QrDisplayScreen(
              orderId: extra?['order_id'] as int,
              qrString: extra?['qr_string'] as String,
              expiresAt: extra?['expires_at'] as DateTime?,
              totalAmount: extra?['total_amount'] as int,
            );
          },
        ),
        GoRoute(
          path: RouteNames.orderDetail,
          builder: (context, state) {
            final id = int.parse(state.uri.queryParameters['id']!);
            return OrderDetailScreen(orderId: id);
          },
        ),
        GoRoute(
          path: RouteNames.rawMaterials,
          builder: (context, state) => const RawMaterialsScreen(),
        ),
        GoRoute(
          path: '${RouteNames.rawMaterials}/add',
          builder: (context, state) => const AddCostEntryScreen(),
        ),
        GoRoute(
          path: '${RouteNames.rawMaterials}/detail/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CostEntryDetailScreen(entryId: id);
          },
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}

class MainShell extends StatefulWidget {
  final UserModel user;
  final Widget child;

  const MainShell({super.key, required this.user, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case RouteNames.kasirHome:
      case RouteNames.ownerHome:
      case RouteNames.order:
        return 0;
      case RouteNames.queue:
        return 1;
      case RouteNames.history:
        return 2;
      case RouteNames.profile:
        return 3;
      default:
        return 0;
    }
  }

  List<BottomNavigationBarItem> _getItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Order'),
      BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Antrian'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.order);
        break;
      case 1:
        context.go(RouteNames.queue);
        break;
      case 2:
        context.go(RouteNames.history);
        break;
      case 3:
        context.go(RouteNames.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getSelectedIndex(context),
        onTap: _onItemTapped,
        items: _getItems(),
      ),
    );
  }
}
