import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';

import '../../../../core/widgets/stat_card.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../staff/domain/staff.dart';

/// Academy Admin dashboard with live counts and module navigation.
class AcademyAdminDashboard extends ConsumerWidget {
  const AcademyAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(currentAcademyIdProvider);
    if (academyId == null) {
      return const Center(child: Text('No academy context available.'));
    }

    final students = ref.watch(studentsStreamProvider(academyId));
    final staff = ref.watch(staffStreamProvider(academyId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _CountStat<Student>(
              value: students,
              title: 'Students',
              icon: Icons.people_outline,
              color: Colors.indigo,
            ),
            _CountStat<Staff>(
              value: staff,
              title: 'Staff',
              icon: Icons.badge_outlined,
              color: Colors.teal,
            ),
            StatCard(
              title: 'Today Attendance',
              value: '—',
              icon: Icons.event_note_outlined,
            ),
            StatCard(
              title: 'Monthly Collection',
              value: '—',
              icon: Icons.payments_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Manage', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _ModuleTile(
              icon: Icons.people_alt_outlined,
              label: 'Students',
              onTap: () => context.push(AppRoutes.studentsList),
            ),
            _ModuleTile(
              icon: Icons.payments_outlined,
              label: 'Fees',
              onTap: () => context.push(AppRoutes.fees),
            ),
            _ModuleTile(
              icon: Icons.event_note_outlined,
              label: 'Attendance',
              onTap: () => context.push(AppRoutes.attendance),
            ),
            _ModuleTile(
              icon: Icons.assessment_outlined,
              label: 'Results',
              onTap: () => context.push(AppRoutes.results),
            ),
            _ModuleTile(
              icon: Icons.badge_outlined,
              label: 'Staff',
              onTap: () => context.push(AppRoutes.staffList),
            ),
            _ModuleTile(
              icon: Icons.account_balance_outlined,
              label: 'Branches',
              onTap: () => context.push(AppRoutes.branchesList),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountStat<T> extends StatelessWidget {
  const _CountStat({
    required this.value,
    required this.title,
    required this.icon,
    required this.color,
  });

  final AsyncValue<List<T>> value;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: title,
      icon: icon,
      color: color,
      value: value.maybeWhen(
        data: (items) => '${items.length}',
        orElse: () => '…',
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
