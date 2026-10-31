import 'package:academy_management/core/widgets/stat_card.dart';
import 'package:academy_management/features/super_admin/application/subscription_providers.dart';
import 'package:academy_management/features/super_admin/domain/subscription_models.dart';
import 'package:academy_management/features/super_admin/domain/subscription_repository.dart';
import 'package:academy_management/features/super_admin/presentation/screens/change_plan_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/edit_plan_price_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/extend_subscription_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/record_payment_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/subscriptions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final List<AcademySubscription> _subscriptions = [
    AcademySubscription(
      id: 'sub_1',
      academyId: 'acad_1',
      academyName: 'Premier Science Academy',
      academyCode: 'ACD-001',
      planId: 'standard',
      planName: 'Standard',
      price: 15000,
      status: 'active',
      startDate: DateTime(2026, 1, 1),
      renewalDate: DateTime.now().add(const Duration(days: 20)),
      billingCycle: 'monthly',
      paymentStatus: 'paid',
    ),
    AcademySubscription(
      id: 'sub_2',
      academyId: 'acad_2',
      academyName: 'Apex Grammar School',
      academyCode: 'ACD-002',
      planId: 'basic',
      planName: 'Basic',
      price: 10000,
      status: 'active',
      startDate: DateTime(2026, 1, 15),
      renewalDate: DateTime.now().add(const Duration(days: 4)), // Expiring soon!
      billingCycle: 'monthly',
      paymentStatus: 'paid',
    ),
    AcademySubscription(
      id: 'sub_3',
      academyId: 'acad_3',
      academyName: 'Oxford Elite College',
      academyCode: 'ACD-003',
      planId: 'premium',
      planName: 'Premium',
      price: 20000,
      status: 'expired',
      startDate: DateTime(2025, 12, 1),
      renewalDate: DateTime.now().subtract(const Duration(days: 5)), // Expired!
      billingCycle: 'monthly',
      paymentStatus: 'overdue',
    ),
  ];

  final List<SubscriptionPlan> _plans = [
    const SubscriptionPlan(
      id: 'basic',
      name: 'Basic',
      price: 10000,
      maxStudents: 200,
      maxBranches: 1,
      features: ['Attendance', 'Fees'],
    ),
    const SubscriptionPlan(
      id: 'standard',
      name: 'Standard',
      price: 15000,
      maxStudents: 500,
      maxBranches: 3,
      isPopular: true,
      features: ['Attendance', 'Fees', 'Exams'],
    ),
    const SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      price: 20000,
      maxStudents: -1,
      maxBranches: -1,
      features: ['Unlimited everything', 'Priority support'],
    ),
  ];

  final List<SubscriptionPayment> _payments = [
    SubscriptionPayment(
      id: 'pay_1',
      academyId: 'acad_1',
      academyName: 'Premier Science Academy',
      amount: 15000,
      paymentDate: DateTime(2026, 10, 1),
      paymentMethod: 'Bank Transfer',
      referenceNumber: 'TRX-123456',
    ),
  ];

  String? updatedPlanId;
  int? updatedPrice;
  bool paymentRecorded = false;
  DateTime? extendedRenewalDate;
  String? updatedAcademyPlanName;

  @override
  Stream<List<AcademySubscription>> watchSubscriptions() =>
      Stream.value(_subscriptions);

  @override
  Future<List<AcademySubscription>> getSubscriptions() async =>
      _subscriptions;

  @override
  Stream<List<SubscriptionPlan>> watchPlans() => Stream.value(_plans);

  @override
  Future<List<SubscriptionPlan>> getPlans() async => _plans;

  @override
  Future<void> updatePlanPrice(String planId, int newPrice) async {
    updatedPlanId = planId;
    updatedPrice = newPrice;
    final index = _plans.indexWhere((p) => p.id == planId);
    if (index != -1) {
      final old = _plans[index];
      _plans[index] = SubscriptionPlan(
        id: old.id,
        name: old.name,
        price: newPrice,
        maxStudents: old.maxStudents,
        maxBranches: old.maxBranches,
        features: old.features,
      );
    }
  }

  @override
  Future<void> updateAcademySubscription(
    String academyId, {
    required String planId,
    required String planName,
    required int price,
    required String status,
    required DateTime renewalDate,
    required String billingCycle,
  }) async {
    updatedAcademyPlanName = planName;
    extendedRenewalDate = renewalDate;
    final index = _subscriptions.indexWhere((s) => s.academyId == academyId);
    if (index != -1) {
      _subscriptions[index] = _subscriptions[index].copyWith(
        planId: planId,
        planName: planName,
        price: price,
        status: status,
        renewalDate: renewalDate,
        billingCycle: billingCycle,
      );
    }
  }

  @override
  Future<void> recordPayment(SubscriptionPayment payment) async {
    paymentRecorded = true;
    _payments.add(payment);
  }

  @override
  Stream<List<SubscriptionPayment>> watchPayments({String? academyId}) =>
      Stream.value(_payments);
}

