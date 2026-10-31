import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_models.dart';

/// Dedicated screen to update the standard monthly price of a subscription plan.
class EditPlanPriceScreen extends ConsumerStatefulWidget {
  const EditPlanPriceScreen({
    super.key,
    this.plan,
    this.planId,
  });

  final SubscriptionPlan? plan;
  final String? planId;

  @override
  ConsumerState<EditPlanPriceScreen> createState() =>
      _EditPlanPriceScreenState();
}

class _EditPlanPriceScreenState extends ConsumerState<EditPlanPriceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  SubscriptionPlan? _plan;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _priceController = TextEditingController(
      text: widget.plan?.price.toString() ?? '15000',
    );
    _loadPlan();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    if (_plan == null && widget.planId != null) {
      try {
        final plans =
            await ref.read(subscriptionRepositoryProvider).getPlans();
        if (mounted) {
          setState(() {
            _plan = plans.firstWhere((p) => p.id == widget.planId);
            _priceController.text = _plan!.price.toString();
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
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

  Future<void> _savePlanPrice() async {
    final plan = _plan;
    if (plan == null || !_formKey.currentState!.validate()) return;

    final newPrice = int.tryParse(_priceController.text.trim());
    if (newPrice == null || newPrice <= 0) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .updatePlanPrice(plan.id, newPrice);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${plan.name} plan monthly fee updated to ${CurrencyFormatter.pkr(newPrice)}.',
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
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update plan price: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final planColor = switch (plan?.id.toLowerCase()) {
      'basic' => const Color(0xFF0EA5E9),
      'premium' => const Color(0xFFA855F7),
      _ => const Color(0xFF6366F1),
    };

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
                        // Header with Back Button
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit ${plan?.name ?? 'Plan'} Fee',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Update standard monthly pricing tier',
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

                        // Plan Summary Banner
                        if (plan != null)
                          _glassCard(
                            borderColor: planColor,
                            color: planColor.withValues(alpha: 0.12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      'Current: ${CurrencyFormatter.pkr(plan.price)}/mo',
                                      style: TextStyle(
                                        color: planColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  plan.maxStudents == -1
                                      ? 'Unlimited Students · Unlimited Branches'
                                      : 'Up to ${plan.maxStudents} Students · Up to ${plan.maxBranches} Campus Branches',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Price Input Card
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New Monthly Price (PKR)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  prefixText: 'Rs. ',
                                  hintText: '15000',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter monthly fee in PKR';
                                  }
                                  final num = int.tryParse(val.trim());
                                  if (num == null || num <= 0) {
                                    return 'Enter a valid positive number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Quick adjustment suggestions
                              const Text(
                                'Quick Presets',
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
                                  for (final amt in [8000, 10000, 15000, 20000, 25000, 30000])
                                    ActionChip(
                                      label: Text(CurrencyFormatter.pkr(amt)),
                                      onPressed: () {
                                        setState(() {
                                          _priceController.text = amt.toString();
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Features Review Card
                        if (plan != null && plan.features.isNotEmpty)
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Included Features for This Tier',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (final feat in plan.features) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feat,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Policy Notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF818CF8),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Updating the plan price sets the new standard monthly rate for academies newly registering or renewing under this tier.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _savePlanPrice,
                            icon: _isSaving
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
                              _isSaving ? 'Saving Price...' : 'Save Updated Price',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
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
