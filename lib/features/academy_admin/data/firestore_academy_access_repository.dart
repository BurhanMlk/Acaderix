import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../domain/academy_access_models.dart';
import '../domain/academy_access_repository.dart';

/// Production Firestore implementation of [AcademyAccessRepository].
class FirestoreAcademyAccessRepository implements AcademyAccessRepository {
  FirestoreAcademyAccessRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<AcademyAccessInfo> watchAcademyAccess(String academyId) {
    if (academyId.isEmpty) {
      return Stream.value(const AcademyAccessInfo(
        state: AcademyAccessState.notFound,
        academyId: '',
        statusReason: 'No academy linked to this account.',
      ));
    }

    final academyDocRef =
        _firestore.collection(FirestorePaths.academies).doc(academyId);
    final subDocRef =
        _firestore.collection(FirestorePaths.subscriptions).doc(academyId);

    late StreamController<AcademyAccessInfo> controller;
    StreamSubscription? academySub;
    StreamSubscription? subSub;

    DocumentSnapshot<Map<String, dynamic>>? lastAcademySnap;
    DocumentSnapshot<Map<String, dynamic>>? lastSubSnap;
    bool academyLoaded = false;
    bool subLoaded = false;

    void emitLatest() {
      if (!academyLoaded || !subLoaded) return;

      final academyData = lastAcademySnap?.data();
      if (lastAcademySnap == null ||
          !lastAcademySnap!.exists ||
          academyData == null) {
        if (!controller.isClosed) {
          controller.add(AcademyAccessInfo(
            state: AcademyAccessState.notFound,
            academyId: academyId,
            statusReason: 'Academy record not found on the platform.',
          ));
        }
        return;
      }

      final subData = lastSubSnap?.data();
      final info = _evaluateAccess(academyId, academyData, subData);
      if (!controller.isClosed) {
        controller.add(info);
      }
    }

    controller = StreamController<AcademyAccessInfo>.broadcast(
      onListen: () {
        academySub = academyDocRef.snapshots().listen((snap) {
          lastAcademySnap = snap;
          academyLoaded = true;
          emitLatest();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        subSub = subDocRef.snapshots().listen((snap) {
          lastSubSnap = snap;
          subLoaded = true;
          emitLatest();
        }, onError: (_) {
          // If subscription doc does not exist, synthesized from academy
          subLoaded = true;
          emitLatest();
        });
      },
      onCancel: () {
        academySub?.cancel();
        subSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<AcademyAccessInfo> getAcademyAccess(String academyId) async {
    if (academyId.isEmpty) {
      return const AcademyAccessInfo(
        state: AcademyAccessState.notFound,
        academyId: '',
        statusReason: 'No academy linked to this account.',
      );
    }

    final academySnap = await _firestore
        .collection(FirestorePaths.academies)
        .doc(academyId)
        .get();
    if (!academySnap.exists || academySnap.data() == null) {
      return AcademyAccessInfo(
        state: AcademyAccessState.notFound,
        academyId: academyId,
        statusReason: 'Academy record not found on the platform.',
      );
    }

    Map<String, dynamic>? subData;
    try {
      final subSnap = await _firestore
          .collection(FirestorePaths.subscriptions)
          .doc(academyId)
          .get();
      if (subSnap.exists) subData = subSnap.data();
    } catch (_) {}

    return _evaluateAccess(academyId, academySnap.data()!, subData);
  }

  AcademyAccessInfo _evaluateAccess(
    String academyId,
    Map<String, dynamic> academyData,
    Map<String, dynamic>? subData,
  ) {
    final academyName = academyData['name'] as String? ?? 'Academy';
    final academyCode = academyData['code'] as String? ?? '';
    final rawStatus =
        (academyData['status'] as String? ?? 'pending').toLowerCase();
    final planName = academyData['subscriptionPlan'] as String? ?? 'Standard';

    // 1. Check raw academy approval status
    if (rawStatus == 'pending') {
      return AcademyAccessInfo(
        state: AcademyAccessState.pending,
        academyId: academyId,
        academyName: academyName,
        academyCode: academyCode,
        rawStatus: rawStatus,
        planName: planName,
        statusReason:
            'Your academy registration is awaiting approval from the platform administration.',
      );
    }

    if (rawStatus == 'suspended') {
      return AcademyAccessInfo(
        state: AcademyAccessState.suspended,
        academyId: academyId,
        academyName: academyName,
        academyCode: academyCode,
        rawStatus: rawStatus,
        planName: planName,
        statusReason:
            'This academy has been suspended by the platform administrator.',
      );
    }

    // 2. Check subscription details
    DateTime? renewalDate;
    String paymentStatus = 'paid';

    if (subData != null) {
      final rawRenewal = subData['renewalDate'];
      if (rawRenewal is Timestamp) {
        renewalDate = rawRenewal.toDate();
      } else if (rawRenewal is String) {
        renewalDate = DateTime.tryParse(rawRenewal);
      }
      paymentStatus =
          (subData['paymentStatus'] as String? ?? 'paid').toLowerCase();
    } else {
      // Synthesize from registration date
      final regRaw = academyData['registrationDate'];
      DateTime start = DateTime.now();
      if (regRaw is Timestamp) start = regRaw.toDate();
      renewalDate = start.add(const Duration(days: 30));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysRemaining = renewalDate != null
        ? renewalDate.difference(today).inDays
        : 30;

    // Check if expired
    if (daysRemaining < 0) {
      return AcademyAccessInfo(
        state: AcademyAccessState.expired,
        academyId: academyId,
        academyName: academyName,
        academyCode: academyCode,
        rawStatus: rawStatus,
        renewalDate: renewalDate,
        paymentStatus: paymentStatus,
        planName: planName,
        statusReason:
            'Subscription period has expired. Please contact Super Admin to renew your monthly plan.',
      );
    }

    // Check payment status
    if (paymentStatus != 'paid') {
      return AcademyAccessInfo(
        state: AcademyAccessState.expired,
        academyId: academyId,
        academyName: academyName,
        academyCode: academyCode,
        rawStatus: rawStatus,
        renewalDate: renewalDate,
        paymentStatus: paymentStatus,
        planName: planName,
        statusReason:
            'Subscription fee payment is pending clearance. Please contact Super Admin.',
      );
    }

    // All conditions met: active, not expired, payment done!
    return AcademyAccessInfo(
      state: AcademyAccessState.active,
      academyId: academyId,
      academyName: academyName,
      academyCode: academyCode,
      rawStatus: rawStatus,
      renewalDate: renewalDate,
      paymentStatus: paymentStatus,
      planName: planName,
      statusReason: 'Active',
    );
  }
}
