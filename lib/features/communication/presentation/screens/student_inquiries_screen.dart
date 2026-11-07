import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../staff/application/staff_providers.dart';
import '../../../student/application/student_providers.dart';
import '../../application/communication_providers.dart';
import '../../domain/chat_message.dart';
import 'academic_chat_screen.dart';
import 'teacher_initiate_chat_modal.dart';

/// Screen displaying the unified 1-to-1 WhatsApp-style conversations between
/// Teachers and Students. Replaces legacy academic doubt threads with a single,
/// direct messaging hub.
class StudentInquiriesScreen extends ConsumerStatefulWidget {
  const StudentInquiriesScreen({
    super.key,
    this.academyId,
    this.teacherId,
    this.studentId,
    this.courseId,
    this.courseName,
    this.initialTab,
  });

  final String? academyId;
  final String? teacherId;
  final String? studentId;
  final String? courseId;
  final String? courseName;
  final int? initialTab;

  @override
  ConsumerState<StudentInquiriesScreen> createState() =>
      _StudentInquiriesScreenState();
}

class _StudentInquiriesScreenState
    extends ConsumerState<StudentInquiriesScreen> {
  String _searchQuery = '';

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

    final effectiveTeacherId = widget.teacherId ?? currentStaff?.staffId ?? currentStaff?.id;
    final effectiveStudentId =
        widget.studentId ?? currentStudent?.id ?? user?.id;

    final isTeacher = currentStaff != null || widget.teacherId != null;
    final isStudent = !isTeacher &&
        (currentStudent != null ||
            widget.studentId != null ||
            (user != null && user.isStudent));

    final repo = ref.watch(communicationRepositoryProvider);

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
                isTeacher ? 'Student Messages' : 'Instructor Messages',
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
                    ? 'Direct 1-on-1 real-time chat with students'
                    : 'Direct 1-on-1 real-time chat with your teachers',
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
            IconButton(
              tooltip: isTeacher ? 'New Chat with Student' : 'Message Instructor',
              icon: const Icon(
                Icons.add_comment_outlined,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              onPressed: () {
                if (isTeacher) {
                  showTeacherInitiateChatModal(
                    context,
                    academyId: effectiveAcademyId,
                  );
                } else {
                  showStudentInitiateChatModal(
                    context,
                    academyId: effectiveAcademyId,
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 4,
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: Text(
            isTeacher ? 'Message Student' : 'Message Teacher',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          onPressed: () {
            if (isTeacher) {
              showTeacherInitiateChatModal(
                context,
                academyId: effectiveAcademyId,
              );
            } else {
              showStudentInitiateChatModal(
                context,
                academyId: effectiveAcademyId,
              );
            }
          },
        ),
        body: StreamBuilder<List<AcademicConversation>>(
          stream: repo.watchAcademicConversations(
            effectiveAcademyId,
            teacherId: isTeacher ? effectiveTeacherId : null,
            studentId: isStudent ? effectiveStudentId : null,
          ),
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
                        'Failed to load messages: ${snapshot.error}',
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

            final allConvs = snapshot.data ?? const <AcademicConversation>[];

            final filtered = allConvs.where((c) {
              if (widget.studentId != null &&
                  widget.studentId!.isNotEmpty &&
                  c.studentId != widget.studentId) {
                return false;
              }
              if (widget.courseId != null &&
                  widget.courseId!.isNotEmpty &&
                  c.courseId != widget.courseId) {
                return false;
              }

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                final matchStudent = c.studentName.toLowerCase().contains(q) ||
                    c.studentRollNumber.toLowerCase().contains(q);
                final matchTeacher = c.teacherName.toLowerCase().contains(q);
                final matchCourse = c.courseName.toLowerCase().contains(q);
                final matchMsg = c.lastMessage.toLowerCase().contains(q);
                return matchStudent || matchTeacher || matchCourse || matchMsg;
              }

              return true;
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search bar
                        TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: isTeacher
                                ? 'Search student name, roll #, or message...'
                                : 'Search instructor, course, or message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF38BDF8), size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.white38, size: 16),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF38BDF8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: _searchQuery.isNotEmpty
                              ? 'No Matching Messages'
                              : 'No Conversations Yet',
                          message: _searchQuery.isNotEmpty
                              ? 'Try searching with a different name, roll number, or course.'
                              : (isTeacher
                                  ? 'No student chats yet. Tap "Message Student" below to start a direct 1-to-1 chat.'
                                  : 'No instructor chats yet. Tap "Message Teacher" below to start a direct 1-to-1 chat.'),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conv = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AcademicConversationListTile(
                              conversation: conv,
                              isViewerTeacher: isTeacher,
                              onTap: () {
                                final otherName = isTeacher
                                    ? conv.studentName
                                    : conv.teacherName;
                                final otherSubtitle = isTeacher
                                    ? 'Roll #${conv.studentRollNumber} • ${conv.courseName}'
                                    : conv.courseName;
                                final otherRole =
                                    isTeacher ? 'student' : 'teacher';
                                final recipientId =
                                    isTeacher ? conv.studentId : conv.teacherId;
                                final recipientRole =
                                    isTeacher ? 'student' : 'staff';

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AcademicChatScreen(
                                      academyId: conv.academyId,
                                      conversationId: conv.id,
                                      otherPartyName: otherName,
                                      otherPartySubtitle: otherSubtitle,
                                      otherPartyRole: otherRole,
                                      recipientId: recipientId,
                                      recipientRole: recipientRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: filtered.length,
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

class _AcademicConversationListTile extends StatelessWidget {
  const _AcademicConversationListTile({
    required this.conversation,
    required this.isViewerTeacher,
    required this.onTap,
  });

  final AcademicConversation conversation;
  final bool isViewerTeacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd • hh:mm a');
    final displayName =
        isViewerTeacher ? conversation.studentName : conversation.teacherName;
    final displaySubtitle = isViewerTeacher
        ? 'Roll #${conversation.studentRollNumber} • ${conversation.courseName}'
        : conversation.courseName;

    final unreadCount = isViewerTeacher
        ? conversation.unreadCountForTeacher
        : conversation.unreadCountForStudent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unreadCount > 0
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                  : Colors.white12,
              width: unreadCount > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Contact Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isViewerTeacher
                    ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.25),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: isViewerTeacher
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF38BDF8),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Conversation Info & Message Snippet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateFormat.format(conversation.lastMessageAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displaySubtitle,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isNotEmpty
                                ? conversation.lastMessage
                                : 'Direct conversation opened',
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
