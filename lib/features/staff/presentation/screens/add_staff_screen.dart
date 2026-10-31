import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/staff_repository_provider.dart';
import '../../domain/staff.dart';

/// Screen for Academy Admin to add a new faculty or administrative staff member with branch assignment.
class AddStaffScreen extends ConsumerStatefulWidget {
  const AddStaffScreen({super.key});

  @override
  ConsumerState<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends ConsumerState<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _jobTitle = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _salary = TextEditingController();
  final _address = TextEditingController();

  String? _branchId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _branchId = ref.read(selectedBranchIdProvider);
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
    final academyId = ref.read(currentAcademyIdProvider) ?? '';
    if (academyId.isEmpty) {
      setState(() => _error = 'No academy context found.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repository = ref.read(staffRepositoryProvider);
      final staff = Staff(
        id: const Uuid().v4(),
        academyId: academyId,
        branchId: _branchId ?? '',
        fullName: _fullName.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        salary: double.tryParse(_salary.text.trim()) ?? 0,
        joiningDate: DateTime.now(),
        status: 'active',
      );

      await repository.create(staff);
      ref.invalidate(staffStreamProvider(academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member "${staff.fullName}" added successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to create staff member: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final branchesAsync = ref.watch(branchesStreamProvider(academyId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                hint: 'e.g. Senior Math Teacher, Admin Officer',
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Add Staff Member',
                icon: Icons.person_add,
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
