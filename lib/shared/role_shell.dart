import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/confirmation_dialog.dart';
import '../core/widgets/empty_state.dart';
import '../features/auth/application/auth_controller.dart';
import 'academy_logo.dart';

/// Shared scaffold for authenticated role dashboards with clean light theme.
class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.title, this.subtitle, this.body});

  final String title;
  final String? subtitle;
  final Widget? body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AcademyLogo(size: 36, borderRadius: 10),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Color(0xFF6B7280)),
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
      body:
          body ??
          const EmptyState(
            title: 'Dashboard under construction',
            message:
                'This area is being built and will be available in an upcoming phase.',
            icon: Icons.construction,
          ),
    );
  }
}
