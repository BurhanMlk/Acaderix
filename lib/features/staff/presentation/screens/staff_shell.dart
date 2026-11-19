import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../communication/presentation/screens/student_inquiries_screen.dart';
import '../../../communication/presentation/widgets/notification_bell_button.dart';
import '../../application/staff_providers.dart';
import 'staff_attendance_tab.dart';
import 'staff_dashboard_screen.dart';
import 'staff_profile_tab.dart';
import 'staff_results_tab.dart';
import 'staff_students_tab.dart';

/// Top-level responsive scaffold for the Staff portal experience with bottom navigation
/// on mobile, side rail on wide screens, and unified transparent glass theme.
class StaffShell extends ConsumerStatefulWidget {
  const StaffShell({super.key});

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  int _currentIndex = 0;

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Staff Dashboard';
      case 1:
        return 'Daily Attendance';
      case 2:
        return 'Exams & Results';
      case 3:
        return 'Campus Students';
      case 4:
        return 'Staff Profile';
      default:
        return 'Staff Portal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffMemberProvider);
    final branch = ref.watch(currentStaffBranchProvider);

    final staffName = staff?.fullName ?? 'Staff';
    final staffId =
        staff?.staffId.isNotEmpty == true ? staff!.staffId : 'STAFF';

    final pages = [
      StaffDashboardScreen(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const StaffAttendanceTab(),
      const StaffResultsTab(),
      const StaffStudentsTab(),
      const StaffProfileTab(),
    ];

    return DashboardBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceMuted,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textSecondary),
              leadingWidth: 48,
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Center(child: AppLogo(size: 28)),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getTitle(_currentIndex),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    branch != null
                        ? '$staffName • ${branch.name}'
                        : staffName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Student Messages',
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudentInquiriesScreen(),
                      ),
                    );
                  },
                ),
                NotificationBellButton(
                  academyId: staff?.academyId ?? '',
                  userId: staff?.id,
                ),
                // Staff ID Chip
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    staffId,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Sign Out',
                      message: 'Are you sure you want to sign out?',
                      confirmLabel: 'Sign Out',
                      destructive: true,
                    );
                    if (confirmed) {
                      ref.read(authControllerProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
            body: isWide
                ? Row(
                    children: [
                      NavigationRail(
                        backgroundColor: AppColors.surfaceMuted,
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (val) =>
                            setState(() => _currentIndex = val),
                        labelType: NavigationRailLabelType.selected,
                        selectedIconTheme: const IconThemeData(
                          color: AppColors.secondary,
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: AppColors.textTertiary,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('Dashboard'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.fact_check_outlined),
                            selectedIcon: Icon(Icons.fact_check),
                            label: Text('Attendance'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.grade_outlined),
                            selectedIcon: Icon(Icons.grade),
                            label: Text('Results'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: Text('Students'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: Text('Profile'),
                          ),
                        ],
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: SmoothTabSwitcher(
                              child: KeyedSubtree(
                                key: ValueKey(_currentIndex),
                                child: pages[_currentIndex],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SmoothTabSwitcher(
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: pages[_currentIndex],
                    ),
                  ),
            bottomNavigationBar: isWide
                ? null
                : Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (val) => setState(() => _currentIndex = val),
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: AppColors.surface,
                      elevation: 0,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: AppColors.textTertiary,
                      selectedFontSize: 11,
                      unselectedFontSize: 11,
                      selectedLabelStyle:
                          const TextStyle(fontWeight: FontWeight.w700),
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.dashboard_outlined),
                          activeIcon: Icon(Icons.dashboard),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.fact_check_outlined),
                          activeIcon: Icon(Icons.fact_check),
                          label: 'Attendance',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.grade_outlined),
                          activeIcon: Icon(Icons.grade),
                          label: 'Results',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.people_outline),
                          activeIcon: Icon(Icons.people),
                          label: 'Students',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          activeIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
