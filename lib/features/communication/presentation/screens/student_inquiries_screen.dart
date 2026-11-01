import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/glass.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../staff/application/staff_providers.dart';
import '../../../student/application/student_providers.dart';
import '../../application/communication_providers.dart';
import '../../domain/inquiry.dart';
import 'ask_teacher_modal.dart';

/// Screen displaying course-scoped Student-to-Teacher Q&A threads and inquiries.
/// Allows students to track questions asked to teachers, and allows teachers/staff
/// to reply directly with academic guidance.
class StudentInquiriesScreen extends ConsumerStatefulWidget {
  const StudentInquiriesScreen({
    super.key,
    this.academyId,
    this.teacherId,
    this.studentId,
    this.courseId,
    this.courseName,
  });

  final String? academyId;
  final String? teacherId;
  final String? studentId;
  final String? courseId;
  final String? courseName;

  @override
  ConsumerState<StudentInquiriesScreen> createState() =>
      _StudentInquiriesScreenState();
}

class _StudentInquiriesScreenState
    extends ConsumerState<StudentInquiriesScreen> {
  String _selectedFilter = 'all'; // 'all', 'open', 'answered'

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = switch (authState) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    final currentStaff = ref.watch(currentStaffMemberProvider);
    final currentStudent = ref.watch(currentStudentProfileProvider);

    final effectiveAcademyId = widget.academyId ??
        currentStaff?.academyId ??
        currentStudent?.academyId ??
        user?.academyId ??
        '';

    final effectiveTeacherId = widget.teacherId ?? currentStaff?.id;
    final effectiveStudentId =
        widget.studentId ?? currentStudent?.id ?? user?.id;

    final isTeacher = currentStaff != null || widget.teacherId != null;
    final isStudent = currentStudent != null ||
        widget.studentId != null ||
        (user != null && user.isStudent);

    final repo = ref.watch(communicationRepositoryProvider);
    final Stream<List<StudentInquiry>> inquiriesStream;
    if (isTeacher && effectiveTeacherId != null) {
      inquiriesStream = repo.watchInquiriesForTeacher(
        effectiveAcademyId,
        effectiveTeacherId,
        teacherStaffId: currentStaff?.staffId,
        teacherName: currentStaff?.fullName ?? user?.displayName,
      );
    } else if (isStudent && effectiveStudentId != null) {
      inquiriesStream = repo.watchInquiriesForStudent(
        effectiveAcademyId,
        effectiveStudentId,
        studentRollNumber: currentStudent?.rollNumber ?? user?.rollNumber,
      );
    } else {
      inquiriesStream = repo.watchAllInquiries(effectiveAcademyId);
    }

    return DashboardBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTeacher ? 'Student Q&A Desk' : 'Course Q&A & Inquiries',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                isTeacher
                    ? 'Answer doubts from enrolled students'
                    : 'Ask your teacher questions anytime',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            if (isStudent)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Builder(
                  builder: (context) {
                    final isCompact = MediaQuery.sizeOf(context).width < 380;
                    if (isCompact) {
                      return IconButton(
                        tooltip: 'Ask Question',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                        icon: const Icon(Icons.help_outline, size: 20),
                        onPressed: () => showAskTeacherModal(
                          context,
                          academyId: effectiveAcademyId,
                          preselectedCourseId: widget.courseId,
                          preselectedCourseName: widget.courseName,
                        ),
                      );
                    }
                    return FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text('Ask Question'),
                      onPressed: () => showAskTeacherModal(
                        context,
                        academyId: effectiveAcademyId,
                        preselectedCourseId: widget.courseId,
                        preselectedCourseName: widget.courseName,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        body: StreamBuilder<List<StudentInquiry>>(
          stream: inquiriesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 40, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load questions: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
              );
            }

            final allInquiries = snapshot.data ?? const <StudentInquiry>[];

            final filteredInquiries = allInquiries.where((inq) {
              if (_selectedFilter == 'open') {
                return inq.status == 'open';
              }
              if (_selectedFilter == 'answered') {
                return inq.status == 'answered' || inq.status == 'resolved';
              }
              return true;
            }).toList();

            final openCount =
                allInquiries.where((i) => i.status == 'open').length;
            final answeredCount = allInquiries
                .where((i) => i.status == 'answered' || i.status == 'resolved')
                .length;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KPI cards row
                        Row(
                          children: [
                            Expanded(
                              child: _KpiChip(
                                label: 'Total Inquiries',
                                count: allInquiries.length.toString(),
                                icon: Icons.question_answer_outlined,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _KpiChip(
                                label: 'Pending Reply',
                                count: openCount.toString(),
                                icon: Icons.pending_actions_outlined,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _KpiChip(
                                label: 'Answered',
                                count: answeredCount.toString(),
                                icon: Icons.check_circle_outline,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Filter segmented tabs
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterButton(
                              label: 'All Threads (${allInquiries.length})',
                              isSelected: _selectedFilter == 'all',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'all'),
                            ),
                            _FilterButton(
                              label: 'Pending ($openCount)',
                              isSelected: _selectedFilter == 'open',
                              accentColor: const Color(0xFFF59E0B),
                              onTap: () =>
                                  setState(() => _selectedFilter = 'open'),
                            ),
                            _FilterButton(
                              label: 'Answered ($answeredCount)',
                              isSelected: _selectedFilter == 'answered',
                              accentColor: const Color(0xFF10B981),
                              onTap: () =>
                                  setState(() => _selectedFilter = 'answered'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (filteredInquiries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.forum_outlined,
                                size: 40,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isTeacher
                                  ? 'No student questions pending'
                                  : 'No inquiry threads found',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTeacher
                                  ? 'When students enrolled in your courses have doubts, their questions will appear here.'
                                  : 'Have a question about your course, assignment, or syllabus? Tap "Ask Question" to reach your teacher.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                              ),
                            ),
                            if (isStudent) ...[
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF38BDF8),
                                  foregroundColor: const Color(0xFF0F172A),
                                ),
                                icon: const Icon(Icons.help_outline, size: 18),
                                label: const Text('Ask Teacher Now'),
                                onPressed: () => showAskTeacherModal(
                                  context,
                                  academyId: effectiveAcademyId,
                                  preselectedCourseId: widget.courseId,
                                  preselectedCourseName: widget.courseName,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final inquiry = filteredInquiries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InquiryCard(
                              inquiry: inquiry,
                              isTeacher: isTeacher,
                              currentStaffName: currentStaff?.fullName ??
                                  user?.displayName ??
                                  'Teacher',
                            ),
                          );
                        },
                        childCount: filteredInquiries.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final String count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accentColor = const Color(0xFF38BDF8),
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accentColor : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends ConsumerWidget {
  const _InquiryCard({
    required this.inquiry,
    required this.isTeacher,
    required this.currentStaffName,
  });

  final StudentInquiry inquiry;
  final bool isTeacher;
  final String currentStaffName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final dateStr = dateFormat.format(inquiry.createdAt);

    final isAnswered =
        inquiry.status == 'answered' || inquiry.status == 'resolved';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Student info & Status pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
                child: Text(
                  inquiry.studentName.isNotEmpty
                      ? inquiry.studentName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (inquiry.studentRollNumber.isNotEmpty)
                          Text(
                            'Roll #${inquiry.studentRollNumber}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inquiry.courseName,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _StatusPill(status: inquiry.status),
            ],
          ),
          const SizedBox(height: 12),

          // Subject & Question content
          Text(
            inquiry.subject,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            inquiry.question,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Footer with date and teacher name
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: dateStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (inquiry.teacherName.isNotEmpty)
                Text.rich(
                  TextSpan(
                    children: [
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.person_pin,
                            size: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: 'Teacher: ${inquiry.teacherName}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Teacher's reply bubble (if answered)
          if (isAnswered && inquiry.reply.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: 'Teacher Reply (${inquiry.teacherName})',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (inquiry.answeredAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd • hh:mm a')
                              .format(inquiry.answeredAt!),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    inquiry.reply,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reply Action button for Teacher
          if (isTeacher) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isAnswered
                      ? Colors.white70
                      : const Color(0xFF38BDF8),
                  side: BorderSide(
                    color: isAnswered
                        ? Colors.white24
                        : const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                icon: Icon(
                  isAnswered ? Icons.edit_note : Icons.reply,
                  size: 16,
                ),
                label: Text(
                  isAnswered ? 'Update Response' : 'Reply to Student',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _showReplyDialog(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref) {
    final replyController = TextEditingController(text: inquiry.reply);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.reply,
                          color: Color(0xFF38BDF8),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reply to ${inquiry.studentName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q: ${inquiry.subject}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inquiry.question,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: replyController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Guidance / Explanation',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Type your explanation or guidance here...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your reply.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text(
                        'Send Reply & Notify Student',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final repo = ref.read(communicationRepositoryProvider);
                        await repo.answerInquiry(
                          academyId: inquiry.academyId,
                          inquiryId: inquiry.id,
                          reply: replyController.text.trim(),
                        );
                        if (bottomSheetContext.mounted) {
                          Navigator.of(bottomSheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reply submitted and push notification dispatched!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'answered':
      case 'resolved':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        label = 'Answered';
        break;
      case 'open':
      default:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
