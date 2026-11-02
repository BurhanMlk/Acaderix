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
import '../../application/support_ticket_providers.dart';
import '../../domain/support_ticket.dart';
import '../widgets/academy_avatar.dart';

/// Screen for Super Admin to manage, investigate, and resolve support inquiries
/// submitted across all academies.
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ticketsAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => ErrorState(
          message: 'Failed to load support tickets.',
          onRetry: () => ref.invalidate(supportTicketsStreamProvider),
        ),
        data: (tickets) => _buildContent(context, tickets),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Log Ticket'),
        onPressed: () => _openNewTicketModal(context),
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
          const Skeleton(height: 140, borderRadius: 16),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<SupportTicket> tickets) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = tickets.where((t) {
      final matchesQuery = query.isEmpty ||
          t.ticketNumber.toLowerCase().contains(query) ||
          t.academyName.toLowerCase().contains(query) ||
          t.academyCode.toLowerCase().contains(query) ||
          t.subject.toLowerCase().contains(query) ||
          t.contactName.toLowerCase().contains(query);

      final matchesStatus = _selectedStatus == 'all' ||
          t.status.toLowerCase() == _selectedStatus.toLowerCase();

      final matchesCategory = _selectedCategory == 'all' ||
          t.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesStatus && matchesCategory;
    }).toList();

    final totalCount = tickets.length;
    final openCount = tickets.where((t) => t.isOpen).length;
    final inProgressCount = tickets.where((t) => t.isInProgress).length;
    final resolvedCount = tickets.where((t) => t.isResolved).length;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(supportTicketsStreamProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // KPI Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrowPhone = constraints.maxWidth < 340;
              final isSmall = constraints.maxWidth < 560;
              final width = isNarrowPhone
                  ? constraints.maxWidth
                  : (isSmall
                      ? (constraints.maxWidth - 12) / 2
                      : (constraints.maxWidth - 36) / 4);

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'Total Tickets',
                      value: totalCount.toString(),
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'Open',
                      value: openCount.toString(),
                      icon: Icons.error_outline_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'In Progress',
                      value: inProgressCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatCard(
                      title: 'Resolved',
                      value: resolvedCount.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by ticket #, academy, subject...',
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

          // Filter by Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Statuses', 'all', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Open', 'open', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'In Progress',
                  'in_progress',
                  _selectedStatus,
                  (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', 'resolved', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Closed', 'closed', _selectedStatus, (v) {
                  setState(() => _selectedStatus = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter by Category
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Categories', 'all', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Technical', 'technical', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Billing', 'billing', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Account', 'account', _selectedCategory, (v) {
                  setState(() => _selectedCategory = v);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Feature Request',
                  'feature_request',
                  _selectedCategory,
                  (v) => setState(() => _selectedCategory = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tickets List
          if (filtered.isEmpty)
            EmptyState(
              title: query.isNotEmpty
                  ? 'No matching tickets'
                  : 'No tickets available',
              message: query.isNotEmpty
                  ? 'Try modifying your search or filters.'
                  : 'All support inquiries have been resolved cleanly.',
              icon: Icons.support_agent_rounded,
            )
          else
            for (final ticket in filtered) ...[
              _TicketCard(
                ticket: ticket,
                onTap: () => _showTicketDetailsSheet(context, ticket),
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

  void _showTicketDetailsSheet(BuildContext context, SupportTicket ticket) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TicketDetailsView(
        ticket: ticket,
        onUpdateStatus: (newStatus, resolutionNote) async {
          Navigator.of(ctx).pop();
          try {
            await ref
                .read(supportTicketRepositoryProvider)
                .updateTicketStatus(ticket.id, newStatus,
                    resolutionNote: resolutionNote);
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Ticket updated to "$newStatus".'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to update ticket status.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
        onAddReply: (replyText) async {
          Navigator.of(ctx).pop();
          try {
            final msg = SupportTicketMessage(
              id: const Uuid().v4(),
              senderName: 'Super Admin Desk',
              senderRole: 'superAdmin',
              message: replyText,
              createdAt: DateTime.now(),
              isStaffReply: true,
            );
            await ref
                .read(supportTicketRepositoryProvider)
                .addTicketMessage(ticket.id, msg);

            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Reply dispatched to academy administrator.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to send reply.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
        onDelete: () async {
          final confirmed = await showConfirmationDialog(
            ctx,
            title: 'Delete Ticket',
            message:
                'Permanently remove ticket ${ticket.ticketNumber} from records?',
            confirmLabel: 'Delete',
            destructive: true,
          );
          if (confirmed == true && ctx.mounted) {
            Navigator.of(ctx).pop();
            try {
              await ref
                  .read(supportTicketRepositoryProvider)
                  .deleteTicket(ticket.id);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Ticket deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (_) {}
          }
        },
      ),
    );
  }

  void _openNewTicketModal(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NewTicketForm(
        onSubmit: (ticket) async {
          Navigator.of(ctx).pop();
          try {
            await ref
                .read(supportTicketRepositoryProvider)
                .createTicket(ticket);
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Support ticket logged successfully!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to log ticket.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          ticket.ticketNumber,
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _priorityBadge(ticket.priority),
                    ],
                  ),
                  _statusBadge(ticket.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                children: [
                  AcademyAvatar(name: ticket.academyName, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.academyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${ticket.contactName} • ${ticket.categoryLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('MMM dd • hh:mm a').format(ticket.updatedAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final (color, label) = switch (priority.toLowerCase()) {
      'urgent' => (const Color(0xFFEF4444), 'URGENT'),
      'high' => (const Color(0xFFF59E0B), 'HIGH'),
      'low' => (const Color(0xFF10B981), 'LOW'),
      _ => (const Color(0xFF38BDF8), 'MEDIUM'),
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

  Widget _statusBadge(String status) {
    final (color, label) = switch (status.toLowerCase()) {
      'open' => (const Color(0xFFEF4444), 'Open'),
      'in_progress' => (const Color(0xFFF59E0B), 'In Progress'),
      'resolved' => (const Color(0xFF10B981), 'Resolved'),
      _ => (Colors.grey, 'Closed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TicketDetailsView extends StatefulWidget {
  const _TicketDetailsView({
    required this.ticket,
    required this.onUpdateStatus,
    required this.onAddReply,
    required this.onDelete,
  });

  final SupportTicket ticket;
  final void Function(String status, String? note) onUpdateStatus;
  final void Function(String reply) onAddReply;
  final VoidCallback onDelete;

  @override
  State<_TicketDetailsView> createState() => _TicketDetailsViewState();
}

class _TicketDetailsViewState extends State<_TicketDetailsView> {
  final _replyController = TextEditingController();
  final _resolutionNoteController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    _resolutionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                Text(
                  t.ticketNumber,
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.categoryLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Ticket',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.subject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),

            // Academy & Contact Info
            Row(
              children: [
                AcademyAvatar(name: t.academyName, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.academyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${t.contactName} (${t.contactEmail})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Conversation Thread
            if (t.messages.isNotEmpty) ...[
              const Text(
                'Activity Thread',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              for (final msg in t.messages) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isStaffReply
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: msg.isStaffReply
                          ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            msg.senderName,
                            style: TextStyle(
                              color: msg.isStaffReply
                                  ? const Color(0xFF818CF8)
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd • hh:mm a')
                                .format(msg.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],

            const SizedBox(height: 12),
            const Text(
              'Update Status',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!t.isInProgress)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    icon: const Icon(Icons.pending_actions_rounded, size: 16),
                    label: const Text('Mark In Progress'),
                    onPressed: () => widget.onUpdateStatus('in_progress', null),
                  ),
                if (!t.isResolved)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark Resolved'),
                    onPressed: () => widget.onUpdateStatus('resolved',
                        _resolutionNoteController.text.trim().isNotEmpty
                            ? _resolutionNoteController.text.trim()
                            : 'Resolved by Super Admin Desk'),
                  ),
                if (!t.isClosed)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Close Ticket'),
                    onPressed: () => widget.onUpdateStatus('closed', null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Reply Box
            const Text(
              'Add Admin Response / Resolution Note',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _replyController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type response to academy administrator...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Reply'),
                onPressed: () {
                  if (_replyController.text.trim().isNotEmpty) {
                    widget.onAddReply(_replyController.text.trim());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTicketForm extends StatefulWidget {
  const _NewTicketForm({required this.onSubmit});

  final Future<void> Function(SupportTicket ticket) onSubmit;

  @override
  State<_NewTicketForm> createState() => _NewTicketFormState();
}

class _NewTicketFormState extends State<_NewTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _academyName = TextEditingController();
  final _academyCode = TextEditingController();
  final _contactName = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactPhone = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();

  String _category = 'technical';
  String _priority = 'medium';
  bool _loading = false;

  @override
  void dispose() {
    _academyName.dispose();
    _academyCode.dispose();
    _contactName.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final id = const Uuid().v4();
    final ticketNum = 'TICK-${1000 + (DateTime.now().millisecond % 900)}';

    final ticket = SupportTicket(
      id: id,
      ticketNumber: ticketNum,
      academyId: const Uuid().v4(),
      academyName: _academyName.text.trim(),
      academyCode: _academyCode.text.trim().toUpperCase(),
      contactName: _contactName.text.trim(),
      contactEmail: _contactEmail.text.trim(),
      contactPhone: _contactPhone.text.trim(),
      subject: _subject.text.trim(),
      description: _description.text.trim(),
      category: _category,
      priority: _priority,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [
        SupportTicketMessage(
          id: const Uuid().v4(),
          senderName: _contactName.text.trim(),
          senderRole: 'academyAdmin',
          message: _description.text.trim(),
          createdAt: DateTime.now(),
        ),
      ],
    );

    await widget.onSubmit(ticket);
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
                'Log New Support Ticket',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record an incoming inquiry or technical request for an academy.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _academyName,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Academy Name *',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter academy name' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _academyCode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Academy Code *',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter code' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _contactName,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contact Person *',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter contact' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contactEmail,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Contact Email *',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'technical', child: Text('Technical')),
                        DropdownMenuItem(
                            value: 'billing', child: Text('Billing')),
                        DropdownMenuItem(
                            value: 'account', child: Text('Account')),
                        DropdownMenuItem(
                            value: 'feature_request',
                            child: Text('Feature')),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'technical'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(
                            value: 'high', child: Text('High')),
                        DropdownMenuItem(
                            value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (v) =>
                          setState(() => _priority = v ?? 'medium'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _subject,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subject *',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter subject' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _description,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Inquiry Description *',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter description' : null,
              ),
              const SizedBox(height: 20),

              LoadingButton(
                label: 'Save & Log Ticket',
                icon: Icons.check_rounded,
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
