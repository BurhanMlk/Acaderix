import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/firestore_ext.dart';
import '../../../core/utils/id_generators.dart';
import '../domain/academy.dart';
import '../domain/academy_repository.dart';

/// Firestore-backed [AcademyRepository].
final class FirestoreAcademyRepository implements AcademyRepository {
  FirestoreAcademyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.academies);

  @override
  Stream<List<Academy>> watchAll() => _collection
      .orderBy('name')
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));

  @override
  Future<List<Academy>> getAll() async {
    final snapshot = await _collection.orderBy('name').get();
    return mapQueryDocs(snapshot, _fromDoc);
  }

  @override
  Future<Academy?> getById(String id) async {
    final snapshot = await _collection.doc(id).get();
    return mapDocument(snapshot, _fromDoc);
  }

  @override
  Future<void> create(Academy academy) {
    final data = toFirestoreData(academy.toJson())..remove('id');
    return _collection.doc(academy.id).set(data);
  }

  @override
  Future<void> updateStatus(String id, String status) {
    return _collection.doc(id).update({'status': status});
  }

  @override
  Future<String> createCustomAcademyWithPackage({
    required String academyName,
    required String academyCode,
    required String address,
    required String city,
    required String province,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerPhone,
    required int maxBranches,
    required int maxStudents,
    required int monthlyFee,
    String billingCycle = 'monthly',
    String status = 'active',
    String paymentStatus = 'paid',
    String? logoUrl,
    String? cnic,
  }) async {
    final cleanEmail = ownerEmail.trim();
    final cleanCode = (academyCode.trim().isNotEmpty
            ? academyCode.trim()
            : IdGenerators.generateAcademyCode())
        .toUpperCase();

    // 1. Verify academy code availability
    final codeDocRef =
        _firestore.collection(FirestorePaths.academyCodes).doc(cleanCode);
    final codeSnap = await codeDocRef.get();
    if (codeSnap.exists) {
      throw ServerException(
        'Academy code "$cleanCode" is already in use. Please enter a different code or leave blank to auto-generate.',
      );
    }

    // 2. Create the Academy Owner in Firebase Auth using a secondary isolated app instance
    // so the Super Admin is NOT logged out.
    String ownerUid = '';
    FirebaseApp? secondaryApp;
    final secondaryAppName =
        'SecondaryAuth_${DateTime.now().millisecondsSinceEpoch}';

    try {
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      try {
        final userCred = await secondaryAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: ownerPassword,
        );
        if (userCred.user != null) {
          await userCred.user!.updateDisplayName(ownerName.trim());
          ownerUid = userCred.user!.uid;
        }
      } on FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          // If the account was created during a previously failed batch write attempt,
          // verify credentials and check if it's an orphaned account without an academy.
          try {
            final existingCred = await secondaryAuth.signInWithEmailAndPassword(
              email: cleanEmail,
              password: ownerPassword,
            );
            if (existingCred.user != null) {
              final existingAcademySnap = await _firestore
                  .collection(FirestorePaths.academies)
                  .where('ownerUid', isEqualTo: existingCred.user!.uid)
                  .limit(1)
                  .get();
              if (existingAcademySnap.docs.isEmpty) {
                // Orphaned user from a previous interrupted creation: safely reuse
                await existingCred.user!.updateDisplayName(ownerName.trim());
                ownerUid = existingCred.user!.uid;
              } else {
                throw const ServerException(
                  'An account with this email address is already managing another academy.',
                );
              }
            }
          } catch (signInErr) {
            if (signInErr is AppException) rethrow;
            throw const ServerException(
              'An account with this email address already exists. Please use a different email or check the password.',
            );
          }
        } else {
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const ServerException(
          'An account with this email address already exists. Please use a different email.',
        );
      } else if (e.code == 'weak-password') {
        throw const ServerException(
          'Password is too weak. Please use at least 6 characters.',
        );
      } else if (e.code == 'invalid-email') {
        throw const ServerException('The email address format is invalid.');
      } else {
        throw ServerException(
            e.message ?? 'Failed to create owner auth account.');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to create owner account: $e');
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }

    if (ownerUid.isEmpty) {
      throw const ServerException('Failed to retrieve user ID for new owner.');
    }

    // 3. Prepare IDs and documents for atomic batch write
    final academyId = _firestore.collection(FirestorePaths.academies).doc().id;
    final branchId = const Uuid().v4();
    final now = DateTime.now();
    final renewalDate = now.add(
      billingCycle == 'quarterly'
          ? const Duration(days: 90)
          : billingCycle == 'yearly'
              ? const Duration(days: 365)
              : const Duration(days: 30),
    );

    final batch = _firestore.batch();

    // A. Root academy document
    final academyRef =
        _firestore.collection(FirestorePaths.academies).doc(academyId);
    batch.set(academyRef, {
      'name': academyName.trim(),
      'code': cleanCode,
      'ownerName': ownerName.trim(),
      'ownerEmail': cleanEmail,
      'ownerPhone': ownerPhone.trim(),
      'ownerUid': ownerUid,
      'cnic': cnic?.trim() ?? '',
      'address': address.trim(),
      'city': city.trim(),
      'province': province.trim(),
      'logoUrl': logoUrl?.trim() ?? '',
      'status': status,
      'branchCount': 1,
      'maxBranches': maxBranches,
      'maxStudents': maxStudents,
      'subscriptionPlan': 'Custom Package',
      'subscriptionPrice': monthlyFee,
      'monthlyFee': monthlyFee,
      'registrationDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // B. Academy code mapping
    batch.set(codeDocRef, {
      'academyId': academyId,
      'code': cleanCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // C. Owner user profile
    final userRef = _firestore.collection(FirestorePaths.users).doc(ownerUid);
    batch.set(userRef, {
      'role': 'academy_admin',
      'academyId': academyId,
      'email': cleanEmail,
      'displayName': ownerName.trim(),
      'phone': ownerPhone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // D. Academy subscription record
    final subRef =
        _firestore.collection(FirestorePaths.subscriptions).doc(academyId);
    batch.set(subRef, {
      'academyId': academyId,
      'academyName': academyName.trim(),
      'academyCode': cleanCode,
      'logoUrl': logoUrl?.trim() ?? '',
      'ownerEmail': cleanEmail,
      'ownerPhone': ownerPhone.trim(),
      'planId': 'custom',
      'planName': 'Custom Package',
      'price': monthlyFee,
      'status': status,
      'paymentStatus': paymentStatus,
      'billingCycle': billingCycle,
      'maxBranches': maxBranches,
      'maxStudents': maxStudents,
      'startDate': Timestamp.fromDate(now),
      'renewalDate': Timestamp.fromDate(renewalDate),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // E. Default Main Campus Branch
    final branchRef = academyRef.collection('branches').doc(branchId);
    batch.set(branchRef, {
      'id': branchId,
      'academyId': academyId,
      'name': 'Main Campus',
      'code': 'MAIN',
      'city': city.trim().isNotEmpty ? city.trim() : 'Campus',
      'address': address.trim(),
      'phone': ownerPhone.trim(),
      'email': cleanEmail,
      'isMainBranch': true,
      'isActive': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return academyId;
  }

  @override
  Future<void> updateOwnerEmail(String id, String newEmail) async {
    final trimmed = newEmail.trim();
    await _collection.doc(id).update({'ownerEmail': trimmed});
    try {
      final snapshot = await _collection.doc(id).get();
      final ownerUid = snapshot.data()?['ownerUid'] as String?;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(ownerUid)
            .set({'email': trimmed}, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  static const List<String> _subcollections = [
    'branches',
    'staff',
    'students',
    'guardians',
    'classes',
    'courses',
    'subjects',
    'batches',
    'enrollments',
    'attendance',
    'staff_attendance',
    'fee_structures',
    'fee_invoices',
    'fee_payments',
    'exams',
    'results',
    'homework',
    'timetables',
    'salaries',
    'expenses',
    'announcements',
    'audit_logs',
    'counters',
  ];

  @override
  Future<void> delete(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final code = data['code'] as String?;
    final ownerUid = data['ownerUid'] as String?;

    // 1. Cascade delete all documents across all subcollections under this academy
    for (final subcollection in _subcollections) {
      await _deleteSubcollectionDocs(id, subcollection);
    }

    // 2. Cascade delete owner profile and any other user profiles linked to this academy
    await _deleteAssociatedUsers(id, ownerUid);

    // 3. Delete academy code mapping (so the code can be claimed again)
    if (code != null && code.isNotEmpty) {
      try {
        await _firestore
            .collection(FirestorePaths.academyCodes)
            .doc(code.toUpperCase())
            .delete();
      } catch (_) {}
    }

    // 4. Finally, delete the root academy document
    await _collection.doc(id).delete();
  }

  Future<void> _deleteSubcollectionDocs(
    String academyId,
    String subcollection,
  ) async {
    try {
      final snapshot =
          await _collection.doc(academyId).collection(subcollection).get();
      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int count = 0;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> _deleteAssociatedUsers(
    String academyId,
    String? ownerUid,
  ) async {
    // Delete owner profile from users collection
    if (ownerUid != null && ownerUid.isNotEmpty) {
      try {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(ownerUid)
            .delete();
      } catch (_) {}
    }

    // Delete any other user documents assigned to this academy
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('academyId', isEqualTo: academyId)
          .get();
      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int count = 0;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (_) {}
  }

  Academy _fromDoc(String id, Map<String, dynamic> data) =>
      Academy.fromJson({...data, 'id': id});
}
