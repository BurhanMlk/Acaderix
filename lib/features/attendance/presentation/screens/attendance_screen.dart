import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/attendance_calculator.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../application/attendance_repository_provider.dart';
import '../../domain/attendance_record.dart';

/// Mark daily student attendance.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final students = ref.watch(studentsStreamProvider(academyId));
    final records = ref.watch(
      attendanceForDateProvider((academyId: academyId, date: _date)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
      body: AsyncListState(
        value: students,
        emptyTitle: 'No students',
        emptyMessage: 'Admit students before marking attendance.',
        onRetry: () => ref.invalidate(studentsStreamProvider),
        builder: (items) {
          final byStudent = <String, AttendanceStatus>{
            for (final record in records.value ?? <AttendanceRecord>[])
              record.studentId: record.status,
          };
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = items[index];
              final current = byStudent[student.id] ?? AttendanceStatus.absent;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(student.fullName),
                  subtitle: Text('Roll #${student.rollNumber}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final status in AttendanceStatus.values)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ChoiceChip(
                            label: Text(status.name.toUpperCase()),
                            selected: current == status,
                            onSelected: (_) =>
                                _mark(academyId, student.id, status),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

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
}
