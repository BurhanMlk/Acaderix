import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/roles.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';

/// Student (and parent) dashboard with transparent glass theme.
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
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName.isEmpty ?? true
                          ? 'Student'
                          : user!.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.rollNumber == null
                          ? 'Roll number unavailable'
                          : 'Roll #${user!.rollNumber}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: const [
            StatCard(
              title: 'Attendance',
              value: '—',
              icon: Icons.event_note,
              color: Color(0xFF6366F1),
            ),
            StatCard(
              title: 'Fees',
              value: '—',
              icon: Icons.payments_outlined,
              color: Color(0xFF10B981),
            ),
            StatCard(
              title: 'Results',
              value: '—',
              icon: Icons.assessment,
              color: Color(0xFFA855F7),
            ),
            StatCard(
              title: 'Homework',
              value: '—',
              icon: Icons.book_outlined,
              color: Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(18),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Role & Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${AppRole.student.label} — students and parents use this dashboard to track attendance, fees, and academic performance.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
