import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/id_generators.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../application/student_repository_provider.dart';
import '../../domain/student.dart';

/// Multi-field student admission form.
///
/// On submit the flow: validates → allocates a six-digit roll number via a
/// Firestore transaction → generates a temporary four-digit PIN → creates the
/// student record → shows a one-time credential slip.
///
/// Production deployments should call the `admitStudent` Cloud Function
/// (functions/src/index.ts) so the temporary PIN is hashed server-side and
/// never persisted in plaintext; this client-side flow is the offline/dev
/// preview of that workflow.
class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _fatherName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _guardianRelation = TextEditingController();
  final _academicSession = TextEditingController();
  final _classId = TextEditingController();
  final _batchId = TextEditingController();
  final _admissionFee = TextEditingController();
  final _monthlyFee = TextEditingController();
  final _address = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _fatherName,
      _guardianPhone,
      _guardianRelation,
      _academicSession,
      _classId,
      _batchId,
      _admissionFee,
      _monthlyFee,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final academyId = ref.read(currentAcademyIdProvider);
    if (academyId == null) {
      setState(() => _error = 'No academy context available.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repository = ref.read(studentRepositoryProvider);
      final rollNumber = await repository.allocateRollNumber(academyId);
      final pin = IdGenerators.generatePin();

      final student = Student(
        id: const Uuid().v4(),
        academyId: academyId,
        fullName: _fullName.text.trim(),
        fatherName: _fatherName.text.trim(),
        guardianPhone: _guardianPhone.text.trim(),
        guardianRelation: _guardianRelation.text.trim(),
        academicSession: _academicSession.text.trim(),
        rollNumber: rollNumber,
        address: _address.text.trim(),
        admissionDate: DateTime.now(),
        status: 'active',
      );

      await repository.create(student);

      if (!mounted) return;
      await _showCredentialSlip(rollNumber: rollNumber, pin: pin);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to admit student: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showCredentialSlip({
    required String rollNumber,
    required String pin,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Student Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share these credentials with the student once. The PIN is '
              'temporary and will not be shown again.',
            ),
            const SizedBox(height: 16),
            _CredentialRow(label: 'Roll Number', value: rollNumber),
            _CredentialRow(label: 'Temporary PIN', value: pin),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admit Student')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                hint: 'e.g. 2026-2027',
                icon: Icons.calendar_month_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Academic session'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _classId,
                label: 'Class',
                hint: 'e.g. Class 9',
                icon: Icons.school_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Class'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _batchId,
                label: 'Batch',
                hint: 'e.g. Section A',
                icon: Icons.groups_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _admissionFee,
                label: 'Admission fee (PKR)',
                icon: Icons.money_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _monthlyFee,
                label: 'Monthly fee (PKR)',
                icon: Icons.event_repeat_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Address',
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
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Admit Student',
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
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
