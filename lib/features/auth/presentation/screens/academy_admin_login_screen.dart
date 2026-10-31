import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../academy_admin/application/academy_access_provider.dart';
import '../../../academy_admin/domain/academy_access_models.dart';
import '../../application/auth_controller.dart';

/// Email/password sign in for academy administrators.
class AcademyAdminLoginScreen extends ConsumerStatefulWidget {
  const AcademyAdminLoginScreen({super.key});

  @override
  ConsumerState<AcademyAdminLoginScreen> createState() =>
      _AcademyAdminLoginScreenState();
}

class _AcademyAdminLoginScreenState
    extends ConsumerState<AcademyAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;

      // 1. Pre-login verification: First use the admin email info to locate the
      // academy and check its status BEFORE signing in and issuing any token.
      AcademyAccessInfo? access;
      try {
        final accessRepo = ref.read(academyAccessRepositoryProvider);
        access = await accessRepo.findAndCheckAcademyByEmail(email);
      } catch (_) {
        // If unauthenticated Firestore queries are denied by remote security rules,
        // fallback to post-login verification with immediate token revocation if inactive.
        access = null;
      }

      if (!mounted) return;

      // 2. If pre-login verified that academy is not active:
      // DO NOT SIGN IN. DO NOT ISSUE TOKEN.
      if (access != null && !access.isActive) {
        context.push(
          AppRoutes.academyStatus,
          extra: access,
        );
        return;
      }

      // 3. Authenticate credentials:
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          );
      if (!mounted) return;

      // 4. If pre-login check was not possible due to remote rules, verify now with auth:
      if (access == null) {
        try {
          final postLoginAccess = await ref.read(academyAccessProvider.future);
          if (!postLoginAccess.isActive) {
            // Academy is not active! Immediately revoke token and clear session!
            await ref.read(authControllerProvider.notifier).signOut();
            if (mounted) {
              context.push(AppRoutes.academyStatus, extra: postLoginAccess);
            }
            return;
          }
        } catch (_) {}
      }

      if (mounted) context.go(homeForRole(user.role));
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          IconButton(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const GlassLoginHeader(
            icon: Icons.apartment_outlined,
            title: 'Academy Admin Login',
            subtitle: 'Sign in to manage your academy',
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassTextField(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _password,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.required(v, 'Password'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    GlassError(message: _error!),
                  ],
                  const SizedBox(height: 16),
                  LoadingButton(
                    label: 'Sign In',
                    icon: Icons.login,
                    loading: _loading,
                    onPressed: _submit,
                    style: glassPrimaryButtonStyle(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
