import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/models/user_model.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/order/screens/order_screen.dart';
import '../features/order/screens/qr_display_screen.dart';
import '../features/queue/screens/queue_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/menu/screens/menu_manage_screen.dart';
import '../features/menu/screens/kasir_manage_screen.dart';
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
          path: RouteNames.order + '/qr',
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
    if (widget.user.isOwner) {
      switch (location) {
        case RouteNames.order:
          return 1;
        case RouteNames.queue:
          return 2;
        case RouteNames.history:
          return 3;
        case RouteNames.menuManage:
          return 4;
        case RouteNames.kasirManage:
          return 5;
        case RouteNames.reports:
          return 6;
        case RouteNames.settings:
          return 7;
        case RouteNames.profile:
          return 8;
        default:
          return 1;
      }
    } else {
      switch (location) {
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
  }

  List<BottomNavigationBarItem> _getItems() {
    if (widget.user.isOwner) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Order'),
        BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Antrian'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kasir'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setelan'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Order'),
        BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Antrian'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }
  }

  void _onItemTapped(int index) {
    if (widget.user.isOwner) {
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
          context.go(RouteNames.menuManage);
          break;
        case 4:
          context.go(RouteNames.kasirManage);
          break;
        case 5:
          context.go(RouteNames.reports);
          break;
        case 6:
          context.go(RouteNames.settings);
          break;
        case 7:
          context.go(RouteNames.profile);
          break;
      }
    } else {
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
