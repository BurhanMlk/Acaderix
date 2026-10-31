import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../admissions/domain/student.dart';
import '../../../branches/domain/branch.dart';
import '../../../staff/domain/staff.dart';
import '../../application/academy_access_provider.dart';
import '../../application/academy_admin_providers.dart';

/// Academy Admin dashboard with frosted glass cards, multi-branch aggregation,
/// overall sum across all branches, branch breakdown, and module navigation.
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

    final studentsAsync = ref.watch(studentsStreamProvider(academyId));
    final staffAsync = ref.watch(staffStreamProvider(academyId));
    final branchesAsync = ref.watch(branchesStreamProvider(academyId));
    final paymentsAsync = ref.watch(paymentsStreamProvider(academyId));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final attendanceAsync = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: today)),
    );
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    // Calculate aggregated or filtered counts
    final allStudents = studentsAsync.value ?? const <Student>[];
    final allStaff = staffAsync.value ?? const <Staff>[];
    final allBranches = branchesAsync.value ?? const <Branch>[];

    final filteredStudents = selectedBranchId == null
        ? allStudents
        : allStudents.where((s) => s.branchId == selectedBranchId).toList();

    final filteredStaff = selectedBranchId == null
        ? allStaff
        : allStaff.where((s) => s.branchId == selectedBranchId).toList();

    final selectedBranch =
        allBranches.where((b) => b.id == selectedBranchId).firstOrNull;

    // Monthly Fee Collection sum
    final totalRevenue = (paymentsAsync.value ?? []).fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final revenueDisplay = totalRevenue > 0
        ? 'Rs. ${totalRevenue.toStringAsFixed(0)}'
        : 'Rs. 0';

    // Attendance stats
    final attendanceRecords = attendanceAsync.value ?? [];
    final presentCount = attendanceRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final attendanceDisplay = attendanceRecords.isNotEmpty
        ? '$presentCount / ${attendanceRecords.length}'
        : '—';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Scope Header & Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedBranchId == null
                        ? 'All Branches (${allBranches.length})'
                        : 'Branch: ${selectedBranch?.name ?? ''} (${selectedBranch?.city ?? ''})',
                    style: TextStyle(
                      color: selectedBranchId == null
                          ? Colors.white70
                          : const Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selectedBranchId != null)
              TextButton.icon(
                onPressed: () {
                  ref.read(selectedBranchIdProvider.notifier).state = null;
                },
                icon: const Icon(Icons.clear_all, size: 16, color: Colors.amber),
                label: const Text(
                  'Reset to All',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Overall Sum Stat Cards Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: selectedBranchId == null ? 'Students' : 'Branch Students',
              value: studentsAsync.maybeWhen(
                data: (_) => '${filteredStudents.length}',
                orElse: () => '…',
              ),
              icon: Icons.people_outline,
              color: const Color(0xFF6366F1),
            ),
            StatCard(
              title: selectedBranchId == null ? 'Staff' : 'Branch Staff',
              value: staffAsync.maybeWhen(
                data: (_) => '${filteredStaff.length}',
                orElse: () => '…',
              ),
              icon: Icons.badge_outlined,
              color: const Color(0xFF14B8A6),
            ),
            StatCard(
              title: 'Total Branches',
              value: branchesAsync.maybeWhen(
                data: (b) => '${b.length}',
                orElse: () => '…',
              ),
              icon: Icons.account_balance_outlined,
              color: const Color(0xFF38BDF8),
            ),
            StatCard(
              title: 'Today Attendance',
              value: attendanceDisplay,
              icon: Icons.event_note_outlined,
              color: const Color(0xFFF59E0B),
            ),
            StatCard(
              title: 'Monthly Collection',
              value: revenueDisplay,
              icon: Icons.payments_outlined,
              color: const Color(0xFF10B981),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Branches Breakdown Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Branches Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.addBranch),
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF38BDF8)),
              label: const Text(
                'Add Branch',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (allBranches.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      color: Color(0xFF38BDF8),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Branches Configured',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add campus locations to organize students, staff, and records by branch.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => context.push(AppRoutes.addBranch),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final branch in allBranches) ...[
                _BranchBreakdownCard(
                  branch: branch,
                  studentCount: allStudents
                      .where((s) => s.branchId == branch.id)
                      .length,
                  staffCount:
                      allStaff.where((s) => s.branchId == branch.id).length,
                  isSelected: selectedBranchId == branch.id,
                  onSelect: () {
                    ref.read(selectedBranchIdProvider.notifier).state =
                        selectedBranchId == branch.id ? null : branch.id;
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),

        const SizedBox(height: 24),

        // Management Grid
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

/// Frosted card displaying a single branch breakdown with quick filter toggle.
class _BranchBreakdownCard extends StatelessWidget {
  const _BranchBreakdownCard({
    required this.branch,
    required this.studentCount,
    required this.staffCount,
    required this.isSelected,
    required this.onSelect,
  });

  final Branch branch;
  final int studentCount;
  final int staffCount;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.14),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch.city.isNotEmpty
                          ? '${branch.city}${branch.address.isNotEmpty ? ' · ${branch.address}' : ''}'
                          : branch.address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _BadgePill(
                          label: '$studentCount Students',
                          color: const Color(0xFF6366F1),
                        ),
                        _BadgePill(
                          label: '$staffCount Staff',
                          color: const Color(0xFF14B8A6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF38BDF8)
                      : Colors.white.withValues(alpha: 0.12),
                  foregroundColor: isSelected ? Colors.black : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isSelected ? 'Viewing' : 'Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
