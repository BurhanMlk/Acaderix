import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/constants/roles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/security_utils.dart';
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

  AppUser? _staffSessionUser;
  AppUser? _studentSessionUser;
  final _sessionController = StreamController<AuthState>.broadcast();

  AppUser? get _activeSessionUser => _staffSessionUser ?? _studentSessionUser;

  @override
  Stream<AuthState> authStateChanges() async* {
    if (_activeSessionUser != null) {
      yield AuthState.authenticated(_activeSessionUser!);
    } else {
      yield await currentState();
    }
    final controller = StreamController<AuthState>();
    final sub1 = _auth.authStateChanges().asyncMap((user) async {
      if (_activeSessionUser != null) {
        return AuthState.authenticated(_activeSessionUser!);
      }
      return _toAuthState(user);
    }).listen(controller.add, onError: controller.addError);
    final sub2 = _sessionController.stream.listen(
      controller.add,
      onError: controller.addError,
    );

    try {
      yield* controller.stream;
    } finally {
      await sub1.cancel();
      await sub2.cancel();
      await controller.close();
    }
  }

  @override
  Future<AuthState> currentState() async {
    if (_activeSessionUser != null) {
      return AuthState.authenticated(_activeSessionUser!);
    }
    return _toAuthState(_auth.currentUser);
  }

  @override
  Future<void> signOut() async {
    _staffSessionUser = null;
    _studentSessionUser = null;
    _sessionController.add(const AuthState.unauthenticated());
    await _auth.signOut();
  }

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
      _staffSessionUser = null;
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
      _staffSessionUser = null;
      return await _toAppUser(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AppUser> refreshCurrentUser() async {
    if (_staffSessionUser != null) return _staffSessionUser!;
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
    final cleanCode = academyCode.trim().toUpperCase();
    final cleanRoll = rollNumber.trim();
    final cleanPin = pin.trim();

    if (cleanCode.isEmpty) {
      throw const AuthException('Please enter the Academy Code.');
    }
    if (cleanRoll.isEmpty) {
      throw const AuthException('Please enter your Roll Number.');
    }
    if (cleanPin.isEmpty) {
      throw const AuthException('Please enter your PIN or Password.');
    }

    try {
      // 1. Resolve academyId
      String academyId = '';
      try {
        final codeSnap = await _firestore
            .collection(FirestorePaths.academyCodes)
            .doc(cleanCode)
            .get();
        if (codeSnap.exists) {
          academyId = codeSnap.data()?['academyId'] as String? ?? '';
        }
      } catch (_) {}

      if (academyId.isEmpty) {
        try {
          final queryAcad = await _firestore
              .collection(FirestorePaths.academies)
              .where('code', isEqualTo: cleanCode)
              .limit(1)
              .get();
          if (queryAcad.docs.isNotEmpty) {
            academyId = queryAcad.docs.first.id;
          }
        } catch (_) {}
      }

      // Check student_accounts collection fallback
      DocumentSnapshot<Map<String, dynamic>>? studentAccSnap;
      try {
        final studentAccDocId = '${cleanCode}_$cleanRoll';
        var snap = await _firestore
            .collection('student_accounts')
            .doc(studentAccDocId)
            .get();
        if (!snap.exists && academyId.isNotEmpty) {
          snap = await _firestore
              .collection('student_accounts')
              .doc('${academyId}_$cleanRoll')
              .get();
        }
        if (snap.exists) {
          studentAccSnap = snap;
          if (academyId.isEmpty) {
            academyId = snap.data()?['academyId'] as String? ?? '';
          }
        }
      } catch (_) {}

      if (academyId.isEmpty && studentAccSnap == null) {
        throw const AuthException(
          'Academy code not recognized. Please check your Academy Code or contact the administration.',
          code: 'academy-not-found',
        );
      }

      // 2. Resolve Student Record
      String studentId = '';
      String studentName = 'Student';
      String? branchId;
      String? storedPin;
      String status = 'active';

      if (studentAccSnap != null && studentAccSnap.exists) {
        final accData = studentAccSnap.data() ?? {};
        studentId = accData['studentDocId'] as String? ?? cleanRoll;
        studentName = accData['fullName'] as String? ?? 'Student';
        branchId = accData['branchId'] as String?;
        storedPin = (accData['pin'] ?? accData['pinHash']) as String?;
        status = accData['status'] as String? ?? 'active';
      }

      if (academyId.isNotEmpty) {
        try {
          final studentQuery = await _firestore
              .collection(FirestorePaths.students(academyId))
              .where('rollNumber', isEqualTo: cleanRoll)
              .limit(1)
              .get();

          if (studentQuery.docs.isNotEmpty) {
            final doc = studentQuery.docs.first;
            final sData = doc.data();
            studentId = doc.id;
            studentName = sData['fullName'] as String? ?? studentName;
            branchId = sData['branchId'] as String? ?? branchId;
            storedPin ??= (sData['pin'] ?? sData['pinHash']) as String?;
            status = sData['status'] as String? ?? status;
          }
        } catch (_) {}
      }

      if (studentId.isEmpty) {
        throw AuthException(
          'Student with Roll Number "$cleanRoll" not found in this academy.',
          code: 'student-not-found',
        );
      }

      if (status != 'active') {
        throw const AuthException(
          'Your student account is currently marked inactive. Please contact the administration.',
          code: 'student-inactive',
        );
      }

      // 3. Verify PIN / Password
      // If student has a stored PIN, check exact match or hashed match.
      // If student has no stored PIN yet, allow '1234' or cleanRoll as default credentials.
      final validPin = (storedPin != null && storedPin.isNotEmpty)
          ? SecurityUtils.verifyPin(cleanPin, storedPin)
          : (cleanPin == '1234' || cleanPin == cleanRoll);

      if (!validPin) {
        throw const AuthException(
          'Incorrect PIN / Password. Please check your credentials.',
          code: 'wrong-pin',
        );
      }

      // 4. Verify Academy Active Status (if academyId is known)
      if (academyId.isNotEmpty) {
        try {
          final acadSnap = await _firestore
              .collection(FirestorePaths.academies)
              .doc(academyId)
              .get();
          if (acadSnap.exists) {
            final acadStatus = acadSnap.data()?['status'] as String? ?? 'active';
            if (acadStatus != 'active') {
              throw const AuthException(
                'Your academy account is currently inactive or suspended. Please contact the administrator.',
                code: 'academy-inactive',
              );
            }
          }
        } catch (_) {}
      }

      final appUser = AppUser(
        id: studentId,
        email: '${cleanRoll.toLowerCase()}@student.acaderix.internal',
        displayName: studentName,
        role: AppRole.student,
        academyId: academyId.isNotEmpty ? academyId : null,
        branchId: branchId,
        rollNumber: cleanRoll,
        isActive: true,
      );

      _studentSessionUser = appUser;
      _staffSessionUser = null;
      _sessionController.add(AuthState.authenticated(appUser));
      return appUser;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to sign in as student: $e');
    }
  }

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) {
      throw const AuthException('Please enter your Staff ID or Email.');
    }
    if (password.isEmpty) {
      throw const AuthException('Please enter your password.');
    }

    // 1. If identifier is an email and user exists in Firebase Auth, attempt standard auth
    if (cleanId.contains('@')) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: cleanId,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          final appUser = await _toAppUser(user);
          if (appUser.role == AppRole.staff) {
            _staffSessionUser = null;
            return appUser;
          }
        }
      } catch (_) {
        // Fallback to checking staff_accounts collection below
      }
    }

    // 2. Query staff_accounts by Staff ID (case-insensitive) or by email
    try {
      DocumentSnapshot<Map<String, dynamic>> snap;
      if (!cleanId.contains('@')) {
        snap = await _firestore
            .collection('staff_accounts')
            .doc(cleanId.toUpperCase())
            .get();
      } else {
        final query = await _firestore
            .collection('staff_accounts')
            .where('email', isEqualTo: cleanId.toLowerCase())
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          throw const AuthException(
            'Staff account not found. Please contact your Academy Administrator.',
            code: 'staff-not-found',
          );
        }
        snap = query.docs.first;
      }

      if (!snap.exists) {
        throw const AuthException(
          'Staff ID not found. Please verify your Staff ID or contact your Academy Administrator.',
          code: 'staff-not-found',
        );
      }

      final data = snap.data() ?? {};
      final storedPassword =
          (data['password'] ?? data['passwordHash']) as String? ?? '';
      final status = data['status'] as String? ?? 'active';

      if (status != 'active') {
        throw const AuthException(
          'Your staff account is currently inactive. Please contact your Academy Administrator.',
          code: 'staff-inactive',
        );
      }

      if (storedPassword.isEmpty ||
          !SecurityUtils.verifyPassword(password, storedPassword)) {
        throw const AuthException(
          'Incorrect password. Please verify your credentials and try again.',
          code: 'wrong-password',
        );
      }

      final academyId = data['academyId'] as String? ?? '';

      // Check academy active standing
      if (academyId.isNotEmpty) {
        final acadSnap = await _firestore
            .collection(FirestorePaths.academies)
            .doc(academyId)
            .get();
        if (acadSnap.exists) {
          final acadStatus = acadSnap.data()?['status'] as String? ?? 'active';
          if (acadStatus != 'active') {
            throw const AuthException(
              'Your academy account is currently inactive or suspended. Please contact the administrator.',
              code: 'academy-inactive',
            );
          }
        }
      }

      final staffCode = data['staffId'] as String? ?? cleanId.toUpperCase();
      final appUser = AppUser(
        id: data['staffDocId'] as String? ?? staffCode,
        email:
            data['email'] as String? ??
            '${staffCode.toLowerCase()}@staff.acaderix.internal',
        displayName: data['fullName'] as String? ?? 'Staff Member',
        role: AppRole.staff,
        academyId: academyId.isNotEmpty ? academyId : null,
        branchId: data['branchId'] as String?,
        rollNumber: staffCode,
        isActive: true,
      );

      _staffSessionUser = appUser;
      _sessionController.add(AuthState.authenticated(appUser));
      return appUser;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Failed to sign in as staff: $e');
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
