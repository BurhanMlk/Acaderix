import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../super_admin/application/support_ticket_providers.dart';
import '../../../super_admin/domain/support_ticket.dart';
import '../../application/academy_access_provider.dart';
import '../../domain/academy_access_models.dart';

/// Screen for Academy Admin to communicate with Super Admin,
/// log support tickets, track resolutions, and chat in message threads.
class AcademySupportScreen extends ConsumerStatefulWidget {
  const AcademySupportScreen({super.key});

  @override
  ConsumerState<AcademySupportScreen> createState() =>
      _AcademySupportScreenState();
}

class _AcademySupportScreenState extends ConsumerState<AcademySupportScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsStreamProvider);
    final access = ref.watch(academyAccessProvider).value;

    final effectiveAcademyId = access?.academyId ?? '';
    final effectiveAcademyCode = access?.academyCode ?? '';
    final effectiveOwnerEmail = access?.ownerEmail ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ticketsAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => ErrorState(
          message: 'Failed to load support tickets.',
          onRetry: () => ref.invalidate(supportTicketsStreamProvider),
        ),
        data: (allTickets) {
          // Filter tickets to only those belonging to this academy
          final academyTickets = allTickets.where((t) {
            final matchesId = effectiveAcademyId.isNotEmpty &&
                t.academyId == effectiveAcademyId;
            final matchesCode = effectiveAcademyCode.isNotEmpty &&
                t.academyCode.toUpperCase() ==
                    effectiveAcademyCode.toUpperCase();
            final matchesEmail = effectiveOwnerEmail.isNotEmpty &&
                t.contactEmail.toLowerCase() ==
                    effectiveOwnerEmail.toLowerCase();
            return matchesId || matchesCode || matchesEmail;
          }).toList();

          return _buildContent(context, academyTickets, access);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text(
          'Ask Super Admin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _openNewTicketModal(context, access),
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

  Widget _buildContent(
    BuildContext context,
    List<SupportTicket> tickets,
    AcademyAccessInfo? access,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = tickets.where((t) {
      final matchesQuery = query.isEmpty ||
          t.ticketNumber.toLowerCase().contains(query) ||
          t.subject.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);

      final matchesStatus = _selectedStatus == 'all' ||
          t.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesQuery && matchesStatus;
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
                      title: 'My Tickets',
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
              hintText: 'Search by ticket # or subject...',
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status Filter Chips
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inquiries List
          if (filtered.isEmpty)
            EmptyState(
              title: query.isNotEmpty
                  ? 'No matching inquiries'
                  : 'No support inquiries yet',
              message: query.isNotEmpty
                  ? 'Try modifying your search query or filters.'
                  : 'Have a question or need assistance from platform administrators? Tap "Ask Super Admin".',
              icon: Icons.support_agent_rounded,
            )
          else
            for (final ticket in filtered) ...[
              _AcademyTicketCard(
                ticket: ticket,
                onTap: () => _showTicketConversationSheet(context, ticket),
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

  void _openNewTicketModal(BuildContext context, AcademyAccessInfo? access) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NewTicketModal(
        access: access,
        onSubmit: (newTicket) async {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(ctx).pop();
          try {
            await ref
                .read(supportTicketRepositoryProvider)
                .createTicket(newTicket);
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Ticket "${newTicket.ticketNumber}" submitted to Super Admin!',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to submit support ticket.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showTicketConversationSheet(
    BuildContext context,
    SupportTicket initialTicket,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _TicketConversationView(
        ticketId: initialTicket.id,
        initialTicket: initialTicket,
      ),
    );
  }
}

class _AcademyTicketCard extends StatelessWidget {
  const _AcademyTicketCard({required this.ticket, required this.onTap});

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
                  _categoryChip(ticket.categoryLabel),
                  _priorityBadge(ticket.priority),
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
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${ticket.messages.length} ${ticket.messages.length == 1 ? 'message' : 'messages'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (ticket.messages.any((m) => m.isStaffReply))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Admin Replied',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(ticket.updatedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
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

class _TicketConversationView extends ConsumerStatefulWidget {
  const _TicketConversationView({
    required this.ticketId,
    required this.initialTicket,
  });

  final String ticketId;
  final SupportTicket initialTicket;

  @override
  ConsumerState<_TicketConversationView> createState() =>
      _TicketConversationViewState();
}

class _TicketConversationViewState
    extends ConsumerState<_TicketConversationView> {
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply(SupportTicket ticket) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final authState = ref.read(authControllerProvider);
    final user = switch (authState) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final senderName =
        user?.displayName.isNotEmpty == true ? user!.displayName : 'Academy Admin';

    final message = SupportTicketMessage(
      id: const Uuid().v4(),
      senderName: senderName,
      senderRole: 'academyAdmin',
      message: text,
      createdAt: DateTime.now(),
    );

    try {
      await ref
          .read(supportTicketRepositoryProvider)
          .addTicketMessage(ticket.id, message);
      _replyController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reply. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsStreamProvider);
    final ticket = ticketsAsync.value
            ?.where((t) => t.id == widget.ticketId)
            .firstOrNull ??
        widget.initialTicket;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
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
          const SizedBox(height: 14),

          // Header Row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.ticketNumber,
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(ticket.status),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            ticket.subject,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Resolution note banner (if resolved)
          if (ticket.resolutionNote != null &&
              ticket.resolutionNote!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resolution by Platform Admin',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ticket.resolutionNote!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Message Thread List
          const Text(
            'Conversation Thread',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ticket.messages.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No replies yet. Super Admin will respond shortly.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: ticket.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = ticket.messages[i];
                      final isSuperAdmin = msg.isStaffReply;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSuperAdmin
                              ? const Color(0xFF6366F1).withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSuperAdmin
                                ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isSuperAdmin) ...[
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 13,
                                    color: Color(0xFF818CF8),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    isSuperAdmin
                                        ? 'Super Admin (Platform Support)'
                                        : msg.senderName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSuperAdmin
                                          ? const Color(0xFF818CF8)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM dd • hh:mm a')
                                      .format(msg.createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
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
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // Message Composer
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type your message to Super Admin...',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                onPressed: _isSending ? null : () => _sendReply(ticket),
              ),
            ],
          ),
        ],
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

class _NewTicketModal extends StatefulWidget {
  const _NewTicketModal({required this.access, required this.onSubmit});

  final AcademyAccessInfo? access;
  final Future<void> Function(SupportTicket ticket) onSubmit;

  @override
  State<_NewTicketModal> createState() => _NewTicketModalState();
}

class _NewTicketModalState extends State<_NewTicketModal> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'technical';
  String _priority = 'medium';
  bool _loading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final id = const Uuid().v4();
    final ticketNum = 'TICK-${1000 + (DateTime.now().millisecond % 900)}';
    final access = widget.access;

    final academyName = access?.academyName.isNotEmpty == true
        ? access!.academyName
        : 'Academy Administrator';
    final academyCode =
        access?.academyCode.isNotEmpty == true ? access!.academyCode : 'ACAD';
    final contactName =
        access?.ownerName.isNotEmpty == true ? access!.ownerName : 'Admin';
    final contactEmail =
        access?.ownerEmail.isNotEmpty == true ? access!.ownerEmail : '';
    final contactPhone =
        access?.supportPhone.isNotEmpty == true ? access!.supportPhone : '';

    final ticket = SupportTicket(
      id: id,
      ticketNumber: ticketNum,
      academyId: access?.academyId ?? const Uuid().v4(),
      academyName: academyName,
      academyCode: academyCode.toUpperCase(),
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [
        SupportTicketMessage(
          id: const Uuid().v4(),
          senderName: contactName,
          senderRole: 'academyAdmin',
          message: _descriptionController.text.trim(),
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
                'Submit Inquire / Ticket to Super Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Our platform support team will review and reply directly to your inquiry.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),

              // Category Field
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Inquiry Category',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'technical',
                    child: Text('Technical Issue / Bug'),
                  ),
                  DropdownMenuItem(
                    value: 'billing',
                    child: Text('Billing & Subscriptions'),
                  ),
                  DropdownMenuItem(
                    value: 'account',
                    child: Text('Account / Quotas'),
                  ),
                  DropdownMenuItem(
                    value: 'feature_request',
                    child: Text('Feature Request'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _category = v ?? 'technical'),
              ),
              const SizedBox(height: 14),

              // Priority Field
              DropdownButtonFormField<String>(
                initialValue: _priority,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Priority Level',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'low',
                    child: Text('Low (General Question)'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Medium (Normal Request)'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('High (Important Need)'),
                  ),
                  DropdownMenuItem(
                    value: 'urgent',
                    child: Text('Urgent (System Blocker)'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _priority = v ?? 'medium'),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g., Request branch quota increase...',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter subject' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Detailed Inquiry *',
                  hintText:
                      'Describe your issue, requirements, or question clearly...',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter inquiry description'
                    : null,
              ),
              const SizedBox(height: 20),

              LoadingButton(
                label: 'Submit Ticket to Super Admin',
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
