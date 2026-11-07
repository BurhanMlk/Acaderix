import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/communication/application/communication_providers.dart';
import 'package:academy_management/features/communication/presentation/screens/academic_chat_screen.dart';
import 'package:academy_management/features/student/application/student_providers.dart';

/// Tab displaying the student's enrolled courses and weekly timetable.
class StudentCoursesTab extends ConsumerStatefulWidget {
  const StudentCoursesTab({super.key});

  @override
  ConsumerState<StudentCoursesTab> createState() => _StudentCoursesTabState();
}

class _StudentCoursesTabState extends ConsumerState<StudentCoursesTab> {
  int _selectedView = 0; // 0 = Enrolled Courses, 1 = Weekly Timetable
  int _selectedDayIndex = 0; // 0 = Mon, 1 = Tue, 2 = Wed, 3 = Thu, 4 = Fri, 5 = Sat

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _dayFullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(currentStudentCoursesProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // View Switcher (Courses vs Timetable)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  title: 'My Courses (${courses.length})',
                  icon: Icons.menu_book_outlined,
                  isSelected: _selectedView == 0,
                  onTap: () => setState(() => _selectedView = 0),
                ),
              ),
              Expanded(
                child: _buildToggleButton(
                  title: 'Class Timetable',
                  icon: Icons.calendar_view_week_outlined,
                  isSelected: _selectedView == 1,
                  onTap: () => setState(() => _selectedView = 1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_selectedView == 0) ...[
          // Courses List View
          if (courses.isEmpty)
            _buildEmptyCoursesState(theme)
          else ...[
            Text(
              'Enrolled Subjects (${courses.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...courses.map((course) => _buildCourseCard(course)),
          ],
        ] else ...[
          // Weekly Timetable View
          _buildTimetableSection(courses, theme),
        ],
      ],
    );
  }

  Widget _buildToggleButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_stories_outlined,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (course.courseCode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                course.courseCode,
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Text(
                            course.isActive ? 'Active Batch' : 'Archived',
                            style: TextStyle(
                              color: course.isActive
                                  ? const Color(0xFF34D399)
                                  : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (course.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                course.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_pin_outlined,
                        size: 15,
                        color: Color(0xFF818CF8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          course.teacherName.isNotEmpty
                              ? course.teacherName
                              : 'Faculty Assigned',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (course.room.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 15,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Room ${course.room}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (course.schedule.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 14,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      course.schedule,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: BorderSide(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 14),
                label: const Text(
                  'Message Teacher',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  final student = ref.read(currentStudentProfileProvider);
                  if (student == null) return;
                  final academyId = course.academyId.isNotEmpty
                      ? course.academyId
                      : student.academyId;
                  final teacherId = course.teacherId.isNotEmpty
                      ? course.teacherId
                      : (course.teacherName.isNotEmpty
                          ? course.teacherName
                          : 'faculty');
                  final teacherName = course.teacherName.isNotEmpty
                      ? course.teacherName
                      : 'Course Instructor';

                  try {
                    final repo = ref.read(communicationRepositoryProvider);
                    final conv = await repo.getOrCreateConversation(
                      academyId: academyId,
                      teacherId: teacherId,
                      teacherName: teacherName,
                      studentId: student.id,
                      studentName: student.fullName,
                      studentRollNumber: student.rollNumber,
                      courseId: course.id,
                      courseName: course.name,
                    );

                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AcademicChatScreen(
                            academyId: conv.academyId,
                            conversationId: conv.id,
                            otherPartyName: teacherName,
                            otherPartySubtitle: course.name,
                            otherPartyRole: 'teacher',
                            recipientId: teacherId,
                            recipientRole: 'staff',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to open chat: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableSection(List<Course> courses, ThemeData theme) {
    final activeDayName = _dayFullNames[_selectedDayIndex];
    final activeDayShort = _days[_selectedDayIndex];

    // Filter courses matching the day, or all courses if schedule contains day or no day specified
    final dayCourses = courses.where((c) {
      final s = c.schedule.toLowerCase();
      if (s.isEmpty) return true;
      return s.contains(activeDayShort.toLowerCase()) ||
          s.contains(activeDayName.toLowerCase()) ||
          s.contains('daily') ||
          s.contains('everyday');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day selector tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_days.length, (index) {
              final isSelected = _selectedDayIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF818CF8)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(
                    _days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          '$activeDayName Schedule',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        if (dayCourses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No scheduled lectures for $activeDayName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...dayCourses.map((course) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Color(0xFF818CF8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.teacherName.isNotEmpty
                              ? 'Teacher: ${course.teacherName}'
                              : 'Faculty Member',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        if (course.schedule.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            course.schedule,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (course.room.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rm ${course.room}',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyCoursesState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: Colors.white30,
            ),
            const SizedBox(height: 12),
            Text(
              'No Enrolled Courses Found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your enrolled subjects and batches will appear here once registered by your academy administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
