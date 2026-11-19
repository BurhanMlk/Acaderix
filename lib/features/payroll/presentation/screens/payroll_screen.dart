import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../../communication/application/communication_providers.dart';
import '../../../communication/domain/app_notification.dart';
import '../../../staff/domain/staff.dart';
import '../../application/payroll_providers.dart';
import '../../domain/salary_record.dart';

/// Staff payroll management screen for Academy Admin:
/// monthly payroll generation, bonus/deduction adjustments, payment disbursement,
/// and automatic staff notifications.
class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  String _query = '';
  String _selectedMonthKey = 'all';
  String _statusFilter = 'all'; // 'all', 'pending', 'paid'

  List<({String key, String label})> _monthOptions() {
    final now = DateTime.now();
    final options = <({String key, String label})>[];
    for (var offset = -5; offset <= 1; offset++) {
      final dt = DateTime(now.year, now.month + offset, 1);
      options.add((
        key: DateFormat('yyyy-MM').format(dt),
        label: DateFormat('MMMM yyyy').format(dt),
      ));
    }
    return options.reversed.toList();
  }

  List<SalaryRecord> _filter(List<SalaryRecord> records, String? branchId) {
    var result = records;
    if (branchId != null && branchId.isNotEmpty) {
      result = result.where((r) => r.branchId == branchId).toList();
    }
    if (_selectedMonthKey != 'all') {
      result = result.where((r) => r.monthKey == _selectedMonthKey).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((r) => r.status == _statusFilter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase().trim();
      result = result.where((r) {
        return r.staffName.toLowerCase().contains(q) ||
            r.staffCode.toLowerCase().contains(q) ||
            r.jobTitle.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  Future<void> _showGeneratePayrollDialog(
    BuildContext context,
    String academyId,
    List<Staff> allStaff,
    String? selectedBranchId,
  ) async {
    final months = _monthOptions();
    final currentKey = DateFormat('yyyy-MM').format(DateTime.now());
    var chosen = months.firstWhere(
      (m) => m.key == currentKey,
      orElse: () => months.first,
    );
    bool generating = false;

    final scopedStaff = selectedBranchId != null && selectedBranchId.isNotEmpty
        ? allStaff.where((s) => s.branchId == selectedBranchId).toList()
        : allStaff;
    final eligibleCount = scopedStaff
        .where((s) => s.status == 'active' && s.salary > 0)
        .length;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Monthly Payroll'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Creates pending salary slips for $eligibleCount active staff member(s) with a configured salary. Existing slips for the selected month are skipped.',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: chosen.key,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Payroll Month',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: months
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.key,
                          child: Text(m.label),
                        ),
                      )
                      .toList(),
                  onChanged: generating
                      ? null
                      : (val) {
                          if (val != null) {
                            setDialogState(() {
                              chosen = months.firstWhere((m) => m.key == val);
                            });
                          }
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: generating ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: generating || eligibleCount == 0
                  ? null
                  : () async {
                      setDialogState(() => generating = true);
                      try {
                        final count = await ref
                            .read(payrollRepositoryProvider)
                            .generateMonthlyPayroll(
                              academyId: academyId,
                              staffList: scopedStaff,
                              monthKey: chosen.key,
                              monthLabel: chosen.label,
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                count > 0
                                    ? 'Generated $count salary slip(s) for ${chosen.label}.'
                                    : 'All eligible staff already have slips for ${chosen.label}.',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => generating = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to generate payroll: $e'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateOrEditDialog(
    BuildContext context,
    String academyId,
    List<Staff> allStaff, {
    SalaryRecord? existing,
  }) async {
    if (existing == null && allStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add staff members first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final months = _monthOptions();
    final currentKey = DateFormat('yyyy-MM').format(DateTime.now());
    var chosenMonth = existing != null
        ? (key: existing.monthKey, label: existing.monthLabel)
        : months.firstWhere(
            (m) => m.key == currentKey,
            orElse: () => months.first,
          );

    Staff selectedStaff = existing != null
        ? allStaff.firstWhere(
            (s) => s.id == existing.staffId,
            orElse: () => Staff(
              id: existing.staffId,
              academyId: academyId,
              staffId: existing.staffCode,
              fullName: existing.staffName,
              jobTitle: existing.jobTitle,
              branchId: existing.branchId,
              salary: existing.baseSalary,
            ),
          )
        : allStaff.first;

    final baseCtrl = TextEditingController(
      text: (existing?.baseSalary ?? selectedStaff.salary).toStringAsFixed(0),
    );
    final bonusCtrl = TextEditingController(
      text: (existing?.bonus ?? 0).toStringAsFixed(0),
    );
    final deductionsCtrl = TextEditingController(
      text: (existing?.deductions ?? 0).toStringAsFixed(0),
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Create Salary Slip' : 'Edit Salary Slip'),
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
                      if (existing == null) ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedStaff.id,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            labelText: 'Staff Member',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: allStaff
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    '${s.fullName} (${s.staffId})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final found = allStaff.firstWhere((s) => s.id == val);
                              setDialogState(() {
                                selectedStaff = found;
                                baseCtrl.text = found.salary.toStringAsFixed(0);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: chosenMonth.key,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          items: months
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.key,
                                  child: Text(m.label),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                chosenMonth = months.firstWhere((m) => m.key == val);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Text(
                          '${existing.staffName} • ${existing.monthLabel}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: baseCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Base Salary (PKR)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (v) {
                          final val = double.tryParse(v?.trim() ?? '');
                          if (val == null || val < 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: bonusCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Bonus (PKR)',
                                prefixIcon: Icon(Icons.add_circle_outline),
                              ),
                              validator: (v) {
                                final val = double.tryParse(v?.trim() ?? '');
                                if (val == null || val < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: deductionsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Deductions',
                                prefixIcon: Icon(Icons.remove_circle_outline),
                              ),
                              validator: (v) {
                                final val = double.tryParse(v?.trim() ?? '');
                                if (val == null || val < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final base = double.tryParse(baseCtrl.text.trim()) ?? 0;
                      final bonus = double.tryParse(bonusCtrl.text.trim()) ?? 0;
                      final deductions =
                          double.tryParse(deductionsCtrl.text.trim()) ?? 0;

                      final record = existing != null
                          ? existing.copyWith(
                              baseSalary: base,
                              bonus: bonus,
                              deductions: deductions,
                              notes: notesCtrl.text.trim(),
                            )
                          : SalaryRecord(
                              id: '${chosenMonth.key}_${selectedStaff.id}',
                              academyId: academyId,
                              staffId: selectedStaff.id,
                              staffCode: selectedStaff.staffId,
                              staffName: selectedStaff.fullName,
                              jobTitle: selectedStaff.jobTitle,
                              branchId: selectedStaff.branchId,
                              monthKey: chosenMonth.key,
                              monthLabel: chosenMonth.label,
                              baseSalary: base,
                              bonus: bonus,
                              deductions: deductions,
                              notes: notesCtrl.text.trim(),
                              status: 'pending',
                              createdAt: DateTime.now(),
                            );

                      await ref
                          .read(payrollRepositoryProvider)
                          .createOrUpdate(record);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 400), () {
      baseCtrl.dispose();
      bonusCtrl.dispose();
      deductionsCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  Future<void> _showMarkPaidDialog(
    BuildContext context,
    SalaryRecord record,
  ) async {
    String method = record.paymentMethod;
    final notesCtrl = TextEditingController(text: record.notes);
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Disburse Salary'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${record.staffName} (${record.monthLabel})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Net Payable: ${CurrencyFormatter.pkr(record.netSalary)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                  ],
                  onChanged: saving
                      ? null
                      : (val) {
                          if (val != null) setDialogState(() => method = val);
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reference / Notes (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      await ref.read(payrollRepositoryProvider).markAsPaid(
                            record.academyId,
                            record.id,
                            paymentMethod: method,
                            notes: notesCtrl.text.trim(),
                          );
                      try {
                        await ref
                            .read(communicationRepositoryProvider)
                            .sendNotification(
                              AppNotification(
                                id: const Uuid().v4(),
                                academyId: record.academyId,
                                recipientId: record.staffCode.isNotEmpty
                                    ? record.staffCode
                                    : record.staffId,
                                recipientRole: 'staff',
                                title: 'Salary Paid: ${record.monthLabel}',
                                body:
                                    'Your salary of ${CurrencyFormatter.pkr(record.netSalary)} has been disbursed.',
                                type: 'payroll_alert',
                                relatedId: record.id,
                              ),
                            );
                      } catch (_) {}
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Marked ${record.staffName}\'s salary as paid.',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 400), notesCtrl.dispose);
  }

  Future<void> _deleteRecord(BuildContext context, SalaryRecord record) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Salary Slip',
      message:
          'Delete ${record.monthLabel} salary slip for ${record.staffName}?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(payrollRepositoryProvider)
        .delete(record.academyId, record.id);
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final salariesAsync = ref.watch(salariesStreamProvider(academyId));
    final allStaff =
        ref.watch(staffStreamProvider(academyId)).value ?? const <Staff>[];
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final months = _monthOptions();

    final allRecords = salariesAsync.value ?? const <SalaryRecord>[];
    final filtered = _filter(allRecords, selectedBranchId);

    final totalNet = filtered.fold<double>(0, (s, r) => s + r.netSalary);
    final paidNet = filtered
        .where((r) => r.isPaid)
        .fold<double>(0, (s, r) => s + r.netSalary);
    final pendingNet = filtered
        .where((r) => !r.isPaid)
        .fold<double>(0, (s, r) => s + r.netSalary);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrEditDialog(context, academyId, allStaff),
        icon: const Icon(Icons.add),
        label: const Text('Add Payslip'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Generate Payroll Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search staff name or ID',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _showGeneratePayrollDialog(
                    context,
                    academyId,
                    allStaff,
                    selectedBranchId,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate'),
                ),
              ],
            ),
          ),

          // Month & Status Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMonthKey,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Months'),
                      ),
                      ...months.map(
                        (m) => DropdownMenuItem(
                          value: m.key,
                          child: Text(m.label),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMonthKey = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _statusFilter = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          BranchTabBar(academyId: academyId),

          // Summary KPI Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                _SummaryPill(
                  label: 'Total',
                  value: CurrencyFormatter.pkr(totalNet),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'Paid',
                  value: CurrencyFormatter.pkr(paidNet),
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _SummaryPill(
                  label: 'Pending',
                  value: CurrencyFormatter.pkr(pendingNet),
                  color: Colors.amber.shade700,
                ),
              ],
            ),
          ),

          Expanded(
            child: AsyncListState<SalaryRecord>(
              value: salariesAsync,
              emptyTitle: 'No payroll records',
              emptyMessage:
                  'Tap "Generate" to create monthly salary slips for active staff.',
              onRetry: () => ref.invalidate(salariesStreamProvider(academyId)),
              builder: (_) {
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No salary slips match the current filters.',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    final branch = branches
                        .where((b) => b.id == record.branchId)
                        .firstOrNull;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.staffName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${record.staffCode}${record.jobTitle.isNotEmpty ? " • ${record.jobTitle}" : ""}${branch != null ? " • ${branch.name}" : ""}',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (record.isPaid
                                            ? AppColors.success
                                            : Colors.amber)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    record.isPaid ? 'PAID' : 'PENDING',
                                    style: TextStyle(
                                      color: record.isPaid
                                          ? AppColors.success
                                          : Colors.amber.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  record.monthLabel,
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.pkr(record.netSalary),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (record.bonus > 0 || record.deductions > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Base: ${CurrencyFormatter.pkr(record.baseSalary)}'
                                '${record.bonus > 0 ? "  +${CurrencyFormatter.pkr(record.bonus)} bonus" : ""}'
                                '${record.deductions > 0 ? "  -${CurrencyFormatter.pkr(record.deductions)} ded." : ""}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!record.isPaid)
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _showMarkPaidDialog(context, record),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Mark Paid'),
                                  ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Edit Slip',
                                  icon: const Icon(Icons.edit_outlined, size: 19),
                                  onPressed: () => _showCreateOrEditDialog(
                                    context,
                                    academyId,
                                    allStaff,
                                    existing: record,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete Slip',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 19,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _deleteRecord(context, record),
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
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
