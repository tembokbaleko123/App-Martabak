import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/order_service.dart';
import '../../order/bloc/order_bloc.dart';
import '../../order/bloc/order_event.dart';

class QrDisplayScreen extends StatefulWidget {
  final int orderId;
  final String qrString;
  final DateTime? expiresAt;
  final int totalAmount;

  const QrDisplayScreen({
    super.key,
    required this.orderId,
    required this.qrString,
    this.expiresAt,
    required this.totalAmount,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _countdownTimer;
  final OrderService _orderService = OrderService();
  bool _isExpired = false;
  bool _isPaid = false;
  bool _isInForeground = true;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isInForeground = false;
      _timer?.cancel();
      _countdownTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _isInForeground = true;
      _startPolling();
      _startCountdown();
    }
  }

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
      if (!_isExpired) {
        setState(() {
          _isExpired = true;
          _timeRemaining = null;
        });
      }
    } else {
      setState(() {
        _timeRemaining = remaining;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isPaid || _isExpired || !_isInForeground) {
        timer.cancel();
        return;
      }

      try {
        final status = await _orderService.getOrderStatus(widget.orderId);

        if (status.status == 'paid') {
          setState(() {
            _isPaid = true;
          });
          timer.cancel();
          _showPaidDialog();
        } else if (status.isExpired) {
          setState(() {
            _isExpired = true;
          });
          timer.cancel();
        }
      } catch (e) {
        debugPrint('Order status check failed: $e');
      }
    });
  }

  void _showPaidDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 80,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'LUNAS!',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pembayaran berhasil',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<OrderBloc>().add(OrderReset());
                context.pop();
              },
              child: const Text('Order Baru'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QRIS'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<OrderBloc>().add(OrderReset());
            context.pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Bayar',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                CurrencyFormatter.format(widget.totalAmount),
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.qrString,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'QR Kedaluwarsa',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_timeRemaining != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _timeRemaining!.inSeconds < 60
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _timeRemaining!.inSeconds < 60
                              ? AppColors.warning
                              : AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Berlaku: ${_formatDuration(_timeRemaining!)}',
                          style: AppTypography.labelLarge.copyWith(
                            color: _timeRemaining!.inSeconds < 60
                                ? AppColors.warning
                                : AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Silakan scan dengan aplikasi QRIS',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'atau',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<OrderBloc>().add(OrderReset());
                  context.pop();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Buat Order Baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
