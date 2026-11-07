import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_access_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/branch_repository_provider.dart';
import '../../domain/branch.dart';

/// Screen for Academy Admin to add a new academy campus or branch.
class AddBranchScreen extends ConsumerStatefulWidget {
  const AddBranchScreen({super.key});

  @override
  ConsumerState<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends ConsumerState<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
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

    final access = ref.read(academyAccessProvider).value;
    final currentBranches =
        ref.read(branchesStreamProvider(academyId)).value ?? [];
    if (access != null &&
        access.maxBranches > 0 &&
        currentBranches.length >= access.maxBranches) {
      setState(() => _error =
          'Branch limit reached (${currentBranches.length}/${access.maxBranches}). Your current subscription package does not allow adding more branches. Please contact Super Admin to upgrade.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repository = ref.read(branchRepositoryProvider);
      final branch = Branch(
        id: const Uuid().v4(),
        academyId: academyId,
        name: _name.text.trim(),
        city: _city.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        isActive: true,
      );

      await repository.create(branch);
      ref.invalidate(branchesStreamProvider(academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Branch "${branch.name}" created successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to create branch: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final access = ref.watch(academyAccessProvider).value;
    final branches = ref.watch(branchesStreamProvider(academyId)).value ?? [];

    final maxBranches = access?.maxBranches ?? 1;
    final isUnlimited = maxBranches <= 0;
    final isLimitReached = !isUnlimited && branches.length >= maxBranches;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isLimitReached)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Campus Limit Reached (${branches.length}/$maxBranches registered).\nYour subscription package does not allow adding more branches. Please contact Super Admin to upgrade.',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              AppTextField(
                controller: _name,
                label: 'Branch name',
                hint: 'e.g. Main Campus, F-10 Branch',
                icon: Icons.account_balance_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Branch name'),
                enabled: !isLimitReached,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _city,
                label: 'City',
                hint: 'e.g. Islamabad, Lahore, Karachi',
                icon: Icons.location_city_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'City'),
                enabled: !isLimitReached,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phone,
                label: 'Contact phone',
                hint: 'e.g. 051-1234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                enabled: !isLimitReached,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Address / Street',
                hint: 'e.g. Sector H-8/4, Street 12',
                icon: Icons.home_outlined,
                maxLines: 2,
                enabled: !isLimitReached,
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
                label: isLimitReached ? 'Limit Reached' : 'Create Branch',
                icon: Icons.add_business,
                loading: _submitting,
                onPressed: isLimitReached ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
