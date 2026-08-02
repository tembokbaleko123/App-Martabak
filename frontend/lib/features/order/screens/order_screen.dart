import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../navigation/route_names.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/menu_grid.dart';
import '../widgets/category_tab.dart';
import '../widgets/cart_item_tile.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderLoadMenus());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state;
    final isOwner = user is AuthAuthenticated && user.user.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Baru'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () => context.push(RouteNames.menuManage),
            ),
        ],
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is OrderQrGenerated) {
            context.push(
              '${RouteNames.order}/qr',
              extra: {
                'order_id': state.order.id,
                'qr_string': state.order.qrString,
                'expires_at': state.order.expiresAt,
                'total_amount': state.order.totalAmount,
              },
            );
          } else if (state is OrderPaid) {
            _showSuccessDialog(context, state);
          } else if (state is OrderPaymentFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Bayar Cash',
                  textColor: Colors.black,
                  onPressed: () {
                    _showCashConfirmationDialog(context);
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) {
            return const LoadingIndicator(message: 'Memuat menu...');
          }

          if (state is OrderError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<OrderBloc>().add(OrderLoadMenus()),
            );
          }

          if (state is OrderSubmitting) {
            return const LoadingIndicator(message: 'Memproses order...');
          }

          if (state is OrderMenuLoaded) {
            return Column(
              children: [
                BlocSelector<OrderBloc, OrderState, int?>(
                  selector: (state) => state is OrderMenuLoaded ? state.selectedCategoryId : null,
                  builder: (context, selectedCategoryId) {
                    return CategoryTab(
                      categories: state.categories,
                      selectedCategoryId: selectedCategoryId,
                      onCategorySelected: (categoryId) {
                        context.read<OrderBloc>().add(OrderSelectCategory(categoryId));
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari menu...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                    ),
                    onChanged: (value) {
                      _searchDebouncer.run(() {
                        context.read<OrderBloc>().add(OrderSearch(value));
                      });
                    },
                  ),
                ),
                Expanded(
                  child: MenuGrid(
                    menus: state.filteredMenus,
                    onMenuTap: (menu) {
                      context.read<OrderBloc>().add(OrderAddItem(menu: menu));
                    },
                  ),
                ),
                if (state.cart.isNotEmpty) _buildCartSummary(context, state),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, OrderMenuLoaded state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.itemCount} item',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  CurrencyFormatter.format(state.totalAmount),
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCartSheet(context),
                    child: const Text('Lihat Keranjang'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _showPaymentDialog(context, state),
                    child: const Text('Bayar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) {
        return BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is! OrderMenuLoaded) {
              return const SizedBox.shrink();
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (sheetContext, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Keranjang', style: AppTypography.titleLarge),
                          TextButton(
                            onPressed: () {
                              context.read<OrderBloc>().add(OrderClearCart());
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Hapus Semua'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: state.cart.length,
                        itemBuilder: (sheetContext, index) {
                          final item = state.cart[index];
                          return CartItemTile(
                            item: item,
                            onQtyChanged: (qty) {
                              context.read<OrderBloc>().add(
                                    OrderUpdateQty(menuId: item.menu.id, qty: qty),
                                  );
                            },
                            onRemove: () {
                              context.read<OrderBloc>().add(OrderRemoveItem(item.menu.id));
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, OrderMenuLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Metode Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: Untuk makan di tempat',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: const Icon(Icons.qr_code, color: AppColors.primary),
                title: const Text('GoQris QRIS'),
                subtitle: const Text('Bayar dengan scan QR'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  context.read<OrderBloc>().add(
                        OrderSubmit(
                          paymentMethod: 'goqris',
                          note: _noteController.text,
                        ),
                      );
                  _noteController.clear();
                },
              ),
              ListTile(
                leading: const Icon(Icons.money, color: AppColors.success),
                title: const Text('Tunai'),
                subtitle: const Text('Bayar langsung'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  context.read<OrderBloc>().add(
                        OrderSubmit(
                          paymentMethod: 'cash',
                          note: _noteController.text,
                        ),
                      );
                  _noteController.clear();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, OrderPaid state) {
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
                state.order.refId,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                CurrencyFormatter.format(state.order.totalAmount),
                style: AppTypography.titleLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<OrderBloc>().add(OrderReset());
              },
              child: const Text('Order Baru'),
            ),
          ],
        );
      },
    );
  }

  void _showCashConfirmationDialog(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembayaran Cash'),
          content: const Text(
            'Yakin ingin mengubah metode pembayaran ke Cash?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<OrderBloc>().add(const OrderSubmit(
                  paymentMethod: 'cash',
                ));
              },
              child: const Text('Ya, Bayar Cash'),
            ),
          ],
        );
      },
    );
  }
}
