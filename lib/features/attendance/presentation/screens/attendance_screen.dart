import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router.dart';

import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academics/application/course_repository_provider.dart';
import '../../../academics/domain/course.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../branches/domain/branch.dart';
import '../../application/attendance_repository_provider.dart';
import '../../domain/attendance_record.dart';
import '../utils/attendance_pdf_generator.dart';

/// Screen allowing Academy Admin to monitor course-based attendance compliance across teachers,
/// review student ledgers, and provide administrative override when teachers are on leave.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _date = DateTime.now();
  int _viewMode = 0; // 0: By Course / Batch (Audit Mode), 1: General Campus Roster

  Future<void> _mark(
    String academyId,
    String studentId,
    AttendanceStatus status, {
    String courseId = '',
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

    final record = AttendanceRecord(
      id: const Uuid().v4(),
      academyId: academyId,
      courseId: courseId,
      studentId: studentId,
      date: normalizedDate,
      status: status,
    );
    await ref.read(attendanceRepositoryProvider).markAttendance(record);
    ref.invalidate(attendanceForDateProvider);
  }

  void _showCourseLedgerModal(
    BuildContext context,
    String academyId,
    Course course,
    List<Student> allStudents,
    List<AttendanceRecord> records,
  ) {
    final enrolledSet = course.enrolledStudentIds.toSet();
    final enrolledStudents = allStudents.where((s) => enrolledSet.contains(s.id)).toList();
    final candidateStudents = enrolledStudents.isNotEmpty
        ? enrolledStudents
        : allStudents.where((s) => s.branchId == course.branchId).toList();
    final modalOverrides = <String, AttendanceStatus>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final relevant = records
              .where((r) => r.courseId == course.id || r.courseId.isEmpty)
              .toList();
          relevant.sort((a, b) {
            final aMatch = a.courseId == course.id ? 1 : 0;
            final bMatch = b.courseId == course.id ? 1 : 0;
            return aMatch.compareTo(bMatch);
          });
          final recordMap = {for (final r in relevant) r.studentId: r};

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Teacher: ${course.teacherName.isNotEmpty ? course.teacherName : "Unassigned"}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF38BDF8)),
                        tooltip: 'Export Course Register PDF',
                        onPressed: () async {
                          await AttendancePdfGenerator.printOrShareAttendanceRegister(
                            academyName: 'Course Attendance Register',
                            branch: null,
                            course: course,
                            teacherName: course.teacherName,
                            date: _date,
                            students: candidateStudents,
                            recordMap: recordMap,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 12),

                  Expanded(
                    child: candidateStudents.isEmpty
                        ? const Center(
                            child: Text(
                              'No students enrolled in this course.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: candidateStudents.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final student = candidateStudents[index];
                              final rec = recordMap[student.id];
                              final currentStatus = modalOverrides[student.id] ?? rec?.status ?? AttendanceStatus.present;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
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
                                    _StatusToggleButton(
                                      status: AttendanceStatus.present,
                                      isSelected: currentStatus == AttendanceStatus.present,
                                      label: 'P',
                                      color: const Color(0xFF10B981),
                                      onTap: () async {
                                        setModalState(() {
                                          modalOverrides[student.id] = AttendanceStatus.present;
                                        });
                                        await _mark(
                                          academyId,
                                          student.id,
                                          AttendanceStatus.present,
                                          courseId: course.id,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _StatusToggleButton(
                                      status: AttendanceStatus.late,
                                      isSelected: currentStatus == AttendanceStatus.late,
                                      label: 'L',
                                      color: const Color(0xFFF59E0B),
                                      onTap: () async {
                                        setModalState(() {
                                          modalOverrides[student.id] = AttendanceStatus.late;
                                        });
                                        await _mark(
                                          academyId,
                                          student.id,
                                          AttendanceStatus.late,
                                          courseId: course.id,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _StatusToggleButton(
                                      status: AttendanceStatus.absent,
                                      isSelected: currentStatus == AttendanceStatus.absent,
                                      label: 'A',
                                      color: const Color(0xFFEF4444),
                                      onTap: () async {
                                        setModalState(() {
                                          modalOverrides[student.id] = AttendanceStatus.absent;
                                        });
                                        await _mark(
                                          academyId,
                                          student.id,
                                          AttendanceStatus.absent,
                                          courseId: course.id,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _StatusToggleButton(
                                      status: AttendanceStatus.leave,
                                      isSelected: currentStatus == AttendanceStatus.leave,
                                      label: 'LV',
                                      color: const Color(0xFF8B5CF6),
                                      onTap: () async {
                                        setModalState(() {
                                          modalOverrides[student.id] = AttendanceStatus.leave;
                                        });
                                        await _mark(
                                          academyId,
                                          student.id,
                                          AttendanceStatus.leave,
                                          courseId: course.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final students = ref.watch(studentsStreamProvider(academyId));
    final coursesAsync = ref.watch(coursesStreamProvider(academyId));
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);
    final records = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: normalizedDate)),
    );
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branch Tabs at top
          BranchTabBar(academyId: academyId),

          // Date Selector Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                    tooltip: 'Export Campus Attendance Register',
                    onPressed: () async {
                      final currentStudents = students.value ?? [];
                      final currentBranch = branches.where((b) => b.id == selectedBranchId).firstOrNull;
                      final relevantStudents = selectedBranchId != null && selectedBranchId.isNotEmpty
                          ? currentStudents.where((s) => s.branchId == selectedBranchId).toList()
                          : currentStudents;
                      final currentRecords = records.value ?? [];
                      final recordMap = {for (final r in currentRecords) r.studentId: r};

                      await AttendancePdfGenerator.printOrShareAttendanceRegister(
                        academyName: currentBranch?.name ?? 'Campus Attendance',
                        branch: currentBranch,
                        course: null,
                        teacherName: 'Administrative Roster',
                        date: _date,
                        students: relevantStudents,
                        recordMap: recordMap,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 13),
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
                        initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ],
              ),
            ),
          ),

          // View Mode Switcher: "Course Compliance Audit" vs "Campus Roster"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _viewMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == 0
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _viewMode == 0
                              ? const Color(0xFF38BDF8)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rule,
                            size: 15,
                            color: _viewMode == 0
                                ? const Color(0xFF38BDF8)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Course Monitoring',
                            style: TextStyle(
                              color: _viewMode == 0
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white70,
                              fontWeight: _viewMode == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _viewMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == 1
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _viewMode == 1
                              ? const Color(0xFF38BDF8)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 15,
                            color: _viewMode == 1
                                ? const Color(0xFF38BDF8)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'General Roster',
                            style: TextStyle(
                              color: _viewMode == 1
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white70,
                              fontWeight: _viewMode == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main View Content
          Expanded(
            child: _viewMode == 0
                ? _buildCourseMonitoringView(
                    academyId: academyId,
                    selectedBranchId: selectedBranchId,
                    coursesAsync: coursesAsync,
                    recordsList: records.value ?? const <AttendanceRecord>[],
                    allStudents: students.value ?? const <Student>[],
                  )
                : _buildGeneralRosterView(
                    academyId: academyId,
                    students: students,
                    records: records,
                    branches: branches,
                    selectedBranchId: selectedBranchId,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseMonitoringView({
    required String academyId,
    required String? selectedBranchId,
    required AsyncValue<List<Course>> coursesAsync,
    required List<AttendanceRecord> recordsList,
    required List<Student> allStudents,
  }) {
    return coursesAsync.when(
      data: (courses) {
        var filteredCourses = courses;
        if (selectedBranchId != null) {
          filteredCourses = filteredCourses
              .where((c) => c.branchId == selectedBranchId)
              .toList();
        }

        if (filteredCourses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 40,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Courses Created Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Courses allow teachers to take class-specific attendance.\nSwitch to "General Roster" or create a course.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Course'),
                    onPressed: () => context.push(AppRoutes.addCourse),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate submission metrics
        int submittedCourses = 0;
        int pendingCourses = 0;

        for (final course in filteredCourses) {
          final courseRecords = recordsList
              .where((r) => r.courseId == course.id)
              .toList();
          if (courseRecords.isNotEmpty) {
            submittedCourses++;
          } else {
            pendingCourses++;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            // Compliance Stats Header
            Row(
              children: [
                _StatBadge(
                  label: 'Submitted',
                  count: submittedCourses,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  label: 'Pending',
                  count: pendingCourses,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  label: 'Total Courses',
                  count: filteredCourses.length,
                  color: const Color(0xFF38BDF8),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...filteredCourses.map((course) {
              final courseRecords = recordsList
                  .where((r) => r.courseId == course.id)
                  .toList();
              final isSubmitted = courseRecords.isNotEmpty;

              final presentCount = courseRecords
                  .where((r) => r.status == AttendanceStatus.present)
                  .length;
              final absentCount = courseRecords
                  .where((r) => r.status == AttendanceStatus.absent)
                  .length;
              final lateCount = courseRecords
                  .where((r) => r.status == AttendanceStatus.late)
                  .length;

              final pct = courseRecords.isEmpty
                  ? 0.0
                  : AttendanceCalculator.percentage(
                      presentDays: presentCount + lateCount,
                      totalDays: courseRecords.length,
                    );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSubmitted
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (course.courseCode.isNotEmpty)
                                Text(
                                  course.courseCode,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isSubmitted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSubmitted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                          child: Text(
                            isSubmitted
                                ? 'SUBMITTED • ${pct.toStringAsFixed(0)}%'
                                : 'PENDING',
                            style: TextStyle(
                              color: isSubmitted
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFBBF24),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Teacher and Schedule
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.teacherName.isNotEmpty
                                  ? course.teacherName
                                  : 'Assigned Teacher',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (course.schedule.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                color: Color(0xFFF59E0B),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.schedule,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    if (isSubmitted) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Roster: $presentCount Present • $absentCount Absent • $lateCount Late',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(
                            isSubmitted ? Icons.visibility : Icons.edit_note,
                            size: 14,
                          ),
                          label: Text(
                            isSubmitted
                                ? 'View Roster'
                                : 'Admin Override / Mark',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSubmitted
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFFF59E0B),
                            side: BorderSide(
                              color: (isSubmitted
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.4),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _showCourseLedgerModal(
                            context,
                            academyId,
                            course,
                            allStudents,
                            recordsList,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error loading courses: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildGeneralRosterView({
    required String academyId,
    required AsyncValue<List<Student>> students,
    required AsyncValue<List<AttendanceRecord>> records,
    required List<Branch> branches,
    required String? selectedBranchId,
  }) {
    return AsyncListState(
      value: students,
      emptyTitle: 'No students',
      emptyMessage: 'Admit students before marking attendance.',
      onRetry: () => ref.invalidate(studentsStreamProvider),
      builder: (items) {
        final filtered = selectedBranchId == null
            ? items
            : items.where((s) => s.branchId == selectedBranchId).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No students match the selected branch.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final byStudent = <String, AttendanceStatus>{
          for (final record in records.value ?? <AttendanceRecord>[])
            record.studentId: record.status,
        };

        int presentCount = 0;
        int absentCount = 0;
        int leaveCount = 0;
        for (final s in filtered) {
          final status = byStudent[s.id] ?? AttendanceStatus.present;
          if (status == AttendanceStatus.present) presentCount++;
          if (status == AttendanceStatus.absent) absentCount++;
          if (status == AttendanceStatus.leave) leaveCount++;
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: filtered.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? 10 : 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Row(
                children: [
                  _StatBadge(
                    label: 'Present',
                    count: presentCount,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Absent',
                    count: absentCount,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Leave',
                    count: leaveCount,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: 'Total',
                    count: filtered.length,
                    color: const Color(0xFF38BDF8),
                  ),
                ],
              );
            }

            final student = filtered[index - 1];
            final current = byStudent[student.id] ?? AttendanceStatus.present;
            final branch =
                branches.where((b) => b.id == student.branchId).firstOrNull;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              const Color(0xFF6366F1).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFF818CF8),
                          child: Text(
                            student.fullName.isNotEmpty
                                ? student.fullName.substring(0, 1).toUpperCase()
                                : 'S',
                            style: const TextStyle(
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Roll #${student.rollNumber}${branch != null ? " • ${branch.name}" : ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(status: current),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final s in AttendanceStatus.values)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: _StatusButton(
                                status: s,
                                isSelected: current == s,
                                onTap: () => _mark(academyId, student.id, s),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusToggleButton extends StatelessWidget {
  const _StatusToggleButton({
    required this.status,
    required this.isSelected,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final AttendanceStatus status;
  final bool isSelected;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withValues(alpha: 0.3),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.4),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AttendanceStatus.present => (const Color(0xFF10B981), 'Present'),
      AttendanceStatus.absent => (Colors.redAccent, 'Absent'),
      AttendanceStatus.late => (Colors.orangeAccent, 'Late'),
      AttendanceStatus.leave => (Colors.amber, 'Leave'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final AttendanceStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      AttendanceStatus.present => (const Color(0xFF10B981), 'Present'),
      AttendanceStatus.absent => (Colors.redAccent, 'Absent'),
      AttendanceStatus.late => (Colors.orangeAccent, 'Late'),
      AttendanceStatus.leave => (Colors.amber, 'Leave'),
    };

    return SizedBox(
      height: 32,
      child: isSelected
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
