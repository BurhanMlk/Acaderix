import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_models.dart';
import '../widgets/academy_avatar.dart';

/// Dedicated screen to record a subscription payment for an academy.
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({
    super.key,
    this.initialSubscription,
    this.academyId,
  });

  final AcademySubscription? initialSubscription;
  final String? academyId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _refController;
  late final TextEditingController _notesController;

  AcademySubscription? _selectedSub;
  List<AcademySubscription> _availableSubs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _paymentMethod = 'Bank Transfer';
  DateTime _paymentDate = DateTime.now();

  static const List<String> _paymentMethods = [
    'Bank Transfer',
    'JazzCash',
    'EasyPaisa',
    'Cash',
    'Credit Card',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _refController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.initialSubscription != null) {
      _selectedSub = widget.initialSubscription;
      _amountController.text = widget.initialSubscription!.price.toString();
    }
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final list =
          await ref.read(subscriptionRepositoryProvider).getSubscriptions();
      if (!mounted) return;
      setState(() {
        _availableSubs = list;
        if (_selectedSub == null && list.isNotEmpty) {
          if (widget.academyId != null) {
            _selectedSub = list.firstWhere(
              (s) => s.academyId == widget.academyId,
              orElse: () => list.first,
            );
          } else {
            _selectedSub = list.first;
          }
          _amountController.text = _selectedSub!.price.toString();
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? color,
    Color? borderColor,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.08),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedSub == null) return;

    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      final payment = SubscriptionPayment(
        id: '',
        academyId: _selectedSub!.academyId,
        academyName: _selectedSub!.academyName,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        referenceNumber: _refController.text.trim(),
        notes: _notesController.text.trim(),
        status: 'completed',
      );

      await ref.read(subscriptionRepositoryProvider).recordPayment(payment);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ${CurrencyFormatter.pkr(amount)} recorded for "${_selectedSub!.academyName}". Subscription renewed (+30 days).',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(AppRoutes.subscriptions);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _isLoading
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      Skeleton(height: 32, width: 220),
                      SizedBox(height: 20),
                      Skeleton(height: 120),
                      SizedBox(height: 20),
                      Skeleton(height: 240),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      children: [
                        // Screen Header with Back Arrow
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Back',
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.subscriptions);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Record Payment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Enter subscription fee receipt details',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Academy Selection Card
                        if (_availableSubs.isNotEmpty)
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Academy',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedSub?.academyId,
                                  dropdownColor: const Color(0xFF1E1B4B),
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: [
                                    for (final sub in _availableSubs)
                                      DropdownMenuItem(
                                        value: sub.academyId,
                                        child: Text(
                                          '${sub.academyName} (${sub.academyCode})',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      final match = _availableSubs.firstWhere(
                                        (e) => e.academyId == val,
                                      );
                                      setState(() {
                                        _selectedSub = match;
                                        _amountController.text =
                                            match.price.toString();
                                      });
                                    }
                                  },
                                ),
                                if (_selectedSub != null) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      AcademyAvatar(
                                        name: _selectedSub!.academyName,
                                        logoUrl: _selectedSub!.logoUrl,
                                        size: 40,
                                        borderRadius: 10,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedSub!.academyName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Current Plan: ${_selectedSub!.planName} · Renewal: ${DateFormatters.date(_selectedSub!.renewalDate)}',
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),

                        // Payment Details Form Card
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Amount (PKR)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  prefixText: 'Rs. ',
                                  hintText: '15000',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter payment amount';
                                  }
                                  final num = int.tryParse(val.trim());
                                  if (num == null || num <= 0) {
                                    return 'Enter a valid amount in PKR';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Payment Method',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final method in _paymentMethods)
                                    ChoiceChip(
                                      label: Text(method),
                                      selected: _paymentMethod == method,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _paymentMethod = method);
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Payment Date',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormatters.date(_paymentDate),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_month,
                                        color: Color(0xFF818CF8),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Reference / Transaction #',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _refController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. TRX-9823412 or Cheque #',
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Notes / Memo (Optional)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Paid in full for upcoming academic month',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Explanatory info box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Recording this payment will generate a receipt, update subscription status to Active, and extend renewal date by 30 days.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Full Width Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submitPayment,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              _isSubmitting
                                  ? 'Recording Payment...'
                                  : 'Save Payment & Renew (+30d)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
