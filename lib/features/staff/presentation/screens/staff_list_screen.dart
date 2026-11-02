import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/id_generators.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../application/staff_repository_provider.dart';
import '../../domain/staff.dart';

/// List of staff members with search, branch tabs, creation, password reset, and full CRUD management.
class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String _query = '';

  List<Staff> _filter(List<Staff> staff, String? branchId) {
    var result = staff;
    if (branchId != null && branchId.isNotEmpty) {
      result = result.where((s) => s.branchId == branchId).toList();
    }
    if (_query.trim().isEmpty) return result;
    final q = _query.toLowerCase().trim();
    return result.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.jobTitle.toLowerCase().contains(q) ||
          s.staffId.toLowerCase().contains(q) ||
          s.phone.contains(q);
    }).toList();
  }

  Future<void> _deleteStaff(String academyId, Staff member) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Staff Member',
      message:
          'Delete staff member "${member.fullName}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(staffRepositoryProvider).delete(academyId, member.id);
      ref.invalidate(staffStreamProvider(academyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff member "${member.fullName}" was deleted.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete staff member: $e')),
        );
      }
    }
  }

  Future<void> _showResetPasswordDialog(
    BuildContext context,
    String academyId,
    Staff member,
  ) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController(
      text: IdGenerators.generateStaffPassword(),
    );
    bool obscurePassword = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Reset Staff Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Staff ID: ${member.staffId.isNotEmpty ? member.staffId : member.id}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (v.trim().length < 6) {
                            return 'Must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          label: const Text(
                            'Generate Random Password',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                            ),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              passwordController.text =
                                  IdGenerators.generateStaffPassword();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newPass = passwordController.text.trim();
                await ref
                    .read(staffRepositoryProvider)
                    .resetPassword(academyId, member.id, newPass);
                ref.invalidate(staffStreamProvider(academyId));
                if (ctx.mounted) Navigator.of(ctx).pop();

                if (context.mounted) {
                  await _showStaffCredentialSlip(
                    context,
                    staff: member.copyWith(password: newPass),
                  );
                }
              },
              child: const Text('Save & View Slip'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStaffCredentialSlip(
    BuildContext context, {
    required Staff staff,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: Color(0xFFA5B4FC),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Staff Credentials',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const Text(
                  'Password updated successfully! Share these updated credentials with the staff member so they can sign in.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _CredentialRow(label: 'Full Name', value: staff.fullName),
                      const Divider(color: Colors.white12, height: 16),
                      _CredentialRow(
                        label: 'Staff ID',
                        value:
                            staff.staffId.isNotEmpty
                                ? staff.staffId
                                : staff.id,
                        isHighlight: true,
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _CredentialRow(
                        label: 'New Password',
                        value: staff.password,
                        isHighlight: true,
                      ),
                      if (staff.jobTitle.isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 16),
                        _CredentialRow(
                          label: 'Designation',
                          value: staff.jobTitle,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Credentials'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                  ),
                  onPressed: () {
                    final sId =
                        staff.staffId.isNotEmpty ? staff.staffId : staff.id;
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'Staff Name: ${staff.fullName}\nStaff ID: $sId\nPassword: ${staff.password}',
                      ),
                    );
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Staff credentials copied to clipboard!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final staff = ref.watch(staffStreamProvider(academyId));
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addStaff),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff Member'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name, designation, or staff ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Branch Scope Tabs at top
          BranchTabBar(academyId: academyId),

          Expanded(
            child: AsyncListState<Staff>(
              value: staff,
              emptyTitle: 'No staff members',
              emptyMessage:
                  'Add faculty and staff members to begin managing records.',
              onRetry: () => ref.invalidate(staffStreamProvider(academyId)),
              builder: (items) {
                final filtered = _filter(items, selectedBranchId);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No staff members match search or branch filter.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final branch =
                        branches.where((b) => b.id == member.branchId).firstOrNull;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF14B8A6,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF2DD4BF),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Main Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Full Name, Staff ID, and Campus Badge
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        member.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (member.staffId.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF6366F1,
                                              ).withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            member.staffId,
                                            style: const TextStyle(
                                              color: Color(0xFFA5B4FC),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      if (branch != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF38BDF8,
                                            ).withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF38BDF8,
                                              ).withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Text(
                                            branch.name,
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Designation / Job Title
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.badge_outlined,
                                          size: 13,
                                          color: Color(0xFF2DD4BF),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          member.jobTitle.isNotEmpty
                                              ? member.jobTitle
                                              : 'Faculty Staff',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Phone & Salary row
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (member.phone.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.phone_outlined,
                                              size: 13,
                                              color: Colors.white54,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              member.phone,
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (member.salary > 0)
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            '${CurrencyFormatter.pkr(member.salary)} / mo',
                                            style: const TextStyle(
                                              color: Color(0xFF34D399),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Popup Actions
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white60,
                              ),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  context.push(
                                    AppRoutes.editStaff,
                                    extra: member,
                                  );
                                } else if (val == 'reset_password') {
                                  _showResetPasswordDialog(
                                    context,
                                    academyId,
                                    member,
                                  );
                                } else if (val == 'delete') {
                                  _deleteStaff(academyId, member);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reset_password',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_reset,
                                        size: 18,
                                        color: Color(0xFF38BDF8),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Reset Password'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Staff',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isHighlight ? const Color(0xFF38BDF8) : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isHighlight ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
