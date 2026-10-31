import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/constants/roles.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Firebase Authentication backed repository.
///
/// The authenticated account lives in Firebase Auth, while the user's role and
/// academy context are stored as a plain document in Firestore
/// (`users/{uid}`). This keeps the backend to Auth + Firestore only — no Cloud
/// Functions are required.
final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthState> authStateChanges() {
    return _auth.authStateChanges().asyncMap(_toAuthState);
  }

  @override
  Future<AuthState> currentState() async {
    return _toAuthState(_auth.currentUser);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Unable to complete sign in.');
      }
      return await _toAppUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Unable to create account.');
      }
      return await _toAppUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AppUser> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.');
    }
    return await _toAppUser(user);
  }

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async {
    try {
      // The caller must be a trusted Cloud Function:
      //   functions/src/studentAuth.ts (added in a later phase).
      final token = await _requestStudentCustomToken(
        academyCode: academyCode,
        rollNumber: rollNumber,
        pin: pin,
      );
      final credential = await _auth.signInWithCustomToken(token);
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Unable to complete student sign in.');
      }
      return await _toAppUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('No user is currently signed in.');
    }
    if (newPassword.length < 8) {
      throw const AuthException(
        'New password must be at least 8 characters.',
        code: 'weak-password',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthException(
          'Current password is incorrect.',
          code: 'wrong-password',
        );
      }
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  /// Requests a custom token from the student-auth Cloud Function.
  ///
  /// Implemented in Phase 5 alongside the Cloud Function. Until then the
  /// callable name and payload are fixed so the client contract is stable.
  Future<String> _requestStudentCustomToken({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async {
    throw const AuthException(
      'Student sign in requires the student-auth Cloud Function '
      '(deployed in a later phase).',
      code: 'student-auth-not-deployed',
    );
  }

  Future<AuthState> _toAuthState(User? user) async {
    if (user == null) return const AuthState.unauthenticated();
    return AuthState.authenticated(await _toAppUser(user));
  }

  Future<AppUser> _toAppUser(User user) async {
    final tokenResult = await user.getIdTokenResult();
    final claimRole = tokenResult.claims?['role'] as String?;

    Map<String, dynamic> data = const {};
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .get();
      data = snapshot.data() ?? const {};
    } catch (_) {}

    final roleId = (data['role'] as String?) ?? claimRole;

    if (data.isEmpty && roleId != null) {
      try {
        await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
          'email': user.email ?? '',
          'role': roleId,
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    final merged = Map<String, dynamic>.of(data);
    if (roleId != null) merged['role'] = roleId;

    if (merged['academyId'] == null &&
        (roleId == 'academy_admin' || roleId == 'staff')) {
      try {
        final query = await _firestore
            .collection(FirestorePaths.academies)
            .where('ownerUid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          merged['academyId'] = query.docs.first.id;
        } else if (user.email != null && user.email!.isNotEmpty) {
          final queryEmail = await _firestore
              .collection(FirestorePaths.academies)
              .where('ownerEmail', isEqualTo: user.email!.trim().toLowerCase())
              .limit(1)
              .get();
          if (queryEmail.docs.isNotEmpty) {
            merged['academyId'] = queryEmail.docs.first.id;
          }
        }
        if (merged['academyId'] != null) {
          await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
            'academyId': merged['academyId'],
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    }

    return _appUserFromDoc(user, merged);
  }

  AppUser _appUserFromDoc(User user, Map<String, dynamic> data) {
    return AppUser(
      id: user.uid,
      email: user.email ?? data['email'] as String? ?? '',
      displayName: user.displayName ?? '',
      role: AppRole.fromId(data['role'] as String?),
      academyId: data['academyId'] as String?,
      branchId: data['branchId'] as String?,
      rollNumber: data['rollNumber'] as String?,
    );
  }

  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          'Incorrect email or password.',
          code: 'invalid-credentials',
        );
      case 'invalid-email':
        return const AuthException(
          'Enter a valid email address.',
          code: 'invalid-email',
        );
      case 'email-already-in-use':
        return const AuthException(
          'This email is already registered. Try signing in instead.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthException(
          'Password must be at least 8 characters.',
          code: 'weak-password',
        );
      case 'user-disabled':
        return const AuthException(
          'This account has been disabled. Contact your administrator.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please try again later.',
          code: 'too-many-requests',
        );
      case 'operation-not-allowed':
        return const AuthException(
          'Sign-in is not enabled for this project yet. '
          'Enable the Email/Password provider in the Firebase console.',
          code: 'provider-disabled',
        );
      case 'network-request-failed':
        return const AuthException(
          'Network error. Check your connection and try again.',
          code: 'network-error',
        );
      default:
        return AuthException(
          'Sign in failed: ${e.message ?? e.code}',
          code: e.code,
        );
    }
  }
}
