import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../payroll/application/payroll_providers.dart';
import '../../../payroll/domain/salary_record.dart';
import '../../application/staff_providers.dart';
import '../../application/staff_repository_provider.dart';

/// Staff profile and self-service view displaying employment details, salary info,
/// and password change dialog.
class StaffProfileTab extends ConsumerWidget {
  const StaffProfileTab({super.key});

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
    String academyId,
    String staffId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Change Password',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Choose a new password for your Staff ID portal account.',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          tooltip: obscureNew ? 'Show password' : 'Hide password',
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          tooltip:
                              obscureConfirm ? 'Show password' : 'Hide password',
                          onPressed: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v != newPassCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref
                      .read(staffRepositoryProvider)
                      .resetPassword(
                        academyId,
                        staffId,
                        newPassCtrl.text.trim(),
                      );
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update password: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffMemberProvider);
    final branch = ref.watch(currentStaffBranchProvider);

    final staffName = staff?.fullName ?? 'Staff Member';
    final staffId = staff?.staffId.isNotEmpty == true ? staff!.staffId : 'STAFF';
    final academyId = staff?.academyId ?? '';
    final joiningStr = staff?.joiningDate != null
        ? '${staff!.joiningDate!.year}-${staff.joiningDate!.month.toString().padLeft(2, '0')}-${staff.joiningDate!.day.toString().padLeft(2, '0')}'
        : 'Active Member';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                child: Text(
                  staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                staffName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                staff?.jobTitle.isNotEmpty == true
                    ? staff!.jobTitle
                    : 'Faculty Member',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Staff ID: $staffId',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Employment Info Card
        _SectionHeader(title: 'Employment Details', icon: Icons.badge_outlined),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Column(
            children: [
              _ProfileRow(label: 'Assigned Campus', value: branch?.name ?? 'Main Campus'),
              _ProfileRow(label: 'Employment Status', value: (staff?.status ?? 'active').toUpperCase()),
              _ProfileRow(label: 'Joining Date', value: joiningStr),
              _ProfileRow(
                label: 'Monthly Salary',
                value: staff != null && staff.salary > 0
                    ? 'PKR ${staff.salary.toStringAsFixed(0)}'
                    : 'Confidential',
              ),
              _ProfileRow(
                label: 'Annual Leave Balance',
                value: '${staff?.leaveBalance ?? 0} Days remaining',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Salary & Payslips History
        _SectionHeader(
          title: 'Salary & Payslips',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 8),
        if (staff != null)
          _StaffPayslipsCard(
            academyId: staff.academyId,
            staffId: staff.id,
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'No payslip records available.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),

        // Contact Information Card
        _SectionHeader(title: 'Contact Information', icon: Icons.contact_mail_outlined),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Column(
            children: [
              _ProfileRow(label: 'Email', value: staff?.email ?? 'N/A'),
              _ProfileRow(label: 'Phone Number', value: staff?.phone ?? 'N/A'),
              _ProfileRow(
                label: 'Address',
                value: staff?.address.isNotEmpty == true ? staff!.address : 'N/A',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Security & Actions Card
        _SectionHeader(title: 'Security & Account', icon: Icons.security_outlined),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.lock_reset, size: 18, color: AppColors.primary),
                label: const Text(
                  'Change Password',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (staff != null) {
                    _showChangePasswordDialog(context, ref, academyId, staff.id);
                  }
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Sign Out',
                    message: 'Are you sure you want to sign out of your staff account?',
                    confirmLabel: 'Sign Out',
                    destructive: true,
                  );
                  if (confirmed) {
                    ref.read(authControllerProvider.notifier).signOut();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StaffPayslipsCard extends ConsumerWidget {
  const _StaffPayslipsCard({
    required this.academyId,
    required this.staffId,
  });

  final String academyId;
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslipsAsync = ref.watch(
      staffSalariesStreamProvider((academyId: academyId, staffId: staffId)),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: payslipsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => Text(
          'Could not load payslips: $e',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        data: (records) {
          if (records.isEmpty) {
            return const Text(
              'No salary slips issued yet.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                _PayslipRow(record: records[i]),
                if (i < records.length - 1)
                  const Divider(color: AppColors.border, height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PayslipRow extends StatelessWidget {
  const _PayslipRow({required this.record});

  final SalaryRecord record;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.monthLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (record.bonus > 0 || record.deductions > 0)
                Text(
                  'Base ${CurrencyFormatter.pkr(record.baseSalary)}'
                  '${record.bonus > 0 ? " +${CurrencyFormatter.pkr(record.bonus)}" : ""}'
                  '${record.deductions > 0 ? " -${CurrencyFormatter.pkr(record.deductions)}" : ""}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.pkr(record.netSalary),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (record.isPaid ? AppColors.success : Colors.amber)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                record.isPaid ? 'PAID' : 'PENDING',
                style: TextStyle(
                  color: record.isPaid
                      ? AppColors.success
                      : Colors.amber.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: AppColors.surfaceMuted, height: 1),
      ],
    );
  }
}
