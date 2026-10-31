import 'subscription_models.dart';

/// Contract for managing platform subscriptions, plans, and payment records.
abstract interface class SubscriptionRepository {
  /// Stream live subscriptions across all academies.
  Stream<List<AcademySubscription>> watchSubscriptions();

  /// Retrieve all current subscriptions once.
  Future<List<AcademySubscription>> getSubscriptions();

  /// Stream platform plans (Basic, Standard, Premium, Custom).
  Stream<List<SubscriptionPlan>> watchPlans();

  /// Retrieve platform plans once.
  Future<List<SubscriptionPlan>> getPlans();

  /// Update an existing plan's monthly price in PKR.
  Future<void> updatePlanPrice(String planId, int newPrice);

  /// Change an academy's subscription plan, status, renewal date, or billing cycle.
  Future<void> updateAcademySubscription(
    String academyId, {
    required String planId,
    required String planName,
    required int price,
    required String status,
    required DateTime renewalDate,
    required String billingCycle,
  });

  /// Record an incoming subscription payment from an academy.
  Future<void> recordPayment(SubscriptionPayment payment);

  /// Stream payment receipts across the platform or for a specific academy.
  Stream<List<SubscriptionPayment>> watchPayments({String? academyId});
}
