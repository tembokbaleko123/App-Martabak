import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/connectivity_bloc.dart';
import '../bloc/connectivity_event.dart';
import '../bloc/connectivity_state.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state.status == ConnectivityStateStatus.connected) {
          return const SizedBox.shrink();
        }

        final Color backgroundColor;
        final Color textColor;
        final IconData icon;
        final String message;

        switch (state.status) {
          case ConnectivityStateStatus.disconnected:
            backgroundColor = AppColors.error;
            textColor = Colors.white;
            icon = Icons.wifi_off;
            message = 'Tidak ada koneksi internet';
            break;
          case ConnectivityStateStatus.serverUnreachable:
            backgroundColor = AppColors.warning;
            textColor = Colors.black87;
            icon = Icons.cloud_off;
            message = 'Server tidak dapat dijangkau';
            break;
          case ConnectivityStateStatus.connected:
            return const SizedBox.shrink();
        }

        return Material(
          color: backgroundColor,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ConnectivityBloc>().add(CheckServerReachability());
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: AppTypography.labelMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
