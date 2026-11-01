import 'package:flutter/material.dart';

import 'student_dashboard_tab.dart';

/// Legacy export wrapper forwarding to [StudentDashboardTab].
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentDashboardTab(
      onNavigateToTab: (_) {},
    );
  }
}
