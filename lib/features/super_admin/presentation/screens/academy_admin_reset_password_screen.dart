import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/academy_repository_provider.dart';
import '../../domain/academy.dart';
import '../widgets/academy_avatar.dart';

/// Dedicated screen inside Super Admin shell to send a password reset link
/// to an Academy Admin's registered email.
class AcademyAdminResetPasswordScreen extends ConsumerStatefulWidget {
  const AcademyAdminResetPasswordScreen({
    super.key,
    this.initialAcademy,
    this.academyId,
  });

  final Academy? initialAcademy;
  final String? academyId;

  @override
  ConsumerState<AcademyAdminResetPasswordScreen> createState() =>
      _AcademyAdminResetPasswordScreenState();
}

class _AcademyAdminResetPasswordScreenState
    extends ConsumerState<AcademyAdminResetPasswordScreen> {
  Academy? _academy;
  bool _isLoading = false;
  bool _isSendingReset = false;
  String? _fetchError;
  String? _actionError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _academy = widget.initialAcademy;
    if (_academy == null && widget.academyId != null) {
      _fetchAcademy(widget.academyId!);
    }
  }

  Future<void> _fetchAcademy(String id) async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      final fetched = await ref.read(academyRepositoryProvider).getById(id);
      if (mounted) {
        setState(() {
          _academy = fetched;
          if (fetched == null) {
            _fetchError = 'Academy not found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetchError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final academy = _academy;
    if (academy == null) return;

    final targetEmail = academy.ownerEmail.trim();
    if (targetEmail.isEmpty) {
      setState(() {
        _actionError =
            'No administrator email is registered for this academy. An email is required to send a password reset link.';
      });
      return;
    }

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Send Password Reset Link',
      message:
          'Send an official Firebase password reset link to "$targetEmail" for "${academy.name}"?\n\nThe administrator will be able to follow the link to set their new password.',
      confirmLabel: 'Send Reset Link',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isSendingReset = true;
      _actionError = null;
      _successMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(targetEmail);

      if (mounted) {
        setState(() {
          _successMessage =
              'Password reset email sent to "$targetEmail"! The academy administrator can open the link in their inbox to establish their new password.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $targetEmail'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is AppException) {
            _actionError = e.message;
          } else {
            _actionError =
                e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              Skeleton(height: 28, width: 200),
              SizedBox(height: 24),
              Skeleton(height: 120),
              SizedBox(height: 24),
              Skeleton(height: 200),
            ],
          ),
        ),
      );
    }

    if (_fetchError != null || _academy == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: _fetchError ?? 'Unable to find academy.',
              onRetry: widget.academyId != null
                  ? () => _fetchAcademy(widget.academyId!)
                  : null,
            ),
          ),
        ),
      );
    }

    final academy = _academy!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header with Back button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.academiesList);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Admin Password',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send password reset email for ${academy.name.isEmpty ? "Academy Admin" : academy.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Academy & Administrator Profile Summary Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcademyAvatar(
                      name: academy.name,
                      logoUrl: academy.logoUrl,
                      size: 56,
                      borderRadius: 14,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  academy.name.isEmpty
                                      ? 'Unnamed Academy'
                                      : academy.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  academy.code,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            theme,
                            icon: Icons.person_outline,
                            label: 'Administrator',
                            value: academy.ownerName.isEmpty
                                ? 'Not specified'
                                : academy.ownerName,
                          ),
                          const SizedBox(height: 4),
                          _infoRow(
                            theme,
                            icon: Icons.email_outlined,
                            label: 'Admin Email',
                            value: academy.ownerEmail.isEmpty
                                ? 'No email registered'
                                : academy.ownerEmail,
                            highlightValue: academy.ownerEmail.isNotEmpty,
                          ),
                          if (academy.ownerPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _infoRow(
                              theme,
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: academy.ownerPhone,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status feedback banners
            if (_actionError != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _actionError!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: theme.colorScheme.onErrorContainer,
                      onPressed: () => setState(() => _actionError = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.green.shade900,
                      onPressed: () => setState(() => _successMessage = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Card: Send Password Reset Link
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send Password Reset Email',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Deliver a secure reset link to the administrator inbox',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      academy.ownerEmail.isNotEmpty
                          ? 'Click below to dispatch an official Firebase password reset link directly to ${academy.ownerEmail}.\n\nNote: The email is sent to the account registered in Firebase Authentication. If the user does not see it in their Primary inbox within 1-2 minutes, check the Spam or Junk folder.'
                          : 'No email address is registered for this academy. An administrator email is required to send a password reset link.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSendingReset || academy.ownerEmail.isEmpty
                          ? null
                          : _sendPasswordResetEmail,
                      icon: _isSendingReset
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSendingReset
                            ? 'Sending Reset Link...'
                            : 'Send Password Reset Link',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlightValue ? FontWeight.w600 : FontWeight.w500,
              color: highlightValue
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
