import 'package:flutter/material.dart';

import '../../../../shared/role_shell.dart';

/// Top-level scaffold for the Staff experience.
class StaffShell extends StatelessWidget {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleShell(title: 'Staff');
  }
}
