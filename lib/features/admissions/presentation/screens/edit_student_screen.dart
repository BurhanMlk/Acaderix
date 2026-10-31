import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/student_repository_provider.dart';
import '../../domain/student.dart';

/// Screen for Academy Admin to edit or delete an existing student record with branch assignment.
class EditStudentScreen extends ConsumerStatefulWidget {
  const EditStudentScreen({super.key, required this.student});

  final Student student;

  @override
  ConsumerState<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends ConsumerState<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _fatherName;
  late final TextEditingController _guardianPhone;
  late final TextEditingController _guardianRelation;
  late final TextEditingController _academicSession;
  late final TextEditingController _notes;
  late final TextEditingController _address;
  late String _status;
  late String? _branchId;

  bool _submitting = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _fullName = TextEditingController(text: s.fullName);
    _fatherName = TextEditingController(text: s.fatherName);
    _guardianPhone = TextEditingController(text: s.guardianPhone);
    _guardianRelation = TextEditingController(text: s.guardianRelation);
    _academicSession = TextEditingController(text: s.academicSession);
    _notes = TextEditingController(text: s.notes);
    _address = TextEditingController(text: s.address);
    _status = s.status.isNotEmpty ? s.status : 'active';
    _branchId = s.branchId.isNotEmpty ? s.branchId : null;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _fatherName.dispose();
    _guardianPhone.dispose();
    _guardianRelation.dispose();
    _academicSession.dispose();
    _notes.dispose();
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
      final updated = widget.student.copyWith(
        fullName: _fullName.text.trim(),
        fatherName: _fatherName.text.trim(),
        guardianPhone: _guardianPhone.text.trim(),
        guardianRelation: _guardianRelation.text.trim(),
        academicSession: _academicSession.text.trim(),
        notes: _notes.text.trim(),
        address: _address.text.trim(),
        status: _status,
        branchId: _branchId ?? '',
      );

      await ref.read(studentRepositoryProvider).update(updated);
      ref.invalidate(studentsStreamProvider(widget.student.academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student "${updated.fullName}" updated successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to update student: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Student',
      message:
          'Are you sure you want to permanently delete student "${widget.student.fullName}" (Roll #${widget.student.rollNumber})? This action cannot be undone.',
      confirmLabel: 'Delete Student',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(studentRepositoryProvider)
          .delete(widget.student.academyId, widget.student.id);
      ref.invalidate(studentsStreamProvider(widget.student.academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student "${widget.student.fullName}" was permanently deleted.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to delete student: $e');
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(
      branchesStreamProvider(widget.student.academyId),
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
                        0xFF6366F1,
                      ).withValues(alpha: 0.3),
                      child: const Icon(Icons.school, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Roll Number: ${widget.student.rollNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Roll numbers are permanent identifiers',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete Student',
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
                label: 'Full name',
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _fatherName,
                label: "Father's name",
                icon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, "Father's name"),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _guardianPhone,
                label: 'Guardian phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Guardian phone'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _guardianRelation,
                label: 'Guardian relation',
                icon: Icons.family_restroom_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _academicSession,
                label: 'Academic session',
                icon: Icons.calendar_month_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Academic session'),
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
                controller: _notes,
                label: 'Notes / Class info',
                icon: Icons.notes_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Address',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Enrollment Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                dropdownColor: const Color(0xFF1E293B),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Suspended'),
                  ),
                  DropdownMenuItem(
                    value: 'graduated',
                    child: Text('Graduated'),
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
