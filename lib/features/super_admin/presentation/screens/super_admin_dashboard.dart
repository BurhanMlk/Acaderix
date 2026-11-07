import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../application/super_admin_providers.dart';
import '../../domain/academy.dart';
import '../super_admin_modules.dart';
import '../widgets/academy_avatar.dart';

const List<Color> _moduleColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF14B8A6), // Teal
  Color(0xFFF59E0B), // Amber
  Color(0xFFA855F7), // Purple
  Color(0xFFEC4899), // Pink
  Color(0xFF38BDF8), // Sky Blue
];

/// Super Admin dashboard with signature transparent glassmorphism theme.
class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academies = ref.watch(academiesStreamProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(academiesStreamProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage academies, subscriptions and platform settings.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isPhone = constraints.maxWidth < 480;
              final crossAxisCount =
                  isPhone ? 2 : (constraints.maxWidth < 800 ? 3 : 4);
              final childAspectRatio = isPhone ? 1.45 : 1.2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
                children: [
                  for (var i = 0; i < superAdminModules.length; i++)
                    _ModuleCard(
                      module: superAdminModules[i],
                      color: _moduleColors[i % _moduleColors.length],
                      onTap: () => context.go(superAdminModules[i].route),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Academies',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.createAcademy),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Academy'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
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
      loading: () => [
        _glassWrapper(
          child: const Padding(
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
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
            color: const Color(0xFF10B981),
          ),
          StatCard(
            title: 'Pending',
            value: '$pending',
            icon: Icons.pending_outlined,
            color: const Color(0xFFF59E0B),
          ),
          StatCard(
            title: 'Suspended',
            value: '$suspended',
            icon: Icons.block,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent additions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.academiesList),
            child: const Text(
              'View all',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      for (final academy in items.take(5))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _glassWrapper(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () =>
                  context.go(AppRoutes.academyDetails, extra: academy),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: AcademyAvatar(
                  name: academy.name,
                  logoUrl: academy.logoUrl,
                  size: 42,
                  borderRadius: 12,
                ),
                title: Text(
                  academy.name.isEmpty ? 'Unnamed academy' : academy.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  '${academy.code} · ${academy.city.isEmpty ? "Location not set" : academy.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                trailing: _StatusChip(status: academy.status),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _glassWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(module.icon, color: color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        module.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final (color, label) = switch (status.toLowerCase()) {
      'active' => (const Color(0xFF10B981), 'Active'),
      'suspended' => (const Color(0xFFEF4444), 'Suspended'),
      'pending' => (const Color(0xFFF59E0B), 'Pending'),
      _ => (Colors.grey, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
