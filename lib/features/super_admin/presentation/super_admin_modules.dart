import 'package:flutter/material.dart';

import '../../../../app/router.dart';

/// A navigable module in the Super Admin portal.
class SuperAdminModule {
  const SuperAdminModule(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// All modules exposed to the platform Super Admin.
const List<SuperAdminModule> superAdminModules = [
  SuperAdminModule('Dashboard', Icons.dashboard_outlined, AppRoutes.superAdmin),
  SuperAdminModule(
    'Academies',
    Icons.apartment_outlined,
    AppRoutes.academiesList,
  ),
  SuperAdminModule(
    'Subscriptions',
    Icons.subscriptions_outlined,
    AppRoutes.subscriptions,
  ),
  SuperAdminModule('Broadcasts', Icons.campaign_outlined, AppRoutes.broadcasts),
  SuperAdminModule(
    'Support',
    Icons.support_agent_outlined,
    AppRoutes.supportTickets,
  ),
  SuperAdminModule(
    'Settings',
    Icons.settings_outlined,
    AppRoutes.platformSettings,
  ),
];
