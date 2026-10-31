import 'package:flutter/material.dart';

import '../../../app/router.dart';

/// A navigable module in the Academy Admin experience.
class AcademyAdminModule {
  const AcademyAdminModule(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// All primary sidebar navigation tabs for Academy Admin.
const List<AcademyAdminModule> academyAdminModules = [
  AcademyAdminModule(
    'Dashboard',
    Icons.dashboard_outlined,
    AppRoutes.academyAdmin,
  ),
  AcademyAdminModule(
    'Branches',
    Icons.account_balance_outlined,
    AppRoutes.branchesList,
  ),
  AcademyAdminModule(
    'Students',
    Icons.people_alt_outlined,
    AppRoutes.studentsList,
  ),
  AcademyAdminModule(
    'Staff',
    Icons.badge_outlined,
    AppRoutes.staffList,
  ),
  AcademyAdminModule(
    'Attendance',
    Icons.event_note_outlined,
    AppRoutes.attendance,
  ),
  AcademyAdminModule(
    'Fees',
    Icons.payments_outlined,
    AppRoutes.fees,
  ),
  AcademyAdminModule(
    'Results',
    Icons.assessment_outlined,
    AppRoutes.results,
  ),
];
