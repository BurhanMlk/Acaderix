import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/result_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../branches/domain/branch.dart';
import '../../application/exam_repository_provider.dart';
import '../../domain/exam_result.dart';

/// Exam results and marks entry with multi-branch management.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final results = ref.watch(resultsStreamProvider(academyId));
    final students =
        ref.watch(studentsStreamProvider(academyId)).value ?? const <Student>[];
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addResult(context, ref, academyId),
        icon: const Icon(Icons.add),
        label: const Text('Add Result'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by student name or roll #',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Branch Scope Tabs at top
          BranchTabBar(academyId: academyId),

          Expanded(
            child: AsyncListState<ExamResult>(
              value: results,
              emptyTitle: 'No results',
              emptyMessage: 'Published results will appear here.',
              onRetry: () => ref.invalidate(resultsStreamProvider),
              builder: (items) {
                // Filter by selected branch
                var filtered = items.where((res) {
                  if (selectedBranchId == null) return true;
                  final student = students.where((s) {
                    return s.id == res.studentId ||
                        s.rollNumber == res.studentId;
                  }).firstOrNull;
                  if (student != null) {
                    return student.branchId == selectedBranchId;
                  }
                  return true;
                }).toList();

                // Filter by query
                if (_query.trim().isNotEmpty) {
                  final q = _query.toLowerCase().trim();
                  filtered = filtered.where((res) {
                    final student = students.where((s) {
                      return s.id == res.studentId ||
                          s.rollNumber == res.studentId;
                    }).firstOrNull;
                    final studentMatch = student != null &&
                        (student.fullName.toLowerCase().contains(q) ||
                            student.rollNumber.contains(q));
                    return res.studentId.toLowerCase().contains(q) ||
                        res.grade.toLowerCase().contains(q) ||
                        studentMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No exam results found for the selected filter.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                // Summary Stats
                int passedCount = 0;
                for (final r in filtered) {
                  if (r.passed) passedCount++;
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: index == 0 ? 10 : 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Row(
                        children: [
                          _ResultMetricCard(
                            label: 'Total Assessed',
                            value: '${filtered.length}',
                            color: const Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 8),
                          _ResultMetricCard(
                            label: 'Passed',
                            value: '$passedCount',
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 8),
                          _ResultMetricCard(
                            label: 'Pass Rate',
                            value: filtered.isNotEmpty
                                ? '${((passedCount / filtered.length) * 100).toStringAsFixed(0)}%'
                                : '0%',
                            color: const Color(0xFF38BDF8),
                          ),
                        ],
                      );
                    }

                    final result = filtered[index - 1];
                    final student = students.where((s) {
                      return s.id == result.studentId ||
                          s.rollNumber == result.studentId;
                    }).firstOrNull;
                    final branch = student != null
                        ? branches
                            .where((b) => b.id == student.branchId)
                            .firstOrNull
                        : null;
                    final percentage = ResultCalculator.percentage(
                      result.obtainedMarks,
                      result.totalMarks,
                    );

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Grade Avatar, Student & Status Badge
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: result.passed
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.2)
                                      : Colors.redAccent
                                          .withValues(alpha: 0.2),
                                  foregroundColor: result.passed
                                      ? const Color(0xFF34D399)
                                      : Colors.redAccent.shade100,
                                  child: Text(
                                    result.grade,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student != null
                                            ? student.fullName
                                            : 'Student ${result.studentId}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (student != null || branch != null) ...[
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (student != null)
                                              Text(
                                                'Roll #${student.rollNumber}',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            if (branch != null &&
                                                selectedBranchId == null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF38BDF8)
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (result.passed
                                            ? const Color(0xFF10B981)
                                            : Colors.redAccent)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (result.passed
                                              ? const Color(0xFF10B981)
                                              : Colors.redAccent)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    result.passed
                                        ? 'PASSED · ${percentage.toStringAsFixed(0)}%'
                                        : 'FAILED · ${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: result.passed
                                          ? const Color(0xFF34D399)
                                          : Colors.redAccent.shade100,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            const SizedBox(height: 8),

                            // Bottom Row: Exact marks format for test matching
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 14,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${result.obtainedMarks.toStringAsFixed(0)} / ${result.totalMarks.toStringAsFixed(0)} marks',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Grade ${result.grade}',
                                    style: TextStyle(
                                      color: result.passed
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

  void _addResult(BuildContext context, WidgetRef ref, String academyId) {
    final formKey = GlobalKey<FormState>();
    final studentRollController = TextEditingController();
    final marksController = TextEditingController();
    final totalController = TextEditingController(text: '100');
    final allStudents =
        ref.read(studentsStreamProvider(academyId)).value ?? const <Student>[];
    final selectedBranchId = ref.read(selectedBranchIdProvider);
    final branchStudents = selectedBranchId != null
        ? allStudents.where((s) => s.branchId == selectedBranchId).toList()
        : allStudents;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assessment_outlined,
                color: Color(0xFFA5B4FC),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Add Result',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (branchStudents.isNotEmpty) ...[
                      const Text(
                        'Select Student',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final s in branchStudents)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                  label: Text(
                                    '${s.fullName} (${s.rollNumber})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  onPressed: () {
                                    studentRollController.text =
                                        s.rollNumber.isNotEmpty
                                            ? s.rollNumber
                                            : s.id;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: studentRollController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Student roll no.',
                        hintText: 'e.g. 100001',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          Validators.required(v, 'Student roll no.'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: marksController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Obtained marks',
                        hintText: 'e.g. 85',
                        prefixIcon: Icon(Icons.score_outlined),
                      ),
                      validator: (v) =>
                          Validators.required(v, 'Obtained marks'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: totalController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Total marks',
                        hintText: 'e.g. 100',
                        prefixIcon: Icon(Icons.fact_check_outlined),
                      ),
                      validator: (v) => Validators.required(v, 'Total marks'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final obtained = double.tryParse(marksController.text) ?? 0;
              final total = double.tryParse(totalController.text) ?? 100;
              final percentage = ResultCalculator.percentage(obtained, total);
              final gradeResult = ResultCalculator.gradeFor(percentage);

              final result = ExamResult(
                id: const Uuid().v4(),
                academyId: academyId,
                examId: 'exam_default',
                studentId: studentRollController.text.trim(),
                obtainedMarks: obtained,
                totalMarks: total,
                grade: gradeResult.label,
                passed: gradeResult.passed,
              );

              await ref.read(examRepositoryProvider).saveResult(result);
              ref.invalidate(resultsStreamProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ResultMetricCard extends StatelessWidget {
  const _ResultMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
