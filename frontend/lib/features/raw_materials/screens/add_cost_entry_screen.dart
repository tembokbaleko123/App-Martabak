import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/raw_material_service.dart';
import '../../../navigation/route_names.dart';

class AddCostEntryScreen extends StatefulWidget {
  const AddCostEntryScreen({super.key});

  @override
  State<AddCostEntryScreen> createState() => _AddCostEntryScreenState();
}

class _AddCostEntryScreenState extends State<AddCostEntryScreen> {
  final RawMaterialService _service = RawMaterialService();
  final _notesController = TextEditingController();

  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime _dateTo = DateTime.now();
  final List<_CostItem> _items = [_CostItem()];
  bool _isSaving = false;

  int get _totalCost {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_CostItem());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      final item = _items[index];
      setState(() {
        _items.removeAt(index);
      });
      item.dispose();
    }
  }

  Future<void> _save() async {
    final validItems = _items.where((item) => item.isValid).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 1 item bahan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final itemsData = validItems.map((item) => {
        'material_name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'price_per_unit': item.pricePerUnit,
      }).toList();

      await _service.createCostEntry(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        items: itemsData,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(RouteNames.rawMaterials);
      }
    } catch (e) {
      setState(() => _isSaving = false);
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.rawMaterials),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${_formatDate(_dateFrom)}  →  ${_formatDate(_dateTo)}',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bahan Baku', style: AppTypography.titleMedium),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _CostItemWidget(
                key: ValueKey(item),
                item: item,
                index: index,
                onRemove: () => _removeItem(index),
                showRemove: _items.length > 1,
                onChanged: () => setState(() {}),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            Text('Catatan (opsional)', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Belanja minggu ini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SummaryCard(totalCost: _totalCost),
          ],
        ),
      ),
    );
  }
}

class _CostItem {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final priceController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  String get unit => unitController.text;
  int get pricePerUnit => int.tryParse(priceController.text) ?? 0;
  int get subtotal => (quantity * pricePerUnit).round();
  bool get isValid => nameController.text.isNotEmpty && quantity > 0 && pricePerUnit > 0;
  String get name => nameController.text;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}

class _CostItemWidget extends StatelessWidget {
  final _CostItem item;
  final int index;
  final VoidCallback onRemove;
  final bool showRemove;
  final VoidCallback onChanged;

  const _CostItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.showRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: item.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bahan',
                    hintText: 'Contoh: Tepung',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (showRemove) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'kg, gram, butir...',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga/Unit',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '= ${CurrencyFormatter.format(item.subtotal)}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalCost;

  const _SummaryCard({required this.totalCost});

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
          Text(
            'Pendapatan dan Laba akan dihitung otomatis berdasarkan tanggal yang dipilih',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
