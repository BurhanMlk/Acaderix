import 'app_user.dart';
import 'auth_state.dart';

/// Abstraction over the authentication backend.
///
/// The Firebase implementation lives in `data/firebase_auth_repository.dart`.
/// A development placeholder is used until Firebase is configured.
abstract interface class AuthRepository {
  /// Emits the current auth state and subsequent changes.
  Stream<AuthState> authStateChanges();

  /// Resolves the current auth state once.
  Future<AuthState> currentState();

  /// Signs the current user out.
  Future<void> signOut();

  /// Signs in an academy admin or staff member with email/password.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a new email/password account and signs it in.
  ///
  /// Used by the academy registration flow. The returned user has no role yet;
  /// the role is written to Firestore afterwards.
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Re-reads the signed-in user's Firestore profile so a newly-written role
  /// (role, academyId) becomes visible to the app.
  Future<AppUser> refreshCurrentUser();

  /// Signs in a student using academy code, roll number and PIN/password.
  ///
  /// The real implementation exchanges verified credentials for a Firebase
  /// custom token via a privileged Cloud Function.
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  });

  /// Sends a password reset email for the given address.
  Future<void> sendPasswordResetEmail(String email);

  /// Changes the signed-in user's password after verifying the old password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
