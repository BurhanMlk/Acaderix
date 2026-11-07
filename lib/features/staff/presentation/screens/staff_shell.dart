import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
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
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
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
                      color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.7),
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
                    color: Color(0xFF38BDF8),
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
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    staffId,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white70,
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
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (val) =>
                            setState(() => _currentIndex = val),
                        labelType: NavigationRailLabelType.selected,
                        selectedIconTheme: const IconThemeData(
                          color: Color(0xFF38BDF8),
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: Color(0xFF38BDF8),
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
                        color: Colors.white10,
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: pages,
                        ),
                      ),
                    ],
                  )
                : IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
            bottomNavigationBar: isWide
                ? null
                : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (val) => setState(() => _currentIndex = val),
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedItemColor: const Color(0xFF38BDF8),
                      unselectedItemColor: Colors.white.withValues(alpha: 0.5),
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
