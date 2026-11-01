import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/communication_providers.dart';
import '../../domain/app_notification.dart';

/// Opens the slide-up modal sheet presenting the user's live in-app notifications.
Future<void> showNotificationCenterModal(BuildContext context, {String? academyId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => NotificationCenterModal(academyId: academyId),
  );
}

class NotificationCenterModal extends ConsumerStatefulWidget {
  const NotificationCenterModal({super.key, this.academyId});

  final String? academyId;

  @override
  ConsumerState<NotificationCenterModal> createState() =>
      _NotificationCenterModalState();
}

class _NotificationCenterModalState
    extends ConsumerState<NotificationCenterModal> {
  String _selectedFilter = 'all'; // 'all', 'broadcast', 'inquiry'

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(userNotificationsStreamProvider);
    final allNotifs = notifsAsync.value ?? const <AppNotification>[];
    final unreadCount = allNotifs.where((n) => !n.isRead).length;

    final filteredNotifs = allNotifs.where((n) {
      if (_selectedFilter == 'broadcast') return n.type == 'broadcast';
      if (_selectedFilter == 'inquiry') {
        return n.type.startsWith('inquiry');
      }
      return true;
    }).toList();

    final auth = ref.watch(authControllerProvider);
    final (authAcademyId, recipientId) = switch (auth) {
      AuthAuthenticated(:final user) => (
          user.academyId ?? '',
          user.rollNumber != null && user.rollNumber!.isNotEmpty
              ? user.rollNumber!
              : user.id,
        ),
      _ => ('', ''),
    };
    final academyId = (widget.academyId?.isNotEmpty == true)
        ? widget.academyId!
        : authAcademyId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF38BDF8),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Notifications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0 && academyId.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.done_all, size: 15),
                    label: const Text(
                      'Mark all read',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      await ref
                          .read(communicationRepositoryProvider)
                          .markAllNotificationsAsRead(academyId, recipientId);
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),

          // Filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All (${allNotifs.length})', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Announcements', 'broadcast'),
                const SizedBox(width: 8),
                _buildFilterChip('Inquiries & Q&A', 'inquiry'),
              ],
            ),
          ),

          const SizedBox(height: 6),
          const Divider(color: Colors.white12, height: 1),

          // Notifications List
          Flexible(
            child: filteredNotifs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "You're all caught up!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No new notifications or alerts at this time.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: filteredNotifs.length,
                    itemBuilder: (context, index) {
                      final n = filteredNotifs[index];
                      return _buildNotificationTile(n, academyId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.25)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF818CF8) : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notif, String academyId) {
    final (icon, iconColor) = switch (notif.type) {
      'broadcast' => (Icons.campaign_outlined, const Color(0xFFF59E0B)),
      'inquiry_question' => (Icons.help_outline, const Color(0xFF38BDF8)),
      'inquiry_reply' => (Icons.mark_chat_read_outlined, const Color(0xFF10B981)),
      _ => (Icons.notifications_outlined, const Color(0xFF818CF8)),
    };

    final timeStr = _formatRelativeTime(notif.createdAt);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFF87171)),
      ),
      onDismissed: (_) {
        if (academyId.isNotEmpty) {
          ref
              .read(communicationRepositoryProvider)
              .markNotificationAsRead(academyId, notif.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!notif.isRead && academyId.isNotEmpty) {
              ref
                  .read(communicationRepositoryProvider)
                  .markNotificationAsRead(academyId, notif.id);
            }
          },
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notif.isRead
                  ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                  : const Color(0xFF1E293B).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notif.isRead
                    ? Colors.white10
                    : const Color(0xFF6366F1).withValues(alpha: 0.4),
                width: notif.isRead ? 0.8 : 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF38BDF8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notif.body,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}
