import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/cloudinary_upload_service.dart';
import '../data/academy_registration_service.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Provides the active [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// Holds the application-wide authentication state.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.authStateChanges().listen(
      (value) => state = value,
      onError: (Object _) => state = const AuthState.unauthenticated(),
    );
    ref.onDispose(subscription.cancel);
    return const AuthState.unknown();
  }

  /// Signs in an academy admin or staff member.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    state = AuthState.authenticated(user);
    return user;
  }

  /// Signs in a student (or parent) using academy code, roll number and PIN.
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async {
    final user = await _repository.signInAsStudent(
      academyCode: academyCode,
      rollNumber: rollNumber,
      pin: pin,
    );
    state = AuthState.authenticated(user);
    return user;
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _repository.sendPasswordResetEmail(email);
  }

  /// Registers a new academy and provisions its Academy Admin.
  ///
  /// Creates the auth account, uploads the optional logo, writes the academy +
  /// owner profile to Firestore, then refreshes the session so the router
  /// sends the user to their academy dashboard.
  Future<AppUser> registerAcademy({
    required String email,
    required String password,
    required String academyName,
    required String address,
    required String cnic,
    required String ownerName,
    required String ownerPhone,
    required String planName,
    required int planPrice,
    Uint8List? logoBytes,
    String logoContentType = 'image/png',
  }) async {
    final user = await _repository.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String? logoUrl;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoUrl = await _uploadLogo(
        bytes: logoBytes,
        contentType: logoContentType,
      );
    }

    await ref.read(academyRegistrationServiceProvider).registerAcademy(
      uid: user.id,
      email: user.email,
      academyName: academyName,
      address: address,
      cnic: cnic,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      planName: planName,
      planPrice: planPrice,
      logoUrl: logoUrl,
    );

    final refreshed = await _repository.refreshCurrentUser();
    state = AuthState.authenticated(refreshed);
    return refreshed;
  }

  Future<String?> _uploadLogo({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final cloudinary = ref.read(cloudinaryUploadServiceProvider);
    return cloudinary.uploadImage(
      bytes,
      uploadPreset: Env.cloudinaryUploadPreset,
      fileName: _logoFileName(contentType),
    );
  }

  String _logoFileName(String contentType) {
    if (contentType.contains('png')) return 'logo.png';
    if (contentType.contains('jpeg') || contentType.contains('jpg')) {
      return 'logo.jpg';
    }
    if (contentType.contains('webp')) return 'logo.webp';
    if (contentType.contains('gif')) return 'logo.gif';
    return 'logo.png';
  }

  /// Signs out and clears the local session.
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }
}
