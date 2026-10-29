import 'package:flutter/material.dart';

import '../../../../shared/role_shell.dart';
import 'academy_admin_dashboard.dart';

/// Top-level scaffold for the Academy Admin experience.
class AcademyAdminShell extends StatelessWidget {
  const AcademyAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleShell(
      title: 'Academy Admin',
      subtitle: 'Manage your academy',
      body: AcademyAdminDashboard(),
    );
  }
}
