import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:academy_management/core/domain/attendance_calculator.dart';
import 'package:academy_management/core/theme/app_colors.dart';
import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/attendance/domain/attendance_record.dart';
import 'package:academy_management/features/student/application/student_providers.dart';

/// Tab presenting the student's attendance analytics, exam eligibility,
/// and chronological attendance history.
class StudentAttendanceTab extends ConsumerStatefulWidget {
  const StudentAttendanceTab({super.key});

  @override
  ConsumerState<StudentAttendanceTab> createState() =>
      _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends ConsumerState<StudentAttendanceTab> {
  AttendanceStatus? _filterStatus; // null = all

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(currentStudentAttendanceRecordsProvider);
    final metrics = ref.watch(studentMetricsProvider);
    final courses = ref.watch(currentStudentCoursesProvider);
    final theme = Theme.of(context);

    // Course lookup map
    final courseMap = {for (final c in courses) c.id: c.name};

    // Calculate status breakdown
    final presentCount =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final absentCount =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount =
        records.where((r) => r.status == AttendanceStatus.late).length;
    final leaveCount =
        records.where((r) => r.status == AttendanceStatus.leave).length;
    final totalCount = records.length;
    final percentage = metrics.attendancePercentage;
    final isEligible = percentage >= 75.0 || totalCount == 0;

    // Filter records
    final filteredRecords = _filterStatus == null
        ? records
        : records.where((r) => r.status == _filterStatus).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Visual Attendance Overview Card with Donut Chart
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Attendance Overview',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isEligible
                              ? AppColors.success
                              : AppColors.danger)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEligible
                            ? AppColors.success
                            : AppColors.danger,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isEligible ? 'Eligible for Exams' : 'Low Attendance Alert',
                      style: TextStyle(
                        color: isEligible
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Donut Chart & Percent Meter
              Row(
                children: [
                  SizedBox(
                    height: 104,
                    width: 104,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 32,
                            sections: totalCount == 0
                                ? [
                                    PieChartSectionData(
                                      value: 100,
                                      color: AppColors.surfaceMuted,
                                      showTitle: false,
                                      radius: 14,
                                    ),
                                  ]
                                : [
                                    if (presentCount > 0)
                                      PieChartSectionData(
                                        value: presentCount.toDouble(),
                                        color: AppColors.success,
                                        showTitle: false,
                                        radius: 14,
                                      ),
                                    if (lateCount > 0)
                                      PieChartSectionData(
                                        value: lateCount.toDouble(),
                                        color: AppColors.warning,
                                        showTitle: false,
                                        radius: 14,
                                      ),
                                    if (absentCount > 0)
                                      PieChartSectionData(
                                        value: absentCount.toDouble(),
                                        color: AppColors.danger,
                                        showTitle: false,
                                        radius: 14,
                                      ),
                                    if (leaveCount > 0)
                                      PieChartSectionData(
                                        value: leaveCount.toDouble(),
                                        color: AppColors.secondary,
                                        showTitle: false,
                                        radius: 14,
                                      ),
                                  ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Present',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendRow('Present', presentCount, AppColors.success),
                        const SizedBox(height: 6),
                        _buildLegendRow('Late', lateCount, AppColors.warning),
                        const SizedBox(height: 6),
                        _buildLegendRow('Absent', absentCount, AppColors.danger),
                        const SizedBox(height: 6),
                        _buildLegendRow('Leave', leaveCount, AppColors.secondary),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Requirement progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Minimum Exam Requirement (75%)',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}% / 75%',
                        style: TextStyle(
                          color: isEligible
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF87171),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isEligible
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All (${records.length})',
                isSelected: _filterStatus == null,
                onTap: () => setState(() => _filterStatus = null),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Present ($presentCount)',
                color: AppColors.success,
                isSelected: _filterStatus == AttendanceStatus.present,
                onTap: () => setState(() => _filterStatus = AttendanceStatus.present),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Absent ($absentCount)',
                color: AppColors.danger,
                isSelected: _filterStatus == AttendanceStatus.absent,
                onTap: () => setState(() => _filterStatus = AttendanceStatus.absent),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Late ($lateCount)',
                color: AppColors.warning,
                isSelected: _filterStatus == AttendanceStatus.late,
                onTap: () => setState(() => _filterStatus = AttendanceStatus.late),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Leave ($leaveCount)',
                color: AppColors.secondary,
                isSelected: _filterStatus == AttendanceStatus.leave,
                onTap: () => setState(() => _filterStatus = AttendanceStatus.leave),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Attendance Records (${filteredRecords.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        if (filteredRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 40,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No attendance logs recorded yet',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredRecords.map((r) {
            final courseName = courseMap[r.courseId] ?? 'Class Lecture';
            final dateStr = DateFormat('EEE, dd MMM yyyy').format(r.date);
            return _buildAttendanceRecordTile(r, courseName, dateStr);
          }),
      ],
    );
  }

  Widget _buildLegendRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count days',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.25)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.surfaceMuted,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordTile(
    AttendanceRecord record,
    String courseName,
    String dateStr,
  ) {
    final (statusColor, statusLabel, icon) = switch (record.status) {
      AttendanceStatus.present => (
          AppColors.success,
          'Present',
          Icons.check_circle_outline,
        ),
      AttendanceStatus.absent => (
          AppColors.danger,
          'Absent',
          Icons.cancel_outlined,
        ),
      AttendanceStatus.late => (
          AppColors.warning,
          'Late',
          Icons.access_time_outlined,
        ),
      AttendanceStatus.leave => (
          AppColors.secondary,
          'Leave',
          Icons.beach_access_outlined,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor, width: 0.8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
