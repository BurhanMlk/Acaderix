import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../application/staff_repository_provider.dart';
import '../../domain/staff.dart';

/// List of staff members with search, branch tabs, creation, and full CRUD management.
class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String _query = '';

  List<Staff> _filter(List<Staff> staff, String? branchId) {
    var result = staff;
    if (branchId != null && branchId.isNotEmpty) {
      result = result.where((s) => s.branchId == branchId).toList();
    }
    if (_query.trim().isEmpty) return result;
    final q = _query.toLowerCase().trim();
    return result.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.jobTitle.toLowerCase().contains(q) ||
          s.phone.contains(q);
    }).toList();
  }

  Future<void> _deleteStaff(String academyId, Staff member) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Staff Member',
      message:
          'Delete staff member "${member.fullName}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(staffRepositoryProvider).delete(academyId, member.id);
      ref.invalidate(staffStreamProvider(academyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff member "${member.fullName}" was deleted.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete staff member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final staff = ref.watch(staffStreamProvider(academyId));
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addStaff),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search staff by name or designation',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Branch Scope Tabs Bar
          BranchTabBar(academyId: academyId),

          Expanded(
            child: AsyncListState<Staff>(
              value: staff,
              emptyTitle: 'No staff members',
              emptyMessage:
                  'Add staff members to manage faculty and administrative roles.',
              onRetry: () => ref.invalidate(staffStreamProvider),
              builder: (items) {
                final filtered = _filter(items, selectedBranchId);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No staff members match search or branch filter.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final branch = branches
                        .where((b) => b.id == member.branchId)
                        .firstOrNull;

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(
                          AppRoutes.editStaff,
                          extra: member,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(
                                  0xFF14B8A6,
                                ).withValues(alpha: 0.2),
                                foregroundColor: const Color(0xFF2DD4BF),
                                child: Text(
                                  member.fullName.isNotEmpty
                                      ? member.fullName
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Full Name (Never Truncated) & Campus Badge
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          member.fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (branch != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF38BDF8)
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              branch.name,
                                              style: const TextStyle(
                                                color: Color(0xFF38BDF8),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // Designation / Job Title
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.badge_outlined,
                                            size: 13,
                                            color: Color(0xFF2DD4BF),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            member.jobTitle.isNotEmpty
                                                ? member.jobTitle
                                                : 'Faculty Staff',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // Phone & Salary row (Wrap prevents any overflow)
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (member.phone.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.phone_outlined,
                                                size: 13,
                                                color: Colors.white54,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                member.phone,
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (member.salary > 0)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFF10B981)
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              '${CurrencyFormatter.pkr(member.salary)} / mo',
                                              style: const TextStyle(
                                                color: Color(0xFF34D399),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Popup Actions
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white60,
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    context.push(
                                      AppRoutes.editStaff,
                                      extra: member,
                                    );
                                  } else if (val == 'delete') {
                                    _deleteStaff(academyId, member);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Staff',
                                          style:
                                              TextStyle(color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
