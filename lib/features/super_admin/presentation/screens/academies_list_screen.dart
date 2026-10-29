import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../application/academy_repository_provider.dart';
import '../../application/super_admin_providers.dart';
import '../../domain/academy.dart';

/// Searchable, filterable list of all academies with status controls.
class AcademiesListScreen extends ConsumerStatefulWidget {
  const AcademiesListScreen({super.key});

  @override
  ConsumerState<AcademiesListScreen> createState() =>
      _AcademiesListScreenState();
}

class _AcademiesListScreenState extends ConsumerState<AcademiesListScreen> {
  String _query = '';
  String? _statusFilter;

  List<Academy> _filter(List<Academy> academies) {
    return academies.where((academy) {
      final matchesQuery =
          _query.isEmpty ||
          academy.name.toLowerCase().contains(_query.toLowerCase()) ||
          academy.code.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus =
          _statusFilter == null || academy.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _setStatus(Academy academy, String status) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Change academy status',
      message: 'Set ${academy.name} to "$status"?',
      confirmLabel: 'Confirm',
      destructive: status == 'suspended',
    );
    if (!confirmed) return;
    await ref.read(academyRepositoryProvider).updateStatus(academy.id, status);
    ref.invalidate(academiesStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final academies = ref.watch(academiesStreamProvider);

    return Column(
      children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or code',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final status in [null, 'pending', 'active', 'suspended'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        status == null ? 'All' : status.toUpperCase(),
                      ),
                      selected: _statusFilter == status,
                      onSelected: (_) => setState(() => _statusFilter = status),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncListState<Academy>(
              value: academies,
              emptyTitle: 'No academies found',
              emptyMessage: 'Try adjusting your search or filters.',
              onRetry: () => ref.invalidate(academiesStreamProvider),
              builder: (items) {
                final filtered = _filter(items);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching academies.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final academy = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: const AppLogo(size: 40, borderRadius: 12),
                        title: Text(academy.name),
                        subtitle: Text(
                          '${academy.code}\n${academy.city} · ${academy.ownerName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (status) => _setStatus(academy, status),
                          itemBuilder: (context) => [
                            for (final status in [
                              'pending',
                              'active',
                              'suspended',
                              'archived',
                            ])
                              PopupMenuItem(
                                value: status,
                                child: Text('Set $status'),
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
    );
  }
}
