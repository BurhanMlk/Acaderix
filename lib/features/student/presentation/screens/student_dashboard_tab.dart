import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:academy_management/core/theme/app_colors.dart';
import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/communication/application/communication_providers.dart';
import 'package:academy_management/features/communication/presentation/screens/student_inquiries_screen.dart';
import 'package:academy_management/features/communication/presentation/widgets/announcement_card.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'student_profile_modal.dart';

class StudentDashboardTab extends ConsumerWidget {
  const StudentDashboardTab({
    super.key,
    required this.onNavigateToTab,
  });

  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProfileProvider);
    final branch = ref.watch(currentStudentBranchProvider);
    final metrics = ref.watch(studentMetricsProvider);
    final courses = ref.watch(currentStudentCoursesProvider);

    final fullName = student?.fullName.isNotEmpty == true
        ? student!.fullName
        : 'Student';
    final rollNumber = student?.rollNumber.isNotEmpty == true
        ? student!.rollNumber
        : '100001';
    final branchName = branch?.name ?? 'Main Campus';
    final session = student?.academicSession.isNotEmpty == true
        ? student!.academicSession
        : '2026-2027';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Student Profile Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Roll #$rollNumber • $session',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.textMuted,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.badge_outlined, size: 14),
                    label: const Text(
                      'ID Card',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => showStudentProfileModal(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        branchName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Enrolled Active',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Q&A Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Direct Teacher Chat',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Message your course instructors in real-time',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: const Color(0xFF0F172A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentInquiriesScreen(
                        academyId: student?.academyId,
                        studentId: student?.id,
                      ),
                    ),
                  );
                },
                child: const Text('Open Chats'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. KPI Metrics Grid (2x2)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _StudentStatCard(
              title: 'Attendance',
              value: '${metrics.attendanceRate.toStringAsFixed(0)}%',
              subtitle: '${metrics.presentDays} Present • ${metrics.absentDays} Absent',
              icon: Icons.event_available,
              color: AppColors.success,
              onTap: () => onNavigateToTab(2),
            ),
            _StudentStatCard(
              title: 'Enrolled Courses',
              value: '${metrics.totalCourses}',
              subtitle: 'Active Batches',
              icon: Icons.menu_book,
              color: AppColors.secondary,
              onTap: () => onNavigateToTab(1),
            ),
            _StudentStatCard(
              title: 'Fee Status',
              value: metrics.feeBalance > 0
                  ? 'Rs ${metrics.feeBalance.toStringAsFixed(0)}'
                  : 'Cleared',
              subtitle: metrics.feeBalance > 0 ? 'Pending Balance' : 'All Paid Up',
              icon: Icons.payments_outlined,
              color: metrics.feeBalance > 0
                  ? const Color(0xFFF43F5E)
                  : AppColors.success,
              onTap: () => onNavigateToTab(4),
            ),
            _StudentStatCard(
              title: 'Performance',
              value: metrics.overallGrade,
              subtitle: '${metrics.overallPercentage.toStringAsFixed(0)}% Average',
              icon: Icons.grade_outlined,
              color: AppColors.primary,
              onTap: () => onNavigateToTab(3),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Today's Class Schedule Preview
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: AppColors.secondary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Class Schedule & Lectures',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateToTab(1),
                    child: const Text(
                      'Full Timetable',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (courses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    'No enrolled classes found for current session.',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...courses.take(3).map((course) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                children: [
                                  if (course.schedule.isNotEmpty)
                                    Text(
                                      course.schedule,
                                      style: TextStyle(
                                        color: AppColors.textPrimary
                                            .withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  if (course.teacherName.isNotEmpty)
                                    Text(
                                      '• ${course.teacherName}',
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (course.room.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Rm ${course.room}',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Attendance Visual Chart Card
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.pie_chart_outline,
                            color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attendance Analytics',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigateToTab(2),
                    child: const Text(
                      'View Ledger',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: [
                            PieChartSectionData(
                              color: AppColors.success,
                              value: metrics.presentDays > 0
                                  ? metrics.presentDays.toDouble()
                                  : 1,
                              title: '',
                              radius: 18,
                            ),
                            if (metrics.absentDays > 0)
                              PieChartSectionData(
                                color: const Color(0xFFF43F5E),
                                value: metrics.absentDays.toDouble(),
                                title: '',
                                radius: 18,
                              ),
                            if (metrics.lateDays > 0)
                              PieChartSectionData(
                                color: AppColors.warning,
                                value: metrics.lateDays.toDouble(),
                                title: '',
                                radius: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendRow('Present', '${metrics.presentDays} days',
                              AppColors.success),
                          const SizedBox(height: 6),
                          _buildLegendRow('Absent', '${metrics.absentDays} days',
                              const Color(0xFFF43F5E)),
                          const SizedBox(height: 6),
                          _buildLegendRow('Late', '${metrics.lateDays} days',
                              AppColors.warning),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 5. Campus Noticeboard & Broadcasts
        Row(
          children: [
            const Icon(Icons.campaign_outlined,
                size: 18, color: Color(0xFFEC4899)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Campus Noticeboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StudentNoticeboardPreview(academyId: student?.academyId ?? ''),
      ],
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StudentStatCard extends StatelessWidget {
  const _StudentStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, color: color, size: 16),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentNoticeboardPreview extends ConsumerWidget {
  const _StudentNoticeboardPreview({required this.academyId});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (academyId.isEmpty) return const SizedBox.shrink();

    final announcementsAsync =
        ref.watch(studentAnnouncementsProvider(academyId));

    return announcementsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceMuted),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  'No recent broadcast announcements',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final topNotices = list.take(3).toList();
        return Column(
          children: topNotices
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnnouncementCard(
                    announcement: a,
                    canDelete: false,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
