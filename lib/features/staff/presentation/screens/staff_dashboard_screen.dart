import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../communication/application/communication_providers.dart';
import '../../../communication/presentation/screens/student_inquiries_screen.dart';
import '../../../communication/presentation/widgets/announcement_card.dart';
import '../../application/staff_providers.dart';

/// Staff Dashboard home view displaying staff profile, quick metrics, and direct action shortcuts.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  final void Function(int tabIndex) onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffMemberProvider);
    final branch = ref.watch(currentStaffBranchProvider);
    final metrics = ref.watch(staffDashboardMetricsProvider);
    final assignedCourses = ref.watch(staffAssignedCoursesProvider);
    final todayRecords = ref.watch(staffTodayAttendanceRecordsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Staff Hero Card
        _StaffHeroCard(
          staffName: staff?.fullName ?? 'Staff Member',
          staffId: staff?.staffId.isNotEmpty == true ? staff!.staffId : 'STAFF',
          jobTitle: staff?.jobTitle.isNotEmpty == true ? staff!.jobTitle : 'Faculty',
          branchName: branch?.name ?? 'Assigned Campus',
          email: staff?.email ?? '',
          phone: staff?.phone ?? '',
          status: staff?.status ?? 'active',
        ),
        const SizedBox(height: 16),

        // Key Metrics Header
        Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'My Campus Overview',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Metrics 2x2 Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isNarrow ? 1.15 : 1.45,
              children: [
                _StaffMetricCard(
                  title: 'Students',
                  value: '${metrics.totalStudents}',
                  subtitle: branch != null ? branch.name : 'Campus Roster',
                  icon: Icons.school_outlined,
                  color: const Color(0xFF38BDF8),
                  onTap: () => onNavigateToTab(3),
                ),
                _StaffMetricCard(
                  title: "Today's Attendance",
                  value: '${metrics.attendanceRate.toStringAsFixed(0)}%',
                  subtitle: '${metrics.presentToday} Present • ${metrics.absentToday} Absent',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () => onNavigateToTab(1),
                ),
                _StaffMetricCard(
                  title: 'My Courses',
                  value: '${metrics.totalCourses}',
                  subtitle: '${assignedCourses.length} Assigned Batches',
                  icon: Icons.menu_book_outlined,
                  color: const Color(0xFFF59E0B),
                  onTap: () => onNavigateToTab(1),
                ),
                _StaffMetricCard(
                  title: 'Leave Balance',
                  value: '${staff?.leaveBalance ?? 0} Days',
                  subtitle: 'Annual Allotted',
                  icon: Icons.beach_access_outlined,
                  color: const Color(0xFFA855F7),
                  onTap: () => onNavigateToTab(4),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Assigned Courses Section (if staff has courses)
        if (assignedCourses.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'My Assigned Courses & Batches',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...assignedCourses.map((course) {
            final courseRecords =
                todayRecords.where((r) => r.courseId == course.id).toList();
            final isSubmitted = courseRecords.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSubmitted
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                ),
              ),
              child: InkWell(
                onTap: () {
                  ref.read(selectedStaffCourseIdProvider.notifier).state =
                      course.id;
                  onNavigateToTab(1);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                '${course.enrolledStudentIds.length} Enrolled',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (course.schedule.isNotEmpty)
                                Text(
                                  '• ${course.schedule}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isSubmitted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSubmitted
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                      child: Text(
                        isSubmitted ? 'SUBMITTED' : 'TAKE ATTENDANCE',
                        style: TextStyle(
                          color: isSubmitted
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFBBF24),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Quick Actions Section
        Row(
          children: [
            const Icon(Icons.flash_on_outlined, size: 18, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Quick Actions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _StaffActionTile(
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF10B981),
          title: "Mark Today's Attendance",
          subtitle: "Record student attendance roster for today's classes",
          onTap: () => onNavigateToTab(1),
        ),
        const SizedBox(height: 10),
        _StaffActionTile(
          icon: Icons.post_add_outlined,
          color: const Color(0xFF38BDF8),
          title: 'Record Exam Marks',
          subtitle: 'Enter quiz, test, and exam scores for students',
          onTap: () => onNavigateToTab(2),
        ),
        const SizedBox(height: 10),
        _StaffActionTile(
          icon: Icons.people_outline,
          color: const Color(0xFFF59E0B),
          title: 'Campus Student Directory',
          subtitle: 'Look up student roll numbers, grades, and parent contacts',
          onTap: () => onNavigateToTab(3),
        ),
        const SizedBox(height: 10),
        _StaffActionTile(
          icon: Icons.question_answer_outlined,
          color: const Color(0xFF38BDF8),
          title: 'Student Q&A Desk',
          subtitle: 'Answer academic doubts and questions from enrolled students',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StudentInquiriesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _StaffActionTile(
          icon: Icons.badge_outlined,
          color: const Color(0xFFA855F7),
          title: 'My Profile & Security',
          subtitle: 'View employment details, salary info, or change password',
          onTap: () => onNavigateToTab(4),
        ),
        const SizedBox(height: 20),

        // Campus Noticeboard Section
        Row(
          children: [
            const Icon(Icons.campaign_outlined,
                size: 18, color: Color(0xFFEC4899)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Campus Noticeboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StaffNoticeboardPreview(academyId: staff?.academyId ?? ''),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StaffHeroCard extends StatelessWidget {
  const _StaffHeroCard({
    required this.staffName,
    required this.staffId,
    required this.jobTitle,
    required this.branchName,
    required this.email,
    required this.phone,
    required this.status,
  });

  final String staffName;
  final String staffId;
  final String jobTitle;
  final String branchName;
  final String email;
  final String phone;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.25),
            const Color(0xFF38BDF8).withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                child: Text(
                  staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _HeroBadge(
                icon: Icons.badge_outlined,
                text: staffId,
                color: const Color(0xFF38BDF8),
              ),
              _HeroBadge(
                icon: Icons.location_city_outlined,
                text: branchName,
                color: const Color(0xFFF59E0B),
              ),
              _HeroBadge(
                icon: Icons.check_circle_outline,
                text: status.toUpperCase(),
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (email.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (phone.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffMetricCard extends StatelessWidget {
  const _StaffMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffActionTile extends StatelessWidget {
  const _StaffActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffNoticeboardPreview extends ConsumerWidget {
  const _StaffNoticeboardPreview({required this.academyId});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (academyId.isEmpty) return const SizedBox.shrink();

    final announcementsAsync =
        ref.watch(staffAnnouncementsProvider(academyId));

    return announcementsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Text(
                  'No recent broadcast announcements',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final topNotices = list.take(3).toList();
        return Column(
          children: topNotices
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnnouncementCard(
                    announcement: a,
                    canDelete: false,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

