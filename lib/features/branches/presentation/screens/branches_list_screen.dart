import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../domain/branch.dart';

/// List of academy branches.
class BranchesListScreen extends ConsumerWidget {
  const BranchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final branches = ref.watch(branchesStreamProvider(academyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      body: AsyncListState<Branch>(
        value: branches,
        emptyTitle: 'No branches',
        emptyMessage: 'Branches registered for this academy appear here.',
        onRetry: () => ref.invalidate(branchesStreamProvider),
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final branch = items[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.account_balance_outlined),
                ),
                title: Text(branch.name),
                subtitle: Text('${branch.city} · ${branch.phone}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
