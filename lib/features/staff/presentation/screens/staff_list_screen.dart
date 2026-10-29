import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../domain/staff.dart';

/// List of staff members.
class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final staff = ref.watch(staffStreamProvider(academyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: AsyncListState<Staff>(
        value: staff,
        emptyTitle: 'No staff',
        emptyMessage: 'Add staff members to manage roles and payroll.',
        onRetry: () => ref.invalidate(staffStreamProvider),
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = items[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
                title: Text(member.fullName),
                subtitle: Text('${member.jobTitle} · ${member.phone}'),
                trailing: Text(member.status.toUpperCase()),
              ),
            );
          },
        ),
      ),
    );
  }
}
