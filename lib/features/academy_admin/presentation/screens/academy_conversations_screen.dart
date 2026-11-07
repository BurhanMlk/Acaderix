import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../admissions/domain/student.dart';
import '../../../communication/application/communication_providers.dart';
import '../../../communication/domain/chat_message.dart';
import '../../../staff/domain/staff.dart';
import '../../application/academy_access_provider.dart';
import '../../application/academy_admin_providers.dart';

/// Academy Admin Conversations Hub Screen
///
/// Provides academy administrators with a comprehensive supervisory directory
/// divided into two tabs:
///   1. Staff Directory: Inspect any teacher to view all their chats with students.
///   2. Student Directory: Inspect any student to view all their chats with teachers.
class AcademyConversationsScreen extends ConsumerStatefulWidget {
  const AcademyConversationsScreen({super.key});

  @override
  ConsumerState<AcademyConversationsScreen> createState() =>
      _AcademyConversationsScreenState();
}

class _AcademyConversationsScreenState
    extends ConsumerState<AcademyConversationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _staffSearchController = TextEditingController();
  final TextEditingController _studentSearchController =
      TextEditingController();
  String _staffSearchQuery = '';
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _staffSearchController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(academyAccessProvider).value;
    final academyId =
        ref.watch(currentAcademyIdProvider) ?? access?.academyId ?? '';

    if (academyId.isEmpty) {
      return const Center(
        child: Text(
          'No academy context available.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final repo = ref.watch(communicationRepositoryProvider);
    final staffAsync = ref.watch(staffStreamProvider(academyId));
    final studentsAsync = ref.watch(studentsStreamProvider(academyId));

    final staffList = staffAsync.value ?? const <Staff>[];
    final studentsList = studentsAsync.value ?? const <Student>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<AcademicConversation>>(
        stream: repo.watchAcademicConversations(academyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load conversations: ${snapshot.error}',
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

          final allConversations =
              snapshot.data ?? const <AcademicConversation>[];

          // Index conversations by teacher and student for O(1) lookup
          final teacherConvsMap = <String, List<AcademicConversation>>{};
          final studentConvsMap = <String, List<AcademicConversation>>{};

          for (final conv in allConversations) {
            teacherConvsMap.putIfAbsent(conv.teacherId, () => []).add(conv);
            if (conv.teacherStaffId.isNotEmpty &&
                conv.teacherStaffId != conv.teacherId) {
              teacherConvsMap
                  .putIfAbsent(conv.teacherStaffId, () => [])
                  .add(conv);
            }

            studentConvsMap.putIfAbsent(conv.studentId, () => []).add(conv);
            if (conv.studentRollNumber.isNotEmpty &&
                conv.studentRollNumber != conv.studentId) {
              studentConvsMap
                  .putIfAbsent(conv.studentRollNumber, () => [])
                  .add(conv);
            }
          }

          // KPI Stats
          final totalChats = allConversations.length;
          final facultyPending = allConversations
              .where((c) => c.unreadCountForTeacher > 0)
              .length;
          final studentPending = allConversations
              .where((c) => c.unreadCountForStudent > 0)
              .length;
          final activeTeachers = allConversations
              .map((c) => c.teacherId)
              .toSet()
              .length;

          return CustomScrollView(
            slivers: [
              // Header & KPI Metrics Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF38BDF8,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF38BDF8,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.forum_outlined,
                              color: Color(0xFF38BDF8),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Teacher & Student Conversations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Directory-level supervisory audit of faculty and student direct 1-to-1 communications',
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
                      const SizedBox(height: 16),

                      // KPI Overview Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 520;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isNarrow ? 2 : 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: isNarrow ? 1.7 : 1.9,
                            children: [
                              _KpiMetricCard(
                                title: 'Total Chats',
                                value: '$totalChats',
                                subtitle: '$activeTeachers Active Teachers',
                                icon: Icons.chat_bubble_outline,
                                color: const Color(0xFF38BDF8),
                              ),
                              _KpiMetricCard(
                                title: 'Faculty Pending',
                                value: '$facultyPending',
                                subtitle: 'Unread by Instructor',
                                icon: Icons.pending_actions_outlined,
                                color: const Color(0xFFF59E0B),
                              ),
                              _KpiMetricCard(
                                title: 'Student Unread',
                                value: '$studentPending',
                                subtitle: 'New Faculty Replies',
                                icon: Icons.mark_chat_unread_outlined,
                                color: const Color(0xFF10B981),
                              ),
                              _KpiMetricCard(
                                title: 'Supervisory Audits',
                                value: '$totalChats',
                                subtitle: '100% Oversight Rate',
                                icon: Icons.security_outlined,
                                color: const Color(0xFFA855F7),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Glassmorphic Segmented Tabs
                      _buildDirectoryTabSelector(
                        staffCount: staffList.length,
                        studentCount: studentsList.length,
                      ),
                    ],
                  ),
                ),
              ),

              // Tab View Content (Staff or Students)
              if (_tabController.index == 0)
                ..._buildStaffSlivers(
                  context,
                  academyId: academyId,
                  staffList: staffList,
                  teacherConvsMap: teacherConvsMap,
                  allConversations: allConversations,
                )
              else
                ..._buildStudentSlivers(
                  context,
                  academyId: academyId,
                  studentsList: studentsList,
                  studentConvsMap: studentConvsMap,
                  allConversations: allConversations,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDirectoryTabSelector({
    required int staffCount,
    required int studentCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Staff Members',
              badgeText: '$staffCount',
              icon: Icons.badge_outlined,
              isSelected: _tabController.index == 0,
              accentColor: const Color(0xFF6366F1),
              onTap: () => setState(() => _tabController.animateTo(0)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              label: 'Students',
              badgeText: '$studentCount',
              icon: Icons.school_outlined,
              isSelected: _tabController.index == 1,
              accentColor: const Color(0xFF0EA5E9),
              onTap: () => setState(() => _tabController.animateTo(1)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStaffSlivers(
    BuildContext context, {
    required String academyId,
    required List<Staff> staffList,
    required Map<String, List<AcademicConversation>> teacherConvsMap,
    required List<AcademicConversation> allConversations,
  }) {
    final query = _staffSearchQuery.trim().toLowerCase();
    final filteredStaff = query.isEmpty
        ? staffList
        : staffList.where((s) {
            final matchName = s.fullName.toLowerCase().contains(query);
            final matchId = s.staffId.toLowerCase().contains(query);
            final matchTitle = s.jobTitle.toLowerCase().contains(query);
            return matchName || matchId || matchTitle;
          }).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            controller: _staffSearchController,
            onChanged: (val) => setState(() => _staffSearchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search staff by name, staff ID, or designation...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF6366F1),
                size: 18,
              ),
              suffixIcon: _staffSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white38,
                        size: 16,
                      ),
                      onPressed: () {
                        _staffSearchController.clear();
                        setState(() => _staffSearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
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
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ),
      ),
      if (filteredStaff.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: EmptyState(
                icon: Icons.person_off_outlined,
                title: _staffSearchQuery.isNotEmpty
                    ? 'No Matching Staff'
                    : 'No Staff Records',
                message: _staffSearchQuery.isNotEmpty
                    ? 'Try searching with a different staff name, ID, or job title.'
                    : 'Staff members added to your academy will appear here.',
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final staff = filteredStaff[index];
              // Lookup conversations for this staff
              final teacherConvs = _findTeacherConversations(
                staff: staff,
                teacherConvsMap: teacherConvsMap,
                allConversations: allConversations,
              );
              final unreadCount = teacherConvs.fold<int>(
                0,
                (sum, c) => sum + c.unreadCountForTeacher,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StaffAuditCard(
                  staff: staff,
                  conversationCount: teacherConvs.length,
                  unreadCount: unreadCount,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TeacherConversationsAuditScreen(
                          academyId: academyId,
                          staff: staff,
                          initialConversations: teacherConvs,
                        ),
                      ),
                    );
                  },
                ),
              );
            }, childCount: filteredStaff.length),
          ),
        ),
    ];
  }

  List<Widget> _buildStudentSlivers(
    BuildContext context, {
    required String academyId,
    required List<Student> studentsList,
    required Map<String, List<AcademicConversation>> studentConvsMap,
    required List<AcademicConversation> allConversations,
  }) {
    final query = _studentSearchQuery.trim().toLowerCase();
    final filteredStudents = query.isEmpty
        ? studentsList
        : studentsList.where((s) {
            final matchName = s.fullName.toLowerCase().contains(query);
            final matchRoll = s.rollNumber.toLowerCase().contains(query);
            return matchName || matchRoll;
          }).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            controller: _studentSearchController,
            onChanged: (val) => setState(() => _studentSearchQuery = val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search student by name or roll number...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF0EA5E9),
                size: 18,
              ),
              suffixIcon: _studentSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white38,
                        size: 16,
                      ),
                      onPressed: () {
                        _studentSearchController.clear();
                        setState(() => _studentSearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
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
                borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
              ),
            ),
          ),
        ),
      ),
      if (filteredStudents.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: EmptyState(
                icon: Icons.school_outlined,
                title: _studentSearchQuery.isNotEmpty
                    ? 'No Matching Students'
                    : 'No Student Records',
                message: _studentSearchQuery.isNotEmpty
                    ? 'Try searching with a different student name or roll number.'
                    : 'Admitted students will appear here for conversation audits.',
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final student = filteredStudents[index];
              // Lookup conversations for this student
              final studentConvs = _findStudentConversations(
                student: student,
                studentConvsMap: studentConvsMap,
                allConversations: allConversations,
              );
              final unreadCount = studentConvs.fold<int>(
                0,
                (sum, c) => sum + c.unreadCountForStudent,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StudentAuditCard(
                  student: student,
                  conversationCount: studentConvs.length,
                  unreadCount: unreadCount,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentConversationsAuditScreen(
                          academyId: academyId,
                          student: student,
                          initialConversations: studentConvs,
                        ),
                      ),
                    );
                  },
                ),
              );
            }, childCount: filteredStudents.length),
          ),
        ),
    ];
  }

  static bool matchesTeacher(AcademicConversation c, Staff staff) {
    final staffId = staff.id.trim();
    final staffCode = staff.staffId.trim().toUpperCase();
    final staffName = staff.fullName.trim().toLowerCase();
    final staffEmail = staff.email.trim().toLowerCase();

    final cTeacherId = c.teacherId.trim();
    final cTeacherStaffId = c.teacherStaffId.trim().toUpperCase();
    final cTeacherName = c.teacherName.trim().toLowerCase();

    // 1. Direct ID / Staff ID match
    if (staffId.isNotEmpty &&
        (cTeacherId == staffId ||
            cTeacherStaffId == staffId.toUpperCase())) {
      return true;
    }
    if (staffCode.isNotEmpty &&
        (cTeacherId.toUpperCase() == staffCode ||
            cTeacherStaffId == staffCode)) {
      return true;
    }

    // 2. Email match
    if (staffEmail.isNotEmpty &&
        (cTeacherId.toLowerCase() == staffEmail ||
            cTeacherStaffId.toLowerCase() == staffEmail)) {
      return true;
    }

    // 3. Name match (case-insensitive)
    if (staffName.isNotEmpty &&
        cTeacherName.isNotEmpty &&
        cTeacherName == staffName) {
      return true;
    }
    if (staffName.isNotEmpty &&
        cTeacherId.isNotEmpty &&
        cTeacherId.toLowerCase() == staffName) {
      return true;
    }

    return false;
  }

  static bool matchesStudent(AcademicConversation c, Student student) {
    final studentId = student.id.trim();
    final roll = student.rollNumber.trim().toUpperCase();
    final studentName = student.fullName.trim().toLowerCase();

    final cStudentId = c.studentId.trim();
    final cRoll = c.studentRollNumber.trim().toUpperCase();
    final cStudentName = c.studentName.trim().toLowerCase();

    // 1. Direct ID / Roll Number match
    if (studentId.isNotEmpty &&
        (cStudentId == studentId ||
            cRoll == studentId.toUpperCase())) {
      return true;
    }
    if (roll.isNotEmpty &&
        (cStudentId.toUpperCase() == roll || cRoll == roll)) {
      return true;
    }

    // 2. Name match (case-insensitive)
    if (studentName.isNotEmpty &&
        (cStudentName == studentName ||
            cStudentId.toLowerCase() == studentName)) {
      return true;
    }

    return false;
  }

  List<AcademicConversation> _findTeacherConversations({
    required Staff staff,
    required Map<String, List<AcademicConversation>> teacherConvsMap,
    required List<AcademicConversation> allConversations,
  }) {
    return allConversations.where((c) => matchesTeacher(c, staff)).toList();
  }

  List<AcademicConversation> _findStudentConversations({
    required Student student,
    required Map<String, List<AcademicConversation>> studentConvsMap,
    required List<AcademicConversation> allConversations,
  }) {
    return allConversations.where((c) => matchesStudent(c, student)).toList();
  }
}

