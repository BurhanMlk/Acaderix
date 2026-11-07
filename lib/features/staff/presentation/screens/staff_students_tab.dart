import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../admissions/domain/student.dart';
import '../../../communication/application/communication_providers.dart';
import '../../../communication/presentation/screens/academic_chat_screen.dart';
import '../../../communication/presentation/screens/teacher_initiate_chat_modal.dart';
import '../../application/staff_providers.dart';

/// Staff view for browsing the campus student roster and looking up student profiles.
class StaffStudentsTab extends ConsumerStatefulWidget {
  const StaffStudentsTab({super.key});

  @override
  ConsumerState<StaffStudentsTab> createState() => _StaffStudentsTabState();
}

class _StaffStudentsTabState extends ConsumerState<StaffStudentsTab> {
  String _query = '';

  void _showStudentDetails(BuildContext context, Student student) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        const Color(0xFF6366F1).withValues(alpha: 0.3),
                    child: Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
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
                          'Roll #${student.rollNumber}${student.academicSession.isNotEmpty ? " • ${student.academicSession}" : ""}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 14),

              _DetailItem(label: 'Gender', value: student.gender),
              _DetailItem(label: 'Father/Guardian', value: student.fatherName),
              _DetailItem(label: 'Relation', value: student.guardianRelation),
              _DetailItem(label: 'Address', value: student.address),
              _DetailItem(label: 'Admission Status', value: student.status.toUpperCase()),
              _DetailItem(label: 'Academic Session', value: student.academicSession),
              const SizedBox(height: 12),

              // Student Privacy Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Parent phone numbers are restricted to protect family privacy. Communication is conducted via in-app chat.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(
                    'Message ${student.fullName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final staff = ref.read(currentStaffMemberProvider);
                    final teacherId = staff?.id.isNotEmpty == true
                        ? staff!.id
                        : (staff?.staffId ?? 'faculty');
                    final teacherName = staff?.fullName.isNotEmpty == true
                        ? staff!.fullName
                        : 'Faculty Teacher';
                    final teacherStaffId = staff?.staffId ?? '';

                    try {
                      final repo = ref.read(communicationRepositoryProvider);
                      final conv = await repo.getOrCreateConversation(
                        academyId: student.academyId,
                        teacherId: teacherId,
                        teacherName: teacherName,
                        teacherStaffId: teacherStaffId,
                        studentId: student.id,
                        studentName: student.fullName,
                        studentRollNumber: student.rollNumber,
                      );

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AcademicChatScreen(
                              academyId: student.academyId,
                              conversationId: conv.id,
                              otherPartyName: student.fullName,
                              otherPartySubtitle:
                                  'Roll #${student.rollNumber}${student.academicSession.isNotEmpty ? " • ${student.academicSession}" : ""}',
                              otherPartyRole: 'student',
                              recipientId: student.id,
                              recipientRole: 'student',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(staffBranchStudentsProvider);
    final branch = ref.watch(currentStaffBranchProvider);

    final filtered = students.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final matchName = s.fullName.toLowerCase().contains(q);
      final matchRoll = s.rollNumber.toLowerCase().contains(q);
      final matchSession = s.academicSession.toLowerCase().contains(q);
      return matchName || matchRoll || matchSession;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Campus Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search student name, roll #, or grade...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                if (branch != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Roster: ${branch.name} (${filtered.length} students)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.add_comment_outlined, size: 14),
                        label: const Text(
                          'Message Student',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => showTeacherInitiateChatModal(
                          context,
                          academyId: branch.academyId,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Students Roster
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'No Students Found',
                    message:
                        'No students match your search query in this campus.',
                    icon: Icons.people_outline,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final s = filtered[index];

                      return InkWell(
                        onTap: () => _showStudentDetails(context, s),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.25),
                                child: Text(
                                  s.fullName.isNotEmpty
                                      ? s.fullName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Roll #${s.rollNumber}',
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (s.academicSession.isNotEmpty)
                                          Text(
                                            '• ${s.academicSession}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
