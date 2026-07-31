import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
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
  final ApiClient _client = ApiClient();
  String? _selectedUsername;
  bool _showPinInput = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _client.get(ApiEndpoints.loginUsers);
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      final activeUsers = list
          .map((e) => e as Map<String, dynamic>)
          .map((e) {
            final role = e['role'] as String;
            return {
              'username': e['username'] as String,
              'label': e['username'] as String,
              'icon': role == 'owner' ? Icons.admin_panel_settings : Icons.person,
            };
          })
          .toList();
      setState(() {
        _users = activeUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onUserSelected(String username) {
    setState(() {
      _selectedUsername = username;
      _showPinInput = true;
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
          }
        },
        builder: (context, state) {
          if (state is AuthLoading || _isLoading) {
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
