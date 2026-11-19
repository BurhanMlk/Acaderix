import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:academy_management/core/widgets/app_logo.dart';
import 'package:academy_management/core/theme/app_colors.dart';
import 'package:academy_management/core/widgets/app_motion.dart';
import 'package:academy_management/core/widgets/confirmation_dialog.dart';
import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/communication/presentation/screens/student_inquiries_screen.dart';
import 'package:academy_management/features/communication/presentation/widgets/notification_bell_button.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'student_attendance_tab.dart';
import 'student_courses_tab.dart';
import 'student_dashboard_tab.dart';
import 'student_fees_tab.dart';
import 'student_profile_modal.dart';
import 'student_results_tab.dart';

/// Top-level responsive scaffold for the Student (and Parent) portal experience with
/// 5-tab mobile navigation, wide screen rail, and dark glass ambient styling.
class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Student Portal';
      case 1:
        return 'Courses & Timetable';
      case 2:
        return 'Attendance Analytics';
      case 3:
        return 'Academic Results';
      case 4:
        return 'Fees & Ledger';
      default:
        return 'Student Portal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProfileProvider);
    final branch = ref.watch(currentStudentBranchProvider);

    final studentName = student?.fullName.isNotEmpty == true
        ? student!.fullName
        : 'Student';
    final rollNumber = student?.rollNumber.isNotEmpty == true
        ? student!.rollNumber
        : '100001';
    final branchName = branch?.name ?? 'Main Campus';

    final pages = [
      StudentDashboardTab(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const StudentCoursesTab(),
      const StudentAttendanceTab(),
      const StudentResultsTab(),
      const StudentFeesTab(),
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
                    '$studentName • Roll #$rollNumber • $branchName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Messages',
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentInquiriesScreen(
                          academyId: student?.academyId,
                          studentId: student?.id,
                        ),
                      ),
                    );
                  },
                ),
                NotificationBellButton(
                  academyId: student?.academyId ?? '',
                  userId: student?.id,
                ),
                IconButton(
                  tooltip: 'Digital ID Pass',
                  icon: const Icon(Icons.badge_outlined, color: AppColors.secondary),
                  onPressed: () => showStudentProfileModal(context),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout, color: AppColors.textTertiary),
                  onPressed: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Sign Out',
                      message: 'Are you sure you want to log out of the student portal?',
                      confirmLabel: 'Sign Out',
                      destructive: true,
                    );
                    if (confirmed && context.mounted) {
                      await ref.read(authControllerProvider.notifier).signOut();
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: isWide
                ? Row(
                    children: [
                      NavigationRail(
                        backgroundColor: const Color(0xFFFCFCFD),
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (index) =>
                            setState(() => _currentIndex = index),
                        labelType: NavigationRailLabelType.all,
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
                        unselectedLabelTextStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('Dashboard'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.menu_book_outlined),
                            selectedIcon: Icon(Icons.menu_book),
                            label: Text('Courses'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.event_note_outlined),
                            selectedIcon: Icon(Icons.event_note),
                            label: Text('Attendance'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.assessment_outlined),
                            selectedIcon: Icon(Icons.assessment),
                            label: Text('Results'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.payments_outlined),
                            selectedIcon: Icon(Icons.payments),
                            label: Text('Fees'),
                          ),
                        ],
                      ),
                      const VerticalDivider(
                        color: AppColors.border,
                        width: 1,
                        thickness: 1,
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
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: NavigationBar(
                      backgroundColor: AppColors.surface,
                      elevation: 0,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _currentIndex = index),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Overview',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_book_outlined),
                          selectedIcon: Icon(Icons.menu_book),
                          label: 'Courses',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.event_note_outlined),
                          selectedIcon: Icon(Icons.event_note),
                          label: 'Attendance',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.assessment_outlined),
                          selectedIcon: Icon(Icons.assessment),
                          label: 'Results',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.payments_outlined),
                          selectedIcon: Icon(Icons.payments),
                          label: 'Fees',
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
