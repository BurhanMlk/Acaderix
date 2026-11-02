import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../application/auth_controller.dart';

/// Student (and parent) sign in using academy code, roll number and PIN.
class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _academyCode = TextEditingController();
  final _rollNumber = TextEditingController();
  final _pin = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _academyCode.dispose();
    _rollNumber.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInAsStudent(
            academyCode: _academyCode.text.trim().toUpperCase(),
            rollNumber: _rollNumber.text.trim(),
            pin: _pin.text.trim(),
          );
      if (mounted) {
        context.go(homeForRole(user.role));
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          IconButton(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const GlassLoginHeader(
            icon: Icons.school_outlined,
            title: 'Student Login',
            subtitle: 'Sign in with academy code and roll number',
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Students and parents sign in here using credentials provided on your admission slip.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _academyCode,
                    label: 'Academy Code',
                    hint: 'e.g. ACD-900',
                    icon: Icons.apartment,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Academy code'),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _rollNumber,
                    label: 'Roll Number (6 digits)',
                    hint: 'e.g. 100001',
                    icon: Icons.pin,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: Validators.rollNumber,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _pin,
                    label: 'PIN / Password',
                    hint: 'e.g. 1234',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.required(v, 'PIN'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    GlassError(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  LoadingButton(
                    label: 'Sign In',
                    icon: Icons.login,
                    loading: _loading,
                    onPressed: _submit,
                    style: glassPrimaryButtonStyle(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
