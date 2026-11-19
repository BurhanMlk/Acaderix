import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../admissions/domain/student.dart';
import '../../../branches/domain/branch.dart';
import '../../../staff/domain/staff.dart';
import '../../../communication/application/communication_providers.dart';
import '../../../super_admin/application/platform_broadcast_providers.dart';
import '../../../super_admin/domain/platform_broadcast.dart';
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
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final studentsAsync = ref.watch(studentsStreamProvider(academyId));
    final staffAsync = ref.watch(staffStreamProvider(academyId));
    final branchesAsync = ref.watch(branchesStreamProvider(academyId));
    final announcementsAsync = ref.watch(
      announcementsStreamProvider((
        academyId: academyId,
        audience: null,
        branchId: selectedBranchId,
      )),
    );
    final paymentsAsync = ref.watch(paymentsStreamProvider(academyId));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final attendanceAsync = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: today)),
    );
    final platformBroadcastsAsync = ref.watch(platformBroadcastsStreamProvider);
    final activeAlert =
        (platformBroadcastsAsync.value ?? const <PlatformBroadcast>[])
            .where((b) => b.isActive)
            .firstOrNull;

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

    final selectedBranch = allBranches
        .where((b) => b.id == selectedBranchId)
        .firstOrNull;

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

    final academyCode = access?.academyCode.trim() ?? '';

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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (academyCode.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: academyCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Academy code "$academyCode" copied to clipboard',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Code: $academyCode',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedBranchId == null
                        ? 'All Branches (${allBranches.length})'
                        : 'Branch: ${selectedBranch?.name ?? ''} (${selectedBranch?.city ?? ''})',
                    style: TextStyle(
                      color: selectedBranchId == null
                          ? AppColors.textTertiary
                          : AppColors.info,
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
                icon: const Icon(
                  Icons.clear_all,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
                label: const Text(
                  'Reset to All',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (activeAlert != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppRoutes.academyAnnouncements),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activeAlert.isUrgent
                        ? const Color(0xFFFEF2F2)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: activeAlert.isUrgent
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFE0E7FF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: activeAlert.isUrgent
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          activeAlert.isUrgent
                              ? Icons.warning_amber_rounded
                              : Icons.campaign_outlined,
                          color: activeAlert.isUrgent
                              ? const Color(0xFFDC2626)
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeAlert.isUrgent
                                  ? 'URGENT NOTICE'
                                  : 'PLATFORM NOTICE',
                              style: TextStyle(
                                color: activeAlert.isUrgent
                                    ? const Color(0xFFDC2626)
                                    : AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeAlert.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              activeAlert.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (allStudents.isEmpty && allStaff.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Getting started',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start setting up your academy by admitting students, creating campus branches, or registering staff members.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_add_outlined,
                        size: 16,
                      ),
                      label: const Text('Admit Student'),
                      onPressed: () => context.push(AppRoutes.addStudent),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text('Add Staff Member'),
                      onPressed: () => context.push(AppRoutes.addStaff),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
              color: AppColors.primary,
            ),
            StatCard(
              title: selectedBranchId == null ? 'Staff' : 'Branch Staff',
              value: staffAsync.maybeWhen(
                data: (_) => '${filteredStaff.length}',
                orElse: () => '…',
              ),
              icon: Icons.badge_outlined,
              color: AppColors.secondary,
            ),
            StatCard(
              title: 'Total Branches',
              value: branchesAsync.maybeWhen(
                data: (b) => '${b.length}',
                orElse: () => '…',
              ),
              icon: Icons.account_balance_outlined,
              color: AppColors.secondary,
            ),
            StatCard(
              title: 'Today Attendance',
              value: attendanceDisplay,
              icon: Icons.event_note_outlined,
              color: AppColors.warning,
            ),
            StatCard(
              title: 'Monthly Collection',
              value: revenueDisplay,
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            StatCard(
              title: 'Noticeboard',
              value: announcementsAsync.maybeWhen(
                data: (list) => '${list.length}',
                orElse: () => 'Active',
              ),
              icon: Icons.campaign_outlined,
              color: const Color(0xFFEC4899),
              onTap: () => context.push(AppRoutes.academyAnnouncements),
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
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.addBranch),
              icon: const Icon(Icons.add, size: 16, color: AppColors.secondary),
              label: const Text(
                'Add Branch',
                style: TextStyle(color: AppColors.secondary, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (allBranches.isEmpty)
          Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.secondary,
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add campus locations to organize students, staff, and records by branch.',
                        style: TextStyle(
                          color: AppColors.textTertiary,
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
                  staffCount: allStaff
                      .where((s) => s.branchId == branch.id)
                      .length,
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
            color: AppColors.textPrimary,
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
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.studentsList),
            ),
            _ModuleTile(
              icon: Icons.payments_outlined,
              label: 'Fees',
              color: AppColors.success,
              onTap: () => context.push(AppRoutes.fees),
            ),
            _ModuleTile(
              icon: Icons.event_note_outlined,
              label: 'Attendance',
              color: AppColors.warning,
              onTap: () => context.push(AppRoutes.attendance),
            ),
            _ModuleTile(
              icon: Icons.assessment_outlined,
              label: 'Results',
              color: const Color(0xFFA855F7),
              onTap: () => context.push(AppRoutes.results),
            ),
            _ModuleTile(
              icon: Icons.forum_outlined,
              label: 'Conversations',
              color: const Color(0xFF0EA5E9),
              onTap: () => context.push(AppRoutes.academyConversations),
            ),
            _ModuleTile(
              icon: Icons.badge_outlined,
              label: 'Staff',
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.staffList),
            ),
            _ModuleTile(
              icon: Icons.menu_book_outlined,
              label: 'Courses',
              color: const Color(0xFFF97316),
              onTap: () => context.push(AppRoutes.coursesList),
            ),
            _ModuleTile(
              icon: Icons.account_balance_outlined,
              label: 'Branches',
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.branchesList),
            ),
            _ModuleTile(
              icon: Icons.campaign_outlined,
              label: 'Broadcasts',
              color: const Color(0xFFEC4899),
              onTap: () => context.push(AppRoutes.academyAnnouncements),
            ),
            _ModuleTile(
              icon: Icons.support_agent_rounded,
              label: 'Help Desk',
              color: const Color(0xFF818CF8),
              onTap: () => context.push(AppRoutes.academySupport),
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
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.secondary : AppColors.surfaceMuted,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppColors.secondary,
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
                    color: AppColors.textPrimary,
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
                    color: AppColors.textTertiary,
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
                      color: AppColors.primary,
                    ),
                    _BadgePill(
                      label: '$staffCount Staff',
                      color: AppColors.secondary,
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
                  ? AppColors.secondary
                  : AppColors.border,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(isSelected ? 'Viewing' : 'Filter'),
          ),
        ],
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
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
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
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
