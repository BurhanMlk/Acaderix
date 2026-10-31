import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/role_shell.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/academy_access_provider.dart';
import 'academy_admin_dashboard.dart';
import 'academy_status_notice_screen.dart';

/// Top-level scaffold for the Academy Admin experience.
/// Checks the academy's real-time account and subscription status.
class AcademyAdminShell extends ConsumerWidget {
  const AcademyAdminShell({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(academyAccessProvider);

    return accessAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 16),
              Text(
                'Checking academy status...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'Failed to load academy status: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(academyAccessProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (access) {
        if (!access.isActive) {
          // Revoke active session and token immediately if status becomes inactive
          Future.microtask(() {
            ref.read(authControllerProvider.notifier).signOut();
          });
          return AcademyStatusNoticeScreen(accessInfo: access);
        }

        return child ??
            const RoleShell(
              title: 'Academy Admin',
              subtitle: 'Manage your academy',
              body: AcademyAdminDashboard(),
            );
      },
    );
  }
}
