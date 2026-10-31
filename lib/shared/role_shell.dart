import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/confirmation_dialog.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/glass.dart';
import '../features/auth/application/auth_controller.dart';
import 'academy_logo.dart';

/// Shared scaffold for authenticated role dashboards with signature transparent glass theme.
class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.title, this.subtitle, this.body});

  final String title;
  final String? subtitle;
  final Widget? body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leadingWidth: 64,
          leading: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: AcademyLogo(size: 36, borderRadius: 10),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out?',
                  confirmLabel: 'Sign Out',
                  destructive: true,
                );
                if (confirmed) {
                  ref.read(authControllerProvider.notifier).signOut();
                }
              },
            ),
          ],
        ),
        body: body ??
            const EmptyState(
              title: 'Dashboard under construction',
              message:
                  'This area is being built and will be available in an upcoming phase.',
              icon: Icons.construction,
            ),
      ),
    );
  }
}
