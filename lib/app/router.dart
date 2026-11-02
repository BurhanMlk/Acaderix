import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/roles.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/screens/academy_admin_login_screen.dart';
import '../features/auth/presentation/screens/super_admin_login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_selection_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/staff_login_screen.dart';
import '../features/auth/presentation/screens/student_login_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/super_admin/domain/academy.dart';
import '../features/super_admin/domain/subscription_models.dart';
import '../features/super_admin/presentation/screens/academies_list_screen.dart';
import '../features/super_admin/presentation/screens/academy_admin_reset_password_screen.dart';
import '../features/super_admin/presentation/screens/academy_details_screen.dart';
import '../features/super_admin/presentation/screens/change_plan_screen.dart';
import '../features/super_admin/presentation/screens/edit_plan_price_screen.dart';
import '../features/super_admin/presentation/screens/extend_subscription_screen.dart';
import '../features/super_admin/presentation/screens/platform_settings_screen.dart';
import '../features/super_admin/presentation/screens/coming_soon_screen.dart';
import '../features/super_admin/presentation/screens/record_payment_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_dashboard.dart';
import '../features/super_admin/presentation/screens/super_admin_reset_password_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_shell.dart';
import '../features/super_admin/presentation/screens/subscriptions_screen.dart';
import '../features/academy_admin/application/academy_access_provider.dart';
import '../features/academy_admin/domain/academy_access_models.dart';
import '../features/academy_admin/presentation/screens/academy_admin_dashboard.dart';
import '../features/academy_admin/presentation/screens/academy_admin_shell.dart';
import '../features/academy_admin/presentation/screens/academy_status_notice_screen.dart';
import '../features/academics/domain/course.dart';
import '../features/academics/presentation/screens/add_course_screen.dart';
import '../features/academics/presentation/screens/courses_list_screen.dart';
import '../features/academics/presentation/screens/edit_course_screen.dart';
import '../features/admissions/domain/student.dart';
import '../features/admissions/presentation/screens/add_student_screen.dart';
import '../features/admissions/presentation/screens/edit_student_screen.dart';
import '../features/admissions/presentation/screens/students_list_screen.dart';
import '../features/fees/presentation/screens/fees_screen.dart';
import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/exams/presentation/screens/results_screen.dart';
import '../features/staff/domain/staff.dart';
import '../features/staff/presentation/screens/add_staff_screen.dart';
import '../features/staff/presentation/screens/edit_staff_screen.dart';
import '../features/staff/presentation/screens/staff_list_screen.dart';
import '../features/staff/presentation/screens/staff_shell.dart';
import '../features/branches/domain/branch.dart';
import '../features/branches/presentation/screens/add_branch_screen.dart';
import '../features/branches/presentation/screens/edit_branch_screen.dart';
import '../features/branches/presentation/screens/branches_list_screen.dart';
import '../features/communication/presentation/screens/announcements_screen.dart';
import '../features/student/presentation/screens/student_shell.dart';

/// Top-level route paths.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String academyAdminLogin = '/login/admin';
  static const String superAdminLogin = '/login/super-admin';
  static const String staffLogin = '/login/staff';
  static const String studentLogin = '/login/student';
  static const String forgotPassword = '/forgot-password';

  static const String superAdmin = '/super-admin';
  static const String academiesList = '/super-admin/academies';
  static const String academyDetails = '/super-admin/academies/details';
  static const String academyAdminResetPassword =
      '/super-admin/academies/reset-password';
  static const String superAdminResetPassword = '/super-admin/reset-password';
  static const String subscriptions = '/super-admin/subscriptions';
  static const String recordPayment =
      '/super-admin/subscriptions/record-payment';
  static const String changePlan = '/super-admin/subscriptions/change-plan';
  static const String extendSubscription =
      '/super-admin/subscriptions/extend';
  static const String editPlanPrice =
      '/super-admin/subscriptions/edit-plan-price';
  static const String broadcasts = '/super-admin/broadcasts';
  static const String supportTickets = '/super-admin/support-tickets';
  static const String platformSettings = '/super-admin/platform-settings';

  static const String academyAdmin = '/academy-admin';
  static const String academyStatus = '/academy-status';
  static const String studentsList = '/academy-admin/students';
  static const String addStudent = '/academy-admin/students/new';
  static const String editStudent = '/academy-admin/students/edit';
  static const String fees = '/academy-admin/fees';
  static const String attendance = '/academy-admin/attendance';
  static const String results = '/academy-admin/results';
  static const String staffList = '/academy-admin/staff';
  static const String addStaff = '/academy-admin/staff/new';
  static const String editStaff = '/academy-admin/staff/edit';
  static const String branchesList = '/academy-admin/branches';
  static const String addBranch = '/academy-admin/branches/new';
  static const String editBranch = '/academy-admin/branches/edit';
  static const String coursesList = '/academy-admin/courses';
  static const String addCourse = '/academy-admin/courses/new';
  static const String editCourse = '/academy-admin/courses/edit';
  static const String academyAnnouncements = '/academy-admin/announcements';

  static const String staff = '/staff';
  static const String student = '/student';
}

