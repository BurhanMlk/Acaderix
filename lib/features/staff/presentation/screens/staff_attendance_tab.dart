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

/// Staff view for taking and reviewing course-based student attendance.
class StaffAttendanceTab extends ConsumerStatefulWidget {
  const StaffAttendanceTab({super.key});

  @override
  ConsumerState<StaffAttendanceTab> createState() => _StaffAttendanceTabState();
}

class _StaffAttendanceTabState extends ConsumerState<StaffAttendanceTab> {
  DateTime _date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  /// Optimistic status store for instantaneous, responsive feedback on tap.
  final Map<String, AttendanceStatus> _optimisticStatus = {};
  final Set<String> _savingStudentIds = {};

  Future<void> _markStatus(
    String academyId,
    String studentId,
    AttendanceStatus status, {
    String courseId = '',
    String staffId = '',
  }) async {
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);

    setState(() {
      _optimisticStatus[studentId] = status;
      _savingStudentIds.add(studentId);
    });

    final record = AttendanceRecord(
      id: const Uuid().v4(),
      academyId: academyId,
      courseId: courseId,
      studentId: studentId,
      markedById: staffId,
      date: normalizedDate,
      status: status,
    );

    try {
      await ref.read(attendanceRepositoryProvider).markAttendance(record);
      ref.invalidate(attendanceForDateProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticStatus.remove(studentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingStudentIds.remove(studentId);
        });
      }
    }
  }

  Future<void> _markAllPresent(
    String academyId,
    List<Student> students, {
    String courseId = '',
    String staffId = '',
  }) async {
    if (students.isEmpty) return;

    final normalizedDate = DateTime(_date.year, _date.month, _date.day);

    setState(() {
      for (final s in students) {
        _optimisticStatus[s.id] = AttendanceStatus.present;
      }
    });

    final records = students
        .map(
          (s) => AttendanceRecord(
            id: const Uuid().v4(),
            academyId: academyId,
            courseId: courseId,
            studentId: s.id,
            markedById: staffId,
            date: normalizedDate,
            status: AttendanceStatus.present,
          ),
        )
        .toList();

    try {
      await ref.read(attendanceRepositoryProvider).markBatchAttendance(records);
      ref.invalidate(attendanceForDateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All enrolled students marked Present for today!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all present: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffMemberProvider);
    final branch = ref.watch(currentStaffBranchProvider);
    final assignedCourses = ref.watch(staffAssignedCoursesProvider);
    final activeCourse = ref.watch(activeStaffCourseProvider);
    final students = ref.watch(staffBranchStudentsProvider);
    final academyId = staff?.academyId ?? '';

    final normalizedDate = DateTime(_date.year, _date.month, _date.day);
    final recordsAsync = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: normalizedDate)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: recordsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(attendanceForDateProvider),
        ),
        data: (records) {
          final currentCourseId = activeCourse?.id ?? '';
          final studentIds = students.map((s) => s.id).toSet();
          final relevant = records.where((r) {
            final matchStudent = studentIds.contains(r.studentId);
            final matchCourse = currentCourseId.isEmpty
                ? true
                : (r.courseId == currentCourseId || r.courseId.isEmpty);
            return matchStudent && matchCourse;
          }).toList();

          // Crucial: sort so course-specific records appear last and take precedence in the map
          relevant.sort((a, b) {
            final aMatch = a.courseId == currentCourseId ? 1 : 0;
            final bMatch = b.courseId == currentCourseId ? 1 : 0;
            return aMatch.compareTo(bMatch);
          });

          final recordMap = {for (final r in relevant) r.studentId: r};

          int present = 0;
          int absent = 0;
          int late = 0;
          int unmarked = 0;

          for (final s in students) {
            final effectiveStatus =
                _optimisticStatus[s.id] ?? recordMap[s.id]?.status;
            if (effectiveStatus == null) {
              unmarked++;
            } else if (effectiveStatus == AttendanceStatus.present) {
              present++;
            } else if (effectiveStatus == AttendanceStatus.absent) {
              absent++;
            } else if (effectiveStatus == AttendanceStatus.late) {
              late++;
            }
          }

          final rate = AttendanceCalculator.percentage(
            presentDays: present + late,
            totalDays: students.isEmpty ? 1 : students.length,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // 1. Date Selector Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          setState(() {
                            _date = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                            _optimisticStatus.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Course / Batch Selector Card
              if (assignedCourses.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: Color(0xFF38BDF8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Course:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: (activeCourse != null &&
                                    assignedCourses.any(
                                        (c) => c.id == activeCourse.id))
                                ? activeCourse.id
                                : (assignedCourses.isNotEmpty
                                    ? assignedCourses.first.id
                                    : null),
                            dropdownColor: const Color(0xFF1E293B),
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            items: assignedCourses.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.name} (${c.enrolledStudentIds.length} students)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _optimisticStatus.clear();
                                });
                                ref
                                    .read(selectedStaffCourseIdProvider.notifier)
                                    .state = val;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 3. Status Badges Row
              Row(
                children: [
                  _StatChip(
                    label: 'Present',
                    count: present,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Absent',
                    count: absent,
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Late',
                    count: late,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Total',
                    count: students.length,
                    color: const Color(0xFF38BDF8),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Compliance status & Batch "Mark All Present" Action
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unmarked == 0 && students.isNotEmpty
                          ? 'Rate: ${rate.toStringAsFixed(0)}% (Submitted)'
                          : '$unmarked of ${students.length} unmarked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unmarked == 0 && students.isNotEmpty
                            ? const Color(0xFF34D399)
                            : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.done_all, size: 14),
                    label: const Text('Mark All Present'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    onPressed: students.isEmpty
                        ? null
                        : () => _markAllPresent(
                            academyId,
                            students,
                            courseId: currentCourseId,
                            staffId: staff?.id ?? '',
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Students Attendance Roster
              if (students.isEmpty)
                EmptyState(
                  title: activeCourse != null
                      ? 'No Students Enrolled'
                      : 'No Students Found',
                  message: activeCourse != null
                      ? 'No students are enrolled in "${activeCourse.name}". Ask admin to enroll students.'
                      : 'No active students found in your assigned campus.',
                  icon: Icons.people_outline,
                )
              else
                ...students.map((student) {
                  final rec = recordMap[student.id];
                  final currentStatus =
                      _optimisticStatus[student.id] ?? rec?.status;
                  final isSaving = _savingStudentIds.contains(student.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          child: Text(
                            student.fullName.isNotEmpty
                                ? student.fullName.substring(0, 1).toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
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
                              Text(
                                'Roll #${student.rollNumber}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _AttendanceStatusSelector(
                          currentStatus: currentStatus,
                          isSaving: isSaving,
                          onStatusSelected: (status) => _markStatus(
                            academyId,
                            student.id,
                            status,
                            courseId: currentCourseId,
                            staffId: staff?.id ?? '',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceStatusSelector extends StatelessWidget {
  const _AttendanceStatusSelector({
    required this.currentStatus,
    required this.onStatusSelected,
    this.isSaving = false,
  });

  final AttendanceStatus? currentStatus;
  final ValueChanged<AttendanceStatus> onStatusSelected;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusCircleBtn(
          label: 'P',
          tooltip: 'Present',
          color: const Color(0xFF10B981),
          isSelected: currentStatus == AttendanceStatus.present,
          onTap: () => onStatusSelected(AttendanceStatus.present),
        ),
        const SizedBox(width: 8),
        _StatusCircleBtn(
          label: 'L',
          tooltip: 'Late',
          color: const Color(0xFFF59E0B),
          isSelected: currentStatus == AttendanceStatus.late,
          onTap: () => onStatusSelected(AttendanceStatus.late),
        ),
        const SizedBox(width: 8),
        _StatusCircleBtn(
          label: 'A',
          tooltip: 'Absent',
          color: const Color(0xFFEF4444),
          isSelected: currentStatus == AttendanceStatus.absent,
          onTap: () => onStatusSelected(AttendanceStatus.absent),
        ),
      ],
    );
  }
}

class _StatusCircleBtn extends StatelessWidget {
  const _StatusCircleBtn({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: color.withValues(alpha: 0.3),
          highlightColor: color.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.35),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
