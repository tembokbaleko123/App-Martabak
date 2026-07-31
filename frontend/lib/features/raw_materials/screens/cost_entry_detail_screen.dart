import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/raw_material_service.dart';
import '../../../navigation/route_names.dart';
import '../../../shared/widgets/loading_indicator.dart';

class CostEntryDetailScreen extends StatefulWidget {
  final int entryId;

  const CostEntryDetailScreen({super.key, required this.entryId});

  @override
  State<CostEntryDetailScreen> createState() => _CostEntryDetailScreenState();
}

class _CostEntryDetailScreenState extends State<CostEntryDetailScreen> {
  final RawMaterialService _service = RawMaterialService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _entry;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entry = await _service.getCostEntry(widget.entryId);
      setState(() {
        _entry = entry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Entry'),
        content: const Text('Apakah Anda yakin ingin menghapus entry ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await _service.deleteCostEntry(widget.entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(RouteNames.rawMaterials);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.rawMaterials),
        ),
        actions: [
          IconButton(
            onPressed: _isDeleting ? null : _deleteEntry,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat...');
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadEntry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_entry == null) {
      return const Center(child: Text('Data tidak ditemukan'));
    }

    final items = _entry!['items'] as List<dynamic>? ?? [];
    final notes = _entry!['notes'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_formatDate(_entry!['date_from'])} - ${_formatDate(_entry!['date_to'])}',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Item:', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value as Map<String, dynamic>;
                final isLast = index == items.length - 1;
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(
                      bottom: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['material_name'] ?? '',
                              style: AppTypography.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${item['quantity']} ${item['unit'] ?? ''} × ${CurrencyFormatter.format(item['price_per_unit'])}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item['subtotal'] ?? 0),
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Catatan:', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(notes, style: AppTypography.bodyMedium),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SummaryCard(
            totalCost: _entry!['total_cost'] ?? 0,
            totalRevenue: _entry!['total_revenue'] ?? 0,
            profit: _entry!['profit'] ?? 0,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalCost;
  final int totalRevenue;
  final int profit;

  const _SummaryCard({
    required this.totalCost,
    required this.totalRevenue,
    required this.profit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Biaya:', style: AppTypography.titleMedium),
              Text(
                CurrencyFormatter.format(totalCost),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pendapatan:', style: AppTypography.titleMedium),
              Text(
                CurrencyFormatter.format(totalRevenue),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LABA:', style: AppTypography.titleLarge),
              Text(
                CurrencyFormatter.format(profit),
                style: AppTypography.titleLarge.copyWith(
                  color: profit >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
