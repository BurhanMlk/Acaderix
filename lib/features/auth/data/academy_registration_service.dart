import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/firebase_services.dart';
import '../../../core/utils/id_generators.dart';

/// Creates a new academy and its first Academy Admin using Firestore only.
///
/// Registration writes three documents directly: the academy, its human
/// friendly academy code, and the owner's `users/{uid}` profile (which carries
/// the `academy_admin` role). No Cloud Functions are involved.
final academyRegistrationServiceProvider = Provider<AcademyRegistrationService>(
  (ref) => AcademyRegistrationService(ref.watch(firestoreProvider)),
);

final class AcademyRegistrationService {
  AcademyRegistrationService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Writes the academy, its code and the owner profile, returning the new
  /// academy id.
  Future<String> registerAcademy({
    required String uid,
    required String email,
    required String academyName,
    required String address,
    required String cnic,
    required String ownerName,
    required String ownerPhone,
    required String planName,
    required int planPrice,
    String? logoUrl,
  }) async {
    final academyId = _firestore
        .collection(FirestorePaths.academies)
        .doc()
        .id;

    try {
      await _firestore.runTransaction((transaction) async {
        final code = await _allocateCode(transaction, academyId);

        transaction.set(
          _firestore.doc(FirestorePaths.academy(academyId)),
          {
            'code': code,
            'name': academyName,
            'address': address,
            'ownerName': ownerName,
            'ownerEmail': email,
            'ownerPhone': ownerPhone,
            'cnic': cnic,
            'subscriptionPlan': planName,
            'subscriptionPrice': planPrice,
            'logoUrl': logoUrl ?? '',
            'ownerUid': uid,
            'status': 'active',
            'branchCount': 0,
            'registrationDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          _firestore.doc('${FirestorePaths.users}/$uid'),
          {
            'role': 'academy_admin',
            'academyId': academyId,
            'email': email,
          },
        );
      });
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        'Could not create your academy. Please try again.',
      );
    }

    return academyId;
  }

  /// Finds an unused academy code within the transaction.
  Future<String> _allocateCode(
    Transaction transaction,
    String academyId,
  ) async {
    for (var i = 0; i < 5; i++) {
      final candidate = IdGenerators.generateAcademyCode();
      final codeRef = _firestore.doc(
        '${FirestorePaths.academyCodes}/$candidate',
      );
      final snapshot = await transaction.get(codeRef);
      if (!snapshot.exists) {
        transaction.set(codeRef, {'academyId': academyId});
        return candidate;
      }
    }
    throw const ServerException('Could not allocate a unique academy code.');
  }
}