void main() {
  group('Subscriptions Module Tests', () {
    testWidgets('Mobile phone viewport (360px) does not overflow on TabBar or payments', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final fakeRepo = _FakeSubscriptionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: SubscriptionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Payments tab
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Renders subscription metrics, academies list, and allows searching/filtering',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeSubscriptionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: SubscriptionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Subscriptions & Billing'), findsOneWidget);

      // Verify Metrics (MRR from active subs: 15,000 + 10,000 = 25,000)
      expect(find.text('Monthly Revenue'), findsOneWidget);
      expect(find.text('Rs. 25,000'), findsOneWidget);
      expect(find.text('Active Subscriptions'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(
          find.widgetWithText(StatCard, 'Expiring Soon (≤7d)'), findsOneWidget);
      expect(
          find.widgetWithText(StatCard, 'Overdue / Expired'), findsOneWidget);

      // Verify Academy items in Tab 1
      expect(find.text('Premier Science Academy'), findsOneWidget);
      expect(find.text('Apex Grammar School'), findsOneWidget);
      expect(find.text('Oxford Elite College'), findsOneWidget);

      // Search for "Apex"
      final searchField =
          find.widgetWithText(TextField, 'Search academy by name or code...');
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Apex');
      await tester.pumpAndSettle();

      expect(find.text('Apex Grammar School'), findsOneWidget);
      expect(find.text('Premier Science Academy'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Premier Science Academy'), findsOneWidget);
    });

    testWidgets('Switches to Plans tab and renders all tiers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeSubscriptionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: SubscriptionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Plans tab
      await tester.tap(find.text('Plans (3)'));
      await tester.pumpAndSettle();

      // Verify plan cards
      expect(find.text('Basic'), findsWidgets);
      expect(find.text('Standard'), findsWidgets);
      expect(find.text('Premium'), findsWidgets);
      expect(find.text('MOST POPULAR'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Edit Plan Price'), findsWidgets);
    });

    testWidgets('Dedicated RecordPaymentScreen saves payment and renews', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeSubscriptionRepository();
      final sub = (await fakeRepo.getSubscriptions()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: RecordPaymentScreen(initialSubscription: sub),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Enter subscription fee receipt details'), findsOneWidget);

      // Verify academy name
      expect(find.text('Premier Science Academy'), findsWidgets);

      // Verify payment amount field
      final amountField = find.byType(TextFormField).first;
      expect(amountField, findsOneWidget);

      // Tap submit button
      await tester.tap(find.widgetWithText(FilledButton, 'Save Payment & Renew (+30d)'));
      await tester.pumpAndSettle();

      expect(fakeRepo.paymentRecorded, isTrue);
    });

    testWidgets('Dedicated ChangePlanScreen allows selecting tier and saving', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeSubscriptionRepository();
      final sub = (await fakeRepo.getSubscriptions()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: ChangePlanScreen(subscription: sub),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Change Subscription Plan'), findsOneWidget);
      expect(find.text('Monthly Billing'), findsOneWidget);
      expect(find.text('Annual (Yearly)'), findsNothing);

      // Tap on Premium plan
      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.widgetWithText(FilledButton, 'Save Plan Changes (Premium)'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatedAcademyPlanName, equals('Premium'));
    });

    testWidgets('Dedicated ExtendSubscriptionScreen adds duration and saves', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeSubscriptionRepository();
      final sub = (await fakeRepo.getSubscriptions()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: ExtendSubscriptionScreen(subscription: sub),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Extend Subscription'), findsOneWidget);
      expect(find.text('+1 Month (30d)'), findsOneWidget);
      expect(find.text('+2 Months (60d)'), findsOneWidget);
      expect(find.text('+3 Months (90d)'), findsOneWidget);
      expect(find.text('+1 Year (365d)'), findsNothing);

      // Tap +3 Months (90d)
      await tester.tap(find.text('+3 Months (90d)'));
      await tester.pumpAndSettle();

      // Tap Save Extension button
      final saveBtn = find.byType(FilledButton).first;
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.extendedRenewalDate, isNotNull);
    });

    testWidgets('Dedicated EditPlanPriceScreen updates plan fee', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeSubscriptionRepository();
      final plan = (await fakeRepo.getPlans()).first; // Basic

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: EditPlanPriceScreen(plan: plan),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Basic Fee'), findsOneWidget);

      // Enter new price
      final priceField = find.widgetWithText(TextFormField, '10000');
      await tester.enterText(priceField, '12500');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.widgetWithText(FilledButton, 'Save Updated Price'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatedPlanId, equals('basic'));
      expect(fakeRepo.updatedPrice, equals(12500));
    });
  });
}
