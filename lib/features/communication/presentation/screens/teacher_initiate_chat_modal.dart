import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../academics/application/course_repository_provider.dart';
import '../../../academics/domain/course.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../staff/application/staff_providers.dart';
import '../../../staff/domain/staff.dart';
import '../../../student/application/student_providers.dart';
import '../../application/communication_providers.dart';
import 'academic_chat_screen.dart';

/// Opens a fast contact picker allowing a teacher to initiate a direct 1-to-1 chat with any student.
/// If [preselectedStudent] is already provided, immediately opens [AcademicChatScreen] without any intermediate form.
Future<void> showTeacherInitiateChatModal(
  BuildContext context, {
  required String academyId,
  Student? preselectedStudent,
}) async {
  if (preselectedStudent != null) {
    // Direct transition without any modal
    final container = ProviderScope.containerOf(context);
    final staff = container.read(currentStaffMemberProvider);
    final teacherId = staff?.id.isNotEmpty == true
        ? staff!.id
        : (staff?.staffId ?? 'faculty');
    final teacherName =
        staff?.fullName.isNotEmpty == true ? staff!.fullName : 'Faculty Teacher';
    final teacherStaffId = staff?.staffId ?? '';

    try {
      final repo = container.read(communicationRepositoryProvider);
      final conversation = await repo.getOrCreateConversation(
        academyId: academyId.isNotEmpty ? academyId : preselectedStudent.academyId,
        teacherId: teacherId,
        teacherName: teacherName,
        teacherStaffId: teacherStaffId,
        studentId: preselectedStudent.id,
        studentName: preselectedStudent.fullName,
        studentRollNumber: preselectedStudent.rollNumber,
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AcademicChatScreen(
              academyId: conversation.academyId,
              conversationId: conversation.id,
              otherPartyName: preselectedStudent.fullName,
              otherPartySubtitle: 'Roll #${preselectedStudent.rollNumber}',
              otherPartyRole: 'student',
              recipientId: preselectedStudent.id,
              recipientRole: 'student',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FastStudentPickerSheet(academyId: academyId),
  );
}

/// Fast student contact picker for teachers to directly initiate a WhatsApp-style chat.
class FastStudentPickerSheet extends ConsumerStatefulWidget {
  const FastStudentPickerSheet({
    super.key,
    required this.academyId,
  });

  final String academyId;

  @override
  ConsumerState<FastStudentPickerSheet> createState() =>
      _FastStudentPickerSheetState();
}

class _FastStudentPickerSheetState
    extends ConsumerState<FastStudentPickerSheet> {
  final _searchController = TextEditingController();
  bool _isNavigating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffMemberProvider);
    final allStudents =
        ref.watch(studentsStreamProvider(widget.academyId)).value ??
            const <Student>[];
    final branchStudents = ref.watch(staffBranchStudentsProvider);
    final candidates =
        branchStudents.isNotEmpty ? branchStudents : allStudents;

    final query = _searchController.text.trim().toLowerCase();
    final filteredCandidates = query.isEmpty
        ? candidates
        : candidates.where((s) {
            return s.fullName.toLowerCase().contains(query) ||
                s.rollNumber.toLowerCase().contains(query);
          }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF38BDF8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Direct Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select any student to open a 1-to-1 real-time conversation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search student by name or roll number...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF38BDF8), size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white38, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
          ),

          // Student List
          Expanded(
            child: _isNavigating
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  )
                : filteredCandidates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_outlined,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 8),
                              const Text(
                                'No matching students found',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredCandidates.length,
                        separatorBuilder: (_, _) => const Divider(
                            color: Color(0xFF1E293B), height: 1),
                        itemBuilder: (ctx, i) {
                          final s = filteredCandidates[i];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.2),
                                child: Text(
                                  s.fullName.isNotEmpty
                                      ? s.fullName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                s.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Roll #${s.rollNumber}${s.notes.isNotEmpty ? " • ${s.notes}" : ""}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFF38BDF8),
                                  size: 16,
                                ),
                              ),
                              onTap: () => _openChatWithStudent(s, staff),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithStudent(Student student, dynamic staff) async {
    setState(() => _isNavigating = true);

    try {
      final teacherId = staff?.id?.isNotEmpty == true
          ? staff.id
          : (staff?.staffId ?? 'faculty');
      final teacherName = staff?.fullName?.isNotEmpty == true
          ? staff.fullName
          : 'Faculty Teacher';
      final teacherStaffId = staff?.staffId ?? '';

      final repo = ref.read(communicationRepositoryProvider);
      final conversation = await repo.getOrCreateConversation(
        academyId: widget.academyId.isNotEmpty
            ? widget.academyId
            : student.academyId,
        teacherId: teacherId,
        teacherName: teacherName,
        teacherStaffId: teacherStaffId,
        studentId: student.id,
        studentName: student.fullName,
        studentRollNumber: student.rollNumber,
      );

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AcademicChatScreen(
              academyId: conversation.academyId,
              conversationId: conversation.id,
              otherPartyName: student.fullName,
              otherPartySubtitle: 'Roll #${student.rollNumber}',
              otherPartyRole: 'student',
              recipientId: student.id,
              recipientRole: 'student',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isNavigating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

/// Fast teacher contact picker allowing a student to initiate a direct 1-to-1 chat with an instructor.
Future<void> showStudentInitiateChatModal(
  BuildContext context, {
  required String academyId,
}) async {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FastTeacherPickerSheet(academyId: academyId),
  );
}

class FastTeacherPickerSheet extends ConsumerStatefulWidget {
  const FastTeacherPickerSheet({
    super.key,
    required this.academyId,
  });

  final String academyId;

  @override
  ConsumerState<FastTeacherPickerSheet> createState() =>
      _FastTeacherPickerSheetState();
}

class _FastTeacherPickerSheetState
    extends ConsumerState<FastTeacherPickerSheet> {
  final _searchController = TextEditingController();
  bool _isNavigating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProfileProvider);
    final studentCourses = ref.watch(currentStudentCoursesProvider);
    final streamCourses = widget.academyId.isNotEmpty
        ? ref.watch(coursesStreamProvider(widget.academyId)).value ??
            const <Course>[]
        : const <Course>[];
    final courses =
        studentCourses.isNotEmpty ? studentCourses : streamCourses;

    final allStaff =
        ref.watch(staffStreamProvider(widget.academyId)).value ??
            const <Staff>[];

    // Build teacher entries from enrolled courses + staff list
    final teacherMap = <String, ({String id, String name, String courseName})>{};
    for (final c in courses) {
      if (c.teacherId.isNotEmpty || c.teacherName.isNotEmpty) {
        final id = c.teacherId.isNotEmpty ? c.teacherId : c.teacherName;
        teacherMap[id] = (
          id: id,
          name: c.teacherName.isNotEmpty ? c.teacherName : 'Faculty Instructor',
          courseName: c.name,
        );
      }
    }
    // Also include teachers from staff list who teach or are active
    for (final s in allStaff) {
      if (s.status == 'active') {
        teacherMap.putIfAbsent(
          s.id,
          () => (
            id: s.id,
            name: s.fullName,
            courseName: s.jobTitle.isNotEmpty ? s.jobTitle : 'Instructor',
          ),
        );
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    final teachersList = teacherMap.values.where((t) {
      if (query.isEmpty) return true;
      return t.name.toLowerCase().contains(query) ||
          t.courseName.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF38BDF8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message Instructor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select an instructor to start a direct 1-to-1 conversation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search instructor by name or subject...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF38BDF8), size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white38, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
          ),

          // Teacher List
          Expanded(
            child: _isNavigating
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  )
                : teachersList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off_outlined,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 8),
                              const Text(
                                'No instructors available to chat',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: teachersList.length,
                        separatorBuilder: (_, _) => const Divider(
                            color: Color(0xFF1E293B), height: 1),
                        itemBuilder: (ctx, i) {
                          final t = teachersList[i];
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.25),
                                child: Text(
                                  t.name.isNotEmpty
                                      ? t.name[0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                t.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                t.courseName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFF38BDF8),
                                  size: 16,
                                ),
                              ),
                              onTap: () => _openChatWithTeacher(
                                teacherId: t.id,
                                teacherName: t.name,
                                courseName: t.courseName,
                                student: student,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithTeacher({
    required String teacherId,
    required String teacherName,
    required String courseName,
    required Student? student,
  }) async {
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student profile not loaded'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isNavigating = true);

    try {
      final repo = ref.read(communicationRepositoryProvider);
      final conversation = await repo.getOrCreateConversation(
        academyId: widget.academyId.isNotEmpty
            ? widget.academyId
            : student.academyId,
        teacherId: teacherId,
        teacherName: teacherName,
        studentId: student.id,
        studentName: student.fullName,
        studentRollNumber: student.rollNumber,
        courseName: courseName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AcademicChatScreen(
              academyId: conversation.academyId,
              conversationId: conversation.id,
              otherPartyName: teacherName,
              otherPartySubtitle: courseName,
              otherPartyRole: 'teacher',
              recipientId: teacherId,
              recipientRole: 'staff',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isNavigating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
