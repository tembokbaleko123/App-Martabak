import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/connectivity_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/order/bloc/order_bloc.dart';
import 'features/queue/bloc/queue_bloc.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/reports/bloc/reports_bloc.dart';
import 'features/connectivity/bloc/connectivity_bloc.dart';
import 'features/connectivity/bloc/connectivity_event.dart';
import 'features/connectivity/widgets/connectivity_banner.dart';
import 'navigation/app_router.dart';

class AppMartabak extends StatefulWidget {
  const AppMartabak({super.key});

  @override
  State<AppMartabak> createState() => _AppMartabakState();
}

class _AppMartabakState extends State<AppMartabak> {
  @override
  void initState() {
    super.initState();
    ConnectivityService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc()..add(AuthCheckSession()),
        ),
        BlocProvider(create: (_) => OrderBloc()),
        BlocProvider(create: (_) => QueueBloc()),
        BlocProvider(create: (_) => HistoryBloc()),
        BlocProvider(create: (_) => ReportsBloc()),
        BlocProvider(create: (_) => ConnectivityBloc()..add(ConnectivityCheck())),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Martabak',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Column(
                children: [
                  const ConnectivityBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              );
            },
            routerConfig: AppRouter.router(context.read<AuthBloc>()),
          );
        },
      ),
    );
  }
}
