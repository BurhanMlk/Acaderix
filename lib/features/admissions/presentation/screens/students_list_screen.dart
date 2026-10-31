import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../application/student_repository_provider.dart';
import '../../domain/student.dart';

/// List of students for an academy with search, branch tabs, and full CRUD management.
class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _query = '';

  Future<void> _deleteStudent(String academyId, Student student) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Student',
      message:
          'Delete student "${student.fullName}" (Roll #${student.rollNumber})? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(studentRepositoryProvider).delete(academyId, student.id);
      ref.invalidate(studentsStreamProvider(academyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student "${student.fullName}" deleted.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete student: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Student> _filter(List<Student> students, String? branchId) {
    var result = students;
    if (branchId != null && branchId.isNotEmpty) {
      result = result.where((s) => s.branchId == branchId).toList();
    }
    if (_query.trim().isEmpty) return result;
    final q = _query.toLowerCase().trim();
    return result.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.rollNumber.contains(q) ||
          s.guardianPhone.contains(q) ||
          s.notes.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final students = ref.watch(studentsStreamProvider(academyId));
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addStudent),
        icon: const Icon(Icons.person_add),
        label: const Text('Admit Student'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or roll number',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Branch Scope Tabs Bar
          BranchTabBar(academyId: academyId),

          Expanded(
            child: AsyncListState<Student>(
              value: students,
              emptyTitle: 'No students',
              emptyMessage: 'Admit students to begin managing records.',
              onRetry: () => ref.invalidate(studentsStreamProvider),
              builder: (items) {
                final filtered = _filter(items, selectedBranchId);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No students match search or branch filter.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final branch = branches
                        .where((b) => b.id == student.branchId)
                        .firstOrNull;

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(
                          AppRoutes.editStudent,
                          extra: student,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.2),
                                foregroundColor: const Color(0xFF818CF8),
                                child: Text(
                                  student.fullName.isNotEmpty
                                      ? student.fullName
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name (Never Truncated) & Campus Badge
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          student.fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (branch != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF38BDF8)
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              branch.name,
                                              style: const TextStyle(
                                                color: Color(0xFF38BDF8),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // Roll Number & Academic Notes (Wrap prevents any overflow)
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Roll #${student.rollNumber}',
                                            style: const TextStyle(
                                              color: Color(0xFFA5B4FC),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (student.notes.isNotEmpty)
                                          Text(
                                            student.notes,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // Guardian Contact info
                                    if (student.guardianPhone.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.phone_outlined,
                                            size: 13,
                                            color: Colors.white54,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${student.guardianRelation.isNotEmpty ? '${student.guardianRelation}: ' : ''}${student.guardianPhone}',
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              // Popup Menu Actions
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white60,
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    context.push(
                                      AppRoutes.editStudent,
                                      extra: student,
                                    );
                                  } else if (val == 'delete') {
                                    _deleteStudent(academyId, student);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Student',
                                          style:
                                              TextStyle(color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
