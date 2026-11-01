import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/communication_providers.dart';
import 'notification_center_modal.dart';

/// Reusable AppBar bell action button displaying real-time unread notification badge
/// and opening the notification center modal sheet.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({
    super.key,
    this.academyId,
    this.userId,
  });

  final String? academyId;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () =>
              showNotificationCenterModal(context, academyId: academyId),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFF0F172A), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
