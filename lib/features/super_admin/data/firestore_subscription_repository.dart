import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../domain/subscription_models.dart';
import '../domain/subscription_repository.dart';

/// Production Firestore implementation of [SubscriptionRepository].
class FirestoreSubscriptionRepository implements SubscriptionRepository {
  FirestoreSubscriptionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _subsCol =>
      _firestore.collection(FirestorePaths.subscriptions);

  CollectionReference<Map<String, dynamic>> get _plansCol =>
      _firestore.collection(FirestorePaths.subscriptionPlans);

  CollectionReference<Map<String, dynamic>> get _paymentsCol =>
      _firestore.collection(FirestorePaths.subscriptionPayments);

  CollectionReference<Map<String, dynamic>> get _academiesCol =>
      _firestore.collection(FirestorePaths.academies);

  @override
  Stream<List<AcademySubscription>> watchSubscriptions() {
    late StreamController<List<AcademySubscription>> controller;
    StreamSubscription? academiesSub;
    StreamSubscription? subsSub;

    List<QueryDocumentSnapshot<Map<String, dynamic>>> lastAcademies = [];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> lastSubs = [];
    bool academiesLoaded = false;
    bool subsLoaded = false;

    void emitLatest() {
      if (!academiesLoaded || !subsLoaded) return;

      final existingSubsMap = <String, AcademySubscription>{
        for (final doc in lastSubs)
          doc.id: AcademySubscription.fromJson(doc.id, doc.data()),
      };

      final results = <AcademySubscription>[];

      for (final doc in lastAcademies) {
        final data = doc.data();
        final academyId = doc.id;
        final existing = existingSubsMap[academyId];

        if (existing != null) {
          // Merge latest academy name and logo
          results.add(existing.copyWith(
            academyName: (data['name'] as String?)?.isNotEmpty == true
                ? data['name']
                : existing.academyName,
            academyCode: (data['code'] as String?)?.isNotEmpty == true
                ? data['code']
                : existing.academyCode,
            logoUrl: (data['logoUrl'] as String?)?.isNotEmpty == true
                ? data['logoUrl']
                : existing.logoUrl,
            ownerEmail: (data['ownerEmail'] as String?)?.isNotEmpty == true
                ? data['ownerEmail']
                : existing.ownerEmail,
            ownerPhone: (data['ownerPhone'] as String?)?.isNotEmpty == true
                ? data['ownerPhone']
                : existing.ownerPhone,
          ));
        } else {
          // Synthesize from academy registration record
          final planName = data['subscriptionPlan'] as String? ?? 'Standard';
          final planPrice = (data['subscriptionPrice'] as num?)?.toInt() ??
              _defaultPriceForPlan(planName);
          final regDateRaw = data['registrationDate'];
          DateTime startDate = DateTime.now();
          if (regDateRaw is Timestamp) {
            startDate = regDateRaw.toDate();
          }

          final synthesized = AcademySubscription(
            id: academyId,
            academyId: academyId,
            academyName: data['name'] as String? ?? 'Unnamed Academy',
            academyCode: data['code'] as String? ?? 'ACD-???',
            logoUrl: data['logoUrl'] as String? ?? '',
            planId: planName.toLowerCase(),
            planName: planName,
            price: planPrice,
            status: data['status'] == 'suspended' ? 'expired' : 'active',
            startDate: startDate,
            renewalDate: startDate.add(const Duration(days: 30)),
            billingCycle: 'monthly',
            paymentStatus: 'paid',
            ownerEmail: data['ownerEmail'] as String? ?? '',
            ownerPhone: data['ownerPhone'] as String? ?? '',
          );

          results.add(synthesized);
        }
      }

      if (!controller.isClosed) {
        controller.add(results);
      }
    }

    controller = StreamController<List<AcademySubscription>>.broadcast(
      onListen: () {
        academiesSub = _academiesCol.snapshots().listen((snap) {
          lastAcademies = snap.docs;
          academiesLoaded = true;
          emitLatest();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        subsSub = _subsCol.snapshots().listen((snap) {
          lastSubs = snap.docs;
          subsLoaded = true;
          emitLatest();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });
      },
      onCancel: () {
        academiesSub?.cancel();
        subsSub?.cancel();
      },
    );

    return controller.stream;
  }

  int _defaultPriceForPlan(String name) {
    return switch (name.toLowerCase()) {
      'basic' => 10000,
      'premium' => 20000,
      _ => 15000,
    };
  }

  @override
  Future<List<AcademySubscription>> getSubscriptions() async {
    final list = await watchSubscriptions().first;
    return list;
  }

  @override
  Stream<List<SubscriptionPlan>> watchPlans() {
    return _plansCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return SubscriptionPlan.defaultPlans;
      }
      return snap.docs
          .map((doc) => SubscriptionPlan.fromJson(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final snap = await _plansCol.get();
    if (snap.docs.isEmpty) {
      return SubscriptionPlan.defaultPlans;
    }
    return snap.docs
        .map((doc) => SubscriptionPlan.fromJson(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> updatePlanPrice(String planId, int newPrice) async {
    final doc = _plansCol.doc(planId);
    final exists = (await doc.get()).exists;
    if (exists) {
      await doc.update({'price': newPrice});
    } else {
      // Find matching default plan to seed
      final defaultPlan = SubscriptionPlan.defaultPlans
          .firstWhere((p) => p.id == planId, orElse: () => SubscriptionPlan(id: planId, name: planId, price: newPrice));
      final map = defaultPlan.toJson();
      map['price'] = newPrice;
      await doc.set(map);
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
    final academyDoc = await _academiesCol.doc(academyId).get();
    final academyData = academyDoc.data() ?? {};

    final subDoc = _subsCol.doc(academyId);
    final existingSubSnap = await subDoc.get();
    final existingSub = existingSubSnap.data() ?? {};

    final name = (academyData['name'] as String?)?.isNotEmpty == true
        ? academyData['name']
        : (existingSub['academyName'] ?? '');
    final code = (academyData['code'] as String?)?.isNotEmpty == true
        ? academyData['code']
        : (existingSub['academyCode'] ?? '');
    final logo = (academyData['logoUrl'] as String?)?.isNotEmpty == true
        ? academyData['logoUrl']
        : (existingSub['logoUrl'] ?? '');
    final email = (academyData['ownerEmail'] as String?)?.isNotEmpty == true
        ? academyData['ownerEmail']
        : (existingSub['ownerEmail'] ?? '');
    final phone = (academyData['ownerPhone'] as String?)?.isNotEmpty == true
        ? academyData['ownerPhone']
        : (existingSub['ownerPhone'] ?? '');

    await subDoc.set({
      'academyId': academyId,
      'academyName': name,
      'academyCode': code,
      'logoUrl': logo,
      'planId': planId,
      'planName': planName,
      'price': price,
      'status': status,
      'renewalDate': Timestamp.fromDate(renewalDate),
      'billingCycle': billingCycle,
      'paymentStatus': status == 'active' ? 'paid' : 'overdue',
      'ownerEmail': email,
      'ownerPhone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also update academy document so registration info stays in sync
    if (academyDoc.exists) {
      await _academiesCol.doc(academyId).set({
        'subscriptionPlan': planName,
        'subscriptionPrice': price,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> recordPayment(SubscriptionPayment payment) async {
    final docRef = payment.id.isNotEmpty
        ? _paymentsCol.doc(payment.id)
        : _paymentsCol.doc();

    await docRef.set({
      'academyId': payment.academyId,
      'academyName': payment.academyName,
      'amount': payment.amount,
      'paymentDate': Timestamp.fromDate(payment.paymentDate),
      'paymentMethod': payment.paymentMethod,
      'referenceNumber': payment.referenceNumber,
      'notes': payment.notes,
      'status': payment.status,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Automatically advance renewal date by 30 days and set status to active
    final subDoc = _subsCol.doc(payment.academyId);
    final subSnap = await subDoc.get();
    if (subSnap.exists) {
      final currentRenewal = subSnap.data()?['renewalDate'];
      DateTime baseDate = DateTime.now();
      if (currentRenewal is Timestamp) {
        baseDate = currentRenewal.toDate();
        if (baseDate.isBefore(DateTime.now())) {
          baseDate = DateTime.now();
        }
      }
      await subDoc.update({
        'status': 'active',
        'paymentStatus': 'paid',
        'renewalDate': Timestamp.fromDate(baseDate.add(const Duration(days: 30))),
        'lastPaymentDate': Timestamp.fromDate(payment.paymentDate),
      });
    }
  }

  @override
  Stream<List<SubscriptionPayment>> watchPayments({String? academyId}) {
    Query<Map<String, dynamic>> query =
        _paymentsCol.orderBy('paymentDate', descending: true);
    if (academyId != null && academyId.isNotEmpty) {
      query = query.where('academyId', isEqualTo: academyId);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) => SubscriptionPayment.fromJson(doc.id, doc.data()))
        .toList());
  }
}
