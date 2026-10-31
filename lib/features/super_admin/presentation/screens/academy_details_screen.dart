import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../application/academy_repository_provider.dart';
import '../../application/super_admin_providers.dart';
import '../../domain/academy.dart';
import '../widgets/academy_avatar.dart';

/// Dedicated screen inside Super Admin shell to view, update status, and manage an academy record.
class AcademyDetailsScreen extends ConsumerStatefulWidget {
  const AcademyDetailsScreen({
    super.key,
    this.initialAcademy,
    this.academyId,
  });

  final Academy? initialAcademy;
  final String? academyId;

  @override
  ConsumerState<AcademyDetailsScreen> createState() =>
      _AcademyDetailsScreenState();
}

class _AcademyDetailsScreenState extends ConsumerState<AcademyDetailsScreen> {
  Academy? _academy;
  bool _isLoading = false;
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      final fetched = await ref.read(academyRepositoryProvider).getById(id);
      if (mounted) {
        setState(() {
          _academy = fetched;
          if (fetched == null) {
            _errorMessage = 'Academy not found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final academy = _academy;
    if (academy == null) return;

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Update Academy Status',
      message: 'Set status of "${academy.name}" to "$newStatus"?',
      confirmLabel: 'Update Status',
      destructive: newStatus == 'suspended',
    );

    if (!confirmed || !mounted) return;

    try {
      await ref.read(academyRepositoryProvider).updateStatus(academy.id, newStatus);
      ref.invalidate(academiesStreamProvider);
      setState(() {
        _academy = academy.copyWith(status: newStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.toUpperCase()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAcademy() async {
    final academy = _academy;
    if (academy == null) return;

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Academy Record',
      message:
          'Are you sure you want to permanently delete "${academy.name}" (${academy.code})?\n\nThis will remove all associated branches, students, staff, and records from the platform. The academy code will be released and can be claimed again.',
      confirmLabel: 'Delete Permanently',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await ref.read(academyRepositoryProvider).delete(academy.id);
      ref.invalidate(academiesStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Academy "${academy.name}" was permanently deleted.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRoutes.academiesList);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete academy: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _glassCard({
    required Widget child,
    Color? color,
    Color? borderColor,
  }) {
    final effectiveColor = color ?? Colors.white.withValues(alpha: 0.08);
    final effectiveBorder =
        borderColor ?? Colors.white.withValues(alpha: 0.16);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: effectiveColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: effectiveBorder, width: 1.2),
          ),
          child: child,
        ),
      ),
    );
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
              Skeleton(height: 32, width: 220),
              SizedBox(height: 24),
              Skeleton(height: 120),
              SizedBox(height: 20),
              Skeleton(height: 180),
              SizedBox(height: 20),
              Skeleton(height: 140),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _academy == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorState(
              message: _errorMessage ?? 'Unable to find academy.',
              onRetry: widget.academyId != null
                  ? () => _fetchAcademy(widget.academyId!)
                  : null,
            ),
          ),
        ),
      );
    }

    final academy = _academy!;
    final (statusColor, statusLabel) = switch (academy.status.toLowerCase()) {
      'active' => (const Color(0xFF10B981), 'ACTIVE'),
      'suspended' => (const Color(0xFFEF4444), 'SUSPENDED'),
      'pending' => (const Color(0xFFF59E0B), 'PENDING'),
      _ => (Colors.grey, academy.status.toUpperCase()),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
            // Navigation Header
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
                        'Academy Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View full profile, update status, and manage this academy record.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Overview Banner Card
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    AcademyAvatar(
                      name: academy.name,
                      logoUrl: academy.logoUrl,
                      size: 64,
                      borderRadius: 16,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            academy.name.isEmpty ? 'Unnamed Academy' : academy.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  academy.code,
                                  style: const TextStyle(
                                    color: Color(0xFFE0E7FF),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Control Action Card
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status Controls',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Active'),
                          selected: academy.status == 'active',
                          selectedColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                          onSelected: (_) => _updateStatus('active'),
                        ),
                        ChoiceChip(
                          label: const Text('Pending'),
                          selected: academy.status == 'pending',
                          selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          onSelected: (_) => _updateStatus('pending'),
                        ),
                        ChoiceChip(
                          label: const Text('Suspended'),
                          selected: academy.status == 'suspended',
                          selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
                          onSelected: (_) => _updateStatus('suspended'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Information Section
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailTile(
                      icon: Icons.apartment,
                      label: 'Total Branches',
                      value: '${academy.branchCount}',
                    ),
                    const Divider(),
                    _DetailTile(
                      icon: Icons.calendar_today,
                      label: 'Registration Date',
                      value: DateFormatters.date(academy.registrationDate),
                    ),
                    const Divider(),
                    _DetailTile(
                      icon: Icons.fingerprint,
                      label: 'Academy Record ID',
                      value: academy.id,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Owner & Contact Section
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owner & Contact Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailTile(
                      icon: Icons.person_outline,
                      label: 'Owner Name',
                      value: academy.ownerName.isEmpty
                          ? 'Not provided'
                          : academy.ownerName,
                    ),
                    const Divider(),
                    _DetailTile(
                      icon: Icons.email_outlined,
                      label: 'Contact Email',
                      value: academy.ownerEmail.isEmpty
                          ? 'Not provided'
                          : academy.ownerEmail,
                    ),
                    const Divider(),
                    _DetailTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: academy.ownerPhone.isEmpty
                          ? 'Not provided'
                          : academy.ownerPhone,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          '${AppRoutes.academyAdminResetPassword}?id=${academy.id}',
                          extra: academy,
                        );
                      },
                      icon: const Icon(Icons.lock_reset, size: 18),
                      label: const Text('Change Admin Password'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Location Section
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailTile(
                      icon: Icons.location_on_outlined,
                      label: 'Campus Address',
                      value: academy.address.isEmpty
                          ? 'Address not set'
                          : academy.address,
                    ),
                    const Divider(),
                    _DetailTile(
                      icon: Icons.map_outlined,
                      label: 'City & Province',
                      value:
                          '${academy.city.isEmpty ? "City not set" : academy.city}${academy.province.isNotEmpty ? ", ${academy.province}" : ""}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Danger Zone
            _glassCard(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderColor: const Color(0xFFEF4444).withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Permanently delete this academy and all its records from the platform. This action is irreversible and the deleted data cannot be recovered. The unique academy code will become available for new registrations.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _deleteAcademy,
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Delete Academy Record'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF818CF8)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
