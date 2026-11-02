import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../application/auth_controller.dart';

/// A selectable subscription plan shown during academy registration.
class _PlanOption {
  const _PlanOption(this.id, this.name, this.price);

  final String id;
  final String name;
  final int price;
}

const List<_PlanOption> _plans = [
  _PlanOption('basic', 'Basic', 10000),
  _PlanOption('standard', 'Standard', 15000),
  _PlanOption('premium', 'Premium', 20000),
];

/// Public registration form for a new academy and its first admin.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _academyName = TextEditingController();
  final _address = TextEditingController();
  final _ownerName = TextEditingController();
  final _cnic = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();

  Uint8List? _logoBytes;
  String _logoMime = 'image/png';
  int _selectedPlan = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _academyName.dispose();
    _address.dispose();
    _ownerName.dispose();
    _cnic.dispose();
    _email.dispose();
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _logoBytes = bytes;
        _logoMime = picked.mimeType ?? 'image/png';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not read the selected image.');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = _plans[_selectedPlan];
      final user = await ref.read(authControllerProvider.notifier).registerAcademy(
        email: _email.text.trim(),
        password: _password.text,
        academyName: _academyName.text.trim(),
        address: _address.text.trim(),
        cnic: _cnic.text.trim(),
        ownerName: _ownerName.text.trim(),
        ownerPhone: _contact.text.trim(),
        planName: plan.name,
        planPrice: plan.price,
        logoBytes: _logoBytes,
        logoContentType: _logoMime,
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
            onPressed: () => context.go(AppRoutes.welcome),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const GlassLoginHeader(
            icon: Icons.apartment_outlined,
            title: 'Register your academy',
            subtitle: 'Create your academy account',
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassTextField(
                    controller: _academyName,
                    label: 'Academy Name *',
                    icon: Icons.business_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Academy name'),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _address,
                    label: 'Address *',
                    icon: Icons.location_on_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Address'),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _email,
                    label: 'Email *',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _ownerName,
                    label: 'Academy Head *',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.required(v, 'Academy Head name'),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _cnic,
                    label: 'CNIC',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: Validators.cnic,
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _contact,
                    label: 'Contact Number *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final req = Validators.required(v, 'Contact number');
                      if (req != null) return req;
                      return Validators.phone(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    controller: _password,
                    label: 'Password *',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Subscription Plan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _plans.length; i++) ...[
                    _PlanCard(
                      plan: _plans[i],
                      selected: _selectedPlan == i,
                      onTap: () => setState(() => _selectedPlan = i),
                    ),
                    if (i < _plans.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 20),
                  if (_logoBytes != null) ...[
                    Center(
                      child: ClipOval(
                        child: Image.memory(
                          _logoBytes!,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton(
                    style: glassGhostButtonStyle(),
                    onPressed: _loading ? null : _pickLogo,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _logoBytes == null
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _logoBytes == null
                                ? 'Upload Academy Logo (optional)'
                                : 'Logo selected — tap to change',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    GlassError(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  LoadingButton(
                    label: 'Create Account',
                    icon: Icons.rocket_launch_outlined,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _PlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.pkr(plan.price)} / month',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
