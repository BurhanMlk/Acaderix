import 'package:flutter/material.dart';

import '../../../../shared/role_shell.dart';
import 'student_dashboard.dart';

/// Top-level scaffold for the Student (and Parent) experience.
class StudentShell extends StatelessWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleShell(
      title: 'Student',
      subtitle: 'Your progress',
      body: StudentDashboard(),
    );
  }
}
