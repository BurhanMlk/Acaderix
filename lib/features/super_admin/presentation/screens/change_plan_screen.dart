import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_models.dart';
import '../widgets/academy_avatar.dart';

/// Dedicated full screen to change/upgrade an academy's subscription plan.
class ChangePlanScreen extends ConsumerStatefulWidget {
  const ChangePlanScreen({
    super.key,
    this.subscription,
    this.academyId,
  });

  final AcademySubscription? subscription;
  final String? academyId;

  @override
  ConsumerState<ChangePlanScreen> createState() => _ChangePlanScreenState();
}

class _ChangePlanScreenState extends ConsumerState<ChangePlanScreen> {
  AcademySubscription? _subscription;
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  bool _isSaving = false;

  late String _selectedPlanId;
  late String _selectedPlanName;
  late int _selectedPrice;
  final String _billingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    _subscription = widget.subscription;
    _selectedPlanId = widget.subscription?.planId ?? 'standard';
    _selectedPlanName = widget.subscription?.planName ?? 'Standard';
    _selectedPrice = widget.subscription?.price ?? 15000;

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_subscription == null && widget.academyId != null) {
        final subs =
            await ref.read(subscriptionRepositoryProvider).getSubscriptions();
        _subscription = subs.firstWhere((s) => s.academyId == widget.academyId);
        _selectedPlanId = _subscription!.planId;
        _selectedPlanName = _subscription!.planName;
        _selectedPrice = _subscription!.price;
      }

      final fetchedPlans =
          await ref.read(subscriptionRepositoryProvider).getPlans();
      if (!mounted) return;
      setState(() {
        _plans = fetchedPlans;
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

  Future<void> _savePlanChange() async {
    final sub = _subscription;
    if (sub == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(subscriptionRepositoryProvider).updateAcademySubscription(
            sub.academyId,
            planId: _selectedPlanId,
            planName: _selectedPlanName,
            price: _selectedPrice,
            status: sub.status,
            renewalDate: sub.renewalDate,
            billingCycle: _billingCycle,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plan for "${sub.academyName}" changed to $_selectedPlanName (${CurrencyFormatter.pkr(_selectedPrice)}/$_billingCycle).',
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
            content: Text('Failed to update plan: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subscription;

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
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      // Header with Back Arrow
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
                                  'Change Subscription Plan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Select a new monthly pricing tier',
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

                      // Academy Info Banner
                      if (sub != null)
                        _glassCard(
                          child: Row(
                            children: [
                              AcademyAvatar(
                                name: sub.academyName,
                                logoUrl: sub.logoUrl,
                                size: 48,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.academyName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          sub.academyCode,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF6366F1)
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Text(
                                            'CURRENT: ${sub.planName.toUpperCase()}',
                                            style: const TextStyle(
                                              color: Color(0xFF818CF8),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Billing Cycle Info Card
                      _glassCard(
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Billing Cycle',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Monthly Plan (billed every 30 days)',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'Monthly Billing',
                                style: TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Available Plans',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // List of Available Plans
                      for (final plan in _plans) ...[
                        _buildPlanSelectionCard(plan),
                        const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 10),

                      // Save Plan Changes Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _savePlanChange,
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
                            _isSaving
                                ? 'Updating Plan...'
                                : 'Save Plan Changes ($_selectedPlanName)',
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
    );
  }

  Widget _buildPlanSelectionCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlanId == plan.id;
    final planColor = switch (plan.id.toLowerCase()) {
      'basic' => const Color(0xFF0EA5E9),
      'premium' => const Color(0xFFA855F7),
      _ => const Color(0xFF6366F1),
    };

    return _glassCard(
      padding: EdgeInsets.zero,
      borderColor: isSelected
          ? planColor
          : Colors.white.withValues(alpha: 0.14),
      color: isSelected
          ? planColor.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.05),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPlanId = plan.id;
              _selectedPlanName = plan.name;
              _selectedPrice = plan.price;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? planColor : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (plan.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: planColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const SizedBox(width: 34),
                Text(
                  CurrencyFormatter.pkr(plan.price),
                  style: TextStyle(
                    color: planColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' / month',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.maxStudents == -1
                        ? 'Unlimited Students · Unlimited Campus Branches'
                        : 'Up to ${plan.maxStudents} Students · Up to ${plan.maxBranches} Branches',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final feat in plan.features) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
