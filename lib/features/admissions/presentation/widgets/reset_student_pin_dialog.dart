import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/id_generators.dart';
import '../../../../core/utils/validators.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/student_repository_provider.dart';
import '../../domain/student.dart';

/// Shows a dialog allowing an Academy Admin to reset a student's login PIN
/// (either by entering a 4-digit PIN manually or generating a random one).
Future<void> showResetStudentPinDialog(
  BuildContext context,
  WidgetRef ref,
  Student student,
) async {
  final newPin = await showDialog<String>(
    context: context,
    builder: (ctx) => _ResetStudentPinDialog(ref: ref, student: student),
  );

  if (newPin != null && context.mounted) {
    await _showPinResetSlip(
      context,
      student: student,
      newPin: newPin,
    );
  }
}

class _ResetStudentPinDialog extends StatefulWidget {
  const _ResetStudentPinDialog({
    required this.ref,
    required this.student,
  });

  final WidgetRef ref;
  final Student student;

  @override
  State<_ResetStudentPinDialog> createState() => _ResetStudentPinDialogState();
}

class _ResetStudentPinDialogState extends State<_ResetStudentPinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pinController;
  bool _obscurePin = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController(text: IdGenerators.generatePin());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_reset,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Reset Student PIN',
              style: TextStyle(
                color: AppColors.textPrimary,
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
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.fullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Roll #${widget.student.rollNumber}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'New PIN (4 digits)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                        tooltip: _obscurePin ? 'Show PIN' : 'Hide PIN',
                        onPressed: () {
                          setState(() => _obscurePin = !_obscurePin);
                        },
                      ),
                    ),
                    validator: Validators.pin,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.surfaceMuted,
                      side: const BorderSide(color: AppColors.border),
                      avatar: const Icon(
                        Icons.casino_outlined,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      label: const Text(
                        'Generate Random PIN',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() {
                                _pinController.text =
                                    IdGenerators.generatePin();
                                _obscurePin = false;
                              });
                            },
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  final newPin = _pinController.text.trim();
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  try {
                    await widget.ref
                        .read(studentRepositoryProvider)
                        .resetPin(
                          widget.student.academyId,
                          widget.student.id,
                          newPin,
                        );
                    widget.ref.invalidate(
                      studentsStreamProvider(widget.student.academyId),
                    );
                    if (mounted) Navigator.of(context).pop(newPin);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _saving = false;
                        _error = 'Failed to reset PIN: $e';
                      });
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save & View Slip'),
        ),
      ],
    );
  }
}

Future<void> _showPinResetSlip(
  BuildContext context, {
  required Student student,
  required String newPin,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.vpn_key_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'PIN Reset Successful',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The login PIN for ${student.fullName} has been updated. Share the new credentials below with the student or guardian.',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SlipRow(label: 'Roll Number', value: student.rollNumber),
                  const Divider(color: AppColors.border, height: 16),
                  _SlipRow(label: 'New PIN', value: newPin),
                ],
              ),
            ),
          ],
        ),
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

class _SlipRow extends StatelessWidget {
  const _SlipRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
