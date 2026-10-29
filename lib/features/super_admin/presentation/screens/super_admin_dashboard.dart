import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../application/super_admin_providers.dart';
import '../../domain/academy.dart';
import '../super_admin_modules.dart';

const List<Color> _moduleColors = [
  Color(0xFF6366F1), // indigo
  Color(0xFF0EA5E9), // sky
  Color(0xFF14B8A6), // teal
  Color(0xFFA855F7), // purple
  Color(0xFFF59E0B), // amber
  Color(0xFF64748B), // slate
];

/// Super Admin dashboard with quick module access and live platform stats.
class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academies = ref.watch(academiesStreamProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(academiesStreamProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Platform Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage academies, subscriptions and broadcasts from one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              for (var i = 0; i < superAdminModules.length; i++)
                _ModuleCard(
                  module: superAdminModules[i],
                  color: _moduleColors[i % _moduleColors.length],
                  onTap: () => context.go(superAdminModules[i].route),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Academies',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._academySection(context, ref, academies),
        ],
      ),
    );
  }

  List<Widget> _academySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Academy>> academies,
  ) {
    return academies.when(
      loading: () => const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Skeleton(width: 48, height: 48, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: double.infinity),
                      SizedBox(height: 8),
                      Skeleton(width: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      error: (error, _) => [
        ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(academiesStreamProvider),
        ),
      ],
      data: (items) => items.isEmpty
          ? const [
              EmptyState(
                title: 'No academies yet',
                message: 'Registered academies will appear here.',
              ),
            ]
          : _academyListItems(context, items),
    );
  }

  List<Widget> _academyListItems(BuildContext context, List<Academy> items) {
    final active = items.where((a) => a.status == 'active').length;
    final pending = items.where((a) => a.status == 'pending').length;
    final suspended = items.where((a) => a.status == 'suspended').length;

    return [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          StatCard(
            title: 'Total Academies',
            value: '${items.length}',
            icon: Icons.apartment,
            color: const Color(0xFF6366F1),
          ),
          StatCard(
            title: 'Active',
            value: '$active',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          StatCard(
            title: 'Pending',
            value: '$pending',
            icon: Icons.pending_outlined,
            color: Colors.orange,
          ),
          StatCard(
            title: 'Suspended',
            value: '$suspended',
            icon: Icons.block,
            color: Colors.red,
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Recent academies', style: Theme.of(context).textTheme.titleMedium),
          TextButton(
            onPressed: () => context.go(AppRoutes.academiesList),
            child: const Text('View all'),
          ),
        ],
      ),
      for (final academy in items.take(5))
        Card(
          child: ListTile(
            leading: const AppLogo(size: 40, borderRadius: 12),
            title: Text(
              academy.name.isEmpty ? 'Unnamed academy' : academy.name,
            ),
            subtitle: Text(academy.code),
            trailing: _StatusChip(status: academy.status),
          ),
        ),
    ];
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.color,
    required this.onTap,
  });

  final SuperAdminModule module;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                module.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'active' => Colors.green,
      'pending' => Colors.orange,
      'suspended' => Colors.red,
      _ => scheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
