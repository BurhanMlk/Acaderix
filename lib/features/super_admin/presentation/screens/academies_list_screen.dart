import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../application/academy_repository_provider.dart';
import '../../application/super_admin_providers.dart';
import '../../domain/academy.dart';
import '../widgets/academy_avatar.dart';

/// Searchable, filterable list of all academies with management and status controls.
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

  Future<void> _deleteAcademy(Academy academy) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Academy Record',
      message:
          'Are you sure you want to permanently delete "${academy.name}" (${academy.code})?\n\nThis will remove all associated records and cannot be undone.',
      confirmLabel: 'Delete Permanently',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(academyRepositoryProvider).delete(academy.id);
      ref.invalidate(academiesStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Academy "${academy.name}" deleted.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete academy: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            decoration: InputDecoration(
              hintText: 'Search by name or code',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.go(
                        AppRoutes.academyDetails,
                        extra: academy,
                      ),
                      child: ListTile(
                        leading: AcademyAvatar(
                          name: academy.name,
                          logoUrl: academy.logoUrl,
                          size: 40,
                          borderRadius: 12,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                academy.name.isEmpty
                                    ? 'Unnamed Academy'
                                    : academy.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(academy.status),
                          ],
                        ),
                        subtitle: Text(
                          '${academy.code} · ${academy.city.isEmpty ? "Location not set" : academy.city}\nOwner: ${academy.ownerName.isEmpty ? "Unknown" : academy.ownerName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'details') {
                              context.go(
                                AppRoutes.academyDetails,
                                extra: academy,
                              );
                            } else if (value == 'change_password') {
                              context.go(
                                AppRoutes.academyAdminResetPassword,
                                extra: academy,
                              );
                            } else if (value == 'delete') {
                              _deleteAcademy(academy);
                            } else {
                              _setStatus(academy, value);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'change_password',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_reset, size: 18),
                                  SizedBox(width: 8),
                                  Text('Change Password'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            for (final status in [
                              'active',
                              'pending',
                              'suspended',
                              'archived',
                            ])
                              PopupMenuItem(
                                value: status,
                                child: Text('Mark $status'),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever,
                                      color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Record',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
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
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'suspended':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
