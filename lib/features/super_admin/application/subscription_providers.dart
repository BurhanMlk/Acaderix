import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/firebase_services.dart';
import '../data/firestore_subscription_repository.dart';
import '../domain/subscription_models.dart';
import '../domain/subscription_repository.dart';

/// Provides the active [SubscriptionRepository].
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => FirestoreSubscriptionRepository(ref.watch(firestoreProvider)),
);

/// Live stream of all academy subscriptions.
final subscriptionsStreamProvider = StreamProvider<List<AcademySubscription>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).watchSubscriptions(),
);

/// Live stream of all platform subscription plans.
final subscriptionPlansStreamProvider = StreamProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).watchPlans(),
);

/// Live stream of subscription payment receipts.
final subscriptionPaymentsStreamProvider =
    StreamProvider<List<SubscriptionPayment>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).watchPayments(),
);
