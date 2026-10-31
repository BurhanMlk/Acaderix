import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/fee_calculator.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../admissions/domain/student.dart';
import '../../../branches/domain/branch.dart';
import '../../application/fee_repository_provider.dart';
import '../../domain/fee_invoice.dart';
import '../../domain/fee_payment.dart';

/// Fee invoices and payment collection with multi-branch management.
class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final invoices = ref.watch(invoicesStreamProvider(academyId));
    final students =
        ref.watch(studentsStreamProvider(academyId)).value ?? const <Student>[];
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvoiceDialog(
          context,
          ref,
          academyId,
          students,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Issue Invoice'),
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
                hintText: 'Search by invoice # or title',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Branch Scope Tabs at top
          BranchTabBar(academyId: academyId),

          Expanded(
            child: AsyncListState<FeeInvoice>(
              value: invoices,
              emptyTitle: 'No invoices',
              emptyMessage:
                  'Generate fee invoices to start collecting payments.',
              onRetry: () => ref.invalidate(invoicesStreamProvider),
              builder: (items) {
                // Filter by branch
                var filtered = items.where((inv) {
                  if (selectedBranchId == null) return true;
                  final student = students
                      .where((s) => s.id == inv.studentId)
                      .firstOrNull;
                  if (student != null) {
                    return student.branchId == selectedBranchId;
                  }
                  return true;
                }).toList();

                // Filter by search query
                if (_query.trim().isNotEmpty) {
                  final q = _query.toLowerCase().trim();
                  filtered = filtered.where((inv) {
                    final student = students
                        .where((s) => s.id == inv.studentId)
                        .firstOrNull;
                    final studentMatch = student != null &&
                        (student.fullName.toLowerCase().contains(q) ||
                            student.rollNumber.contains(q));
                    return inv.invoiceNo.toLowerCase().contains(q) ||
                        inv.title.toLowerCase().contains(q) ||
                        studentMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No fee invoices match the filter.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                // Financial metrics
                double totalBilled = 0;
                double totalPaid = 0;
                for (final inv in filtered) {
                  totalBilled += inv.totalAmount;
                  totalPaid += inv.paidAmount;
                }
                final totalOutstanding = totalBilled - totalPaid;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: index == 0 ? 10 : 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Financial Summary Header Cards
                      return Row(
                        children: [
                          _FeeStatCard(
                            label: 'Total Billed',
                            amount: totalBilled,
                            color: const Color(0xFF818CF8),
                          ),
                          const SizedBox(width: 8),
                          _FeeStatCard(
                            label: 'Collected',
                            amount: totalPaid,
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 8),
                          _FeeStatCard(
                            label: 'Pending',
                            amount: totalOutstanding > 0 ? totalOutstanding : 0,
                            color: totalOutstanding > 0
                                ? Colors.amber
                                : Colors.white60,
                          ),
                        ],
                      );
                    }

                    final invoice = filtered[index - 1];
                    final outstanding = FeeCalculator.outstanding(
                      invoice.totalAmount,
                      invoice.paidAmount,
                    );
                    final student = students
                        .where((s) => s.id == invoice.studentId)
                        .firstOrNull;
                    final branch = student != null
                        ? branches
                            .where((b) => b.id == student.branchId)
                            .firstOrNull
                        : null;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Title & Status Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.title.isNotEmpty
                                            ? invoice.title
                                            : invoice.invoiceNo,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        invoice.invoiceNo,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(
                                  status: invoice.status,
                                  outstanding: outstanding,
                                ),
                              ],
                            ),

                            // Student & Branch Row (Wrap avoids overflow)
                            if (student != null || branch != null) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (student != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 13,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${student.fullName} (Roll #${student.rollNumber})',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (branch != null &&
                                      selectedBranchId == null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
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

                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            const SizedBox(height: 8),

                            // Footer: Amounts & Action Button
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total: ${CurrencyFormatter.pkr(invoice.totalAmount)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Paid: ${CurrencyFormatter.pkr(invoice.paidAmount)}'
                                        '${outstanding > 0 ? ' · Due: ${CurrencyFormatter.pkr(outstanding)}' : ''}',
                                        style: TextStyle(
                                          color: outstanding > 0
                                              ? Colors.amber.shade200
                                              : const Color(0xFF34D399),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (outstanding > 0)
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: () => _collectPayment(
                                      context,
                                      ref,
                                      academyId,
                                      invoice,
                                      outstanding,
                                    ),
                                    child: const Text('Collect'),
                                  )
                                else
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF34D399),
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Settled',
                                        style: TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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

  void _collectPayment(
    BuildContext context,
    WidgetRef ref,
    String academyId,
    FeeInvoice invoice,
    double outstanding,
  ) {
    final controller = TextEditingController(
      text: outstanding.toStringAsFixed(0),
    );
    final student = ref
        .read(studentsStreamProvider(academyId))
        .value
        ?.where((s) => s.id == invoice.studentId)
        .firstOrNull;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Color(0xFF34D399),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Collect Payment',
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invoice Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invoice.invoiceNo,
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Due: ${CurrencyFormatter.pkr(outstanding)}',
                                style: TextStyle(
                                  color: Colors.amber.shade200,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (student != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Student: ${student.fullName} (${student.rollNumber})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Amount (PKR)',
                      prefixIcon:
                          const Icon(Icons.currency_exchange_outlined),
                      helperText:
                          'Max ${CurrencyFormatter.pkr(outstanding)}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            const Color(0xFF6366F1).withValues(alpha: 0.2),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        label: Text(
                          'Full: ${CurrencyFormatter.pkr(outstanding)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        onPressed: () {
                          controller.text =
                              outstanding.toStringAsFixed(0);
                        },
                      ),
                      if (outstanding >= 2000)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          label: Text(
                            'Half: ${CurrencyFormatter.pkr(outstanding / 2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          onPressed: () {
                            controller.text =
                                (outstanding / 2).toStringAsFixed(0);
                          },
                        ),
                    ],
                  ),
                ],
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
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > outstanding) return;

              final payment = FeePayment(
                id: const Uuid().v4(),
                academyId: academyId,
                invoiceId: invoice.id,
                studentId: invoice.studentId,
                amount: amount,
                paidAt: DateTime.now(),
                method: 'cash',
              );

              await ref.read(feeRepositoryProvider).recordPayment(payment);
              ref.invalidate(invoicesStreamProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showCreateInvoiceDialog(
    BuildContext context,
    WidgetRef ref,
    String academyId,
    List<Student> students,
  ) {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please admit students first before issuing invoices.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: 'Monthly Tuition Fee');
    final amountController = TextEditingController(text: '8000');
    final selectedBranchId = ref.read(selectedBranchIdProvider);
    final eligibleStudents = selectedBranchId != null
        ? students.where((s) => s.branchId == selectedBranchId).toList()
        : students;
    final targetStudents =
        eligibleStudents.isNotEmpty ? eligibleStudents : students;
    String selectedStudentId = targetStudents.first.id;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFFA5B4FC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Issue Invoice',
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
                      DropdownButtonFormField<String>(
                        initialValue: selectedStudentId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: const InputDecoration(
                          labelText: 'Select Student',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        selectedItemBuilder: (context) => targetStudents
                            .map(
                              (s) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${s.fullName} (${s.rollNumber})',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        items: targetStudents
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.fullName} (${s.rollNumber})',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStudentId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Title',
                          hintText: 'e.g. Tuition Fee - November',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) =>
                            Validators.required(v, 'Invoice title'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Amount (PKR)',
                          hintText: 'e.g. 8000',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final parsed = double.tryParse(v);
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
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
                final amount =
                    double.tryParse(amountController.text) ?? 0;
                final invoiceNo =
                    'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                final newInvoice = FeeInvoice(
                  id: const Uuid().v4(),
                  academyId: academyId,
                  studentId: selectedStudentId,
                  invoiceNo: invoiceNo,
                  title: titleController.text.trim(),
                  baseAmount: amount,
                  paidAmount: 0,
                  status: 'unpaid',
                  dueDate: DateTime.now().add(const Duration(days: 15)),
                );

                await ref
                    .read(feeRepositoryProvider)
                    .createInvoice(newInvoice);
                ref.invalidate(invoicesStreamProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeStatCard extends StatelessWidget {
  const _FeeStatCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
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
                CurrencyFormatter.pkr(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.outstanding});

  final String status;
  final double outstanding;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (outstanding <= 0 || status == 'paid') {
      bg = const Color(0xFF10B981).withValues(alpha: 0.15);
      fg = const Color(0xFF34D399);
      label = 'PAID';
    } else if (status == 'partial') {
      bg = Colors.amber.withValues(alpha: 0.15);
      fg = Colors.amber.shade300;
      label = 'PARTIAL';
    } else {
      bg = Colors.redAccent.withValues(alpha: 0.15);
      fg = Colors.redAccent.shade100;
      label = 'UNPAID';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
