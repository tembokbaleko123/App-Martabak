import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/raw_material_service.dart';
import '../../../navigation/route_names.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  State<RawMaterialsScreen> createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  final RawMaterialService _service = RawMaterialService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _service.getCostEntries();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bahan Baku & Laba'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.profile),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${RouteNames.rawMaterials}/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat data...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadEntries,
      );
    }

    if (_entries.isEmpty) {
      return const EmptyState(
        title: 'Belum ada data',
        subtitle: 'Tambah entry biaya bahan baku untuk melihat laporan laba',
        icon: Icons.inventory_2_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return _CostEntryCard(
            entry: entry,
            onTap: () => context.go('${RouteNames.rawMaterials}/detail/${entry['id']}'),
          );
        },
      ),
    );
  }
}

class _CostEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const _CostEntryCard({
    required this.entry,
    required this.onTap,
  });

  String _formatDateRange(String from, String to) {
    final fromDate = DateTime.parse(from);
    final toDate = DateTime.parse(to);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${fromDate.day} ${months[fromDate.month - 1]} ${fromDate.year} - ${toDate.day} ${months[toDate.month - 1]} ${toDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = entry['items'] as List<dynamic>? ?? [];
    final itemNames = items.take(3).map((item) {
      final qty = item['quantity'];
      final unit = item['unit'] ?? '';
      final name = item['material_name'];
      return '$name $qty${unit.isNotEmpty ? ' $unit' : ''}';
    }).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatDateRange(entry['date_from'], entry['date_to']),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pengeluaran:', style: AppTypography.bodyMedium),
                  Text(
                    CurrencyFormatter.format(entry['total_cost'] ?? 0),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pendapatan:', style: AppTypography.bodyMedium),
                  Text(
                    CurrencyFormatter.format(entry['total_revenue'] ?? 0),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LABA:', style: AppTypography.labelLarge),
                  Text(
                    CurrencyFormatter.format(entry['profit'] ?? 0),
                    style: AppTypography.titleMedium.copyWith(
                      color: (entry['profit'] ?? 0) >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (itemNames.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '[$itemNames${items.length > 3 ? ', ...' : ''}]',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
