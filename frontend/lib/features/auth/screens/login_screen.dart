import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/pin_input.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/user_grid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedUsername;
  String _pin = '';
  bool _showPinInput = false;

  final List<Map<String, dynamic>> _users = const [
    {'username': 'owner', 'label': 'Owner', 'icon': Icons.admin_panel_settings},
    {'username': 'Budi', 'label': 'Budi', 'icon': Icons.person},
    {'username': 'Andi', 'label': 'Andi', 'icon': Icons.person},
  ];

  void _onUserSelected(String username) {
    setState(() {
      _selectedUsername = username;
      _showPinInput = true;
      _pin = '';
    });
  }

  void _onPinCompleted(String pin) {
    if (_selectedUsername != null) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(username: _selectedUsername!, pin: pin),
          );
    }
  }

  void _onBackPressed() {
    setState(() {
      _showPinInput = false;
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() {
              _pin = '';
            });
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const LoadingIndicator(message: 'Memuat...');
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Martabak',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pilih kasir dan masukkan PIN',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_showPinInput) ...[
                    _buildPinHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    PinInput(
                      length: 6,
                      onCompleted: _onPinCompleted,
                    ),
                  ] else ...[
                    UserGrid(
                      users: _users,
                      onUserSelected: _onUserSelected,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _onBackPressed,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Masuk sebagai $_selectedUsername',
              style: AppTypography.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Masukkan PIN (6 digit)',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
