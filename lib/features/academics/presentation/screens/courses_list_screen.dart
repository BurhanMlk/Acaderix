import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../application/course_repository_provider.dart';
import '../../domain/course.dart';

/// Screen listing all courses/batches for the academy admin, with branch filtering,
/// teacher assignment display, and student enrollment controls.
class CoursesListScreen extends ConsumerStatefulWidget {
  const CoursesListScreen({super.key});

  @override
  ConsumerState<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends ConsumerState<CoursesListScreen> {
  String _query = '';

  Future<void> _showEnrollmentDialog(
    BuildContext context,
    String academyId,
    Course course,
    List<Student> allStudents,
  ) async {
    final branchStudents = course.branchId.isEmpty
        ? allStudents
        : allStudents.where((s) => s.branchId == course.branchId).toList();
    final candidateStudents =
        branchStudents.isNotEmpty ? branchStudents : allStudents;

    final selectedIds = Set<String>.from(course.enrolledStudentIds);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.group_add, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enroll Students • ${course.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: candidateStudents.isEmpty
                ? const Center(
                    child: Text(
                      'No students found in this branch.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: candidateStudents.length,
                    itemBuilder: (context, index) {
                      final s = candidateStudents[index];
                      final isEnrolled = selectedIds.contains(s.id);

                      return CheckboxListTile(
                        value: isEnrolled,
                        activeColor: const Color(0xFF38BDF8),
                        checkColor: Colors.black,
                        title: Text(
                          s.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Roll #${s.rollNumber}${s.academicSession.isNotEmpty ? " • ${s.academicSession}" : ""}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedIds.add(s.id);
                            } else {
                              selectedIds.remove(s.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
              ),
              onPressed: () async {
                final updated = course.copyWith(
                  enrolledStudentIds: selectedIds.toList(),
                );
                await ref.read(courseRepositoryProvider).saveCourse(updated);
                ref.invalidate(coursesStreamProvider(academyId));
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Enrolled ${selectedIds.length} students into ${course.name}',
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('Save (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final coursesAsync = ref.watch(coursesStreamProvider(academyId));
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
        onPressed: () => context.push(AppRoutes.addCourse),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branch Scope Tabs
          BranchTabBar(academyId: academyId),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search courses by name, code, or teacher...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),

          // Courses List
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                var filtered = courses;
                if (selectedBranchId != null) {
                  filtered =
                      filtered.where((c) => c.branchId == selectedBranchId).toList();
                }
                if (_query.isNotEmpty) {
                  filtered = filtered.where((c) {
                    final matchName = c.name.toLowerCase().contains(_query);
                    final matchCode =
                        c.courseCode.toLowerCase().contains(_query);
                    final matchTeacher =
                        c.teacherName.toLowerCase().contains(_query);
                    return matchName || matchCode || matchTeacher;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No Courses Found',
                    message: _query.isNotEmpty
                        ? 'No courses match "$_query".'
                        : 'No courses registered for this campus. Tap "Add Course" to create one.',
                    icon: Icons.menu_book_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final course = filtered[index];
                    return _CourseCard(
                      course: course,
                      onEnroll: () async {
                        final allStudents = await ref
                            .read(studentsStreamProvider(academyId).future);
                        if (context.mounted) {
                          _showEnrollmentDialog(
                            context,
                            academyId,
                            course,
                            allStudents,
                          );
                        }
                      },
                      onEdit: () => context.push(
                        AppRoutes.editCourse,
                        extra: course,
                      ),
                      onDelete: () async {
                        final confirmed = await showConfirmationDialog(
                          context,
                          title: 'Delete Course',
                          message:
                              'Are you sure you want to delete "${course.name}"? Enrolled students will not be deleted.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (confirmed == true) {
                          await ref
                              .read(courseRepositoryProvider)
                              .deleteCourse(academyId, course.id);
                          ref.invalidate(coursesStreamProvider(academyId));
                        }
                      },
                    );
                  },
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onEnroll,
    required this.onEdit,
    required this.onDelete,
  });

  final Course course;
  final VoidCallback onEnroll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
              // Enrolled Count Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${course.enrolledStudentIds.length} Enrolled',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Teacher & Schedule Wrap
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (course.teacherName.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.teacherName,
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
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 8),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.group_add, size: 14),
                label: const Text('Enroll Students'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onEnroll,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit Course',
                icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete Course',
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent.shade100,
                  size: 18,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
