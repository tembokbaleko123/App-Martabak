import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../navigation/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryLoad());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const LoadingIndicator(message: 'Memuat riwayat...');
          }

          if (state is HistoryError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<HistoryBloc>().add(const HistoryLoad()),
            );
          }

          if (state is HistoryLoaded) {
            return Column(
              children: [
                _buildSummary(state),
                Expanded(
                  child: state.orders.isEmpty
                      ? const EmptyState(
                          title: 'Belum ada riwayat',
                          subtitle: 'Order yang sudah dibayar akan muncul di sini',
                          icon: Icons.history,
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<HistoryBloc>().add(const HistoryLoad());
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: state.orders.length,
                            itemBuilder: (context, index) {
                              final order = state.orders[index];
                              return _HistoryItemCard(order: order);
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummary(HistoryLoaded state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${state.orders.length}',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                'Transaksi',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Column(
            children: [
              Text(
                CurrencyFormatter.format(state.totalAmount),
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                'Total',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final OrderListItem order;

  const _HistoryItemCard({required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (order.status) {
      case 'paid':
        statusColor = AppColors.paid;
        break;
      case 'pending':
        statusColor = AppColors.pending;
        break;
      case 'expired':
        statusColor = AppColors.expired;
        break;
      case 'cancelled':
        statusColor = AppColors.cancelled;
        break;
      default:
        statusColor = AppColors.textHint;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          context.push('${RouteNames.orderDetail}?id=${order.id}');
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.refId,
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatWita(order.createdAtWita),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
