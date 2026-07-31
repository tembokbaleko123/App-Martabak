import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/menu_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';

class MenuManageScreen extends StatefulWidget {
  const MenuManageScreen({super.key});

  @override
  State<MenuManageScreen> createState() => _MenuManageScreenState();
}

class _MenuManageScreenState extends State<MenuManageScreen> {
  final ApiClient _client = ApiClient();
  bool _isLoading = true;
  List<MenuModel> _menus = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.get(ApiEndpoints.menusAll);
      final list = response.data as List<dynamic>;
      setState(() {
        _menus = list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
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
        title: const Text('Kelola Menu'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenuDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat menu...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadMenus,
      );
    }

    if (_menus.isEmpty) {
      return const EmptyState(
        title: 'Belum ada menu',
        subtitle: 'Tambah menu baru untuk memulai',
        icon: Icons.menu_book,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMenus,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _menus.length,
        itemBuilder: (context, index) {
          final menu = _menus[index];
          return _MenuCard(
            menu: menu,
            onToggleActive: () => _toggleMenuActive(menu),
            onEdit: () => _showEditMenuDialog(menu),
            onDelete: () => _deleteMenu(menu),
          );
        },
      ),
    );
  }

  Future<void> _toggleMenuActive(MenuModel menu) async {
    try {
      await _client.patch(
        '${ApiEndpoints.menus}${menu.id}/',
        data: {'is_active': !menu.isActive},
      );
      _loadMenus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddMenuDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'manis';
    String emoji = '🥞';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Menu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Menu'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: MenuCategory.values.map((cat) {
                        return ButtonSegment(
                          value: cat.value,
                          label: Text(cat.label),
                        );
                      }).toList(),
                      selected: {selectedCategory},
                      onSelectionChanged: (Set<String> selection) {
                        setDialogState(() {
                          selectedCategory = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Text('Emoji: '),
                        const SizedBox(width: AppSpacing.md),
                        ...['🥞', '🍫', '🧀', '🍳', '⭐'].map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  emoji = e;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: emoji == e
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(e, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _client.post(
                        ApiEndpoints.menus,
                        data: {
                          'name': nameController.text,
                          'price': int.tryParse(priceController.text) ?? 0,
                          'category': selectedCategory,
                          'emoji': emoji,
                        },
                      );
                      _loadMenus();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMenuDialog(MenuModel menu) {
    final nameController = TextEditingController(text: menu.name);
    final priceController = TextEditingController(text: menu.price.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Menu'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _client.patch(
                    '${ApiEndpoints.menus}${menu.id}/',
                    data: {
                      'name': nameController.text,
                      'price': int.tryParse(priceController.text) ?? menu.price,
                    },
                  );
                  _loadMenus();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMenu(MenuModel menu) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Menu'),
          content: Text('Apakah Anda yakin ingin menghapus "${menu.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _client.delete('${ApiEndpoints.menus}${menu.id}/');
                  _loadMenus();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.menu,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Opacity(
        opacity: menu.isActive ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(menu.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name, style: AppTypography.labelLarge),
                    Text(
                      CurrencyFormatter.format(menu.price),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      menu.category.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: menu.isActive,
                onChanged: (_) => onToggleActive(),
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return null;
                }),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
