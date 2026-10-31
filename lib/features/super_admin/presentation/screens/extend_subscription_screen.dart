import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_models.dart';
import '../widgets/academy_avatar.dart';

/// Dedicated screen to extend an academy's subscription renewal date.
class ExtendSubscriptionScreen extends ConsumerStatefulWidget {
  const ExtendSubscriptionScreen({
    super.key,
    this.subscription,
    this.academyId,
  });

  final AcademySubscription? subscription;
  final String? academyId;

  @override
  ConsumerState<ExtendSubscriptionScreen> createState() =>
      _ExtendSubscriptionScreenState();
}

class _ExtendSubscriptionScreenState
    extends ConsumerState<ExtendSubscriptionScreen> {
  AcademySubscription? _subscription;
  late DateTime _selectedDate;
  int? _selectedPresetDays = 30;
  bool _isLoading = true;
  bool _isSaving = false;

  DateTime get _baseDate {
    final now = DateTime.now();
    final renewal = _subscription?.renewalDate;
    if (renewal != null && renewal.isAfter(now)) {
      return renewal;
    }
    return now;
  }

  @override
  void initState() {
    super.initState();
    _subscription = widget.subscription;
    final now = DateTime.now();
    final renewal = widget.subscription?.renewalDate;
    final base = (renewal != null && renewal.isAfter(now)) ? renewal : now;
    _selectedDate = base.add(const Duration(days: 30));
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    if (_subscription == null && widget.academyId != null) {
      try {
        final subs =
            await ref.read(subscriptionRepositoryProvider).getSubscriptions();
        if (mounted) {
          final match =
              subs.where((s) => s.academyId == widget.academyId).firstOrNull;
          setState(() {
            _subscription = match;
            if (match != null) {
              _selectedDate = _baseDate.add(const Duration(days: 30));
            }
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

  void _setDuration(int days) {
    setState(() {
      _selectedPresetDays = days;
      _selectedDate = _baseDate.add(Duration(days: days));
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1B4B),
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedPresetDays = null;
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExtension() async {
    final sub = _subscription;
    if (sub == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(subscriptionRepositoryProvider).updateAcademySubscription(
            sub.academyId,
            planId: sub.planId,
            planName: sub.planName,
            price: sub.price,
            status: 'active',
            renewalDate: _selectedDate,
            billingCycle: sub.billingCycle,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subscription for "${sub.academyName}" extended to ${DateFormatters.date(_selectedDate)}.',
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
            content: Text('Failed to extend subscription: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subscription;

    if (!_isLoading && sub == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 54,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Subscription Record Not Found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unable to load subscription details for this academy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.subscriptions);
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Subscriptions'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Extend Subscription',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Extend renewal date and maintain active status',
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
                                    Text(
                                      '${sub.academyCode} · ${sub.planName} Plan',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Current Expiry Card
                      if (sub != null)
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Subscription Status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Current Expiry Date',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    DateFormatters.date(sub.renewalDate),
                                    style: TextStyle(
                                      color: sub.isExpired
                                          ? const Color(0xFFEF4444)
                                          : (sub.isExpiringSoon
                                              ? const Color(0xFFF59E0B)
                                              : Colors.white),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Time Remaining',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    sub.isExpired
                                        ? 'Expired (${sub.daysRemaining.abs()} days ago)'
                                        : '${sub.daysRemaining} days remaining',
                                    style: TextStyle(
                                      color: sub.isExpired
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Quick Add Duration
                      _glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Add Extension Duration',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final (label, days) in [
                                  ('+1 Month (30d)', 30),
                                  ('+2 Months (60d)', 60),
                                  ('+3 Months (90d)', 90),
                                  ('+6 Months (180d)', 180),
                                ])
                                  ChoiceChip(
                                    label: Text(label),
                                    selected: _selectedPresetDays == days,
                                    onSelected: (_) => _setDuration(days),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _pickCustomDate,
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
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pick Custom Calendar Date',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF818CF8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New Expiry Date Preview
                      _glassCard(
                        borderColor: const Color(0xFF6366F1),
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Expiry Date',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Status will be set to Active',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              DateFormatters.date(_selectedDate),
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Extension Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveExtension,
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
                                ? 'Saving Extension...'
                                : 'Save Extension (${DateFormatters.date(_selectedDate)})',
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
}
