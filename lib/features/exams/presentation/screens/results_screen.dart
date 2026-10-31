import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/result_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/exam_repository_provider.dart';
import '../../domain/exam_result.dart';

/// Exam results and marks entry.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final results = ref.watch(resultsStreamProvider(academyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addResult(context, ref, academyId),
        icon: const Icon(Icons.add),
        label: const Text('Add Result'),
      ),
      body: AsyncListState<ExamResult>(
        value: results,
        emptyTitle: 'No results',
        emptyMessage: 'Published results will appear here.',
        onRetry: () => ref.invalidate(resultsStreamProvider),
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final result = items[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(result.grade)),
                title: Text('Student ${result.studentId}'),
                subtitle: Text(
                  '${result.obtainedMarks.toStringAsFixed(0)} / '
                  '${result.totalMarks.toStringAsFixed(0)} marks',
                ),
                trailing: Icon(
                  result.passed
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: result.passed ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addResult(
    BuildContext context,
    WidgetRef ref,
    String academyId,
  ) async {
    final result = await showDialog<ExamResult>(
      context: context,
      builder: (context) => _AddResultDialog(academyId: academyId),
    );

    if (result != null) {
      await ref.read(examRepositoryProvider).saveResult(result);
      ref.invalidate(resultsStreamProvider);
    }
  }
}

class _AddResultDialog extends StatefulWidget {
  const _AddResultDialog({required this.academyId});

  final String academyId;

  @override
  State<_AddResultDialog> createState() => _AddResultDialogState();
}

class _AddResultDialogState extends State<_AddResultDialog> {
  final _studentIdController = TextEditingController();
  final _obtainedController = TextEditingController();
  final _totalController = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _studentIdController.dispose();
    _obtainedController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final obtained = double.tryParse(_obtainedController.text) ?? 0;
    final total = double.tryParse(_totalController.text) ?? 0;
    final evaluation = ResultCalculator.evaluate(obtained, total);

    Navigator.of(context).pop(
      ExamResult(
        id: const Uuid().v4(),
        academyId: widget.academyId,
        examId: '',
        studentId: _studentIdController.text.trim(),
        obtainedMarks: obtained,
        totalMarks: total,
        grade: evaluation.label,
        passed: evaluation.passed,
        isPublished: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Result'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student roll no.',
              ),
              validator: (v) => Validators.required(v, 'Roll no.'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _obtainedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Obtained marks'),
              validator: (v) => Validators.required(v, 'Obtained marks'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total marks'),
              validator: (v) => Validators.required(v, 'Total marks'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
