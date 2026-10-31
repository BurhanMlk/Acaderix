import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/branch_repository_provider.dart';
import '../../domain/branch.dart';

/// Screen for Academy Admin to edit or delete a branch record.
class EditBranchScreen extends ConsumerStatefulWidget {
  const EditBranchScreen({super.key, required this.branch});

  final Branch branch;

  @override
  ConsumerState<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends ConsumerState<EditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late bool _isActive;

  bool _submitting = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _name = TextEditingController(text: b.name);
    _city = TextEditingController(text: b.city);
    _phone = TextEditingController(text: b.phone);
    _address = TextEditingController(text: b.address);
    _isActive = b.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
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
      final updated = widget.branch.copyWith(
        name: _name.text.trim(),
        city: _city.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        isActive: _isActive,
      );

      await ref.read(branchRepositoryProvider).update(updated);
      ref.invalidate(branchesStreamProvider(widget.branch.academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Branch "${updated.name}" updated successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed to update branch: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Branch',
      message:
          'Are you sure you want to permanently delete branch "${widget.branch.name}" (${widget.branch.city})? This action cannot be undone.',
      confirmLabel: 'Delete Branch',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(branchRepositoryProvider)
          .delete(widget.branch.academyId, widget.branch.id);
      ref.invalidate(branchesStreamProvider(widget.branch.academyId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Branch "${widget.branch.name}" was permanently deleted.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete branch: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        0xFF0EA5E9,
                      ).withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Branch Campus Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.branch.city.isNotEmpty
                                ? widget.branch.city
                                : 'Campus Branch',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete Branch',
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
                controller: _name,
                label: 'Branch name',
                icon: Icons.account_balance_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Branch name'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _city,
                label: 'City',
                icon: Icons.location_city_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'City'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phone,
                label: 'Contact phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Address / Street',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                title: const Text('Branch is Active'),
                subtitle: const Text(
                  'Active branches appear in admission and staff assignment menus',
                ),
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
