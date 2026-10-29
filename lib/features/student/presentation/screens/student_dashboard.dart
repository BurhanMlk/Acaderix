import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/roles.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';

/// Student (and parent) dashboard.
///
/// Module screens (attendance, timetable, homework, results, fees) are added
/// in later phases; this shell shows the student's identity and module grid.
class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
            title: Text(user?.displayName ?? 'Student'),
            subtitle: Text(
              user?.rollNumber == null
                  ? 'Roll number unavailable'
                  : 'Roll #${user!.rollNumber}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: const [
            StatCard(title: 'Attendance', value: '—', icon: Icons.event_note),
            StatCard(title: 'Fees', value: '—', icon: Icons.payments_outlined),
            StatCard(title: 'Results', value: '—', icon: Icons.assessment),
            StatCard(title: 'Homework', value: '—', icon: Icons.book_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('${AppRole.student.label} — parents use this same login.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