// ---------------------------------------------------------------------------
// TEACHER CONVERSATIONS AUDIT SCREEN (WhatsApp Chat View for Staff Record)
// ---------------------------------------------------------------------------

class TeacherConversationsAuditScreen extends ConsumerStatefulWidget {
  const TeacherConversationsAuditScreen({
    super.key,
    required this.academyId,
    required this.staff,
    this.initialConversations = const [],
  });

  final String academyId;
  final Staff staff;
  final List<AcademicConversation> initialConversations;

  @override
  ConsumerState<TeacherConversationsAuditScreen> createState() =>
      _TeacherConversationsAuditScreenState();
}

class _TeacherConversationsAuditScreenState
    extends ConsumerState<TeacherConversationsAuditScreen> {
  String? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(communicationRepositoryProvider);

    return StreamBuilder<List<AcademicConversation>>(
      stream: repo.watchAcademicConversations(widget.academyId),
      initialData: widget.initialConversations.isNotEmpty
          ? widget.initialConversations
          : null,
      builder: (context, snapshot) {
        final allConvs = snapshot.data ?? widget.initialConversations;
        final convs = allConvs
            .where((c) => _AcademyConversationsScreenState.matchesTeacher(
                  c,
                  widget.staff,
                ))
            .toList();

        if (convs.isEmpty) {
          return DashboardBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: const Color(0xFF0F172A),
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.25),
                      child: Text(
                        widget.staff.fullName.isNotEmpty
                            ? widget.staff.fullName[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
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
                            widget.staff.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.staff.jobTitle.isNotEmpty
                                ? widget.staff.jobTitle
                                : 'Faculty Instructor',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
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
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No Conversation History',
                    message:
                        'This teacher has not exchanged any WhatsApp messages with students yet.',
                  ),
                ),
              ),
            ),
          );
        }

        final activeConv =
            _selectedConversationId != null &&
                convs.any((c) => c.id == _selectedConversationId)
            ? convs.firstWhere((c) => c.id == _selectedConversationId)
            : convs.first;

        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(
                    0xFF6366F1,
                  ).withValues(alpha: 0.25),
                  child: Text(
                    widget.staff.fullName.isNotEmpty
                        ? widget.staff.fullName[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
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
                        '${widget.staff.fullName} ↔ ${activeConv.studentName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Student: Roll #${activeConv.studentRollNumber} • ${activeConv.courseName}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 20),
                tooltip: 'Export Transcript',
                onPressed: () => _exportTranscript(context, ref, activeConv),
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 16,
                  color: Color(0xFF38BDF8),
                ),
                label: const Text(
                  'Export',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _exportTranscript(context, ref, activeConv),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Supervisory Notice Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Supervisory Audit Mode • Academy Administrator Oversight • Read-Only',
                          style: TextStyle(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Multi-Student Thread Picker Pills (if multiple conversations exist)
                if (convs.length > 1)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: convs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final conv = convs[index];
                        final isSelected = conv.id == activeConv.id;
                        return ChoiceChip(
                          label: Text(
                            '${conv.studentName} (${conv.studentRollNumber})',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedConversationId = conv.id);
                            }
                          },
                        );
                      },
                    ),
                  ),

                // WhatsApp Chat Message Stream
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: repo.watchChatMessages(
                      widget.academyId,
                      activeConv.id,
                    ),
                    builder: (context, msgSnapshot) {
                      if (msgSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !msgSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF38BDF8),
                          ),
                        );
                      }

                      final messages =
                          msgSnapshot.data ?? const <ChatMessage>[];

                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No messages in this chat yet',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isTeacherSender = msg.isFromTeacher;
                          return _AuditWhatsAppChatBubble(
                            message: msg,
                            isRightSide: isTeacherSender,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Locked Supervisory Bottom Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      top: BorderSide(color: Color(0xFF1E293B), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Read-Only Supervisory Mode • Export transcript using the button above',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// STUDENT CONVERSATIONS AUDIT SCREEN (WhatsApp Chat View for Student Record)
// ---------------------------------------------------------------------------

class StudentConversationsAuditScreen extends ConsumerStatefulWidget {
  const StudentConversationsAuditScreen({
    super.key,
    required this.academyId,
    required this.student,
    this.initialConversations = const [],
  });

  final String academyId;
  final Student student;
  final List<AcademicConversation> initialConversations;

  @override
  ConsumerState<StudentConversationsAuditScreen> createState() =>
      _StudentConversationsAuditScreenState();
}

class _StudentConversationsAuditScreenState
    extends ConsumerState<StudentConversationsAuditScreen> {
  String? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(communicationRepositoryProvider);

    return StreamBuilder<List<AcademicConversation>>(
      stream: repo.watchAcademicConversations(widget.academyId),
      initialData: widget.initialConversations.isNotEmpty
          ? widget.initialConversations
          : null,
      builder: (context, snapshot) {
        final allConvs = snapshot.data ?? widget.initialConversations;
        final convs = allConvs
            .where((c) => _AcademyConversationsScreenState.matchesStudent(
                  c,
                  widget.student,
                ))
            .toList();

        if (convs.isEmpty) {
          return DashboardBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: const Color(0xFF0F172A),
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(
                        0xFF0EA5E9,
                      ).withValues(alpha: 0.25),
                      child: Text(
                        widget.student.fullName.isNotEmpty
                            ? widget.student.fullName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
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
                            widget.student.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Roll #${widget.student.rollNumber}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
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
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No Conversation History',
                    message:
                        'This student has not exchanged any WhatsApp messages with teachers yet.',
                  ),
                ),
              ),
            ),
          );
        }

        final activeConv =
            _selectedConversationId != null &&
                convs.any((c) => c.id == _selectedConversationId)
            ? convs.firstWhere((c) => c.id == _selectedConversationId)
            : convs.first;

        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(
                    0xFF0EA5E9,
                  ).withValues(alpha: 0.25),
                  child: Text(
                    widget.student.fullName.isNotEmpty
                        ? widget.student.fullName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
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
                        '${widget.student.fullName} ↔ ${activeConv.teacherName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Instructor: ${activeConv.teacherName} • ${activeConv.courseName}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 20),
                tooltip: 'Export Transcript',
                onPressed: () => _exportTranscript(context, ref, activeConv),
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 16,
                  color: Color(0xFF38BDF8),
                ),
                label: const Text(
                  'Export',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _exportTranscript(context, ref, activeConv),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Supervisory Notice Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Supervisory Audit Mode • Academy Administrator Oversight • Read-Only',
                          style: TextStyle(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Multi-Teacher Thread Picker Pills (if multiple conversations exist)
                if (convs.length > 1)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: convs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final conv = convs[index];
                        final isSelected = conv.id == activeConv.id;
                        return ChoiceChip(
                          label: Text(
                            '${conv.teacherName} (${conv.courseName})',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedConversationId = conv.id);
                            }
                          },
                        );
                      },
                    ),
                  ),

                // WhatsApp Chat Message Stream
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: repo.watchChatMessages(
                      widget.academyId,
                      activeConv.id,
                    ),
                    builder: (context, msgSnapshot) {
                      if (msgSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !msgSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF38BDF8),
                          ),
                        );
                      }

                      final messages =
                          msgSnapshot.data ?? const <ChatMessage>[];

                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No messages in this chat yet',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isTeacherSender = msg.isFromTeacher;
                          return _AuditWhatsAppChatBubble(
                            message: msg,
                            isRightSide: isTeacherSender,
                          );
                        },
                      );
                    },
                  ),
                ),

                // Locked Supervisory Bottom Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(
                      top: BorderSide(color: Color(0xFF1E293B), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Read-Only Supervisory Mode • Export transcript using the button above',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// WHATSAPP CHAT BUBBLE & PDF TRANSCRIPT EXPORT HELPER
// ---------------------------------------------------------------------------

class _AuditWhatsAppChatBubble extends StatelessWidget {
  const _AuditWhatsAppChatBubble({
    required this.message,
    required this.isRightSide,
  });

  final ChatMessage message;
  final bool isRightSide;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);
    final isTeacher = message.isFromTeacher;

    return Align(
      alignment: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isRightSide
              ? const Color(0xFF005C4B) // WhatsApp dark teal/green
              : const Color(0xFF202C33), // WhatsApp slate grey
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isRightSide ? 14 : 2),
            bottomRight: Radius.circular(isRightSide ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName,
                  style: TextStyle(
                    color: isTeacher
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFFA5B4FC),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isTeacher
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFFA5B4FC))
                            .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isTeacher ? 'TEACHER' : 'STUDENT',
                    style: TextStyle(
                      color: isTeacher
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFA5B4FC),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Message Text
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp and WhatsApp Ticks
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 14, color: Color(0xFF38BDF8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _exportTranscript(
  BuildContext context,
  WidgetRef ref,
  AcademicConversation conv,
) async {
  try {
    final repo = ref.read(communicationRepositoryProvider);
    final messages = await repo
        .watchChatMessages(conv.academyId, conv.id)
        .first;

    final doc = pw.Document();
    final timeFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ACADERIX ACADEMIC CONVERSATION TRANSCRIPT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Teacher: ${conv.teacherName}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.Text(
              'Student: ${conv.studentName} (Roll #${conv.studentRollNumber})',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Course: ${conv.courseName}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Thread ID: ${conv.id}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 12),
            if (messages.isEmpty)
              pw.Text(
                'No messages in this conversation thread.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              )
            else
              ...messages.map((m) {
                final isTeacher = m.isFromTeacher;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: isTeacher ? PdfColors.blue50 : PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${m.senderName} (${m.senderRole.toUpperCase()})',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: isTeacher
                                  ? PdfColors.blue800
                                  : PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            timeFormat.format(m.createdAt),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(m.text, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'transcript_${conv.id}.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export transcript: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// PRESENTATIONAL TILES & COMPONENTS
// ---------------------------------------------------------------------------

class _StaffAuditCard extends StatelessWidget {
  const _StaffAuditCard({
    required this.staff,
    required this.conversationCount,
    required this.unreadCount,
    required this.onTap,
  });

  final Staff staff;
  final int conversationCount;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : Colors.white12,
              width: unreadCount > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(
                      0xFF6366F1,
                    ).withValues(alpha: 0.25),
                    child: Text(
                      staff.fullName.isNotEmpty
                          ? staff.fullName[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.fullName,
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
                          staff.jobTitle.isNotEmpty
                              ? staff.jobTitle
                              : 'Faculty Instructor',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ID #${staff.staffId.isNotEmpty ? staff.staffId : staff.id}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: conversationCount > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 11,
                          color: conversationCount > 0
                              ? const Color(0xFF34D399)
                              : Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$conversationCount Student Chats',
                          style: TextStyle(
                            color: conversationCount > 0
                                ? const Color(0xFF34D399)
                                : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$unreadCount Pending Reply',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
}

class _StudentAuditCard extends StatelessWidget {
  const _StudentAuditCard({
    required this.student,
    required this.conversationCount,
    required this.unreadCount,
    required this.onTap,
  });

  final Student student;
  final int conversationCount;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.5)
                  : Colors.white12,
              width: unreadCount > 0 ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: 0.2),
                    child: Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
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
                          'Roll #${student.rollNumber}${student.notes.isNotEmpty ? " • ${student.notes}" : ""}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Roll #${student.rollNumber}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: conversationCount > 0
                          ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 11,
                          color: conversationCount > 0
                              ? const Color(0xFF818CF8)
                              : Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$conversationCount Teacher Chats',
                          style: TextStyle(
                            color: conversationCount > 0
                                ? const Color(0xFF818CF8)
                                : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$unreadCount New Messages',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.badgeText,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final String badgeText;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : Colors.white60,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
