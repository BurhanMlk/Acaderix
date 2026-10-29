import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/empty_state.dart';
import '../features/auth/application/auth_controller.dart';
import 'academy_logo.dart';

/// Shared scaffold for authenticated role dashboards.
///
/// Provides a titled app bar and a sign-out action. Individual role shells
/// pass their own body content.
class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.title, this.subtitle, this.body});

  final String title;
  final String? subtitle;
  final Widget? body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AcademyLogo(size: 36, borderRadius: 10),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
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
