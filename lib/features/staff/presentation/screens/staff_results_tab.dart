import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/result_calculator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../exams/application/exam_repository_provider.dart';
import '../../../exams/domain/exam.dart';
import '../../../exams/domain/exam_result.dart';
import '../../application/staff_providers.dart';

/// Staff view for viewing student evaluations and recording new exam marks.
class StaffResultsTab extends ConsumerStatefulWidget {
  const StaffResultsTab({super.key});

  @override
  ConsumerState<StaffResultsTab> createState() => _StaffResultsTabState();
}

class _StaffResultsTabState extends ConsumerState<StaffResultsTab> {
  String _query = '';

  Future<void> _showAddResultDialog(
    BuildContext context,
    String academyId,
    List<Student> students,
    List<Exam> exams,
  ) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students available to assign marks to.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uniqueStudents = {for (final s in students) s.id: s}.values.toList();
    final uniqueExams = {for (final e in exams) e.id: e}.values.toList();

    final formKey = GlobalKey<FormState>();
    String selectedStudentId = uniqueStudents.first.id;
    String selectedExamId =
        uniqueExams.isNotEmpty ? uniqueExams.first.id : 'exam_general';
    final marksObtainedCtrl = TextEditingController(text: '85');
    final totalMarksCtrl = TextEditingController(text: '100');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = double.tryParse(totalMarksCtrl.text.trim()) ?? 100.0;
          final obtained =
              double.tryParse(marksObtainedCtrl.text.trim()) ?? 0.0;
          final pct = ResultCalculator.percentage(obtained, total);
          final gradeResult = ResultCalculator.gradeFor(pct);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            title: const Row(
              children: [
                Icon(Icons.post_add, color: Color(0xFF38BDF8), size: 22),
                SizedBox(width: 8),
                Text(
                  'Record Exam Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Select Student
                      const Text(
                        'Select Student',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStudentId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: uniqueStudents.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.fullName} (Roll #${s.rollNumber})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStudentId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Select / Enter Exam
                      if (uniqueExams.isNotEmpty) ...[
                        const Text(
                          'Select Exam',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedExamId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: uniqueExams.map((e) {
                            return DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.name.isNotEmpty ? e.name : 'General Exam',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedExamId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Marks Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: marksObtainedCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Obtained Marks',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null) return 'Enter number';
                                if (n < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: totalMarksCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Total Marks',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                              validator: (v) {
                                final n = double.tryParse(v ?? '');
                                if (n == null || n <= 0) return 'Enter > 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Calculation Preview
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Percentage: ${pct.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Grade: ${gradeResult.label} (${gradeResult.passed ? "Pass" : "Fail"})',
                              style: TextStyle(
                                color: gradeResult.passed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                  if (!formKey.currentState!.validate()) return;
                  final obt = double.parse(marksObtainedCtrl.text.trim());
                  final tot = double.parse(totalMarksCtrl.text.trim());
                  final p = ResultCalculator.percentage(obt, tot);
                  final g = ResultCalculator.gradeFor(p);

                  final newResult = ExamResult(
                    id: const Uuid().v4(),
                    academyId: academyId,
                    examId: selectedExamId,
                    studentId: selectedStudentId,
                    obtainedMarks: obt,
                    totalMarks: tot,
                    grade: g.label,
                    passed: g.passed,
                    isPublished: true,
                  );

                  await ref.read(examRepositoryProvider).saveResult(newResult);
                  ref.invalidate(resultsStreamProvider(academyId));
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exam result saved successfully!'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Save Result'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffMemberProvider);
    final academyId = staff?.academyId ?? '';
    final students = ref.watch(staffBranchStudentsProvider);
    final resultsAsync = ref.watch(resultsStreamProvider(academyId));
    final exams = ref.watch(examsStreamProvider(academyId)).value ?? const <Exam>[];

    final studentMap = {for (final s in students) s.id: s};
    final examMap = {for (final e in exams) e.id: e};

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.post_add),
        label: const Text('Add Result'),
        onPressed: () => _showAddResultDialog(context, academyId, students, exams),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by student name or roll #...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8), size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
          ),

          // Results List
          Expanded(
            child: resultsAsync.when(
              data: (allResults) {
                // Filter to branch students if branch is scoped
                final branchStudentIds = students.map((s) => s.id).toSet();
                final relevant = allResults.where((r) {
                  if (students.isNotEmpty && !branchStudentIds.contains(r.studentId)) {
                    return false;
                  }
                  if (_query.isEmpty) return true;
                  final s = studentMap[r.studentId];
                  final matchStudent =
                      s?.fullName.toLowerCase().contains(_query) ?? false;
                  final matchRoll = s?.rollNumber.contains(_query) ?? false;
                  final exam = examMap[r.examId];
                  final matchExam =
                      exam?.name.toLowerCase().contains(_query) ?? false;
                  return matchStudent || matchRoll || matchExam;
                }).toList();

                if (relevant.isEmpty) {
                  return const EmptyState(
                    title: 'No Exam Results',
                    message:
                        'No results match your criteria. Tap "Add Result" to record marks.',
                    icon: Icons.grade_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: relevant.length,
                  itemBuilder: (context, index) {
                    final res = relevant[index];
                    final student = studentMap[res.studentId];
                    final exam = examMap[res.examId];
                    final pct = ResultCalculator.percentage(
                      res.obtainedMarks,
                      res.totalMarks,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student?.fullName ?? 'Student (${res.studentId})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (student != null)
                                      Text(
                                        'Roll #${student.rollNumber}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Pass/Fail Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (res.passed
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: res.passed
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                child: Text(
                                  res.passed
                                      ? 'PASSED · ${pct.toStringAsFixed(0)}%'
                                      : 'FAILED · ${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: res.passed
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
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

                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                exam?.name ?? 'General Evaluation',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${res.obtainedMarks.toStringAsFixed(0)} / ${res.totalMarks.toStringAsFixed(0)} marks',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Grade ${res.grade}',
                                      style: TextStyle(
                                        color: res.passed
                                            ? const Color(0xFF34D399)
                                            : Colors.redAccent.shade100,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
              ),
              error: (err, _) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(resultsStreamProvider(academyId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
