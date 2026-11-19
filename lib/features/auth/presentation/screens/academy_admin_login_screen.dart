import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/roles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../academy_admin/application/academy_access_provider.dart';
import '../../../academy_admin/domain/academy_access_models.dart';
import '../../application/auth_controller.dart';

/// Unified email/password sign in for Super Administrators and Academy Administrators.
///
/// Automatically detects whether the signed-in account is a Super Admin or
/// Academy Admin and redirects to the corresponding dashboard.
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
  bool _obscurePassword = true;
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

      // 2. If pre-login verified that an academy exists and is not active:
      // DO NOT SIGN IN. DO NOT ISSUE TOKEN.
      // Note: Super Admin emails have no academy (AcademyAccessState.notFound),
      // so they proceed to authentication and role auto-detection.
      if (access != null &&
          !access.isActive &&
          access.state != AcademyAccessState.notFound) {
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

      if (user.role == AppRole.unauthenticated) {
        await ref.read(authControllerProvider.notifier).signOut();
        if (mounted) {
          setState(() {
            _error = 'Account role not recognized. Please contact support.';
          });
        }
        return;
      }

      // 4. For Academy Admins, if pre-login check was not possible or returned
      // notFound, verify academy access now with auth:
      if (user.role == AppRole.academyAdmin &&
          (access == null || access.state == AcademyAccessState.notFound)) {
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
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const GlassLoginHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Login',
            subtitle: 'Sign in with your admin email to continue',
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
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.required(v, 'Password'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
