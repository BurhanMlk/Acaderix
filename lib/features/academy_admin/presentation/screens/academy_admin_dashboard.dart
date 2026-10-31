import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../application/academy_access_provider.dart';
import '../../application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../staff/domain/staff.dart';

/// Academy Admin dashboard with frosted glass cards, live counts and module navigation.
class AcademyAdminDashboard extends ConsumerWidget {
  const AcademyAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(academyAccessProvider).value;
    final academyId = ref.watch(currentAcademyIdProvider) ?? access?.academyId;
    if (academyId == null || academyId.isEmpty) {
      return const Center(
        child: Text(
          'No academy context available.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final students = ref.watch(studentsStreamProvider(academyId));
    final staff = ref.watch(staffStreamProvider(academyId));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
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
              color: const Color(0xFF6366F1),
            ),
            _CountStat<Staff>(
              value: staff,
              title: 'Staff',
              icon: Icons.badge_outlined,
              color: const Color(0xFF14B8A6),
            ),
            const StatCard(
              title: 'Today Attendance',
              value: '—',
              icon: Icons.event_note_outlined,
              color: Color(0xFFF59E0B),
            ),
            const StatCard(
              title: 'Monthly Collection',
              value: '—',
              icon: Icons.payments_outlined,
              color: Color(0xFF10B981),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Manage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
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
              color: const Color(0xFF6366F1),
              onTap: () => context.push(AppRoutes.studentsList),
            ),
            _ModuleTile(
              icon: Icons.payments_outlined,
              label: 'Fees',
              color: const Color(0xFF10B981),
              onTap: () => context.push(AppRoutes.fees),
            ),
            _ModuleTile(
              icon: Icons.event_note_outlined,
              label: 'Attendance',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push(AppRoutes.attendance),
            ),
            _ModuleTile(
              icon: Icons.assessment_outlined,
              label: 'Results',
              color: const Color(0xFFA855F7),
              onTap: () => context.push(AppRoutes.results),
            ),
            _ModuleTile(
              icon: Icons.badge_outlined,
              label: 'Staff',
              color: const Color(0xFF14B8A6),
              onTap: () => context.push(AppRoutes.staffList),
            ),
            _ModuleTile(
              icon: Icons.account_balance_outlined,
              label: 'Branches',
              color: const Color(0xFF38BDF8),
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
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
