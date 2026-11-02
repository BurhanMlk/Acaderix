import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../academics/domain/course.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../attendance/application/attendance_repository_provider.dart';
import '../../../attendance/domain/attendance_record.dart';
import '../../../attendance/presentation/utils/attendance_pdf_generator.dart';
import '../../../branches/domain/branch.dart';
import '../../application/staff_providers.dart';

/// Comprehensive staff view for taking, reviewing, and analyzing course-based student attendance.
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

  String _searchQuery = '';
  AttendanceStatus? _statusFilter; // null = all, or specific status
  bool _showUnmarkedOnly = false;
  bool _showAnalytics = false;

  Future<void> _markStatus(
    String academyId,
    String studentId,
    AttendanceStatus status, {
    String courseId = '',
    String staffId = '',
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);

    if (normalizedDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Advance attendance is locked. Attendance cannot be recorded for future dates.',
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);

    if (normalizedDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Advance attendance is locked. Attendance cannot be recorded for future dates.',
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

  Future<void> _exportAttendancePdf({
    required String academyName,
    required Branch? branch,
    required Course? course,
    required String teacherName,
    required List<Student> students,
    required Map<String, AttendanceRecord> recordMap,
  }) async {
    try {
      await AttendancePdfGenerator.printOrShareAttendanceRegister(
        academyName: academyName,
        branch: branch,
        course: course,
        teacherName: teacherName,
        date: _date,
        students: students,
        recordMap: recordMap,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate attendance PDF: $e'),
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);
    final isFutureDate = normalizedDate.isAfter(today);

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
          int leave = 0;
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
            } else if (effectiveStatus == AttendanceStatus.leave) {
              leave++;
            }
          }

          final rate = AttendanceCalculator.percentage(
            presentDays: present + late,
            totalDays: students.isEmpty ? 1 : students.length,
          );

          // Apply search query and status filters
          final filteredStudents = students.where((s) {
            final query = _searchQuery.trim().toLowerCase();
            final matchesQuery = query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.rollNumber.toLowerCase().contains(query);

            if (!matchesQuery) return false;

            final status = _optimisticStatus[s.id] ?? recordMap[s.id]?.status;

            if (_showUnmarkedOnly) {
              return status == null;
            }

            if (_statusFilter != null) {
              return status == _statusFilter;
            }

            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // 1. Date Selector & PDF Export Header
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
                            DateFormat('EEE, MMM d, yyyy').format(_date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (branch != null)
                            Text(
                              branch.name,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _showAnalytics ? 'Hide Chart' : 'Show Chart',
                      icon: Icon(
                        _showAnalytics
                            ? Icons.analytics
                            : Icons.analytics_outlined,
                        color: const Color(0xFF38BDF8),
                        size: 19,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () =>
                          setState(() => _showAnalytics = !_showAnalytics),
                    ),
                    IconButton(
                      tooltip: 'Export PDF Register',
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFF38BDF8),
                        size: 19,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => _exportAttendancePdf(
                        academyName: branch?.name ?? 'Acaderix Academy',
                        branch: branch,
                        course: activeCourse,
                        teacherName: staff?.fullName ?? '',
                        students: students,
                        recordMap: recordMap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 12),
                      label: const Text('Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
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

              // Advance Attendance Guardrail Warning
              if (isFutureDate) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock, color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Advance Attendance Locked: Attendance cannot be recorded for future dates.',
                          style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

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
                    isSelected: _statusFilter == AttendanceStatus.present,
                    onTap: () {
                      setState(() {
                        _showUnmarkedOnly = false;
                        _statusFilter = _statusFilter == AttendanceStatus.present
                            ? null
                            : AttendanceStatus.present;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Late',
                    count: late,
                    color: const Color(0xFFF59E0B),
                    isSelected: _statusFilter == AttendanceStatus.late,
                    onTap: () {
                      setState(() {
                        _showUnmarkedOnly = false;
                        _statusFilter = _statusFilter == AttendanceStatus.late
                            ? null
                            : AttendanceStatus.late;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Absent',
                    count: absent,
                    color: const Color(0xFFEF4444),
                    isSelected: _statusFilter == AttendanceStatus.absent,
                    onTap: () {
                      setState(() {
                        _showUnmarkedOnly = false;
                        _statusFilter = _statusFilter == AttendanceStatus.absent
                            ? null
                            : AttendanceStatus.absent;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Leave',
                    count: leave,
                    color: const Color(0xFF8B5CF6),
                    isSelected: _statusFilter == AttendanceStatus.leave,
                    onTap: () {
                      setState(() {
                        _showUnmarkedOnly = false;
                        _statusFilter = _statusFilter == AttendanceStatus.leave
                            ? null
                            : AttendanceStatus.leave;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _StatChip(
                    label: 'Total',
                    count: students.length,
                    color: const Color(0xFF38BDF8),
                    isSelected: _statusFilter == null && !_showUnmarkedOnly,
                    onTap: () {
                      setState(() {
                        _statusFilter = null;
                        _showUnmarkedOnly = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Rate & Batch "Mark All Present" Action
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
                  const SizedBox(width: 8),
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
                    onPressed: isFutureDate || students.isEmpty
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
              const SizedBox(height: 8),

              // 5. Visual Interactive Analytics with fl_chart (Collapsible)
              if (_showAnalytics && students.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Roll Breakdown',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (rate >= 75
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${rate.toStringAsFixed(0)}% Rate',
                              style: TextStyle(
                                color: rate >= 75
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFF87171),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 130,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 26,
                                  sections: [
                                    if (present > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFF10B981),
                                        value: present.toDouble(),
                                        title: '$present',
                                        radius: 34,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (late > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFFF59E0B),
                                        value: late.toDouble(),
                                        title: '$late',
                                        radius: 34,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (absent > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFFEF4444),
                                        value: absent.toDouble(),
                                        title: '$absent',
                                        radius: 34,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (leave > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFF8B5CF6),
                                        value: leave.toDouble(),
                                        title: '$leave',
                                        radius: 34,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (unmarked > 0)
                                      PieChartSectionData(
                                        color: Colors.white24,
                                        value: unmarked.toDouble(),
                                        title: '$unmarked',
                                        radius: 34,
                                        titleStyle: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legendItem(
                                      'Present', present, const Color(0xFF10B981)),
                                  const SizedBox(height: 4),
                                  _legendItem('Late', late, const Color(0xFFF59E0B)),
                                  const SizedBox(height: 4),
                                  _legendItem(
                                      'Absent', absent, const Color(0xFFEF4444)),
                                  const SizedBox(height: 4),
                                  _legendItem(
                                      'Leave', leave, const Color(0xFF8B5CF6)),
                                  if (unmarked > 0) ...[
                                    const SizedBox(height: 4),
                                    _legendItem('Unmarked', unmarked, Colors.white38),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 6. Quick Student Search and Quick Filter Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search roll # or student name...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.white54,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                color: Colors.white54,
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (unmarked > 0) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showUnmarkedOnly,
                      label: Text(
                        'Unmarked ($unmarked)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _showUnmarkedOnly
                              ? Colors.black
                              : Colors.amberAccent,
                        ),
                      ),
                      backgroundColor: Colors.amber.withValues(alpha: 0.1),
                      selectedColor: Colors.amberAccent,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) {
                        setState(() {
                          _showUnmarkedOnly = val;
                          if (val) _statusFilter = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // 7. Students Attendance Roster
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
              else if (filteredStudents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          color: Colors.white38,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No students matching current filter',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _statusFilter = null;
                              _showUnmarkedOnly = false;
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredStudents.map((student) {
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          isLocked: isFutureDate,
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

  static Widget _legendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.28)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
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

class _AttendanceStatusSelector extends StatelessWidget {
  const _AttendanceStatusSelector({
    required this.currentStatus,
    required this.onStatusSelected,
    this.isSaving = false,
    this.isLocked = false,
  });

  final AttendanceStatus? currentStatus;
  final ValueChanged<AttendanceStatus> onStatusSelected;
  final bool isSaving;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.35 : 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusCircleBtn(
            label: 'P',
            tooltip: isLocked ? 'Advance attendance is locked' : 'Present',
            color: const Color(0xFF10B981),
            isSelected: currentStatus == AttendanceStatus.present,
            onTap: isLocked
                ? () {}
                : () => onStatusSelected(AttendanceStatus.present),
          ),
          const SizedBox(width: 5),
          _StatusCircleBtn(
            label: 'L',
            tooltip: isLocked ? 'Advance attendance is locked' : 'Late',
            color: const Color(0xFFF59E0B),
            isSelected: currentStatus == AttendanceStatus.late,
            onTap: isLocked
                ? () {}
                : () => onStatusSelected(AttendanceStatus.late),
          ),
          const SizedBox(width: 5),
          _StatusCircleBtn(
            label: 'A',
            tooltip: isLocked ? 'Advance attendance is locked' : 'Absent',
            color: const Color(0xFFEF4444),
            isSelected: currentStatus == AttendanceStatus.absent,
            onTap: isLocked
                ? () {}
                : () => onStatusSelected(AttendanceStatus.absent),
          ),
          const SizedBox(width: 5),
          _StatusCircleBtn(
            label: 'LV',
            tooltip: isLocked ? 'Advance attendance is locked' : 'Leave',
            color: const Color(0xFF8B5CF6),
            isSelected: currentStatus == AttendanceStatus.leave,
            onTap: isLocked
                ? () {}
                : () => onStatusSelected(AttendanceStatus.leave),
          ),
        ],
      ),
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
    final isCompact = label.length > 1;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          splashColor: color.withValues(alpha: 0.3),
          highlightColor: color.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeInOut,
            width: isCompact ? 34 : 32,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.35),
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
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
                fontSize: isCompact ? 11 : 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
