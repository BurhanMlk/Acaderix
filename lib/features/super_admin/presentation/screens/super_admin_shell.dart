import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../shared/academy_logo.dart';
import '../../../auth/application/auth_controller.dart';
import '../super_admin_modules.dart';

/// Top-level scaffold for the Super Admin experience with ambient glassmorphism theme.
class SuperAdminShell extends ConsumerWidget {
  const SuperAdminShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  String get _title {
    if (location.startsWith(AppRoutes.academyDetails)) return 'Academy Details';
    if (location.startsWith(AppRoutes.academyAdminResetPassword)) {
      return 'Reset Admin Password';
    }
    if (location.startsWith(AppRoutes.superAdminResetPassword)) {
      return 'Reset Password';
    }
    if (location.startsWith(AppRoutes.recordPayment)) return 'Record Payment';
    if (location.startsWith(AppRoutes.changePlan)) return 'Change Plan';
    if (location.startsWith(AppRoutes.extendSubscription)) {
      return 'Extend Subscription';
    }
    if (location.startsWith(AppRoutes.editPlanPrice)) return 'Edit Plan Price';
    for (final module in superAdminModules) {
      if (module.route == location) return module.label;
    }
    return 'Super Admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                children: [
                  _SuperAdminSidebar(location: location, isDrawer: false),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ContentHeader(title: _title),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            drawer: Drawer(
              backgroundColor: const Color(0xFF0B1120).withValues(alpha: 0.95),
              child: _SuperAdminSidebar(location: location, isDrawer: true),
            ),
            body: child,
          );
        },
      ),
    );
  }
}

class _ContentHeader extends StatelessWidget {
  const _ContentHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SuperAdminSidebar extends ConsumerWidget {
  const _SuperAdminSidebar({
    required this.location,
    this.isDrawer = false,
  });

  final String location;
  final bool isDrawer;

  void _navigate(BuildContext context, String route) {
    if (isDrawer) {
      Navigator.of(context).pop();
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDrawer
            ? Colors.transparent
            : const Color(0xFF0B1120).withValues(alpha: 0.75),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  const AcademyLogo(size: 40, borderRadius: 12),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acadrix',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Super Admin',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDrawer)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'Close menu',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),
            for (final module in superAdminModules)
              _SidebarItem(
                module: module,
                selected: location == module.route,
                onTap: () => _navigate(context, module.route),
              ),
            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            _SidebarAction(
              icon: Icons.logout,
              label: 'Sign out',
              onTap: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Sign Out',
                  message:
                      'Are you sure you want to sign out of the Super Admin dashboard?',
                  confirmLabel: 'Sign Out',
                  destructive: true,
                );
                if (!confirmed) return;
                if (isDrawer && context.mounted) {
                  Navigator.of(context).pop();
                }
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final SuperAdminModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.transparent;
    final foreground = selected ? Colors.white : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(module.icon, color: foreground, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
