import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/roles.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/glass.dart';

class _LoginOption {
  const _LoginOption(this.role, this.icon, this.description);
  final AppRole role;
  final IconData icon;
  final String description;
}

const List<_LoginOption> _options = [
  _LoginOption(
    AppRole.superAdmin,
    Icons.admin_panel_settings_outlined,
    'Platform management & global controls',
  ),
  _LoginOption(
    AppRole.academyAdmin,
    Icons.apartment_outlined,
    'Manage your academy end to end',
  ),
  _LoginOption(
    AppRole.staff,
    Icons.badge_outlined,
    'Teaching, attendance & assigned duties',
  ),
  _LoginOption(
    AppRole.student,
    Icons.school_outlined,
    'Students & parents view progress',
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
          const _BrandHeader(),
          const SizedBox(height: 32),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose how you want to sign in',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Parents can use the Student login to view their child\u2019s information.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
        const AppLogo(size: 92, borderRadius: 26),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Smart academy management, all in one place',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
      AppRole.superAdmin => AppRoutes.superAdminLogin,
      AppRole.academyAdmin => AppRoutes.academyAdminLogin,
      AppRole.staff => AppRoutes.staffLogin,
      AppRole.student => AppRoutes.studentLogin,
      AppRole.unauthenticated => AppRoutes.login,
    };

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.role.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
