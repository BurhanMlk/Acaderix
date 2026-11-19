import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/roles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/glass.dart';

class _LoginOption {
  const _LoginOption(this.role, this.title, this.icon, this.description);
  final AppRole role;
  final String title;
  final IconData icon;
  final String description;
}

const List<_LoginOption> _options = [
  _LoginOption(
    AppRole.academyAdmin,
    'Admin',
    Icons.admin_panel_settings_outlined,
    'Academy & platform administration',
  ),
  _LoginOption(
    AppRole.staff,
    'Staff',
    Icons.badge_outlined,
    'Class schedules, attendance & grading',
  ),
  _LoginOption(
    AppRole.student,
    'Student',
    Icons.school_outlined,
    'Attendance, vouchers & academic results',
  ),
];

/// Lets the user choose the role they want to sign in as.
class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          IconButton(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            tooltip: 'Back to Welcome',
            onPressed: () {
              try {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
              } catch (_) {}
              try {
                context.go(AppRoutes.welcome);
              } catch (_) {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const _BrandHeader(),
          const SizedBox(height: 32),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose how you want to sign in',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Parents can use the Student login to view their child\u2019s information.',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 20),
                for (final option in _options) ...[
                  _RoleTile(option: option),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogo(
          size: 92,
          borderRadius: 26,
          withGlow: true,
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'School and academy management platform',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.option});

  final _LoginOption option;

  @override
  Widget build(BuildContext context) {
    final route = switch (option.role) {
      AppRole.superAdmin || AppRole.academyAdmin => AppRoutes.academyAdminLogin,
      AppRole.staff => AppRoutes.staffLogin,
      AppRole.student => AppRoutes.studentLogin,
      AppRole.unauthenticated => AppRoutes.login,
    };

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
