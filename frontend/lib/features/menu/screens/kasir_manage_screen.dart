import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state.dart';

class KasirManageScreen extends StatefulWidget {
  const KasirManageScreen({super.key});

  @override
  State<KasirManageScreen> createState() => _KasirManageScreenState();
}

class _KasirManageScreenState extends State<KasirManageScreen> {
  final ApiClient _client = ApiClient();
  bool _isLoading = true;
  List<UserModel> _kasirs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKasirs();
  }

  Future<void> _loadKasirs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.get(ApiEndpoints.kasirs);
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      setState(() {
        _kasirs = list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
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
        title: const Text('Kelola Kasir'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddKasirDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat kasir...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: _loadKasirs,
      );
    }

    if (_kasirs.isEmpty) {
      return const EmptyState(
        title: 'Belum ada kasir',
        subtitle: 'Tambah kasir baru untuk memulai',
        icon: Icons.people,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadKasirs,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _kasirs.length,
        itemBuilder: (context, index) {
          final kasir = _kasirs[index];
          return _KasirCard(
            kasir: kasir,
            onResetPin: () => _showResetPinDialog(kasir),
            onToggleActive: () => _toggleActive(kasir),
          );
        },
      ),
    );
  }

  void _showAddKasirDialog() {
    final usernameController = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Kasir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN (4-6 digit)',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
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
                  await _client.post(
                    ApiEndpoints.kasirs,
                    data: {
                      'username': usernameController.text,
                      'pin': pinController.text,
                      'role': 'kasir',
                    },
                  );
                  _loadKasirs();
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

  void _showResetPinDialog(UserModel kasir) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Reset PIN ${kasir.username}'),
          content: const Text('Pilih metode reset PIN:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resetPinRandom(kasir);
              },
              child: const Text('Random'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showManualPinDialog(kasir);
              },
              child: const Text('Input Manual'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPinRandom(UserModel kasir) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _client.post(
        ApiEndpoints.resetPin.replaceAll('{id}', kasir.id.toString()),
      );
      final data = response.data as Map<String, dynamic>;
      final newPin = data['new_pin'] as String;
      messenger.showSnackBar(
        SnackBar(content: Text('PIN ${kasir.username} berhasil direset ke $newPin')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showManualPinDialog(UserModel kasir) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Input PIN Manual - ${kasir.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru (6 digit)',
                  hintText: 'Contoh: 123456',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi PIN',
                  hintText: 'Masukkan ulang PIN',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
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
                final pin = pinController.text;
                final confirm = confirmController.text;

                if (pin.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN harus 6 digit'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                if (pin != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN tidak cocok'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                await _resetPinManual(kasir, pin);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPinManual(UserModel kasir, String newPin) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _client.post(
        ApiEndpoints.resetPin.replaceAll('{id}', kasir.id.toString()),
        data: {'new_pin': newPin},
      );
      final data = response.data as Map<String, dynamic>;
      final savedPin = data['new_pin'] as String;
      messenger.showSnackBar(
        SnackBar(content: Text('PIN ${kasir.username} berhasil direset ke $savedPin')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleActive(UserModel kasir) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _client.patch(
        '${ApiEndpoints.kasirs}${kasir.id}/',
        data: {'is_active': !kasir.isActive},
      );
      _loadKasirs();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _KasirCard extends StatelessWidget {
  final UserModel kasir;
  final VoidCallback onResetPin;
  final VoidCallback onToggleActive;

  const _KasirCard({
    required this.kasir,
    required this.onResetPin,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Opacity(
        opacity: kasir.isActive ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kasir.isOwner
                    ? AppColors.secondary.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  kasir.isOwner ? Icons.admin_panel_settings : Icons.person,
                  color: kasir.isOwner ? AppColors.secondaryDark : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kasir.username, style: AppTypography.labelLarge),
                    Text(
                      kasir.isOwner ? 'Owner' : 'Kasir',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kasir.isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        kasir.isActive ? 'Aktif' : 'Nonaktif',
                        style: AppTypography.labelMedium.copyWith(
                          color: kasir.isActive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!kasir.isOwner) ...[
                IconButton(
                  onPressed: onResetPin,
                  icon: const Icon(Icons.lock_reset),
                  tooltip: 'Reset PIN',
                ),
                Switch(
                  value: kasir.isActive,
                  onChanged: (_) => onToggleActive(),
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return null;
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
