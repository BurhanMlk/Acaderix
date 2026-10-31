import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/branch_tab_bar.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../application/attendance_repository_provider.dart';
import '../../domain/attendance_record.dart';

/// Mark daily student attendance with branch scope tabs and responsive cards.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _date = DateTime.now();

  Future<void> _mark(
    String academyId,
    String studentId,
    AttendanceStatus status,
  ) async {
    final record = AttendanceRecord(
      id: const Uuid().v4(),
      academyId: academyId,
      studentId: studentId,
      date: _date,
      status: status,
    );
    await ref.read(attendanceRepositoryProvider).markAttendance(record);
    ref.invalidate(attendanceForDateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final students = ref.watch(studentsStreamProvider(academyId));
    final normalizedDate = DateTime(_date.year, _date.month, _date.day);
    final records = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: normalizedDate)),
    );
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branch Tabs at top
          BranchTabBar(academyId: academyId),

          // Date Selector & Stats Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: const Text('Change Date'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: AsyncListState(
              value: students,
              emptyTitle: 'No students',
              emptyMessage: 'Admit students before marking attendance.',
              onRetry: () => ref.invalidate(studentsStreamProvider),
              builder: (items) {
                final filtered = selectedBranchId == null
                    ? items
                    : items.where((s) => s.branchId == selectedBranchId).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No students match the selected branch.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                final byStudent = <String, AttendanceStatus>{
                  for (final record in records.value ?? <AttendanceRecord>[])
                    record.studentId: record.status,
                };

                // Quick stats summary
                int presentCount = 0;
                int absentCount = 0;
                int leaveCount = 0;
                for (final s in filtered) {
                  final status = byStudent[s.id] ?? AttendanceStatus.present;
                  if (status == AttendanceStatus.present) presentCount++;
                  if (status == AttendanceStatus.absent) absentCount++;
                  if (status == AttendanceStatus.leave) leaveCount++;
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 10 : 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Attendance Summary Row
                      return Row(
                        children: [
                          _StatBadge(
                            label: 'Present',
                            count: presentCount,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            label: 'Absent',
                            count: absentCount,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            label: 'Leave',
                            count: leaveCount,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          _StatBadge(
                            label: 'Total',
                            count: filtered.length,
                            color: const Color(0xFF38BDF8),
                          ),
                        ],
                      );
                    }

                    final student = filtered[index - 1];
                    final current =
                        byStudent[student.id] ?? AttendanceStatus.present;
                    final branch = branches
                        .where((b) => b.id == student.branchId)
                        .firstOrNull;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Profile Header
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.2),
                                  foregroundColor: const Color(0xFF818CF8),
                                  child: Text(
                                    student.fullName.isNotEmpty
                                        ? student.fullName
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : 'S',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Roll #${student.rollNumber}'
                                        '${branch != null && selectedBranchId == null ? ' · ${branch.name}' : ''}',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Current Status Indicator Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(current)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _statusColor(current)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(current),
                                    style: TextStyle(
                                      color: _statusColor(current),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            const SizedBox(height: 8),

                            // Attendance Status Chips Row (Evenly Distributed)
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text(
                                        'PRESENT',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    selected:
                                        current == AttendanceStatus.present,
                                    selectedColor: const Color(0xFF10B981)
                                        .withValues(alpha: 0.3),
                                    showCheckmark: false,
                                    onSelected: (_) => _mark(
                                      academyId,
                                      student.id,
                                      AttendanceStatus.present,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text(
                                        'ABSENT',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    selected:
                                        current == AttendanceStatus.absent,
                                    selectedColor: Colors.redAccent
                                        .withValues(alpha: 0.3),
                                    showCheckmark: false,
                                    onSelected: (_) => _mark(
                                      academyId,
                                      student.id,
                                      AttendanceStatus.absent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text(
                                        'LEAVE',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    selected: current == AttendanceStatus.leave,
                                    selectedColor:
                                        Colors.amber.withValues(alpha: 0.3),
                                    showCheckmark: false,
                                    onSelected: (_) => _mark(
                                      academyId,
                                      student.id,
                                      AttendanceStatus.leave,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981);
      case AttendanceStatus.absent:
        return Colors.redAccent;
      case AttendanceStatus.leave:
        return Colors.amber;
      case AttendanceStatus.late:
        return Colors.orangeAccent;
    }
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'On Leave';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
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
