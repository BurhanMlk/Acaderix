import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:academy_management/core/widgets/app_logo.dart';
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
                    '$studentName • Roll #$rollNumber • $branchName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Course Q&A & Doubts',
                  icon: const Icon(
                    Icons.question_answer_outlined,
                    color: Color(0xFF38BDF8),
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
                  icon: const Icon(Icons.badge_outlined, color: Color(0xFF38BDF8)),
                  onPressed: () => showStudentProfileModal(context),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout, color: Colors.white70),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.03),
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (index) =>
                            setState(() => _currentIndex = index),
                        labelType: NavigationRailLabelType.all,
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
                        unselectedLabelTextStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
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
                        color: Colors.white12,
                        width: 1,
                        thickness: 1,
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
                : NavigationBarTheme(
                    data: NavigationBarThemeData(
                      indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const IconThemeData(color: Color(0xFF38BDF8));
                        }
                        return IconThemeData(
                          color: Colors.white.withValues(alpha: 0.6),
                        );
                      }),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          );
                        }
                        return TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      elevation: 8,
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
