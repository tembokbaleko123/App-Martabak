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
import '../../../data/services/category_service.dart';

class MenuManageScreen extends StatefulWidget {
  const MenuManageScreen({super.key});

  @override
  State<MenuManageScreen> createState() => _MenuManageScreenState();
}

class _MenuManageScreenState extends State<MenuManageScreen> with SingleTickerProviderStateMixin {
  final ApiClient _client = ApiClient();
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<MenuModel> _menus = [];
  List<CategoryModel> _categories = [];
  String? _error;
  Set<int> _selectedMenuIds = {};
  bool _isSelectionMode = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final menusResponse = await _client.get(ApiEndpoints.menusAll);
      final categoriesResponse = await _categoryService.getAllCategories();

      List<dynamic> menusList;
      if (menusResponse.data is Map<String, dynamic>) {
        final data = menusResponse.data as Map<String, dynamic>;
        menusList = data['data'] as List<dynamic>;
      } else {
        menusList = menusResponse.data as List<dynamic>;
      }

      setState(() {
        _menus = menusList.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
        _categories = categoriesResponse;
        _isLoading = false;
        _selectedMenuIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleMenuSelection(int menuId) {
    setState(() {
      if (_isSelectionMode) {
        if (_selectedMenuIds.contains(menuId)) {
          _selectedMenuIds.remove(menuId);
          if (_selectedMenuIds.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedMenuIds.add(menuId);
        }
      } else {
        _selectedMenuIds.add(menuId);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedMenuIds.length == _menus.length) {
        _selectedMenuIds.clear();
      } else {
        _selectedMenuIds = _menus.map((m) => m.id).toSet();
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedMenuIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _bulkUpdate({int? categoryId, bool? isActive}) async {
    if (_selectedMenuIds.isEmpty) return;

    try {
      await _client.patch(
        ApiEndpoints.menusBulk,
        data: {
          'menu_ids': _selectedMenuIds.toList(),
          if (categoryId != null) 'category_id': categoryId,
          if (isActive != null) 'is_active': isActive,
        },
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showBulkCategoryDialog() {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada kategori tersedia')),
      );
      return;
    }

    CategoryModel? selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ubah Kategori (${_selectedMenuIds.length} menu)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pilih kategori baru untuk ${_selectedMenuIds.length} menu yang dipilih.'),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<CategoryModel>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    },
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
                    if (selectedCategory != null) {
                      await _bulkUpdate(categoryId: selectedCategory!.id);
                    }
                  },
                  child: const Text('Ubah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Menu'),
          content: Text('Apakah Anda yakin ingin menghapus ${_selectedMenuIds.length} menu? Menu akan di-nonaktifkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _bulkUpdate(isActive: false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBarWithTabs(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildCategoryTab(),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddMenuDialog();
          } else {
            _showAddCategoryDialog();
          }
        },
        backgroundColor: _tabController.index == 0 ? AppColors.primary : AppColors.secondary,
        child: Icon(_tabController.index == 0 ? Icons.restaurant_menu : Icons.category),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBarWithTabs() {
    return AppBar(
      title: const Text('Kelola Menu'),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Menu'),
          Tab(text: 'Kategori'),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        Expanded(child: _buildBody()),
        if (_selectedMenuIds.isNotEmpty) _buildBulkActionBar(),
      ],
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      children: [
        Expanded(child: _buildCategoryList()),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedMenuIds.length} dipilih'),
      actions: [
        TextButton(
          onPressed: _toggleSelectAll,
          child: Text(
            _selectedMenuIds.length == _menus.length ? 'Batal Semua' : 'Pilih Semua',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionBar() {
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
        top: false,
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _BulkActionButton(
              icon: Icons.category,
              label: 'Ubah Kategori',
              onPressed: _showBulkCategoryDialog,
            ),
            _BulkActionButton(
              icon: Icons.check_circle,
              label: 'Aktifkan',
              onPressed: () => _bulkUpdate(isActive: true),
            ),
            _BulkActionButton(
              icon: Icons.cancel,
              label: 'Nonaktifkan',
              onPressed: () => _bulkUpdate(isActive: false),
            ),
            _BulkActionButton(
              icon: Icons.delete,
              label: 'Hapus',
              color: AppColors.error,
              onPressed: _showBulkDeleteConfirmation,
            ),
          ],
        ),
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
        onRetry: _loadData,
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _menus.length,
        itemBuilder: (context, index) {
          final menu = _menus[index];
          return _MenuCard(
            menu: menu,
            isSelected: _selectedMenuIds.contains(menu.id),
            isSelectionMode: _isSelectionMode,
            onToggleOrEnterSelection: _toggleMenuSelection,
            onToggleActive: () => _toggleMenuActive(menu),
            onEdit: () => _showEditMenuDialog(menu),
            onDelete: () => _deleteMenu(menu),
          );
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat kategori...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }

    if (_categories.isEmpty) {
      return const EmptyState(
        title: 'Belum ada kategori',
        subtitle: 'Tambah kategori baru untuk memulai',
        icon: Icons.category,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryCard(
            category: category,
            onToggleActive: () => _toggleCategoryActive(category),
            onEdit: () => _showEditCategoryDialog(category),
          );
        },
      ),
    );
  }

  Future<void> _toggleCategoryActive(CategoryModel category) async {
    try {
      await _categoryService.updateCategory(
        category.id,
        {'is_active': !category.isActive},
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final sortOrderController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Contoh: Manis',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort Order (opsional)',
                  hintText: 'Angka untuk urutan',
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
                  await _categoryService.createCategory(
                    name: nameController.text,
                    sortOrder: int.tryParse(sortOrderController.text),
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil ditambahkan')),
                  );
                  _loadData();
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

  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final sortOrderController = TextEditingController(
      text: category.sortOrder?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort Order (opsional)',
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
                  await _categoryService.updateCategory(
                    category.id,
                    {
                      'name': nameController.text,
                      if (sortOrderController.text.isNotEmpty)
                        'sort_order': int.tryParse(sortOrderController.text),
                    },
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil diupdate')),
                  );
                  _loadData();
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

  Future<void> _toggleMenuActive(MenuModel menu) async {
    try {
      await _client.patch(
        '${ApiEndpoints.menus}${menu.id}/',
        data: {'is_active': !menu.isActive},
      );
      _loadData();
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
    final customEmojiController = TextEditingController();
    CategoryModel? selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    String emoji = '🥞';
    bool useCustomEmoji = false;

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
                    if (_categories.isEmpty)
                      const Text('Tidak ada kategori. Tambahkan kategori terlebih dahulu.')
                    else
                      DropdownButtonFormField<CategoryModel>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Emoji:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ['🥞', '🍫', '🧀', '🍳', '⭐', '🍕', '🍔', '🍟'].map((e) {
                        final isSelected = emoji == e && !useCustomEmoji;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              emoji = e;
                              useCustomEmoji = false;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: AppColors.primary, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Text(e, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: customEmojiController,
                      decoration: InputDecoration(
                        labelText: 'Atau gunakan emoji custom',
                        hintText: 'Paste emoji here',
                        border: const OutlineInputBorder(),
                        suffixIcon: customEmojiController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    customEmojiController.clear();
                                    useCustomEmoji = false;
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value.isNotEmpty) {
                            emoji = value;
                            useCustomEmoji = true;
                          } else {
                            useCustomEmoji = false;
                          }
                        });
                      },
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
                          'category_id': selectedCategory?.id,
                          'emoji': emoji,
                        },
                      );
                      _loadData();
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
                  _loadData();
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
                  _loadData();
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
  final bool isSelected;
  final bool isSelectionMode;
  final void Function(int menuId) onToggleOrEnterSelection;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.menu,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggleOrEnterSelection,
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
        child: InkWell(
          onTap: () => onToggleOrEnterSelection(menu.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleOrEnterSelection(menu.id),
                    activeColor: AppColors.primary,
                  ),
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
                        menu.categoryName?.toUpperCase() ?? '',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSelectionMode) ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        backgroundColor: color?.withValues(alpha: 0.1) ?? AppColors.primary.withValues(alpha: 0.1),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;

  const _CategoryCard({
    required this.category,
    required this.onToggleActive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Opacity(
        opacity: category.isActive ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name.toUpperCase(),
                      style: AppTypography.labelLarge,
                    ),
                    if (category.sortOrder != null)
                      Text(
                        'Sort: ${category.sortOrder}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: category.isActive,
                onChanged: (_) => onToggleActive(),
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return null;
                }),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
