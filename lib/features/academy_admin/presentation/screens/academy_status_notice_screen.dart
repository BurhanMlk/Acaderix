import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/academy_access_provider.dart';
import '../../domain/academy_access_models.dart';

/// Dedicated screen presented when an academy admin logs in but their academy
/// is in a restricted state (Pending, Suspended, Expired, or Overdue).
class AcademyStatusNoticeScreen extends ConsumerStatefulWidget {
  const AcademyStatusNoticeScreen({
    super.key,
    required this.accessInfo,
  });

  final AcademyAccessInfo accessInfo;

  @override
  ConsumerState<AcademyStatusNoticeScreen> createState() =>
      _AcademyStatusNoticeScreenState();
}

class _AcademyStatusNoticeScreenState
    extends ConsumerState<AcademyStatusNoticeScreen> {
  late AcademyAccessInfo _info;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _info = widget.accessInfo;
  }

  @override
  void didUpdateWidget(AcademyStatusNoticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accessInfo != oldWidget.accessInfo) {
      _info = widget.accessInfo;
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final accessRepo = ref.read(academyAccessRepositoryProvider);
      AcademyAccessInfo updated;
      if (_info.academyId.isNotEmpty) {
        updated = await accessRepo.getAcademyAccess(_info.academyId);
      } else if (_info.ownerEmail.isNotEmpty) {
        updated = await accessRepo.findAndCheckAcademyByEmail(_info.ownerEmail);
      } else {
        updated = _info;
      }
      ref.invalidate(academyAccessProvider);
      if (mounted) {
        setState(() => _info = updated);
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_info.isActive
              ? 'Status updated: Academy is now Active! You can sign in.'
              : 'Status: ${_info.rawStatus.toUpperCase()}. Please contact Super Admin if you need help.'),
          backgroundColor: _info.isActive
              ? const Color(0xFF10B981)
              : const Color(0xFF6366F1),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? color,
    Color? borderColor,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.08),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

    // Determine visual theme according to access state
    final (
      Color stateColor,
      IconData stateIcon,
      String badgeText,
      String heading,
      String subtitle,
      String description,
    ) = switch (info.state) {
      AcademyAccessState.pending => (
          const Color(0xFFF59E0B),
          Icons.hourglass_top_rounded,
          'APPROVAL PENDING',
          'Account Approval Pending',
          'Your academy registration is currently under review by Super Admin.',
          'Once your academy is approved, full access to students, staff, attendance, fees, and examination modules will be automatically unlocked.',
        ),
      AcademyAccessState.suspended => (
          const Color(0xFFEF4444),
          Icons.block_rounded,
          'ACCOUNT SUSPENDED',
          'Academy Account Suspended',
          'Access to this academy has been suspended by the platform administrator.',
          'Operational features for your academy are temporarily paused. Please reach out to Super Admin to resolve the suspension.',
        ),
      AcademyAccessState.expired => (
          const Color(0xFFF97316),
          Icons.timer_off_rounded,
          'SUBSCRIPTION EXPIRED',
          'Subscription Renewal Required',
          'Your monthly subscription has expired or fee payment is pending clearance.',
          'To restore complete access to your academy dashboard, please contact Super Admin to record your fee payment or extend your subscription.',
        ),
      AcademyAccessState.notFound => (
          const Color(0xFF94A3B8),
          Icons.search_off_rounded,
          'ACADEMY NOT FOUND',
          'No Academy Linked',
          'No registered academy record was found for this user account.',
          'Please verify your sign-in email or contact platform support to link your account to an academy.',
        ),
      AcademyAccessState.active => (
          const Color(0xFF10B981),
          Icons.check_circle_rounded,
          'ACTIVE',
          'Academy Active',
          'Your account is in good standing.',
          'You may proceed to your dashboard.',
        ),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                children: [
                  // Top bar with sign out
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Color(0xFF818CF8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Acaderix Platform',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).signOut();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.academyAdminLogin);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Back to Login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Status Header Card
                  _glassCard(
                    borderColor: stateColor.withValues(alpha: 0.5),
                    color: stateColor.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Large Status Icon with Glow
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: stateColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stateColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            stateIcon,
                            size: 48,
                            color: stateColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: stateColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: stateColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: stateColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Academy Snapshot Details (if available)
                  if (info.academyName.isNotEmpty)
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academy Information',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Academy Name',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  info.academyName,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Academy Code',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                info.academyCode.isEmpty
                                    ? 'N/A'
                                    : info.academyCode,
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subscription Tier',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${info.planName} Plan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (info.renewalDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Renewal / Expiry Date',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  DateFormatters.date(info.renewalDate!),
                                  style: TextStyle(
                                    color: info.isExpired
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payment Status',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                info.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  color: info.paymentStatus == 'paid'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Contact Super Admin Card
                  _glassCard(
                    borderColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: Color(0xFF818CF8),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Super Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Platform Support & Activation Hotline',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Super Admin Contact Number Item
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_in_talk_rounded,
                                color: Color(0xFF10B981),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Super Admin Phone Number',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      info.supportPhone,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                tooltip: 'Copy Phone Number',
                                onPressed: () => _copyToClipboard(
                                  info.supportPhone,
                                  'Phone number',
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: const Color(0xFF818CF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Super Admin Email Item
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF818CF8),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Super Admin Support Email',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      info.supportEmail,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                tooltip: 'Copy Email Address',
                                onPressed: () => _copyToClipboard(
                                  info.supportEmail,
                                  'Support email',
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: const Color(0xFF818CF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Helpful reminder
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white54,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: Quote your Academy Code when calling for faster assistance.',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // If status updated to active after check, provide one-tap sign in
                  if (info.isActive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.academyAdminLogin);
                            }
                          },
                          icon: const Icon(Icons.login_rounded),
                          label: const Text(
                            'Academy is Active — Sign In Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Actions: Check Status Again / Refresh
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isRefreshing ? null : _refreshStatus,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        _isRefreshing
                            ? 'Checking Status...'
                            : 'Check Status Again',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Back to Login Secondary Action
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).signOut();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.academyAdminLogin);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
