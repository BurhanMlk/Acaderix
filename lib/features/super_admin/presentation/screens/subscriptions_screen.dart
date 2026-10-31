import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_card.dart';
import '../widgets/academy_avatar.dart';
import '../../application/subscription_providers.dart';
import '../../domain/subscription_models.dart';

/// Full-featured Super Admin Subscriptions Management Screen.
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _statusFilter;
  String? _planFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _glassWrapper({
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
          padding: padding,
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

  List<AcademySubscription> _filterSubscriptions(
      List<AcademySubscription> items) {
    return items.where((sub) {
      final matchesQuery = _searchQuery.isEmpty ||
          sub.academyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sub.academyCode.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = switch (_statusFilter) {
        'active' => sub.status == 'active' && !sub.isExpiringSoon,
        'expiring_soon' => sub.status == 'active' && sub.isExpiringSoon,
        'expired' => sub.status == 'expired' || sub.isExpired,
        _ => true,
      };

      final matchesPlan = _planFilter == null ||
          sub.planId.toLowerCase() == _planFilter!.toLowerCase() ||
          sub.planName.toLowerCase() == _planFilter!.toLowerCase();

      return matchesQuery && matchesStatus && matchesPlan;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Dedicated Mobile Screens Navigation
  // ---------------------------------------------------------------------------

  void _navigateToRecordPayment({AcademySubscription? presetSub}) async {
    await context.push(
      presetSub != null
          ? '${AppRoutes.recordPayment}?academyId=${presetSub.academyId}'
          : AppRoutes.recordPayment,
      extra: presetSub,
    );
    ref.invalidate(subscriptionsStreamProvider);
    ref.invalidate(subscriptionPaymentsStreamProvider);
  }

  void _navigateToChangePlan(AcademySubscription sub) async {
    await context.push(
      '${AppRoutes.changePlan}?academyId=${sub.academyId}',
      extra: sub,
    );
    ref.invalidate(subscriptionsStreamProvider);
  }

  void _navigateToExtendSubscription(AcademySubscription sub) async {
    await context.push(
      '${AppRoutes.extendSubscription}?academyId=${sub.academyId}',
      extra: sub,
    );
    ref.invalidate(subscriptionsStreamProvider);
  }

  void _navigateToEditPlanPrice(SubscriptionPlan plan) async {
    await context.push(
      '${AppRoutes.editPlanPrice}?planId=${plan.id}',
      extra: plan,
    );
    ref.invalidate(subscriptionPlansStreamProvider);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(subscriptionsStreamProvider);
    final plansAsync = ref.watch(subscriptionPlansStreamProvider);
    final paymentsAsync = ref.watch(subscriptionPaymentsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              final headerInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Subscriptions & Billing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage academy plans, track renewal cycles, and view revenue.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              final actionButton = FilledButton.icon(
                onPressed: () => _navigateToRecordPayment(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    actionButton,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 12),
                  actionButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Overview Metrics Row
          subsAsync.when(
            loading: () => const Row(
              children: [
                Expanded(child: Skeleton(height: 90)),
                SizedBox(width: 10),
                Expanded(child: Skeleton(height: 90)),
              ],
            ),
            error: (err, _) => const SizedBox.shrink(),
            data: (subscriptions) {
              final activeSubs = subscriptions.where((s) => s.status == 'active');
              final totalMRR = activeSubs.fold<int>(0, (sum, s) => sum + s.price);
              final activeCount = activeSubs.length;
              final expiringSoonCount =
                  subscriptions.where((s) => s.status == 'active' && s.isExpiringSoon).length;
              final expiredCount = subscriptions
                  .where((s) => s.status == 'expired' || s.isExpired)
                  .length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  return GridView.count(
                    crossAxisCount: isNarrow ? 2 : 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isNarrow ? 1.15 : 1.35,
                    children: [
                      StatCard(
                        title: 'Monthly Revenue',
                        value: CurrencyFormatter.pkr(totalMRR),
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF6366F1),
                      ),
                      StatCard(
                        title: 'Active Subscriptions',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                      ),
                      StatCard(
                        title: 'Expiring Soon (≤7d)',
                        value: '$expiringSoonCount',
                        icon: Icons.timelapse_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      StatCard(
                        title: 'Overdue / Expired',
                        value: '$expiredCount',
                        icon: Icons.error_outline,
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Segmented Tabs
          _glassWrapper(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.domain, size: 16),
                        const SizedBox(width: 5),
                        Text('Academies (${subsAsync.value?.length ?? 0})'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.style_outlined, size: 16),
                        const SizedBox(width: 5),
                        Text('Plans (${plansAsync.value?.length ?? 3})'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 16),
                        const SizedBox(width: 5),
                        Text('Payments (${paymentsAsync.value?.length ?? 0})'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tab Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return switch (_tabController.index) {
                0 => _buildAcademiesTab(subsAsync),
                1 => _buildPlansTab(plansAsync),
                2 => _buildPaymentsTab(paymentsAsync),
                _ => const SizedBox.shrink(),
              };
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Academy Subscriptions
  // ---------------------------------------------------------------------------

  Widget _buildAcademiesTab(AsyncValue<List<AcademySubscription>> subsAsync) {
    return subsAsync.when(
      loading: () => const Column(
        children: [
          Skeleton(height: 60),
          SizedBox(height: 12),
          Skeleton(height: 120),
          SizedBox(height: 12),
          Skeleton(height: 120),
        ],
      ),
      error: (err, _) => ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(subscriptionsStreamProvider),
      ),
      data: (subscriptions) {
        final filtered = _filterSubscriptions(subscriptions);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search academy by name or code...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final (label, val) in [
                    ('All', null),
                    ('Active', 'active'),
                    ('Expiring Soon', 'expiring_soon'),
                    ('Expired', 'expired'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: _statusFilter == val,
                        onSelected: (_) => setState(() => _statusFilter = val),
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Text(
                    'Plan:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final (label, val) in [
                    ('All', null),
                    ('Basic', 'basic'),
                    ('Standard', 'standard'),
                    ('Premium', 'premium'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: _planFilter == val,
                        onSelected: (_) => setState(() => _planFilter = val),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              _glassWrapper(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.white54),
                      SizedBox(height: 12),
                      Text(
                        'No matching academy subscriptions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try clearing search or filters to see all subscriptions.',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final sub in filtered) ...[
                _buildSubscriptionCard(sub),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard(AcademySubscription sub) {
    final (badgeColor, badgeText) = switch (sub.status.toLowerCase()) {
      'active' when sub.isExpiringSoon => (
          const Color(0xFFF59E0B),
          'EXPIRING IN ${sub.daysRemaining}D'
        ),
      'active' => (const Color(0xFF10B981), 'ACTIVE'),
      'grace_period' => (const Color(0xFFF59E0B), 'GRACE PERIOD'),
      _ => (const Color(0xFFEF4444), 'EXPIRED'),
    };

    final planColor = switch (sub.planId.toLowerCase()) {
      'basic' => const Color(0xFF0EA5E9),
      'premium' => const Color(0xFFA855F7),
      _ => const Color(0xFF6366F1),
    };

    return _glassWrapper(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcademyAvatar(
                  name: sub.academyName,
                  logoUrl: sub.logoUrl,
                  size: 50,
                  borderRadius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sub.academyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            sub.academyCode,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: planColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: planColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              sub.planName.toUpperCase(),
                              style: TextStyle(
                                color: planColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.pkr(sub.price)} / ${sub.billingCycle}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: sub.isExpired
                      ? const Color(0xFFEF4444)
                      : (sub.isExpiringSoon
                          ? const Color(0xFFF59E0B)
                          : Colors.white70),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Renewal: ${DateFormatters.date(sub.renewalDate)}',
                    style: TextStyle(
                      color: sub.isExpired
                          ? const Color(0xFFEF4444)
                          : (sub.isExpiringSoon
                              ? const Color(0xFFF59E0B)
                              : Colors.white70),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _navigateToChangePlan(sub),
                  icon: const Icon(Icons.upgrade, size: 16),
                  label: const Text('Change Plan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _navigateToExtendSubscription(sub),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Extend'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _navigateToRecordPayment(presetSub: sub),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark Paid'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Subscription Plans
  // ---------------------------------------------------------------------------

  Widget _buildPlansTab(AsyncValue<List<SubscriptionPlan>> plansAsync) {
    return plansAsync.when(
      loading: () => const Row(
        children: [
          Expanded(child: Skeleton(height: 250)),
          SizedBox(width: 12),
          Expanded(child: Skeleton(height: 250)),
        ],
      ),
      error: (err, _) => ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(subscriptionPlansStreamProvider),
      ),
      data: (plans) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 750;
            if (isNarrow) {
              return Column(
                children: [
                  for (final plan in plans) ...[
                    _buildPlanCard(plan),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final plan in plans)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPlanCard(plan),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final planColor = switch (plan.id.toLowerCase()) {
      'basic' => const Color(0xFF0EA5E9),
      'premium' => const Color(0xFFA855F7),
      _ => const Color(0xFF6366F1),
    };

    return _glassWrapper(
      borderColor: plan.isPopular ? planColor : null,
      color: plan.isPopular ? planColor.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              if (plan.isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: planColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatter.pkr(plan.price),
                  style: TextStyle(
                    color: planColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                Text(
                  ' / ${plan.billingPeriod}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _planQuotaRow(
            icon: Icons.school_outlined,
            label: plan.maxStudents == -1
                ? 'Unlimited Students'
                : 'Up to ${plan.maxStudents} Students',
          ),
          const SizedBox(height: 8),
          _planQuotaRow(
            icon: Icons.apartment_outlined,
            label: plan.maxBranches == -1
                ? 'Unlimited Campus Branches'
                : 'Up to ${plan.maxBranches} Branch Campus',
          ),
          const SizedBox(height: 16),
          const Text(
            'Included Features',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          for (final feat in plan.features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToEditPlanPrice(plan),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Plan Price'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: planColor.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planQuotaRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF818CF8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Payment History
  // ---------------------------------------------------------------------------

  Widget _buildPaymentsTab(
      AsyncValue<List<SubscriptionPayment>> paymentsAsync) {
    return paymentsAsync.when(
      loading: () => const Column(
        children: [
          Skeleton(height: 80),
          SizedBox(height: 12),
          Skeleton(height: 80),
        ],
      ),
      error: (err, _) => ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(subscriptionPaymentsStreamProvider),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return _glassWrapper(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_outlined,
                    size: 48,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No payment records found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Recorded academy subscription fee receipts will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _navigateToRecordPayment(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Record First Payment'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (final payment in payments) ...[
              _glassWrapper(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  payment.academyName.isEmpty
                                      ? 'Academy Payment'
                                      : payment.academyName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.pkr(payment.amount),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${DateFormatters.date(payment.paymentDate)}  ·  ${payment.paymentMethod}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                              if (payment.referenceNumber.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'Ref: ${payment.referenceNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (payment.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              payment.notes,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
