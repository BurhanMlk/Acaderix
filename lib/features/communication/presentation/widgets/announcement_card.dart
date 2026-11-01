import 'package:academy_management/core/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/announcement.dart';

/// Glass card displaying a broadcast message cast or institutional announcement.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onDelete,
    this.canDelete = false,
  });

  final Announcement announcement;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final isUrgent = announcement.isUrgent;
    final dateStr = DateFormat('MMM d, yyyy • hh:mm a').format(announcement.createdAt);

    final (audienceColor, audienceLabel) = switch (announcement.audience) {
      'staff' => (const Color(0xFF6366F1), 'Staff Only'),
      'students' => (const Color(0xFF38BDF8), 'Students Only'),
      _ => (const Color(0xFF10B981), 'All Campus'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFF87171)),
                        SizedBox(width: 4),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: audienceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: audienceColor, width: 0.8),
                  ),
                  child: Text(
                    audienceLabel,
                    style: TextStyle(
                      color: audienceColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    announcement.category,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (announcement.isPinned)
                  const Icon(
                    Icons.push_pin,
                    size: 14,
                    color: Color(0xFFFBBF24),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              announcement.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),

            // Content
            Text(
              announcement.content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            if (announcement.courseName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.book_outlined, size: 13, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      announcement.courseName,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Footer: Author & Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        child: const Icon(Icons.person, size: 12, color: Colors.white70),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          announcement.authorName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
