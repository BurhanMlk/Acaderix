import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/staff_repository_provider.dart';
import '../../domain/staff.dart';

/// Screen for Academy Admin to edit or delete a staff member with branch assignment.
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
  late String _status;
  late String? _branchId;

  bool _submitting = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    _fullName = TextEditingController(text: s.fullName);
    _jobTitle = TextEditingController(text: s.jobTitle);
    _phone = TextEditingController(text: s.phone);
    _email = TextEditingController(text: s.email);
    _salary = TextEditingController(
      text: s.salary > 0 ? s.salary.toStringAsFixed(0) : '',
    );
    _address = TextEditingController(text: s.address);
    _status = s.status.isNotEmpty ? s.status : 'active';
    _branchId = s.branchId.isNotEmpty ? s.branchId : null;
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

  Future<void> _save() async {
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

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(
      branchesStreamProvider(widget.staff.academyId),
    );

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
                child: Row(
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
                          const Text(
                            'Staff Member Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
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
                      icon: _deleting
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
                label: 'Email Address',
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
                                b.city.isNotEmpty ? '${b.name} (${b.city})' : b.name,
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
                              b.city.isNotEmpty ? '${b.name} (${b.city})' : b.name,
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
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
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
                icon: Icons.save_outlined,
                loading: _submitting,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
