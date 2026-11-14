import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/fee_calculator.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../academics/application/course_repository_provider.dart';
import '../../../admissions/domain/student.dart';
import '../../../branches/domain/branch.dart';
import '../../application/fee_repository_provider.dart'
    hide invoicesStreamProvider, paymentsStreamProvider;
import '../../domain/fee_invoice.dart';
import '../../domain/fee_payment.dart';
import '../../domain/fee_structure.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: const Text(
            'Fees',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF6B7280),
              ),
              tooltip: 'Fee structures',
              onPressed: () => context.push(AppRoutes.feeStructures),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Invoices'),
              Tab(text: 'Defaulters'),
            ],
            indicatorColor: Color(0xFF4F46E5),
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Color(0xFF6B7280),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'bulk',
              tooltip: 'Bulk generate',
              backgroundColor: const Color(0xFFEEF2FF),
              foregroundColor: const Color(0xFF4F46E5),
              onPressed: () =>
                  _showBulkGenerateDialog(context, ref, academyId, students),
              child: const Icon(Icons.group_add_outlined),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'issue',
              onPressed: () =>
                  _showCreateInvoiceDialog(context, ref, academyId, students),
              icon: const Icon(Icons.add),
              label: const Text('Issue invoice'),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ── Tab 0: Invoices ──────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by invoice # or student',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                BranchTabBar(academyId: academyId),
                Expanded(
                  child: AsyncListState<FeeInvoice>(
                    value: invoices,
                    emptyTitle: 'No invoices',
                    emptyMessage:
                        'Generate fee invoices to start collecting payments.',
                    onRetry: () => ref.invalidate(invoicesStreamProvider),
                    builder: (items) {
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

                      if (_query.trim().isNotEmpty) {
                        final q = _query.toLowerCase().trim();
                        filtered = filtered.where((inv) {
                          final student = students
                              .where((s) => s.id == inv.studentId)
                              .firstOrNull;
                          final studentMatch =
                              student != null &&
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
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                        );
                      }

                      double totalBilled = 0;
                      double totalPaid = 0;
                      for (final inv in filtered) {
                        totalBilled += inv.totalAmount;
                        totalPaid += inv.paidAmount;
                      }
                      final totalOutstanding = totalBilled - totalPaid;

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length + 1,
                        separatorBuilder: (_, index) =>
                            SizedBox(height: index == 0 ? 10 : 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
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
                                  amount: totalOutstanding > 0
                                      ? totalOutstanding
                                      : 0,
                                  color: totalOutstanding > 0
                                      ? Colors.amber
                                      : const Color(0xFF9CA3AF),
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

                          return _InvoiceCard(
                            invoice: invoice,
                            student: student,
                            branch: branch,
                            selectedBranchId: selectedBranchId,
                            outstanding: outstanding,
                            onCollect: () => _collectPayment(
                              context,
                              ref,
                              academyId,
                              invoice,
                              outstanding,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // ── Tab 1: Defaulters ────────────────────────────────────
            _DefaultersTab(
              academyId: academyId,
              students: students,
              selectedBranchId: selectedBranchId,
            ),
          ],
        ),
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
    final amountCtrl = TextEditingController(
      text: outstanding.toStringAsFixed(0),
    );
    final referenceCtrl = TextEditingController();
    String method = 'cash';

    final student = ref
        .read(studentsStreamProvider(academyId))
        .value
        ?.where((s) => s.id == invoice.studentId)
        .firstOrNull;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Collect payment',
                  style: TextStyle(
                    color: Color(0xFF111827),
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
                    // Invoice summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Due: ${CurrencyFormatter.pkr(outstanding)}',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
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
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (student != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Student: ${student.fullName} (${student.rollNumber})',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Amount field
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Color(0xFF111827)),
                      decoration: InputDecoration(
                        labelText: 'Amount (PKR)',
                        prefixIcon: const Icon(
                          Icons.currency_exchange_outlined,
                        ),
                        helperText: 'Max ${CurrencyFormatter.pkr(outstanding)}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick chips
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.1),
                          side: const BorderSide(
                            color: Color(0xFF4F46E5),
                            width: 0.8,
                          ),
                          label: Text(
                            'Full: ${CurrencyFormatter.pkr(outstanding)}',
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () =>
                              amountCtrl.text = outstanding.toStringAsFixed(0),
                        ),
                        if (outstanding >= 2000)
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFF3F4F6),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            label: Text(
                              'Half: ${CurrencyFormatter.pkr(outstanding / 2)}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () => amountCtrl.text = (outstanding / 2)
                                .toStringAsFixed(0),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Payment method
                    DropdownButtonFormField<String>(
                      value: method,
                      dropdownColor: Colors.white,
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank transfer'),
                        ),
                        DropdownMenuItem(
                          value: 'cheque',
                          child: Text('Cheque'),
                        ),
                        DropdownMenuItem(
                          value: 'jazzcash',
                          child: Text('JazzCash'),
                        ),
                        DropdownMenuItem(
                          value: 'easypaisa',
                          child: Text('Easypaisa'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => method = v);
                      },
                    ),
                    if (method != 'cash') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: referenceCtrl,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Color(0xFF111827)),
                        decoration: InputDecoration(
                          labelText: method == 'cheque'
                              ? 'Cheque number'
                              : 'Transaction reference',
                          prefixIcon: const Icon(Icons.tag_outlined),
                        ),
                      ),
                    ],
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
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0 || amount > outstanding + 0.01) return;

                final payment = FeePayment(
                  id: const Uuid().v4(),
                  academyId: academyId,
                  invoiceId: invoice.id,
                  studentId: invoice.studentId,
                  amount: amount,
                  paidAt: DateTime.now(),
                  method: method,
                  reference: referenceCtrl.text.trim(),
                );

                await ref.read(feeRepositoryProvider).recordPayment(payment);
                ref.invalidate(invoicesStreamProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bulk invoice generation ─────────────────────────────────────────────
  void _showBulkGenerateDialog(
    BuildContext context,
    WidgetRef ref,
    String academyId,
    List<Student> students,
  ) {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students found. Admit students first.'),
        ),
      );
      return;
    }

    final structures =
        ref.read(feeStructuresStreamProvider(academyId)).value ?? [];
    if (structures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No fee structures found.'),
          action: SnackBarAction(
            label: 'Create one',
            onPressed: () => context.push(AppRoutes.feeStructures),
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);
    final monthCtrl = TextEditingController(text: monthLabel);
    FeeStructure selectedStructure = structures.first;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Students eligible for selected structure
          final eligible = students.where((s) {
            if (selectedStructure.branchId.isNotEmpty &&
                s.branchId != selectedStructure.branchId)
              return false;
            return s.status == 'active' || s.status.isEmpty;
          }).toList();

          final dueDate = DateTime(
            now.year,
            now.month,
            selectedStructure.dueDayOfMonth,
          );

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_add_outlined,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bulk generate invoices',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
                      DropdownButtonFormField<FeeStructure>(
                        initialValue: selectedStructure,
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Fee structure',
                          prefixIcon: Icon(Icons.list_alt_outlined),
                        ),
                        items: structures
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  '${s.title} — ${CurrencyFormatter.pkr(s.amount)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => selectedStructure = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: monthCtrl,
                        style: const TextStyle(color: Color(0xFF111827)),
                        decoration: const InputDecoration(
                          labelText: 'Month label',
                          hintText: 'e.g. November 2026',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF34D399,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${eligible.length} invoices will be created',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ${CurrencyFormatter.pkr(selectedStructure.amount)} each\n'
                              'Due: ${DateFormat('d MMM yyyy').format(dueDate)}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
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
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (eligible.isEmpty) return;
                  final count = await ref
                      .read(feeRepositoryProvider)
                      .bulkCreateInvoices(
                        structure: selectedStructure,
                        studentIds: eligible.map((s) => s.id).toList(),
                        monthLabel: monthCtrl.text.trim().isEmpty
                            ? monthLabel
                            : monthCtrl.text.trim(),
                        dueDate: dueDate,
                      );
                  ref.invalidate(invoicesStreamProvider);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Generated $count invoices.'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  }
                },
                child: const Text('Generate'),
              ),
            ],
          );
        },
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
    final targetStudents = eligibleStudents.isNotEmpty
        ? eligibleStudents
        : students;
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
                    color: Color(0xFF111827),
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
                        dropdownColor: Colors.white,
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
                        style: const TextStyle(color: Color(0xFF111827)),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Color(0xFF111827)),
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
                final amount = double.tryParse(amountController.text) ?? 0;
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

                await ref.read(feeRepositoryProvider).createInvoice(newInvoice);
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

