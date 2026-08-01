import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/order_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  OrderModel? _order;
  String? _error;
  bool _isCancelling = false;
  Timer? _countdownTimer;
  Duration? _timeRemaining;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final order = await _orderService.getOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_order?.expiresAt == null) return;

    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    if (_order?.expiresAt == null) return;

    final remaining = _order!.expiresAt!.difference(DateTime.now());
    if (remaining.isNegative && !_isExpired) {
      setState(() {
        _isExpired = true;
        _timeRemaining = Duration.zero;
      });
      _countdownTimer?.cancel();
      _loadOrderDetail();
    } else if (!remaining.isNegative) {
      setState(() {
        _timeRemaining = remaining;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Order'),
        content: const Text('Apakah Anda yakin ingin membatalkan order ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      await _orderService.cancelOrder(widget.orderId);
      _loadOrderDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat detail order...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadOrderDetail,
      );
    }

    if (_order == null) {
      return const Center(child: Text('Order tidak ditemukan'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildItemsSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildSummary(),
          const SizedBox(height: AppSpacing.lg),
          _buildPaymentInfo(),
          if (_order!.isPending && _order!.qrString != null && _order!.qrString!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildQrSection(),
          ],
          if (_order!.isPending) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildCancelButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text('QR Code Pembayaran', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: QrImageView(
                data: _order!.qrString!,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_timeRemaining != null && !_isExpired) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Berlaku selama: ${_formatDuration(_timeRemaining!)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (_isExpired) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'QR sudah kadaluarsa',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_order!.refId, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (_order!.kasirName != null)
              Text(
                'Kasir: ${_order!.kasirName}',
                style: AppTypography.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.formatWita(_order!.createdAtWita),
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
                _buildStatusBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor = Colors.white;
    String label;

    switch (_order!.status) {
      case 'paid':
        bgColor = AppColors.success;
        label = 'LUNAS';
        break;
      case 'pending':
        bgColor = Colors.orange;
        label = 'MENUNGGU';
        break;
      case 'expired':
        bgColor = AppColors.error;
        label = 'KADALUARSA';
        break;
      case 'cancelled':
        bgColor = AppColors.textHint;
        label = 'DIBATALKAN';
        break;
      default:
        bgColor = AppColors.textHint;
        label = _order!.status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: _order!.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildItemTile(item),
                  if (index < _order!.items.length - 1)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Text(
            item.menuEmoji ?? '🍽️',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuName ?? 'Menu',
                  style: AppTypography.labelLarge,
                ),
                Text(
                  '${item.qty} x ${CurrencyFormatter.format(item.priceAtOrder)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTypography.titleMedium),
                Text(
                  CurrencyFormatter.format(_order!.totalAmount),
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.payment,
              'Pembayaran',
              _order!.paymentMethodLabel,
            ),
            if (_order!.note != null && _order!.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildInfoRow(
                Icons.note,
                'Catatan',
                _order!.note!,
              ),
            ],
            if (_order!.paidAtWita != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildInfoRow(
                Icons.check_circle,
                'Dibayar',
                DateFormatter.formatWita(_order!.paidAtWita!),
              ),
            ],
            if (_order!.isPending && _order!.expiresAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildInfoRow(
                Icons.timer,
                'Berlaku hingga',
                DateFormatter.formatWita(_order!.expiresAtWita!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCancelling ? null : _cancelOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
        ),
        child: _isCancelling
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Batalkan Order'),
      ),
    );
  }
}
