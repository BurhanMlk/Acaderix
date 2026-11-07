import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_access_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/branch_repository_provider.dart';
import '../../domain/branch.dart';

/// List of academy branches with search, creation, scope filtering, and full CRUD management.
class BranchesListScreen extends ConsumerStatefulWidget {
  const BranchesListScreen({super.key});

  @override
  ConsumerState<BranchesListScreen> createState() => _BranchesListScreenState();
}

class _BranchesListScreenState extends ConsumerState<BranchesListScreen> {
  String _query = '';

  List<Branch> _filter(List<Branch> branches) {
    if (_query.trim().isEmpty) return branches;
    final q = _query.toLowerCase().trim();
    return branches.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.city.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteBranch(String academyId, Branch branch) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Branch',
      message:
          'Delete branch "${branch.name}" (${branch.city})? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(branchRepositoryProvider).delete(academyId, branch.id);
      ref.invalidate(branchesStreamProvider(academyId));
      if (ref.read(selectedBranchIdProvider) == branch.id) {
        ref.read(selectedBranchIdProvider.notifier).state = null;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Branch "${branch.name}" was deleted.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete branch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final branches = ref.watch(branchesStreamProvider(academyId));
    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final access = ref.watch(academyAccessProvider).value;

    final branchCount = branches.value?.length ?? 0;
    final maxBranches = access?.maxBranches ?? 1;
    final isUnlimited = maxBranches <= 0;
    final isAtLimit = !isUnlimited && branchCount >= maxBranches;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addBranch),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Branch'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search branches by name or city',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAtLimit
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAtLimit
                          ? Colors.amber.withValues(alpha: 0.4)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAtLimit ? Icons.warning_amber_rounded : Icons.domain,
                        size: 14,
                        color: isAtLimit ? Colors.amber : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Quota: $branchCount / ${isUnlimited ? '∞' : maxBranches} Campuses',
                        style: TextStyle(
                          color: isAtLimit ? Colors.amber : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  access?.planName ?? 'Standard',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncListState<Branch>(
              value: branches,
              emptyTitle: 'No branches registered',
              emptyMessage:
                  'Add physical campuses or study centers to organize your academy.',
              onRetry: () => ref.invalidate(branchesStreamProvider),
              builder: (items) {
                final filtered = _filter(items);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No branches match search.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final branch = filtered[index];
                    final isScopeSelected = selectedBranchId == branch.id;

                    return Card(
                      child: ListTile(
                        onTap: () => context.push(
                          AppRoutes.editBranch,
                          extra: branch,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF0EA5E9,
                          ).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFF38BDF8),
                          child: const Icon(Icons.account_balance_outlined),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                branch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isScopeSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF38BDF8,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8),
                                  ),
                                ),
                                child: const Text(
                                  'Active Filter',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${branch.city}${branch.address.isNotEmpty ? ' · ${branch.address}' : ''}'
                          '${branch.phone.isNotEmpty ? '\nContact: ${branch.phone}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: branch.phone.isNotEmpty,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'scope') {
                              ref
                                  .read(selectedBranchIdProvider.notifier)
                                  .state = isScopeSelected ? null : branch.id;
                            } else if (val == 'edit') {
                              context.push(
                                AppRoutes.editBranch,
                                extra: branch,
                              );
                            } else if (val == 'delete') {
                              _deleteBranch(academyId, branch);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'scope',
                              child: Row(
                                children: [
                                  Icon(
                                    isScopeSelected
                                        ? Icons.clear_all
                                        : Icons.filter_alt_outlined,
                                    size: 20,
                                    color: const Color(0xFF38BDF8),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isScopeSelected
                                        ? 'Clear Filter'
                                        : 'Filter Dashboard to Branch',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
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
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
