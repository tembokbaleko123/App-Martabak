import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/order/bloc/order_bloc.dart';
import 'features/queue/bloc/queue_bloc.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/reports/bloc/reports_bloc.dart';
import 'navigation/app_router.dart';

class AppMartabak extends StatelessWidget {
  const AppMartabak({super.key});

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
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Martabak',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router(context.read<AuthBloc>()),
          );
        },
      ),
    );
  }
}
