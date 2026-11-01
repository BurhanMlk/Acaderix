import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/id_generators.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../academics/application/course_repository_provider.dart';
import '../../../academics/domain/course.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/staff_repository_provider.dart';
import '../../domain/staff.dart';
import '../widgets/course_assignment_selector.dart';

/// Screen for Academy Admin to edit existing staff member details, reassign branch, or reset login password.
class EditStaffScreen extends ConsumerStatefulWidget {
  const EditStaffScreen({super.key, required this.staff});

  final Staff staff;

  @override
  ConsumerState<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends ConsumerState<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _jobTitle;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _salary;
  late final TextEditingController _address;

  late String? _branchId;
  late String _status;
  Set<String>? _selectedCourseIds;
  bool _submitting = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.staff.fullName);
    _jobTitle = TextEditingController(text: widget.staff.jobTitle);
    _phone = TextEditingController(text: widget.staff.phone);
    _email = TextEditingController(text: widget.staff.email);
    _salary = TextEditingController(
      text: widget.staff.salary > 0
          ? widget.staff.salary.toStringAsFixed(0)
          : '',
    );
    _address = TextEditingController(text: widget.staff.address);
    _branchId = widget.staff.branchId.isNotEmpty
        ? widget.staff.branchId
        : null;
    _status = widget.staff.status.isNotEmpty ? widget.staff.status : 'active';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _jobTitle.dispose();
    _phone.dispose();
    _email.dispose();
    _salary.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final updated = widget.staff.copyWith(
        fullName: _fullName.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        salary: double.tryParse(_salary.text.trim()) ?? 0,
        address: _address.text.trim(),
        status: _status,
        branchId: _branchId ?? '',
      );

      await ref.read(staffRepositoryProvider).update(updated);
      ref.invalidate(staffStreamProvider(widget.staff.academyId));

      // Update course assignments for this staff member
      if (_selectedCourseIds != null) {
        try {
          final courseRepo = ref.read(courseRepositoryProvider);
          final courses = ref
                  .read(coursesStreamProvider(widget.staff.academyId))
                  .value ??
              const <Course>[];
          for (final course in courses) {
            final wasAssigned = (course.teacherId.isNotEmpty &&
                    course.teacherId == widget.staff.id) ||
                (widget.staff.staffId.isNotEmpty &&
                    course.teacherId.toUpperCase() ==
                        widget.staff.staffId.toUpperCase());
            final isNowAssigned = _selectedCourseIds!.contains(course.id);

            if (!wasAssigned && isNowAssigned) {
              await courseRepo.saveCourse(
                course.copyWith(
                  teacherId: widget.staff.id,
                  teacherName: updated.fullName,
                  branchId: course.branchId.isEmpty && updated.branchId.isNotEmpty
                      ? updated.branchId
                      : course.branchId,
                ),
              );
            } else if (wasAssigned && !isNowAssigned) {
              await courseRepo.saveCourse(
                course.copyWith(
                  teacherId: '',
                  teacherName: '',
                ),
              );
            } else if (wasAssigned &&
                isNowAssigned &&
                course.teacherName != updated.fullName) {
              await courseRepo.saveCourse(
                course.copyWith(teacherName: updated.fullName),
              );
            }
          }
          ref.invalidate(coursesStreamProvider(widget.staff.academyId));
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Staff member "${updated.fullName}" updated successfully!',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to update staff member: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Staff Member',
      message:
          'Are you sure you want to permanently delete "${widget.staff.fullName}"? This action cannot be undone.',
      confirmLabel: 'Delete Staff',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete(widget.staff.academyId, widget.staff.id);
      ref.invalidate(staffStreamProvider(widget.staff.academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Staff member "${widget.staff.fullName}" was deleted.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to delete staff member: $e');
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController(
      text: IdGenerators.generateStaffPassword(),
    );

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
                              widget.staff.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Staff ID: ${widget.staff.staffId.isNotEmpty ? widget.staff.staffId : widget.staff.id}',
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
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_outline),
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
                    .resetPassword(
                      widget.staff.academyId,
                      widget.staff.id,
                      newPass,
                    );
                ref.invalidate(staffStreamProvider(widget.staff.academyId));
                if (ctx.mounted) Navigator.of(ctx).pop();

                if (context.mounted) {
                  await _showStaffCredentialSlip(newPassword: newPass);
                }
              },
              child: const Text('Save & View Slip'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStaffCredentialSlip({required String newPassword}) async {
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
                      _CredentialRow(
                        label: 'Full Name',
                        value: widget.staff.fullName,
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _CredentialRow(
                        label: 'Staff ID',
                        value:
                            widget.staff.staffId.isNotEmpty
                                ? widget.staff.staffId
                                : widget.staff.id,
                        isHighlight: true,
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _CredentialRow(
                        label: 'New Password',
                        value: newPassword,
                        isHighlight: true,
                      ),
                      if (widget.staff.jobTitle.isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 16),
                        _CredentialRow(
                          label: 'Designation',
                          value: widget.staff.jobTitle,
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
                        widget.staff.staffId.isNotEmpty
                            ? widget.staff.staffId
                            : widget.staff.id;
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'Staff Name: ${widget.staff.fullName}\nStaff ID: $sId\nPassword: $newPassword',
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
    final branchesAsync = ref.watch(
      branchesStreamProvider(widget.staff.academyId),
    );
    final coursesAsync = ref.watch(
      coursesStreamProvider(widget.staff.academyId),
    );

    if (_selectedCourseIds == null && coursesAsync.hasValue) {
      _selectedCourseIds = coursesAsync.value!
          .where((c) =>
              (c.teacherId.isNotEmpty && c.teacherId == widget.staff.id) ||
              (widget.staff.staffId.isNotEmpty &&
                  c.teacherId.toUpperCase() ==
                      widget.staff.staffId.toUpperCase()))
          .map((c) => c.id)
          .toSet();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info & Action Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(
                            0xFF14B8A6,
                          ).withValues(alpha: 0.3),
                          child: const Icon(Icons.badge, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    widget.staff.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (widget.staff.staffId.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        widget.staff.staffId,
                                        style: const TextStyle(
                                          color: Color(0xFFA5B4FC),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.staff.jobTitle.isNotEmpty
                                    ? widget.staff.jobTitle
                                    : 'Faculty Staff',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete Staff Member',
                          icon:
                              _deleting
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.redAccent,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                          onPressed: _deleting ? null : _delete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Staff Login Credentials',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock_reset, size: 15),
                          label: const Text('Reset Password'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: const Color(0xFF38BDF8),
                            side: const BorderSide(
                              color: Color(0xFF38BDF8),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          onPressed: _showResetPasswordDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _fullName,
                label: 'Full Name',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _jobTitle,
                label: 'Job Title / Designation',
                icon: Icons.work_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Job title'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phone,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Phone number'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _email,
                label: 'Email Address (Optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              // Branch Assignment
              branchesAsync.when(
                data: (branches) {
                  if (branches.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String?>(
                      initialValue: _branchId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Campus / Branch',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      selectedItemBuilder: (context) {
                        return [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Main Campus (Default)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          ...branches.map(
                            (b) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                b.city.isNotEmpty
                                    ? '${b.name} (${b.city})'
                                    : b.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ];
                      },
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Main Campus (Default)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ...branches.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(
                              b.city.isNotEmpty
                                  ? '${b.name} (${b.city})'
                                  : b.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _branchId = val),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              // Course Assignment
              coursesAsync.when(
                data: (courses) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CourseAssignmentSelector(
                      courses: courses,
                      selectedCourseIds: _selectedCourseIds ?? const <String>{},
                      currentStaffId: widget.staff.id,
                      onToggleCourse: (id) {
                        setState(() {
                          _selectedCourseIds ??= <String>{};
                          if (_selectedCourseIds!.contains(id)) {
                            _selectedCourseIds!.remove(id);
                          } else {
                            _selectedCourseIds!.add(id);
                          }
                        });
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              AppTextField(
                controller: _salary,
                label: 'Monthly Salary (PKR)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Residential Address',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Staff Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                dropdownColor: const Color(0xFF1E293B),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Inactive'),
                  ),
                  DropdownMenuItem(
                    value: 'on_leave',
                    child: Text('On Leave'),
                  ),
                  DropdownMenuItem(
                    value: 'terminated',
                    child: Text('Terminated'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Save Changes',
                icon: Icons.save,
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
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
