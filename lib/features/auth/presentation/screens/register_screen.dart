import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
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

/// Multi-step registration wizard for a new academy and its first admin.
///
/// Features:
/// - Step 1: Academy Profile (Name, Address)
/// - Step 2: Administrator & Contact (Head Name, CNIC, Phone)
/// - Step 3: Account Credentials (Email, Master Password)
/// - Step 4: Subscription & Branding (Plan, Logo, Summary, Submit)
/// - Local device draft persistence via [SharedPreferences]
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Step Form Keys
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  // Text Controllers
  final _academyName = TextEditingController();
  final _address = TextEditingController();
  final _ownerName = TextEditingController();
  final _cnic = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  // Wizard state
  int _currentStep = 0;
  static const int _totalSteps = 4;
  bool _obscurePassword = true;
  Uint8List? _logoBytes;
  String _logoMime = 'image/png';
  int _selectedPlan = 0;
  bool _loading = false;
  String? _error;
  bool _draftRestored = false;

  // Persistence keys
  static const _prefPrefix = 'acaderix_reg_draft_';
  static const _keyAcademyName = '${_prefPrefix}academy_name';
  static const _keyAddress = '${_prefPrefix}address';
  static const _keyOwnerName = '${_prefPrefix}owner_name';
  static const _keyCnic = '${_prefPrefix}cnic';
  static const _keyContact = '${_prefPrefix}contact';
  static const _keyEmail = '${_prefPrefix}email';
  static const _keyPlan = '${_prefPrefix}selected_plan';
  static const _keyStep = '${_prefPrefix}step';

  static const List<String> _stepTitles = [
    'Academy Profile',
    'Administrator',
    'Credentials',
    'Plan & Branding',
  ];

  static const List<String> _stepSubtitles = [
    'Institution name and campus address',
    'Academy head and official phone number',
    'Login email and master security password',
    'Subscription package and optional branding',
  ];

  @override
  void initState() {
    super.initState();
    _loadDraft();

    _academyName.addListener(_saveDraft);
    _address.addListener(_saveDraft);
    _ownerName.addListener(_saveDraft);
    _cnic.addListener(_saveDraft);
    _contact.addListener(_saveDraft);
    _email.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _academyName.removeListener(_saveDraft);
    _address.removeListener(_saveDraft);
    _ownerName.removeListener(_saveDraft);
    _cnic.removeListener(_saveDraft);
    _contact.removeListener(_saveDraft);
    _email.removeListener(_saveDraft);

    _academyName.dispose();
    _address.dispose();
    _ownerName.dispose();
    _cnic.dispose();
    _contact.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ==========================================
  // Local Device Storage Draft Persistence
  // ==========================================

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final academyName = prefs.getString(_keyAcademyName) ?? '';
      final address = prefs.getString(_keyAddress) ?? '';
      final ownerName = prefs.getString(_keyOwnerName) ?? '';
      final cnic = prefs.getString(_keyCnic) ?? '';
      final contact = prefs.getString(_keyContact) ?? '';
      final email = prefs.getString(_keyEmail) ?? '';
      final plan = prefs.getInt(_keyPlan) ?? 0;
      final step = prefs.getInt(_keyStep) ?? 0;

      final hasData = academyName.isNotEmpty ||
          address.isNotEmpty ||
          ownerName.isNotEmpty ||
          contact.isNotEmpty ||
          email.isNotEmpty;

      if (hasData && mounted) {
        setState(() {
          _academyName.text = academyName;
          _address.text = address;
          _ownerName.text = ownerName;
          _cnic.text = cnic;
          _contact.text = contact;
          _email.text = email;
          _selectedPlan = (plan >= 0 && plan < _plans.length) ? plan : 0;
          _currentStep = (step >= 0 && step < _totalSteps) ? step : 0;
          _draftRestored = true;
        });
      }
    } catch (_) {
      // Local storage read failed silently
    }
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAcademyName, _academyName.text);
      await prefs.setString(_keyAddress, _address.text);
      await prefs.setString(_keyOwnerName, _ownerName.text);
      await prefs.setString(_keyCnic, _cnic.text);
      await prefs.setString(_keyContact, _contact.text);
      await prefs.setString(_keyEmail, _email.text);
      await prefs.setInt(_keyPlan, _selectedPlan);
      await prefs.setInt(_keyStep, _currentStep);
    } catch (_) {
      // Local storage write failed silently
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAcademyName);
      await prefs.remove(_keyAddress);
      await prefs.remove(_keyOwnerName);
      await prefs.remove(_keyCnic);
      await prefs.remove(_keyContact);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPlan);
      await prefs.remove(_keyStep);
    } catch (_) {
      // Local storage clear failed silently
    }
  }

  Future<void> _clearAndResetDraft() async {
    await _clearDraft();
    if (!mounted) return;
    setState(() {
      _academyName.clear();
      _address.clear();
      _ownerName.clear();
      _cnic.clear();
      _contact.clear();
      _email.clear();
      _password.clear();
      _selectedPlan = 0;
      _currentStep = 0;
      _draftRestored = false;
      _logoBytes = null;
      _error = null;
    });
  }

  // ==========================================
  // Step Navigation & Validation
  // ==========================================

  void _onBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _error = null;
      });
      _saveDraft();
    } else {
      try {
        if (context.canPop()) {
          context.pop();
          return;
        }
      } catch (_) {}
      try {
        context.go(AppRoutes.welcome);
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    }
  }

  void _nextStep() {
    setState(() => _error = null);

    if (_currentStep == 0) {
      if (!_step0Key.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_step1Key.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_step2Key.currentState!.validate()) return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _saveDraft();
    }
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

  // ==========================================
  // Final Consolidated Submission
  // ==========================================

  Future<void> _submit() async {
    // Re-verify that earlier steps still satisfy validation
    if (Validators.required(_academyName.text, 'Academy name') != null ||
        Validators.required(_address.text, 'Address') != null) {
      setState(() {
        _currentStep = 0;
        _error = 'Please complete your academy profile first.';
      });
      return;
    }

    if (Validators.required(_ownerName.text, 'Academy Head name') != null ||
        Validators.required(_contact.text, 'Contact number') != null ||
        Validators.phone(_contact.text) != null ||
        Validators.cnic(_cnic.text) != null) {
      setState(() {
        _currentStep = 1;
        _error = 'Please verify administrator details.';
      });
      return;
    }

    if (Validators.email(_email.text) != null ||
        Validators.password(_password.text) != null) {
      setState(() {
        _currentStep = 2;
        _error = 'Please verify account credentials and password.';
      });
      return;
    }

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

      // Successfully provisioned: purge local device draft
      await _clearDraft();

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

  // ==========================================
  // UI Builder
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Top Navigation & Step Indicator Header
              _buildTopHeader(),

              const SizedBox(height: 16),

              // Restored Draft Notification Banner
              if (_draftRestored) _buildDraftBanner(),

              // Glass Card containing the Active Step Content
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _buildCurrentStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Bar with Back Arrow, Step Titles, and Progress Segments
  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: _onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              tooltip: _currentStep > 0 ? 'Previous step' : 'Back to welcome',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Step ${_currentStep + 1} of $_totalSteps',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _stepTitles[_currentStep],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stepSubtitles[_currentStep],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress Segment Bars
        Row(
          children: List.generate(_totalSteps, (index) {
            final isDone = index < _currentStep;
            final isActive = index == _currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? AppColors.textPrimary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Draft Notice Banner with "Start Fresh / Clear" option
  Widget _buildDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore_outlined, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Draft recovered from your device',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: _clearAndResetDraft,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Start fresh',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dispatches the active step view
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0AcademyProfile();
      case 1:
        return _buildStep1AdminDetails();
      case 2:
        return _buildStep2Credentials();
      case 3:
      default:
        return _buildStep3PlanAndSubmit();
    }
  }

  // ------------------------------------------
  // STEP 0: Academy Profile
  // ------------------------------------------
  Widget _buildStep0AcademyProfile() {
    return Form(
      key: _step0Key,
      child: Column(
        key: const ValueKey('step_0_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.apartment_outlined,
            title: 'Institution Profile',
            subtitle: 'Provide your academy or school branch details.',
          ),
          const SizedBox(height: 20),
          GlassTextField(
            controller: _academyName,
            label: 'Academy Name *',
            hint: 'e.g. Falcon Science Academy',
            icon: Icons.business_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.required(v, 'Academy name'),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _address,
            label: 'Address *',
            hint: 'e.g. Plot 42, Main Boulevard, Lahore',
            icon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.required(v, 'Address'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            GlassError(message: _error!),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: glassPrimaryButtonStyle(),
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Continue to Administrator'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // STEP 1: Administrator & Contact
  // ------------------------------------------
  Widget _buildStep1AdminDetails() {
    return Form(
      key: _step1Key,
      child: Column(
        key: const ValueKey('step_1_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.person_outline,
            title: 'Administrator Details',
            subtitle: 'Primary contact and head of the institution.',
          ),
          const SizedBox(height: 20),
          GlassTextField(
            controller: _ownerName,
            label: 'Academy Head *',
            hint: 'e.g. Professor Tariq Mehmood',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.required(v, 'Academy Head name'),
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _cnic,
            label: 'CNIC',
            hint: '13-digit national identity (optional)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: Validators.cnic,
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _contact,
            label: 'Contact Number *',
            hint: 'e.g. 03001234567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (v) {
              final req = Validators.required(v, 'Contact number');
              if (req != null) return req;
              return Validators.phone(v);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            GlassError(message: _error!),
          ],
          const SizedBox(height: 24),
          _buildStepButtons(
            onBack: _onBack,
            onNext: _nextStep,
            nextLabel: 'Continue to Credentials',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // STEP 2: Account Credentials & Security
  // ------------------------------------------
  Widget _buildStep2Credentials() {
    return Form(
      key: _step2Key,
      child: Column(
        key: const ValueKey('step_2_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.lock_outline,
            title: 'Account Credentials',
            subtitle: 'Master administrator login details.',
          ),
          const SizedBox(height: 20),
          GlassTextField(
            controller: _email,
            label: 'Email *',
            hint: 'e.g. admin@youracademy.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _password,
            label: 'Password *',
            hint: 'Minimum 6 characters',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            textInputAction: TextInputAction.done,
            validator: Validators.password,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            GlassError(message: _error!),
          ],
          const SizedBox(height: 24),
          _buildStepButtons(
            onBack: _onBack,
            onNext: _nextStep,
            nextLabel: 'Continue to Plan',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // STEP 3: Subscription, Logo & Submit
  // ------------------------------------------
  Widget _buildStep3PlanAndSubmit() {
    final activePlan = _plans[_selectedPlan];

    return Column(
      key: const ValueKey('step_3_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.credit_card_outlined,
          title: 'Subscription & Logo',
          subtitle: 'Choose your subscription tier and optional institution logo.',
        ),
        const SizedBox(height: 20),

        // Subscription Plan Selection
        const Text(
          'Select Subscription Plan *',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _plans.length; i++) ...[
          _PlanCard(
            plan: _plans[i],
            selected: _selectedPlan == i,
            onTap: () {
              setState(() => _selectedPlan = i);
              _saveDraft();
            },
          ),
          if (i < _plans.length - 1) const SizedBox(height: 8),
        ],

        const SizedBox(height: 20),

        // Optional Logo Upload
        if (_logoBytes != null) ...[
          Center(
            child: ClipOval(
              child: Image.memory(
                _logoBytes!,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _logoBytes == null
                      ? 'Upload Academy Logo (optional)'
                      : 'Logo selected — tap to replace',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Registration Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Registration Summary',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Divider(height: 18, color: AppColors.border),
              _buildSummaryRow('Academy', _academyName.text),
              _buildSummaryRow('Campus', _address.text),
              _buildSummaryRow('Head', _ownerName.text),
              _buildSummaryRow('Contact', _contact.text),
              _buildSummaryRow('Email', _email.text),
              _buildSummaryRow(
                'Plan',
                '${activePlan.name} (${CurrencyFormatter.pkr(activePlan.price)}/mo)',
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          GlassError(message: _error!),
        ],

        const SizedBox(height: 24),

        // Action Buttons: Create Account & Back
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LoadingButton(
              label: 'Create Account',
              icon: Icons.rocket_launch_outlined,
              loading: _loading,
              onPressed: _submit,
              style: glassPrimaryButtonStyle(),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: glassGhostButtonStyle(),
              onPressed: _loading ? null : _onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepButtons({
    required VoidCallback onBack,
    required VoidCallback onNext,
    required String nextLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: glassPrimaryButtonStyle(),
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(
            nextLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: glassGhostButtonStyle(),
          onPressed: onBack,
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
      color: selected ? AppColors.primaryLight : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.pkr(plan.price)} / month',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
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