/// Public routes reachable without authentication.
const Set<String> _publicRoutes = {
  AppRoutes.welcome,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.academyAdminLogin,
  AppRoutes.superAdminLogin,
  AppRoutes.staffLogin,
  AppRoutes.studentLogin,
  AppRoutes.forgotPassword,
  AppRoutes.academyStatus,
};

/// Entry routes a signed-in user should be redirected away from.
const Set<String> _entryRoutes = {
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.academyAdminLogin,
  AppRoutes.superAdminLogin,
  AppRoutes.staffLogin,
  AppRoutes.studentLogin,
};

/// Routes each role is permitted to visit. This is a client-side convenience
/// guard; real authorization lives in custom claims + security rules.
final Map<AppRole, Set<String>> _roleRoutes = {
  AppRole.superAdmin: {
    AppRoutes.superAdmin,
    AppRoutes.academiesList,
    AppRoutes.academyDetails,
    AppRoutes.academyAdminResetPassword,
    AppRoutes.superAdminResetPassword,
    AppRoutes.subscriptions,
    AppRoutes.recordPayment,
    AppRoutes.changePlan,
    AppRoutes.extendSubscription,
    AppRoutes.editPlanPrice,
    AppRoutes.broadcasts,
    AppRoutes.supportTickets,
    AppRoutes.platformSettings,
  },
  AppRole.academyAdmin: {
    AppRoutes.academyAdmin,
    AppRoutes.academyStatus,
    AppRoutes.studentsList,
    AppRoutes.addStudent,
    AppRoutes.editStudent,
    AppRoutes.fees,
    AppRoutes.attendance,
    AppRoutes.results,
    AppRoutes.staffList,
    AppRoutes.addStaff,
    AppRoutes.editStaff,
    AppRoutes.branchesList,
    AppRoutes.addBranch,
    AppRoutes.editBranch,
    AppRoutes.coursesList,
    AppRoutes.addCourse,
    AppRoutes.editCourse,
    AppRoutes.academyAnnouncements,
  },
  AppRole.staff: {AppRoutes.staff},
  AppRole.student: {AppRoutes.student},
  AppRole.unauthenticated: _publicRoutes,
};

/// Tracks whether the initial branded splash presentation has finished playing.
///
/// In test environments, this defaults to true so widget/e2e tests don't wait for timers.
/// In real app runs, it begins as false so [SplashScreen] can display its full
/// animation and branding before transitioning to the destination screen.
class SplashCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    return isTest;
  }

  void complete() => state = true;
}

final splashCompletedProvider =
    NotifierProvider<SplashCompletedNotifier, bool>(
  SplashCompletedNotifier.new,
);

/// Maps a role to its home route.
String homeForRole(AppRole role) => switch (role) {
  AppRole.superAdmin => AppRoutes.superAdmin,
  AppRole.academyAdmin => AppRoutes.academyAdmin,
  AppRole.staff => AppRoutes.staff,
  AppRole.student => AppRoutes.student,
  AppRole.unauthenticated => AppRoutes.welcome,
};

String? _redirect(
  AuthState auth,
  String location, {
  AcademyAccessInfo? access,
  bool splashCompleted = true,
}) {
  if (!splashCompleted) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (auth is AuthUnknown) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final user = switch (auth) {
    AuthAuthenticated(:final user) when user.role.isAuthenticated => user,
    _ => null,
  };

  if (user == null) {
    return _publicRoutes.contains(location) ? null : AppRoutes.welcome;
  }

  // Gate Academy Admin by academy access status (active vs pending/suspended/expired)
  if (user.role == AppRole.academyAdmin && access != null) {
    if (!access.isActive) {
      if (location != AppRoutes.academyStatus) {
        return AppRoutes.academyStatus;
      }
      return null;
    } else {
      if (location == AppRoutes.academyStatus) {
        return AppRoutes.academyAdmin;
      }
    }
  }

  final home = (user.role == AppRole.academyAdmin &&
          access != null &&
          !access.isActive)
      ? AppRoutes.academyStatus
      : homeForRole(user.role);

  if (_entryRoutes.contains(location)) return home;

  final allowed = _roleRoutes[user.role] ?? const <String>{};
  return allowed.contains(location) ? null : home;
}

