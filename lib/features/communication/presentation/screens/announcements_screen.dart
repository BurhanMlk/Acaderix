import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/academics/application/course_repository_provider.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../super_admin/application/platform_broadcast_providers.dart';
import '../../../super_admin/domain/platform_broadcast.dart';
import '../../application/communication_providers.dart';
import '../../domain/announcement.dart';
import '../widgets/announcement_card.dart';

/// Screen for Academy Admin to manage broadcasts, message casts,
/// and campus-wide announcements.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key, this.academyId});

  final String? academyId;

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _audienceFilter = 'all'; // 'all', 'staff', 'students'
  int _selectedTab = 0; // 0: Campus Broadcasts, 1: Super Admin Platform Notices

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final effectiveAcademyId = (widget.academyId?.isNotEmpty == true)
        ? widget.academyId!
        : (user?.academyId ?? '');

    final announcementsAsync = ref.watch(
      announcementsStreamProvider((
        academyId: effectiveAcademyId,
        audience: null,
        branchId: null,
      )),
    );
    final announcements = announcementsAsync.value ?? const [];

    final platformBroadcastsAsync = ref.watch(platformBroadcastsStreamProvider);
    final platformBroadcasts = (platformBroadcastsAsync.value ??
            const <PlatformBroadcast>[])
        .where((b) => b.isActive)
        .toList();

    final theme = Theme.of(context);

    final filtered = announcements.where((a) {
      if (_audienceFilter == 'all') return true;
      return a.audience == _audienceFilter;
    }).toList();

    final urgentCount = announcements.where((a) => a.isUrgent).length;
    final urgentPlatformCount =
        platformBroadcasts.where((b) => b.isUrgent).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Noticeboard & Broadcasts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_selectedTab == 0) ...[
            IconButton(
              tooltip: 'New Broadcast',
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF38BDF8)),
              onPressed: () =>
                  _showCreateAnnouncementDialog(context, effectiveAcademyId),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign, size: 20),
              label: const Text(
                'Broadcast Announcement',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () =>
                  _showCreateAnnouncementDialog(context, effectiveAcademyId),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Segmented Navigation: Campus vs Super Admin Notices
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: _selectedTab == 0
                            ? Border.all(color: const Color(0xFF6366F1))
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.campaign_outlined,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Campus (${announcements.length})',
                                style: TextStyle(
                                  color: _selectedTab == 0
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: _selectedTab == 1
                            ? Border.all(color: const Color(0xFF6366F1))
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_outlined,
                                  size: 16, color: Color(0xFF818CF8)),
                              const SizedBox(width: 6),
                              Text(
                                'From Super Admin (${platformBroadcasts.length})',
                                style: TextStyle(
                                  color: _selectedTab == 1
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: _selectedTab == 1
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_selectedTab == 0) ...[
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.campaign_outlined,
                            color: Color(0xFF818CF8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${announcements.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Broadcasts Sent',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFF87171),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$urgentCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Urgent Alerts',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Audience Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAudienceChip(
                      'All Audience (${announcements.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildAudienceChip('Staff Only', 'staff'),
                  const SizedBox(width: 8),
                  _buildAudienceChip('Students Only', 'students'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.campaign_outlined,
                        size: 44,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Broadcast Announcements',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Post campus-wide notices, exam alerts, and institutional messages to staff and students.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((a) {
                return AnnouncementCard(
                  announcement: a,
                  onDelete: () async {
                    await ref
                        .read(communicationRepositoryProvider)
                        .deleteAnnouncement(a.academyId, a.id);
                  },
                );
              }),
          ] else ...[
            // Super Admin Platform Notices View
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Color(0xFF818CF8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${platformBroadcasts.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Platform Notices',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.priority_high_rounded,
                            color: Color(0xFFF87171),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$urgentPlatformCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Critical Alerts',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (platformBroadcasts.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 44,
                        color: Colors.white30,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No Platform Notices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Platform maintenance, billing announcements, and upgrades from Super Admin will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final pb in platformBroadcasts) ...[
                _AcademyPlatformNoticeCard(
                  broadcast: pb,
                  onTap: () => _showPlatformNoticeDetailDialog(context, pb),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ],
      ),
    );
  }

  Widget _buildAudienceChip(String label, String value) {
    final isSelected = _audienceFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _audienceFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.25)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context, String academyId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateAnnouncementSheet(academyId: academyId),
    );
  }

  void _showPlatformNoticeDetailDialog(
    BuildContext context,
    PlatformBroadcast broadcast,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF818CF8),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Super Admin Notice',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    broadcast.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        broadcast.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: broadcast.isUrgent
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        broadcast.priority.toUpperCase(),
                        style: TextStyle(
                          color: broadcast.isUrgent
                              ? const Color(0xFFF87171)
                              : const Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd • hh:mm a').format(broadcast.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Text(
                  broadcast.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target Audience: ${broadcast.audienceLabel}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AcademyPlatformNoticeCard extends StatelessWidget {
  const _AcademyPlatformNoticeCard({
    required this.broadcast,
    required this.onTap,
  });

  final PlatformBroadcast broadcast;
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
              Row(
                children: [
                  _priorityBadge(broadcast.priority),
                  const SizedBox(width: 8),
                  _categoryChip(broadcast.category),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(broadcast.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                broadcast.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: Color(0xFF818CF8),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Official Super Admin Broadcast',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (broadcast.sentPushNotification) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 13,
                      color: Colors.amber.withValues(alpha: 0.8),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.4),
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
    final (color, label) = switch (priority.toLowerCase()) {
      'urgent' => (const Color(0xFFEF4444), 'URGENT'),
      'high' => (const Color(0xFFF59E0B), 'HIGH'),
      'low' => (const Color(0xFF10B981), 'LOW'),
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

class _CreateAnnouncementSheet extends ConsumerStatefulWidget {
  const _CreateAnnouncementSheet({this.academyId});

  final String? academyId;

  @override
  ConsumerState<_CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState
    extends ConsumerState<_CreateAnnouncementSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _audience = 'all'; // 'all', 'staff', 'students'
  String _priority = 'normal'; // 'normal', 'urgent'
  String _category = 'General';
  String _selectedCourseId = '';
  String _selectedCourseName = '';

  bool _isPublishing = false;

  static const _categories = [
    'General',
    'Exam Alert',
    'Holiday',
    'Fee Notice',
    'Emergency',
    'Event',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final academyId = (widget.academyId?.isNotEmpty == true)
        ? widget.academyId!
        : (user?.academyId ?? '');

    final courses = academyId.isNotEmpty
        ? ref.watch(coursesStreamProvider(academyId)).value ?? []
        : [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: Color(0xFF38BDF8), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast New Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Audience Selector
                const Text(
                  'Select Target Audience',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildAudienceOption(
                        label: 'All Campus',
                        value: 'all',
                        icon: Icons.groups_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAudienceOption(
                        label: 'Staff Only',
                        value: 'staff',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAudienceOption(
                        label: 'Students Only',
                        value: 'students',
                        icon: Icons.school_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Priority & Category Row
                Row(
                  children: [
                    // Priority Toggle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Priority Level',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildPriorityButton('Normal', 'normal'),
                              const SizedBox(width: 6),
                              _buildPriorityButton('Urgent Alert', 'urgent'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Category dropdown
                const Text(
                  'Notice Category',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      value: _category,
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                ),

                if (courses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Optional Course Link',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        value: _selectedCourseId.isEmpty ? '' : _selectedCourseId,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text(
                              'None (General Notice)',
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ),
                          ...courses.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val ?? '';
                            if (_selectedCourseId.isNotEmpty) {
                              final match = courses.where((c) => c.id == val).firstOrNull;
                              _selectedCourseName = match?.name ?? '';
                            } else {
                              _selectedCourseName = '';
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Title field
                const Text(
                  'Announcement Title',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Mid-Term Examination Schedule Released',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 14),

                // Content field
                const Text(
                  'Message Body & Description',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Provide full details for students and faculty regarding timings, prerequisites, or action required...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 24),

                // Publish Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isPublishing
                          ? 'Broadcasting Message...'
                          : 'Broadcast & Send Push Alert',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _isPublishing ? null : _publishAnnouncement,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _audience == value;
    return GestureDetector(
      onTap: () => setState(() => _audience = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.25)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF818CF8) : Colors.white60,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, String value) {
    final isSelected = _priority == value;
    final isUrgent = value == 'urgent';
    final activeColor = isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUrgent) ...[
              Icon(Icons.bolt, size: 14, color: isSelected ? activeColor : Colors.white60),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishAnnouncement() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and message content.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final auth = ref.read(authControllerProvider);
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final academyId = (widget.academyId?.isNotEmpty == true)
        ? widget.academyId!
        : (user?.academyId ?? '');
    if (academyId.isEmpty) return;

    setState(() => _isPublishing = true);

    try {
      final announcement = Announcement(
        id: '',
        academyId: academyId,
        title: title,
        content: content,
        audience: _audience,
        priority: _priority,
        category: _category,
        courseId: _selectedCourseId,
        courseName: _selectedCourseName,
        authorId: user?.id ?? '',
        authorName: user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'Academy Administration',
        authorRole: 'academyAdmin',
        createdAt: DateTime.now(),
      );

      await ref
          .read(communicationRepositoryProvider)
          .sendAnnouncement(announcement);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast announcement published and delivered.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish announcement: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }
}
