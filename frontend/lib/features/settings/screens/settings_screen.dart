import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/app_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _client = ApiClient();
  bool _isLoading = true;
  String? _shopName;
  String? _goqrisStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _client.get(ApiEndpoints.settings);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _shopName = data['goqris_project_name'] as String? ?? '';
        _isLoading = false;
      });

      _loadGoqrisStatus();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGoqrisStatus() async {
    try {
      final response = await _client.get(ApiEndpoints.goqrisProfile);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _goqrisStatus = data['status'] as String? ?? 'unknown';
      });
    } catch (e) {
      setState(() {
        _goqrisStatus = 'error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (_isLoading) {
            return const LoadingIndicator(message: 'Memuat pengaturan...');
          }

          if (_error != null) {
            return AppErrorWidget(
              message: _error!,
              onRetry: _loadSettings,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GoQris', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _buildGoqrisCard(),
                const SizedBox(height: AppSpacing.lg),
                Text('Tentang', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _buildAboutCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoqrisCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_goqrisStatus) {
      case 'active':
        statusColor = AppColors.success;
        statusText = 'Aktif';
        statusIcon = Icons.check_circle;
        break;
      case 'not_configured':
        statusColor = AppColors.warning;
        statusText = 'Belum dikonfigurasi';
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = AppColors.error;
        statusText = 'Error';
        statusIcon = Icons.error;
    }

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status GoQris', style: AppTypography.labelLarge),
                    Text(
                      statusText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadGoqrisStatus,
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Nama Toko'),
            subtitle: Text(_shopName ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditShopNameDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Martabak'),
            subtitle: const Text('Versi 1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Aplikasi Kasir Martabak'),
            subtitle: const Text('Dengan pembayaran GoQris QRIS'),
          ),
        ],
      ),
    );
  }

  void _showEditShopNameDialog() {
    final controller = TextEditingController(text: _shopName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Nama Toko'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Toko',
              hintText: 'Masukkan nama toko',
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
                try {
                  await _client.patch(
                    ApiEndpoints.settings,
                    data: {'goqris_project_name': controller.text},
                  );
                  setState(() {
                    _shopName = controller.text;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama toko berhasil diperbarui')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
