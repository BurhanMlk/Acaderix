import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:academy_management/core/widgets/glass.dart';
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
        // 1. Student Hero Profile Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.white,
                      size: 28,
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
                            color: Colors.white,
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
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
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
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 14,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        branchName,
                        style: const TextStyle(
                          color: Colors.white,
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
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
              color: const Color(0xFF10B981),
              onTap: () => onNavigateToTab(2),
            ),
            _StudentStatCard(
              title: 'Enrolled Courses',
              value: '${metrics.totalCourses}',
              subtitle: 'Active Batches',
              icon: Icons.menu_book,
              color: const Color(0xFF38BDF8),
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
                  : const Color(0xFF10B981),
              onTap: () => onNavigateToTab(4),
            ),
            _StudentStatCard(
              title: 'Performance',
              value: metrics.overallGrade,
              subtitle: '${metrics.overallPercentage.toStringAsFixed(0)}% Average',
              icon: Icons.grade_outlined,
              color: const Color(0xFFA855F7),
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
                        Icon(Icons.schedule, color: Color(0xFF38BDF8), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Class Schedule & Lectures',
                            style: TextStyle(
                              color: Colors.white,
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
                      'All Courses',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (courses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No active course schedules assigned yet.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                )
              else
                ...courses.take(3).map((course) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.class_outlined,
                            color: Color(0xFF38BDF8),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                course.teacherName.isNotEmpty
                                    ? 'Teacher: ${course.teacherName}'
                                    : 'Room: ${course.room.isNotEmpty ? course.room : "General Hall"}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (course.schedule.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  course.schedule,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                              color: const Color(0xFFF59E0B)
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
                            color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attendance Analytics',
                            style: TextStyle(
                              color: Colors.white,
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
                        color: Color(0xFF10B981),
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
                              color: const Color(0xFF10B981),
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
                                color: const Color(0xFFF59E0B),
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
                              const Color(0xFF10B981)),
                          const SizedBox(height: 6),
                          _buildLegendRow('Absent', '${metrics.absentDays} days',
                              const Color(0xFFF43F5E)),
                          const SizedBox(height: 6),
                          _buildLegendRow('Late', '${metrics.lateDays} days',
                              const Color(0xFFF59E0B)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            color: Colors.white.withValues(alpha: 0.05),
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
                        color: Colors.white.withValues(alpha: 0.7),
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
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
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
