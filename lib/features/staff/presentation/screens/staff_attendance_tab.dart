import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../attendance/application/attendance_repository_provider.dart';
import '../../../attendance/domain/attendance_record.dart';
import '../../application/staff_providers.dart';

/// Staff view for taking and reviewing daily student attendance.
class StaffAttendanceTab extends ConsumerStatefulWidget {
  const StaffAttendanceTab({super.key});

  @override
  ConsumerState<StaffAttendanceTab> createState() => _StaffAttendanceTabState();
}

class _StaffAttendanceTabState extends ConsumerState<StaffAttendanceTab> {
  DateTime _date = DateTime.now();

  Future<void> _markStatus(
    String academyId,
    String studentId,
    AttendanceStatus status,
  ) async {
    final record = AttendanceRecord(
      id: const Uuid().v4(),
      academyId: academyId,
      studentId: studentId,
      date: _date,
      status: status,
    );
    await ref.read(attendanceRepositoryProvider).markAttendance(record);
    ref.invalidate(attendanceForDateProvider);
  }

  Future<void> _markAllPresent(
    String academyId,
    List<Student> students,
  ) async {
    for (final s in students) {
      final record = AttendanceRecord(
        id: const Uuid().v4(),
        academyId: academyId,
        studentId: s.id,
        date: _date,
        status: AttendanceStatus.present,
      );
      await ref.read(attendanceRepositoryProvider).markAttendance(record);
    }
    ref.invalidate(attendanceForDateProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All students marked Present for today!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffMemberProvider);
    final branch = ref.watch(currentStaffBranchProvider);
    final students = ref.watch(staffBranchStudentsProvider);
    final academyId = staff?.academyId ?? '';

    final normalizedDate = DateTime(_date.year, _date.month, _date.day);
    final recordsAsync = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: normalizedDate)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date Selector Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (branch != null)
                          Text(
                            branch.name,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: const Text('Change Date'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Attendance Summary & Batch Action Bar
          recordsAsync.when(
            data: (records) {
              final studentIds = students.map((s) => s.id).toSet();
              final relevant =
                  records.where((r) => studentIds.contains(r.studentId)).toList();
              final recordMap = {for (final r in relevant) r.studentId: r};

              int present = 0;
              int absent = 0;
              int late = 0;
              int unmarked = 0;

              for (final s in students) {
                final rec = recordMap[s.id];
                if (rec == null) {
                  unmarked++;
                } else if (rec.status == AttendanceStatus.present) {
                  present++;
                } else if (rec.status == AttendanceStatus.absent) {
                  absent++;
                } else if (rec.status == AttendanceStatus.late) {
                  late++;
                }
              }

              final rate = AttendanceCalculator.percentage(
                presentDays: present + late,
                totalDays: students.isEmpty ? 1 : students.length,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _SummaryChip(
                            label: 'Present: $present',
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: 'Absent: $absent',
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: 'Late: $late',
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: 'Unmarked: $unmarked',
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          _SummaryChip(
                            label: '${rate.toStringAsFixed(0)}% Rate',
                            color: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (students.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _markAllPresent(academyId, students),
                          icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF10B981)),
                          label: const Text(
                            'Mark All Present',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Students Roster List
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                final recordMap = {for (final r in records) r.studentId: r};

                if (students.isEmpty) {
                  return const EmptyState(
                    title: 'No Students Found',
                    message:
                        'There are no students assigned to this campus branch yet.',
                    icon: Icons.school_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final record = recordMap[student.id];
                    final currentStatus = record?.status;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    const Color(0xFF6366F1).withValues(alpha: 0.25),
                                child: Text(
                                  student.fullName.isNotEmpty
                                      ? student.fullName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Roll #${student.rollNumber}',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (student.academicSession.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${student.academicSession}',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            height: 1,
                          ),
                          const SizedBox(height: 8),

                          // Present / Absent / Late action buttons
                          Row(
                            children: [
                              Expanded(
                                child: _StatusButton(
                                  label: 'Present',
                                  icon: Icons.check,
                                  isSelected:
                                      currentStatus == AttendanceStatus.present,
                                  color: const Color(0xFF10B981),
                                  onPressed: () => _markStatus(
                                    academyId,
                                    student.id,
                                    AttendanceStatus.present,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _StatusButton(
                                  label: 'Absent',
                                  icon: Icons.close,
                                  isSelected:
                                      currentStatus == AttendanceStatus.absent,
                                  color: const Color(0xFFEF4444),
                                  onPressed: () => _markStatus(
                                    academyId,
                                    student.id,
                                    AttendanceStatus.absent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _StatusButton(
                                  label: 'Late',
                                  icon: Icons.schedule,
                                  isSelected:
                                      currentStatus == AttendanceStatus.late,
                                  color: const Color(0xFFF59E0B),
                                  onPressed: () => _markStatus(
                                    academyId,
                                    student.id,
                                    AttendanceStatus.late,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
              error: (err, _) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(attendanceForDateProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
