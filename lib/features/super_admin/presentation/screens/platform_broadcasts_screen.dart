import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../application/platform_broadcast_providers.dart';
import '../../domain/platform_broadcast.dart';

/// Screen for Super Admin to broadcast announcements, system maintenance alerts,
/// and notices to all academies or targeted subscription tiers.
class PlatformBroadcastsScreen extends ConsumerStatefulWidget {
  const PlatformBroadcastsScreen({super.key});

  @override
  ConsumerState<PlatformBroadcastsScreen> createState() =>
      _PlatformBroadcastsScreenState();
}

class _PlatformBroadcastsScreenState
    extends ConsumerState<PlatformBroadcastsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final broadcastsAsync = ref.watch(platformBroadcastsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: broadcastsAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => ErrorState(
          message: 'Failed to load platform broadcasts.',
          onRetry: () => ref.invalidate(platformBroadcastsStreamProvider),
        ),
        data: (broadcasts) => _buildContent(context, broadcasts),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('New Broadcast'),
        onPressed: () => _openNewBroadcastModal(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Expanded(child: Skeleton(height: 84, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 84, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 16),
        const Skeleton(height: 48, borderRadius: 12),
        const SizedBox(height: 16),
        for (var i = 0; i < 3; i++) ...[
          const Skeleton(height: 120, borderRadius: 16),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<PlatformBroadcast> broadcasts,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = broadcasts.where((b) {
      final matchesQuery = query.isEmpty ||
          b.title.toLowerCase().contains(query) ||
          b.message.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'all' ||
          b.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesStatus = _selectedStatus == 'all' ||
          (_selectedStatus == 'active' && b.isActive) ||
          (_selectedStatus == 'expired' && !b.isActive);

      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();

    final totalCount = broadcasts.length;
    final activeCount = broadcasts.where((b) => b.isActive).length;
    final urgentCount =
        broadcasts.where((b) => b.isActive && b.isUrgent).length;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(platformBroadcastsStreamProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Header Stats Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrowPhone = constraints.maxWidth < 340;
              final isSmall = constraints.maxWidth < 480;
              final width = isNarrowPhone
                  ? constraints.maxWidth
                  : (isSmall
                      ? (constraints.maxWidth - 12) / 2
                      : (constraints.maxWidth - 24) / 3);

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'Total Broadcasts',
                      value: totalCount.toString(),
                      icon: Icons.campaign_outlined,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'Active Notices',
                      value: activeCount.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'Urgent Alerts',
                      value: urgentCount.toString(),
                      icon: Icons.priority_high_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search broadcasts by title or keyword...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status & Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Statuses', 'all', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Active Only', 'active', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Expired Only', 'expired', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Categories', 'all', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('System', 'system', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Maintenance',
                  'maintenance',
                  _selectedCategory,
                  (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Billing', 'billing', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Feature', 'feature', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Broadcasts List
          if (filtered.isEmpty)
            EmptyState(
              title: query.isNotEmpty
                  ? 'No matching broadcasts'
                  : 'No broadcasts available',
              message: query.isNotEmpty
                  ? 'Try modifying your search criteria.'
                  : 'Tap "New Broadcast" to send a platform-wide notice.',
              icon: Icons.campaign_outlined,
            )
          else
            for (final broadcast in filtered) ...[
              _BroadcastCard(
                broadcast: broadcast,
                onView: () => _showBroadcastDetailsModal(context, broadcast),
                onToggleActive: () =>
                    _toggleBroadcastActive(broadcast, !broadcast.isActive),
                onDelete: () => _confirmDeleteBroadcast(context, broadcast),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.35),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF6366F1)
            : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Future<void> _toggleBroadcastActive(
    PlatformBroadcast broadcast,
    bool newState,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(platformBroadcastRepositoryProvider)
          .toggleBroadcastActive(broadcast.id, newState);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              newState
                  ? 'Broadcast activated successfully.'
                  : 'Broadcast marked as inactive.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update broadcast status.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteBroadcast(
    BuildContext context,
    PlatformBroadcast broadcast,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Broadcast',
      message:
          'Are you sure you want to permanently delete "${broadcast.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true && mounted) {
      try {
        await ref
            .read(platformBroadcastRepositoryProvider)
            .deleteBroadcast(broadcast.id);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Broadcast deleted successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to delete broadcast.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _showBroadcastDetailsModal(
    BuildContext context,
    PlatformBroadcast broadcast,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _priorityBadge(broadcast.priority),
                  const SizedBox(width: 8),
                  _categoryChip(broadcast.category),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: broadcast.isActive
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      broadcast.isActive ? 'Active' : 'Expired',
                      style: TextStyle(
                        color: broadcast.isActive
                            ? Colors.greenAccent
                            : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                broadcast.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                broadcast.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              _detailRow(Icons.groups_outlined, 'Target Audience',
                  broadcast.audienceLabel),
              const SizedBox(height: 8),
              _detailRow(
                Icons.schedule_rounded,
                'Published',
                DateFormat('MMM dd, yyyy • hh:mm a')
                    .format(broadcast.createdAt),
              ),
              const SizedBox(height: 8),
              _detailRow(
                Icons.notifications_active_outlined,
                'Push Notification',
                broadcast.sentPushNotification
                    ? 'Dispatched to devices'
                    : 'Not sent',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _openNewBroadcastModal(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NewBroadcastForm(
        onSubmit: (broadcast, sendPush) async {
          Navigator.of(ctx).pop();
          try {
            await ref
                .read(platformBroadcastRepositoryProvider)
                .createBroadcast(broadcast);

            if (sendPush) {
              // Simulated push trigger
              debugPrint(
                  'Triggering broadcast push notification: ${broadcast.title}');
            }

            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Broadcast published successfully!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to publish broadcast.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final p = priority.toLowerCase();
    final (color, label) = switch (p) {
      'urgent' => (const Color(0xFFEF4444), 'URGENT'),
      'high' => (const Color(0xFFF59E0B), 'HIGH'),
      _ => (const Color(0xFF38BDF8), 'NORMAL'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({
    required this.broadcast,
    required this.onView,
    required this.onToggleActive,
    required this.onDelete,
  });

  final PlatformBroadcast broadcast;
  final VoidCallback onView;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUrgent = broadcast.isUrgent;

    return GlassCard(
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUrgent) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEF4444),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _priorityBadge(broadcast.priority),
                  const SizedBox(width: 8),
                  _categoryChip(broadcast.category),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormat('MMM dd • hh:mm a')
                            .format(broadcast.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                broadcast.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                broadcast.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            broadcast.audienceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (broadcast.sentPushNotification) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 13,
                            color: Colors.amber.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      broadcast.isActive
                          ? Icons.pause_circle_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 20,
                      color: broadcast.isActive
                          ? Colors.amberAccent
                          : Colors.greenAccent,
                    ),
                    tooltip: broadcast.isActive
                        ? 'Deactivate notice'
                        : 'Activate notice',
                    onPressed: onToggleActive,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Delete notice',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final p = priority.toLowerCase();
    final (color, label) = switch (p) {
      'urgent' => (const Color(0xFFEF4444), 'URGENT'),
      'high' => (const Color(0xFFF59E0B), 'HIGH'),
      _ => (const Color(0xFF38BDF8), 'NORMAL'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NewBroadcastForm extends StatefulWidget {
  const _NewBroadcastForm({required this.onSubmit});

  final Future<void> Function(PlatformBroadcast broadcast, bool sendPush)
      onSubmit;

  @override
  State<_NewBroadcastForm> createState() => _NewBroadcastFormState();
}

class _NewBroadcastFormState extends State<_NewBroadcastForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _category = 'system';
  String _priority = 'normal';
  String _targetAudience = 'all';
  bool _sendPush = true;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final broadcast = PlatformBroadcast(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      category: _category,
      priority: _priority,
      targetAudience: _targetAudience,
      createdAt: DateTime.now(),
      isActive: true,
      sentPushNotification: _sendPush,
    );

    await widget.onSubmit(broadcast, _sendPush);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Platform Broadcast',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Publish system updates or notices to academy administrators.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Notice Title *',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('System Update')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance Notice')),
                  DropdownMenuItem(
                      value: 'billing', child: Text('Billing & Policy')),
                  DropdownMenuItem(
                      value: 'feature', child: Text('Feature Release')),
                  DropdownMenuItem(
                      value: 'general', child: Text('General Announcement')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'system'),
              ),
              const SizedBox(height: 14),

              // Target Audience Selector
              DropdownButtonFormField<String>(
                initialValue: _targetAudience,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Target Audience',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('All Academies (Global)')),
                  DropdownMenuItem(
                      value: 'active',
                      child: Text('Active Subscribers Only')),
                  DropdownMenuItem(
                      value: 'past_due',
                      child: Text('Past Due / Pending Renewals')),
                ],
                onChanged: (v) =>
                    setState(() => _targetAudience = v ?? 'all'),
              ),
              const SizedBox(height: 14),

              // Priority Selector
              DropdownButtonFormField<String>(
                initialValue: _priority,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Priority Level',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal (Informational)')),
                  DropdownMenuItem(value: 'high', child: Text('High (Important Action)')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent (Immediate Alert)')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'normal'),
              ),
              const SizedBox(height: 14),

              // Message Body
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Detailed Message *',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter message' : null,
              ),
              const SizedBox(height: 10),

              // Push notification toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Send Device Push Notification',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  'Broadcast instant alerts to all enrolled academy mobile devices',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                value: _sendPush,
                activeThumbColor: const Color(0xFF6366F1),
                onChanged: (val) => setState(() => _sendPush = val),
              ),
              const SizedBox(height: 20),

              // Submit Button
              LoadingButton(
                label: 'Publish Broadcast',
                icon: Icons.send_rounded,
                loading: _loading,
                onPressed: _submit,
                style: glassPrimaryButtonStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
