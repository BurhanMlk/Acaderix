import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/fees/domain/fee_invoice.dart';
import 'package:academy_management/features/fees/domain/fee_payment.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'package:academy_management/features/student/presentation/utils/student_pdf_generator.dart';

/// Tab presenting the student's fee invoices, dues, payment history ledger,
/// and instant PDF receipt generation.
class StudentFeesTab extends ConsumerStatefulWidget {
  const StudentFeesTab({super.key});

  @override
  ConsumerState<StudentFeesTab> createState() => _StudentFeesTabState();
}

class _StudentFeesTabState extends ConsumerState<StudentFeesTab> {
  int _selectedView = 0; // 0 = Invoices & Dues, 1 = Payment History Ledger

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProfileProvider);
    final branch = ref.watch(currentStudentBranchProvider);
    final invoices = ref.watch(currentStudentInvoicesProvider);
    final payments = ref.watch(currentStudentPaymentsProvider);
    final metrics = ref.watch(studentMetricsProvider);
    final theme = Theme.of(context);

    final totalBilled = invoices.fold<double>(
      0,
      (sum, inv) => sum + inv.totalAmount,
    );
    final totalPaid = payments.isNotEmpty
        ? payments.fold<double>(0, (sum, p) => sum + p.amount)
        : invoices.fold<double>(0, (sum, inv) => sum + inv.paidAmount);
    final balance = metrics.outstandingFees;
    final isFullyPaid = balance <= 0 && invoices.isNotEmpty;

    final primaryStudent = student ??
        const Student(
          id: 'std_default',
          academyId: '',
          fullName: 'Student',
          rollNumber: '100001',
          academicSession: '2026-2027',
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // 1. Fee Account Summary Card
        GlassCard(
          padding: const EdgeInsets.all(18),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Fee Account Status',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isFullyPaid
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFullyPaid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isFullyPaid ? 'ALL CLEARED' : 'PAYMENT DUE',
                      style: TextStyle(
                        color: isFullyPaid
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Balance Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outstanding Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: balance > 0
                          ? const Color(0xFFF87171)
                          : const Color(0xFF34D399),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),

              // Breakdown: Total Billed vs Paid
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Invoiced',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ${totalBilled.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: Colors.white12,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Paid',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs ${totalPaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // View Switcher (Invoices vs Payments)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  title: 'Invoices (${invoices.length})',
                  icon: Icons.receipt_long_outlined,
                  isSelected: _selectedView == 0,
                  onTap: () => setState(() => _selectedView = 0),
                ),
              ),
              Expanded(
                child: _buildToggleButton(
                  title: 'Receipts (${payments.length})',
                  icon: Icons.history_edu_outlined,
                  isSelected: _selectedView == 1,
                  onTap: () => setState(() => _selectedView = 1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_selectedView == 0) ...[
          // Invoices View
          if (invoices.isEmpty)
            _buildEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Invoices Issued',
              message:
                  'No fee invoices have been generated for your student account.',
            )
          else ...[
            Text(
              'Fee Invoices (${invoices.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...invoices.map((inv) {
              return _buildInvoiceCard(
                invoice: inv,
                student: primaryStudent,
                branch: branch,
                payment: payments.isNotEmpty ? payments.first : null,
              );
            }),
          ],
        ] else ...[
          // Payments Ledger View
          if (payments.isEmpty)
            _buildEmptyState(
              icon: Icons.history_edu_outlined,
              title: 'No Payment History',
              message:
                  'Recorded fee payment transactions will be displayed here.',
            )
          else ...[
            Text(
              'Payment Receipts Ledger (${payments.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...payments.map((p) {
              return _buildPaymentCard(
                payment: p,
                student: primaryStudent,
                branch: branch,
                invoice: invoices.isNotEmpty ? invoices.first : null,
              );
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard({
    required FeeInvoice invoice,
    required Student student,
    required dynamic branch,
    required FeePayment? payment,
  }) {
    final invBalance = invoice.totalAmount - invoice.paidAmount;
    final isPaid = invoice.status.toLowerCase() == 'paid' || invBalance <= 0;
    final dueDateStr = invoice.dueDate != null
        ? DateFormat('dd MMM yyyy').format(invoice.dueDate!)
        : 'Immediate';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.title.isNotEmpty
                            ? invoice.title
                            : 'Tuition & Academic Term Fee',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoice #${invoice.invoiceNo.isNotEmpty ? invoice.invoiceNo : invoice.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isPaid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPaid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'UNPAID',
                    style: TextStyle(
                      color: isPaid
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Payable',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs ${invoice.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Paid Amount',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs ${invoice.paidAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueDateStr,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Print Receipt action button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text(
                  'Print Official Receipt (PDF)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  try {
                    await StudentPdfGenerator.printFeeReceipt(
                      student: student,
                      branch: branch,
                      invoice: invoice,
                      payment: payment,
                      feeBalance: invBalance.clamp(0, double.infinity),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to print receipt: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required FeePayment payment,
    required Student student,
    required dynamic branch,
    required FeeInvoice? invoice,
  }) {
    final dateStr = payment.paidAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(payment.paidAt!)
        : 'Recent Transaction';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs ${payment.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.method.toUpperCase()} • Ref #${payment.reference.isNotEmpty ? payment.reference : payment.id.substring(0, 6)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.print_outlined, size: 14),
                label: const Text(
                  'Receipt',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  try {
                    await StudentPdfGenerator.printFeeReceipt(
                      student: student,
                      branch: branch,
                      invoice: invoice,
                      payment: payment,
                      feeBalance: 0,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to print receipt: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid on $dateStr',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SUCCESSFUL',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 44, color: Colors.white30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
