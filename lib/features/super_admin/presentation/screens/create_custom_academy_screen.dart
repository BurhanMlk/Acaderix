import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/id_generators.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../application/academy_repository_provider.dart';
import '../../application/subscription_providers.dart';
import '../../application/super_admin_providers.dart';

/// Screen allowing Super Admin to customly create an academy with specific owner
/// credentials and custom subscription quotas (branches, students, monthly fee in PKR).
class CreateCustomAcademyScreen extends ConsumerStatefulWidget {
  const CreateCustomAcademyScreen({super.key});

  @override
  ConsumerState<CreateCustomAcademyScreen> createState() =>
      _CreateCustomAcademyScreenState();
}

class _CreateCustomAcademyScreenState
    extends ConsumerState<CreateCustomAcademyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Academy Controllers
  final _academyName = TextEditingController();
  final _academyCode = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController(text: 'Punjab');
  final _logoUrl = TextEditingController();

  // Owner Controllers
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _cnic = TextEditingController();

  // Custom Package Quotas Controllers
  final _maxBranches = TextEditingController(text: '1');
  final _maxStudents = TextEditingController(text: '200');
  final _monthlyFee = TextEditingController(text: '15000');

  bool _unlimitedBranches = false;
  bool _unlimitedStudents = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  String _billingCycle = 'monthly';
  String _status = 'active';
  String _paymentStatus = 'paid';

  @override
  void initState() {
    super.initState();
    _academyCode.text = IdGenerators.generateAcademyCode();
  }

  @override
  void dispose() {
    _academyName.dispose();
    _academyCode.dispose();
    _address.dispose();
    _city.dispose();
    _province.dispose();
    _logoUrl.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _ownerPassword.dispose();
    _ownerPhone.dispose();
    _cnic.dispose();
    _maxBranches.dispose();
    _maxStudents.dispose();
    _monthlyFee.dispose();
    super.dispose();
  }

  void _generateNewCode() {
    setState(() {
      _academyCode.text = IdGenerators.generateAcademyCode();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final branchesQuota = _unlimitedBranches
        ? -1
        : int.tryParse(_maxBranches.text.trim()) ?? 1;
    final studentsQuota = _unlimitedStudents
        ? -1
        : int.tryParse(_maxStudents.text.trim()) ?? 200;
    final fee = int.tryParse(_monthlyFee.text.trim()) ?? 15000;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repository = ref.read(academyRepositoryProvider);
      final academyId = await repository.createCustomAcademyWithPackage(
        academyName: _academyName.text.trim(),
        academyCode: _academyCode.text.trim().toUpperCase(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        province: _province.text.trim(),
        ownerName: _ownerName.text.trim(),
        ownerEmail: _ownerEmail.text.trim(),
        ownerPassword: _ownerPassword.text.trim(),
        ownerPhone: _ownerPhone.text.trim(),
        maxBranches: branchesQuota,
        maxStudents: studentsQuota,
        monthlyFee: fee,
        billingCycle: _billingCycle,
        status: _status,
        paymentStatus: _paymentStatus,
        logoUrl: _logoUrl.text.trim(),
        cnic: _cnic.text.trim(),
      );

      // Invalidate platform streams
      ref.invalidate(academiesStreamProvider);
      ref.invalidate(subscriptionsStreamProvider);

      if (!mounted) return;

      // Show credential summary slip
      await _showCredentialsDialog(
        academyId: academyId,
        academyName: _academyName.text.trim(),
        academyCode: _academyCode.text.trim().toUpperCase(),
        ownerEmail: _ownerEmail.text.trim(),
        ownerPassword: _ownerPassword.text.trim(),
        ownerName: _ownerName.text.trim(),
        maxBranches: branchesQuota,
        maxStudents: studentsQuota,
        monthlyFee: fee,
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showCredentialsDialog({
    required String academyId,
    required String academyName,
    required String academyCode,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerName,
    required int maxBranches,
    required int maxStudents,
    required int monthlyFee,
  }) async {
    final branchesStr = maxBranches == -1 ? 'Unlimited' : '$maxBranches branch(es)';
    final studentsStr = maxStudents == -1 ? 'Unlimited' : '$maxStudents students';

    final slipText = '''
🎓 ACADERIX ACADEMY OWNER ACCOUNT CREATED
--------------------------------------
Academy: $academyName
Academy Code: $academyCode
Owner Name: $ownerName
Login Email: $ownerEmail
Password: $ownerPassword

📦 Custom Package Quotas:
• Allowed Campuses/Branches: $branchesStr
• Allowed Students: $studentsStr
• Monthly Fee: PKR ${monthlyFee.toString()}

Login Portal: Download Acaderix Mobile App or sign in as Academy Admin.
''';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Academy & Owner Created!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The academy and owner account have been provisioned successfully with custom package limits.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _slipRow('Academy', academyName),
                      _slipRow('Academy Code', academyCode, isBold: true),
                      _slipRow('Owner Email', ownerEmail),
                      _slipRow('Password', ownerPassword, isSecret: true),
                      const Divider(color: Colors.white12, height: 16),
                      _slipRow('Branches Quota', branchesStr),
                      _slipRow('Students Quota', studentsStr),
                      _slipRow('Monthly Fee', 'PKR $monthlyFee'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: slipText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Credentials and package details copied to clipboard!'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Slip'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _slipRow(String label, String value,
      {bool isBold = false, bool isSecret = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isSecret ? const Color(0xFFFBBF24) : Colors.white,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontFamily: isSecret ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Navigation Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Academies',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.academiesList);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Custom Academy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    icon: Icons.domain,
                    title: 'Academy Details',
                    subtitle: 'Institution profile and campus location',
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    children: [
                      AppTextField(
                        controller: _academyName,
                        label: 'Academy Name',
                        hint: 'e.g. Cambridge Science College',
                        icon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.required(v, 'Academy Name'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _academyCode,
                              label: 'Academy Code',
                              hint: 'e.g. CSC99',
                              icon: Icons.tag,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  Validators.required(v, 'Academy Code'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: IconButton.filledTonal(
                              onPressed: _generateNewCode,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Generate new random code',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _address,
                        label: 'Address / Street',
                        hint: 'e.g. Main Boulevard, Gulberg III',
                        icon: Icons.place_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.required(v, 'Address'),
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveTwoColumns(
                        first: AppTextField(
                          controller: _city,
                          label: 'City',
                          hint: 'e.g. Lahore',
                          icon: Icons.location_city_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.required(v, 'City'),
                        ),
                        second: AppTextField(
                          controller: _province,
                          label: 'Province / State',
                          hint: 'e.g. Punjab',
                          icon: Icons.map_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.required(v, 'Province'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _logoUrl,
                        label: 'Logo URL (Optional)',
                        hint: 'https://...',
                        icon: Icons.image_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.person_outline,
                    title: 'Academy Owner Credentials',
                    subtitle: 'Owner login info to access Academy Admin dashboard',
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    children: [
                      AppTextField(
                        controller: _ownerName,
                        label: 'Owner Full Name',
                        hint: 'e.g. Muhammad Aslam',
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.required(v, 'Owner Name'),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _ownerEmail,
                        label: 'Owner Login Email',
                        hint: 'e.g. admin@cambridge.edu.pk',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _ownerPassword,
                        label: 'Login Password',
                        hint: 'Min 6 characters',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveTwoColumns(
                        first: AppTextField(
                          controller: _ownerPhone,
                          label: 'Phone / WhatsApp',
                          hint: '03001234567',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              Validators.required(v, 'Owner Phone'),
                        ),
                        second: AppTextField(
                          controller: _cnic,
                          label: 'CNIC (Optional)',
                          hint: '35201-xxxxxxx-x',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Custom Package Quotas & Billing',
                    subtitle:
                        'Set customized branch & student limits and monthly fee in PKR',
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    children: [
                      _buildQuotaField(
                        controller: _maxBranches,
                        label: 'Allowed Branches',
                        hint: 'e.g. 1, 2, 5',
                        icon: Icons.account_balance_outlined,
                        isUnlimited: _unlimitedBranches,
                        onUnlimitedChanged: (val) {
                          setState(() {
                            _unlimitedBranches = val;
                            if (val) _maxBranches.text = '-1';
                            if (!val && _maxBranches.text == '-1') {
                              _maxBranches.text = '1';
                            }
                          });
                        },
                        validator: (v) {
                          if (_unlimitedBranches) return null;
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) {
                            return 'Enter at least 1 branch';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildQuotaField(
                        controller: _maxStudents,
                        label: 'Allowed Students',
                        hint: 'e.g. 200, 500',
                        icon: Icons.people_outline,
                        isUnlimited: _unlimitedStudents,
                        onUnlimitedChanged: (val) {
                          setState(() {
                            _unlimitedStudents = val;
                            if (val) _maxStudents.text = '-1';
                            if (!val && _maxStudents.text == '-1') {
                              _maxStudents.text = '200';
                            }
                          });
                        },
                        validator: (v) {
                          if (_unlimitedStudents) return null;
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) {
                            return 'Enter at least 1 student';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _monthlyFee,
                        label: 'Monthly Fee (Rupees / PKR)',
                        hint: 'e.g. 15000',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) {
                            return 'Enter valid monthly fee in PKR';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _billingCycle,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Billing Cycle',
                          prefixIcon: const Icon(Icons.repeat),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(
                              value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(
                              value: 'quarterly', child: Text('Quarterly')),
                          DropdownMenuItem(
                              value: 'yearly', child: Text('Yearly')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _billingCycle = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Academy Status',
                          prefixIcon: const Icon(Icons.toggle_on_outlined),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(
                              value: 'active', child: Text('Active')),
                          DropdownMenuItem(
                              value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(
                              value: 'suspended', child: Text('Suspended')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentStatus,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Initial Payment Status',
                          prefixIcon: const Icon(Icons.receipt_long_outlined),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(
                              value: 'paid', child: Text('Paid (Fee Received)')),
                          DropdownMenuItem(
                              value: 'unpaid', child: Text('Unpaid (Pending Fee)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentStatus = val);
                        },
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  LoadingButton(
                    label: 'Create Academy & Owner Account',
                    icon: Icons.add_business,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveTwoColumns({
    required Widget first,
    required Widget second,
    double breakpoint = 500,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildQuotaField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isUnlimited,
    required ValueChanged<bool> onUnlimitedChanged,
    required String? Function(String?) validator,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chip = FilterChip(
          label: const Text('Unlimited'),
          selected: isUnlimited,
          onSelected: onUnlimitedChanged,
        );

        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: controller,
                label: label,
                hint: hint,
                icon: icon,
                keyboardType: TextInputType.number,
                enabled: !isUnlimited,
                validator: validator,
              ),
              const SizedBox(height: 6),
              chip,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                label: label,
                hint: hint,
                icon: icon,
                keyboardType: TextInputType.number,
                enabled: !isUnlimited,
                validator: validator,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: chip,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF818CF8), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
