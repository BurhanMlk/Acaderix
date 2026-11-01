import 'package:academy_management/features/academics/application/course_repository_provider.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/communication_providers.dart';
import '../../domain/inquiry.dart';

/// Opens the modal sheet allowing a student to ask their course instructor a question.
Future<void> showAskTeacherModal(
  BuildContext context, {
  String? academyId,
  String? preselectedCourseId,
  String? preselectedCourseName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AskTeacherSheet(
      academyId: academyId,
      preselectedCourseId: preselectedCourseId,
      preselectedCourseName: preselectedCourseName,
    ),
  );
}

class _AskTeacherSheet extends ConsumerStatefulWidget {
  const _AskTeacherSheet({
    this.academyId,
    this.preselectedCourseId,
    this.preselectedCourseName,
  });

  final String? academyId;
  final String? preselectedCourseId;
  final String? preselectedCourseName;

  @override
  ConsumerState<_AskTeacherSheet> createState() => _AskTeacherSheetState();
}

class _AskTeacherSheetState extends ConsumerState<_AskTeacherSheet> {
  final _subjectController = TextEditingController();
  final _questionController = TextEditingController();

  Course? _selectedCourse;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProfileProvider);
    final studentCourses = ref.watch(currentStudentCoursesProvider);
    final academyId = (widget.academyId?.isNotEmpty == true)
        ? widget.academyId!
        : (student?.academyId ?? '');
    final streamCourses = academyId.isNotEmpty
        ? ref.watch(coursesStreamProvider(academyId)).value ?? []
        : <Course>[];
    final courses =
        studentCourses.isNotEmpty ? studentCourses : streamCourses;

    if (_selectedCourse == null) {
      if (widget.preselectedCourseId != null) {
        _selectedCourse = courses
            .where((c) => c.id == widget.preselectedCourseId)
            .firstOrNull;
      }
      if (_selectedCourse == null && courses.isNotEmpty) {
        _selectedCourse = courses.first;
      }
    }

    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ask Teacher a Question',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Course & Teacher Selector
                const Text(
                  'Select Enrolled Subject / Course',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (courses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No enrolled courses available to query.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Course>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        value: _selectedCourse,
                        items: courses.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCourse = val);
                        },
                      ),
                    ),
                  ),

                if (_selectedCourse != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_pin_outlined,
                          size: 16,
                          color: Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Instructor: ${_selectedCourse!.teacherName.isNotEmpty ? _selectedCourse!.teacherName : "Course Faculty Member"}',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Question Topic / Subject
                const Text(
                  'Question Subject / Topic',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _subjectController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Help understanding Chapter 4 formula derivation',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 14),

                // Question Details Area
                const Text(
                  'Detailed Question',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _questionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Write your question clearly so the teacher can guide you with step-by-step concepts or recommendations...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting Question...'
                          : 'Send Question to Teacher',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitInquiry(student),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInquiry(dynamic student) async {
    final subject = _subjectController.text.trim();
    final question = _questionController.text.trim();

    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course to ask your teacher.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (subject.isEmpty || question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both subject and your question.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authControllerProvider);
      final user = switch (auth) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      };

      final academyId = (widget.academyId?.isNotEmpty == true)
          ? widget.academyId!
          : (_selectedCourse!.academyId.isNotEmpty
              ? _selectedCourse!.academyId
              : (student?.academyId.isNotEmpty == true
                  ? student!.academyId
                  : (user?.academyId ?? '')));

      final studentId = (student?.id.isNotEmpty == true)
          ? student!.id
          : (user?.id.isNotEmpty == true
              ? user!.id
              : 'std_current');
      final studentName = (student?.fullName.isNotEmpty == true)
          ? student!.fullName
          : (user?.displayName.isNotEmpty == true
              ? user!.displayName
              : 'Enrolled Student');
      final rollNumber = (student?.rollNumber.isNotEmpty == true)
          ? student!.rollNumber
          : (user?.rollNumber ?? '');

      if (academyId.isEmpty) {
        throw Exception('No active academy profile found to submit question.');
      }

      final inquiry = StudentInquiry(
        id: '',
        academyId: academyId,
        courseId: _selectedCourse!.id,
        courseName: _selectedCourse!.name,
        studentId: studentId,
        studentName: studentName,
        studentRollNumber: rollNumber,
        teacherId: _selectedCourse!.teacherId,
        teacherName: _selectedCourse!.teacherName.isNotEmpty
            ? _selectedCourse!.teacherName
            : 'Course Faculty',
        subject: subject,
        question: question,
        createdAt: DateTime.now(),
      );

      await ref.read(communicationRepositoryProvider).submitInquiry(inquiry);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Question sent to your instructor! You will receive a notification when answered.',
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit question: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
