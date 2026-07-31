import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../navigation/route_names.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPinChangeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN berhasil diubah'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthPinChangeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${state.errorMessage}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! AuthAuthenticated) {
              return const LoadingIndicator();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(state.user),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.user.isOwner) ...[
                    Text('Manajemen', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    _buildMenuItem(
                      icon: Icons.menu_book,
                      title: 'Kelola Menu',
                      onTap: () => context.go(RouteNames.menuManage),
                    ),
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Kelola Kasir',
                      onTap: () => context.go(RouteNames.kasirManage),
                    ),
                    _buildMenuItem(
                      icon: Icons.bar_chart,
                      title: 'Laporan',
                      onTap: () => context.go(RouteNames.reports),
                    ),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Pengaturan',
                      onTap: () => context.go(RouteNames.settings),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text('Akun', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Ganti PIN',
                    onTap: () => _showChangePinDialog(context),
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Keluar',
                    textColor: AppColors.error,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              user.isOwner ? Icons.admin_panel_settings : Icons.person,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: AppTypography.titleLarge,
                ),
                Text(
                  user.isOwner ? 'Owner' : 'Kasir',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? AppColors.primary),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ganti PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Lama',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: newPinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru',
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
              onPressed: () {
                context.read<AuthBloc>().add(
                      AuthChangePinRequested(
                        oldPin: oldPinController.text,
                        newPin: newPinController.text,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}
