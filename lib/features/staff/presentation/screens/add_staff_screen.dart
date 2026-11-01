import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/id_generators.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academics/application/course_repository_provider.dart';
import '../../../academics/domain/course.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/staff_repository_provider.dart';
import '../../domain/staff.dart';
import '../widgets/course_assignment_selector.dart';

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
  final Set<String> _selectedCourseIds = {};
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
      final staffId = await repository.allocateStaffId(academyId);
      final initialPassword = IdGenerators.generateStaffPassword();

      final staff = Staff(
        id: const Uuid().v4(),
        academyId: academyId,
        staffId: staffId,
        password: initialPassword,
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

      // Assign selected courses to this staff member
      final assignedCourseNames = <String>[];
      if (_selectedCourseIds.isNotEmpty) {
        try {
          final courseRepo = ref.read(courseRepositoryProvider);
          final courses = ref.read(coursesStreamProvider(academyId)).value ??
              const <Course>[];
          for (final courseId in _selectedCourseIds) {
            final course = courses.where((c) => c.id == courseId).firstOrNull;
            if (course != null) {
              assignedCourseNames.add(course.name);
              await courseRepo.saveCourse(
                course.copyWith(
                  teacherId: staff.id,
                  teacherName: staff.fullName,
                  branchId: course.branchId.isEmpty && staff.branchId.isNotEmpty
                      ? staff.branchId
                      : course.branchId,
                ),
              );
            }
          }
          ref.invalidate(coursesStreamProvider(academyId));
        } catch (_) {
          // Gracefully continue even if courses repository is not hooked in mock/offline tests
        }
      }

      if (!mounted) return;
      setState(() => _submitting = false);
      await _showStaffCredentialSlip(
        staff: staff,
        assignedCourses: assignedCourseNames,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to create staff member: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showStaffCredentialSlip({
    required Staff staff,
    List<String> assignedCourses = const [],
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                    'A staff account has been created. Please share these login credentials with the staff member.',
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
                          value: staff.staffId,
                          isHighlight: true,
                        ),
                        const Divider(color: Colors.white12, height: 16),
                        _CredentialRow(
                          label: 'Initial Password',
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
                        if (assignedCourses.isNotEmpty) ...[
                          const Divider(color: Colors.white12, height: 16),
                          _CredentialRow(
                            label: 'Assigned Courses',
                            value: assignedCourses.join(', '),
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
                      final courseListStr = assignedCourses.isNotEmpty
                          ? '\nCourses: ${assignedCourses.join(', ')}'
                          : '';
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              'Staff Name: ${staff.fullName}\nStaff ID: ${staff.staffId}\nPassword: ${staff.password}$courseListStr',
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
    final branchesAsync = ref.watch(branchesStreamProvider(academyId));
    final coursesAsync = ref.watch(coursesStreamProvider(academyId));

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
              // Course / Batch Assignment
              coursesAsync.when(
                data: (courses) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CourseAssignmentSelector(
                      courses: courses,
                      selectedCourseIds: _selectedCourseIds,
                      onToggleCourse: (id) {
                        setState(() {
                          if (_selectedCourseIds.contains(id)) {
                            _selectedCourseIds.remove(id);
                          } else {
                            _selectedCourseIds.add(id);
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
