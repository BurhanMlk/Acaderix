import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/fee_calculator.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/fee_repository_provider.dart';
import '../../domain/fee_invoice.dart';
import '../../domain/fee_payment.dart';

/// Fee invoices and payment collection.
class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final invoices = ref.watch(invoicesStreamProvider(academyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: AsyncListState<FeeInvoice>(
        value: invoices,
        emptyTitle: 'No invoices',
        emptyMessage: 'Generate fee invoices to start collecting payments.',
        onRetry: () => ref.invalidate(invoicesStreamProvider),
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final invoice = items[index];
            final outstanding = FeeCalculator.outstanding(
              invoice.totalAmount,
              invoice.paidAmount,
            );
            return Card(
              child: ListTile(
                title: Text(
                  invoice.title.isEmpty ? invoice.invoiceNo : invoice.title,
                ),
                subtitle: Text(
                  '${invoice.invoiceNo}\n${CurrencyFormatter.pkr(invoice.totalAmount)} '
                  '· Paid ${CurrencyFormatter.pkr(invoice.paidAmount)}',
                  maxLines: 2,
                ),
                isThreeLine: true,
                trailing: outstanding > 0
                    ? FilledButton(
                        onPressed: () => _collectPayment(
                          context,
                          ref,
                          academyId,
                          invoice,
                          outstanding,
                        ),
                        child: const Text('Collect'),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _collectPayment(
    BuildContext context,
    WidgetRef ref,
    String academyId,
    FeeInvoice invoice,
    double outstanding,
  ) async {
    final amountController = TextEditingController(
      text: outstanding.toStringAsFixed(0),
    );
    final methodController = TextEditingController(text: 'Cash');

    final result = await showDialog<FeePayment>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Collect Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (PKR)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: methodController,
              decoration: const InputDecoration(labelText: 'Method'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              Navigator.of(context).pop(
                FeePayment(
                  id: const Uuid().v4(),
                  academyId: academyId,
                  studentId: invoice.studentId,
                  invoiceId: invoice.id,
                  amount: amount,
                  method: methodController.text.trim(),
                  paidAt: DateTime.now(),
                ),
              );
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );

    amountController.dispose();
    methodController.dispose();

    if (result != null) {
      await ref.read(feeRepositoryProvider).recordPayment(result);
      ref.invalidate(invoicesStreamProvider);
      ref.invalidate(paymentsStreamProvider);
    }
  }
}