// ── Invoice Card ────────────────────────────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.student,
    required this.branch,
    required this.selectedBranchId,
    required this.outstanding,
    required this.onCollect,
  });

  final FeeInvoice invoice;
  final Student? student;
  final Branch? branch;
  final String? selectedBranchId;
  final double outstanding;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        outstanding > 0 &&
        invoice.dueDate != null &&
        invoice.dueDate!.isBefore(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.title.isNotEmpty
                            ? invoice.title
                            : invoice.invoiceNo,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            invoice.invoiceNo,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: invoice.status, outstanding: outstanding),
              ],
            ),
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
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${student!.fullName} (Roll #${student!.rollNumber})',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  if (branch != null && selectedBranchId == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        branch!.name,
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (invoice.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Due: ${DateFormat('d MMM yyyy').format(invoice.dueDate!)}',
                style: TextStyle(
                  color: isOverdue
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF9CA3AF),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${CurrencyFormatter.pkr(invoice.totalAmount)}',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Paid: ${CurrencyFormatter.pkr(invoice.paidAmount)}'
                        '${outstanding > 0 ? ' · Due: ${CurrencyFormatter.pkr(outstanding)}' : ''}',
                        style: TextStyle(
                          color: outstanding > 0
                              ? Colors.amber.shade700
                              : const Color(0xFF16A34A),
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
                    onPressed: onCollect,
                    child: const Text('Collect'),
                  )
                else
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Settled',
                        style: TextStyle(
                          color: Color(0xFF10B981),
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
  }
}

// ── Defaulters Tab ─────────────────────────────────────────────────────────────────
class _DefaultersTab extends ConsumerWidget {
  const _DefaultersTab({
    required this.academyId,
    required this.students,
    required this.selectedBranchId,
  });

  final String academyId;
  final List<Student> students;
  final String? selectedBranchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices =
        ref.watch(invoicesStreamProvider(academyId)).value ?? const [];
    final now = DateTime.now();

    // Collect overdue invoices (unpaid/partial AND past due date)
    final overdue = invoices.where((inv) {
      final outstanding = FeeCalculator.outstanding(
        inv.totalAmount,
        inv.paidAmount,
      );
      if (outstanding <= 0) return false;
      if (inv.dueDate != null && inv.dueDate!.isAfter(now)) return false;
      if (selectedBranchId != null) {
        final student = students
            .where((s) => s.id == inv.studentId)
            .firstOrNull;
        if (student != null && student.branchId != selectedBranchId) {
          return false;
        }
      }
      return true;
    }).toList();

    // Group by student
    final Map<String, List<FeeInvoice>> byStudent = {};
    for (final inv in overdue) {
      byStudent.putIfAbsent(inv.studentId, () => []).add(inv);
    }

    if (byStudent.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Color(0xFF10B981),
              ),
              SizedBox(height: 16),
              Text(
                'No defaulters',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'All students are up to date with payments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Summary header
    double totalOutstanding = 0;
    for (final inv in overdue) {
      totalOutstanding += FeeCalculator.outstanding(
        inv.totalAmount,
        inv.paidAmount,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: byStudent.length + 1,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFDC2626).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${byStudent.length} student${byStudent.length == 1 ? '' : 's'} with overdue payments',
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Total outstanding: ${CurrencyFormatter.pkr(totalOutstanding)}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final studentId = byStudent.keys.elementAt(index - 1);
        final studentInvoices = byStudent[studentId]!;
        final student = students.where((s) => s.id == studentId).firstOrNull;
        double studentOutstanding = 0;
        for (final inv in studentInvoices) {
          studentOutstanding += FeeCalculator.outstanding(
            inv.totalAmount,
            inv.paidAmount,
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        student?.fullName.isNotEmpty == true
                            ? student!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.fullName ?? 'Unknown student',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (student != null)
                            Text(
                              'Roll #${student.rollNumber}',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.pkr(studentOutstanding),
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${studentInvoices.length} invoice${studentInvoices.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    final phone = student?.guardianPhone.isNotEmpty == true
                        ? student!.guardianPhone
                        : student?.phone ?? '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          phone.isNotEmpty
                              ? 'Reminder queued for ${student?.fullName ?? 'student'} ($phone)'
                              : 'No contact number on file for ${student?.fullName ?? 'student'}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined, size: 16),
                  label: const Text('Send reminder'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Existing helper widgets ─────────────────────────────────────────────────────
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
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
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
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
