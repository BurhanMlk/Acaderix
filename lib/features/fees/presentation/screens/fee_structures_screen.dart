import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../academics/application/course_repository_provider.dart';
import '../../application/fee_repository_provider.dart';
import '../../domain/fee_structure.dart';

/// Manage reusable fee structure templates for bulk invoice generation.
class FeeStructuresScreen extends ConsumerWidget {
  const FeeStructuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final structures = ref.watch(feeStructuresStreamProvider(academyId));

    return PageScaffold(
      title: 'Fee structures',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStructureDialog(context, ref, academyId),
        icon: const Icon(Icons.add),
        label: const Text('Add structure'),
      ),
      child: AsyncListState<FeeStructure>(
        value: structures,
        emptyTitle: 'No fee structures',
        emptyMessage:
            'Create a fee template to start generating invoices in bulk.',
        onRetry: () => ref.invalidate(feeStructuresStreamProvider),
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = items[index];
            return _StructureCard(
              structure: s,
              onEdit: () =>
                  _showStructureDialog(context, ref, academyId, existing: s),
              onDelete: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Delete structure',
                  message:
                      'Delete "${s.title}"? Existing invoices are not affected.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (confirmed) {
                  await ref
                      .read(feeRepositoryProvider)
                      .deleteFeeStructure(academyId, s.id);
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _showStructureDialog(
    BuildContext context,
    WidgetRef ref,
    String academyId, {
    FeeStructure? existing,
  }) {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(
      text: existing?.amount.toStringAsFixed(0) ?? '',
    );
    final dueDayCtrl = TextEditingController(
      text: (existing?.dueDayOfMonth ?? 15).toString(),
    );
    final fineCtrl = TextEditingController(
      text: (existing?.lateFinePerDay ?? 0).toStringAsFixed(0),
    );
    final maxFineCtrl = TextEditingController(
      text: (existing?.lateFineMax ?? 500).toStringAsFixed(0),
    );

    String frequency = existing?.frequency ?? 'monthly';
    String branchId = existing?.branchId ?? '';
    String courseId = existing?.courseId ?? '';

    final branches =
        ref.read(branchesStreamProvider(academyId)).value ?? const [];
    final courses =
        ref.read(coursesStreamProvider(academyId)).value ?? const [];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            isEdit ? 'Edit fee structure' : 'New fee structure',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g. Monthly Tuition Fee',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (v) => Validators.required(v, 'Title'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Amount (PKR) *',
                          hintText: 'e.g. 8000',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          if ((double.tryParse(v) ?? 0) <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: frequency,
                        dropdownColor: Colors.white,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                          DropdownMenuItem(
                            value: 'quarterly',
                            child: Text('Quarterly'),
                          ),
                          DropdownMenuItem(
                            value: 'annual',
                            child: Text('Annual'),
                          ),
                          DropdownMenuItem(
                            value: 'one-time',
                            child: Text('One time'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => frequency = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dueDayCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Due day of month (1-28)',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '') ?? 0;
                          if (n < 1 || n > 28) return 'Enter 1 to 28';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fineCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Late fine/day',
                                prefixIcon: Icon(Icons.warning_amber_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: maxFineCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max fine',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (branches.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: branchId.isEmpty ? null : branchId,
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Branch (optional)',
                            prefixIcon: Icon(Icons.domain_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All branches'),
                            ),
                            ...branches.map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => branchId = v ?? ''),
                        ),
                      ],
                      if (courses.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: courseId.isEmpty ? null : courseId,
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Course (optional)',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All courses'),
                            ),
                            ...courses.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => courseId = v ?? ''),
                        ),
                      ],
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
                final structure = FeeStructure(
                  id: existing?.id ?? const Uuid().v4(),
                  academyId: academyId,
                  title: titleCtrl.text.trim(),
                  amount: double.tryParse(amountCtrl.text) ?? 0,
                  frequency: frequency,
                  dueDayOfMonth: int.tryParse(dueDayCtrl.text) ?? 15,
                  lateFinePerDay: double.tryParse(fineCtrl.text) ?? 0,
                  lateFineMax: double.tryParse(maxFineCtrl.text) ?? 500,
                  branchId: branchId,
                  courseId: courseId,
                  isActive: existing?.isActive ?? true,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                await ref
                    .read(feeRepositoryProvider)
                    .saveFeeStructure(structure);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StructureCard extends StatelessWidget {
  const _StructureCard({
    required this.structure,
    required this.onEdit,
    required this.onDelete,
  });

  final FeeStructure structure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final freq = switch (structure.frequency) {
      'monthly' => 'Monthly',
      'quarterly' => 'Quarterly',
      'annual' => 'Annual',
      'one-time' => 'One time',
      _ => structure.frequency,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    structure.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    freq,
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.pkr(structure.amount),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _infoChip(
                  Icons.calendar_today_outlined,
                  'Due on the ${structure.dueDayOfMonth}th',
                ),
                if (structure.lateFinePerDay > 0)
                  _infoChip(
                    Icons.warning_amber_outlined,
                    'Rs. ${structure.lateFinePerDay.toStringAsFixed(0)}/day late fine',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!structure.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: const Color(0xFF6B7280),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: const Color(0xFFDC2626),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    );
  }
}