/// Provides the application router with auth- and role-aware redirects.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(academyAccessProvider, (_, _) => refresh.value++);
  ref.listen(splashCompletedProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(
      ref.read(authControllerProvider),
      state.matchedLocation,
      access: ref.read(academyAccessProvider).value,
      splashCompleted: ref.read(splashCompletedProvider),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.academyAdminLogin,
        builder: (context, state) => const AcademyAdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminLogin,
        builder: (context, state) => const SuperAdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffLogin,
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentLogin,
        builder: (context, state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => SuperAdminShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.superAdmin,
            builder: (context, state) => const SuperAdminDashboard(),
          ),
          GoRoute(
            path: AppRoutes.academiesList,
            builder: (context, state) => const AcademiesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.academyDetails,
            builder: (context, state) => AcademyDetailsScreen(
              initialAcademy: state.extra as Academy?,
              academyId: state.uri.queryParameters['id'],
            ),
          ),
          GoRoute(
            path: AppRoutes.academyAdminResetPassword,
            builder: (context, state) => AcademyAdminResetPasswordScreen(
              initialAcademy: state.extra as Academy?,
              academyId: state.uri.queryParameters['id'],
            ),
          ),
          GoRoute(
            path: AppRoutes.superAdminResetPassword,
            builder: (context, state) =>
                const SuperAdminResetPasswordScreen(),
          ),
          GoRoute(
            path: AppRoutes.subscriptions,
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.recordPayment,
            builder: (context, state) => RecordPaymentScreen(
              initialSubscription: state.extra as AcademySubscription?,
              academyId: state.uri.queryParameters['academyId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.changePlan,
            builder: (context, state) => ChangePlanScreen(
              subscription: state.extra as AcademySubscription?,
              academyId: state.uri.queryParameters['academyId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.extendSubscription,
            builder: (context, state) => ExtendSubscriptionScreen(
              subscription: state.extra as AcademySubscription?,
              academyId: state.uri.queryParameters['academyId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.editPlanPrice,
            builder: (context, state) => EditPlanPriceScreen(
              plan: state.extra as SubscriptionPlan?,
              planId: state.uri.queryParameters['planId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.broadcasts,
            builder: (context, state) => const ComingSoonScreen(),
          ),
          GoRoute(
            path: AppRoutes.supportTickets,
            builder: (context, state) => const ComingSoonScreen(),
          ),
          GoRoute(
            path: AppRoutes.platformSettings,
            builder: (context, state) => const PlatformSettingsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AcademyAdminShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.academyAdmin,
            builder: (context, state) => const AcademyAdminDashboard(),
          ),
          GoRoute(
            path: AppRoutes.branchesList,
            builder: (context, state) => const BranchesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.addBranch,
            builder: (context, state) => const AddBranchScreen(),
          ),
          GoRoute(
            path: AppRoutes.editBranch,
            builder: (context, state) =>
                EditBranchScreen(branch: state.extra as Branch),
          ),
          GoRoute(
            path: AppRoutes.studentsList,
            builder: (context, state) => const StudentsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.addStudent,
            builder: (context, state) => const AddStudentScreen(),
          ),
          GoRoute(
            path: AppRoutes.editStudent,
            builder: (context, state) =>
                EditStudentScreen(student: state.extra as Student),
          ),
          GoRoute(
            path: AppRoutes.staffList,
            builder: (context, state) => const StaffListScreen(),
          ),
          GoRoute(
            path: AppRoutes.addStaff,
            builder: (context, state) => const AddStaffScreen(),
          ),
          GoRoute(
            path: AppRoutes.editStaff,
            builder: (context, state) =>
                EditStaffScreen(staff: state.extra as Staff),
          ),
          GoRoute(
            path: AppRoutes.coursesList,
            builder: (context, state) => const CoursesListScreen(),
          ),
          GoRoute(
            path: AppRoutes.addCourse,
            builder: (context, state) => const AddCourseScreen(),
          ),
          GoRoute(
            path: AppRoutes.editCourse,
            builder: (context, state) =>
                EditCourseScreen(course: state.extra as Course),
          ),
          GoRoute(
            path: AppRoutes.fees,
            builder: (context, state) => const FeesScreen(),
          ),
          GoRoute(
            path: AppRoutes.attendance,
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.results,
            builder: (context, state) => const ResultsScreen(),
          ),
          GoRoute(
            path: AppRoutes.academyAnnouncements,
            builder: (context, state) => const AnnouncementsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.academyStatus,
        builder: (context, state) {
          final access = state.extra is AcademyAccessInfo
              ? state.extra as AcademyAccessInfo
              : ref.watch(academyAccessProvider).value ??
                  const AcademyAccessInfo(
                    state: AcademyAccessState.pending,
                    academyId: '',
                  );
          return AcademyStatusNoticeScreen(accessInfo: access);
        },
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffShell(),
      ),
      GoRoute(
        path: AppRoutes.student,
        builder: (context, state) => const StudentShell(),
      ),
    ],
  );
});
