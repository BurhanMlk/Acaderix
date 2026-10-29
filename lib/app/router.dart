import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/roles.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/screens/academy_admin_login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_selection_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/staff_login_screen.dart';
import '../features/auth/presentation/screens/student_login_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/super_admin/presentation/screens/academies_list_screen.dart';
import '../features/super_admin/presentation/screens/coming_soon_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_dashboard.dart';
import '../features/super_admin/presentation/screens/super_admin_shell.dart';
import '../features/academy_admin/presentation/screens/academy_admin_shell.dart';
import '../features/admissions/presentation/screens/add_student_screen.dart';
import '../features/admissions/presentation/screens/students_list_screen.dart';
import '../features/fees/presentation/screens/fees_screen.dart';
import '../features/attendance/presentation/screens/attendance_screen.dart';
import '../features/exams/presentation/screens/results_screen.dart';
import '../features/staff/presentation/screens/staff_list_screen.dart';
import '../features/staff/presentation/screens/staff_shell.dart';
import '../features/branches/presentation/screens/branches_list_screen.dart';
import '../features/student/presentation/screens/student_shell.dart';

/// Top-level route paths.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String academyAdminLogin = '/login/admin';
  static const String staffLogin = '/login/staff';
  static const String studentLogin = '/login/student';
  static const String forgotPassword = '/forgot-password';

  static const String superAdmin = '/super-admin';
  static const String academiesList = '/super-admin/academies';
  static const String subscriptions = '/super-admin/subscriptions';
  static const String broadcasts = '/super-admin/broadcasts';
  static const String supportTickets = '/super-admin/support-tickets';
  static const String platformSettings = '/super-admin/platform-settings';

  static const String academyAdmin = '/academy-admin';
  static const String studentsList = '/academy-admin/students';
  static const String addStudent = '/academy-admin/students/new';
  static const String fees = '/academy-admin/fees';
  static const String attendance = '/academy-admin/attendance';
  static const String results = '/academy-admin/results';
  static const String staffList = '/academy-admin/staff';
  static const String branchesList = '/academy-admin/branches';

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
  AppRoutes.staffLogin,
  AppRoutes.studentLogin,
  AppRoutes.forgotPassword,
};

/// Entry routes a signed-in user should be redirected away from.
const Set<String> _entryRoutes = {
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
};

/// Routes each role is permitted to visit. This is a client-side convenience
/// guard; real authorization lives in custom claims + security rules.
final Map<AppRole, Set<String>> _roleRoutes = {
  AppRole.superAdmin: {
    AppRoutes.superAdmin,
    AppRoutes.academiesList,
    AppRoutes.subscriptions,
    AppRoutes.broadcasts,
    AppRoutes.supportTickets,
    AppRoutes.platformSettings,
  },
  AppRole.academyAdmin: {
    AppRoutes.academyAdmin,
    AppRoutes.studentsList,
    AppRoutes.addStudent,
    AppRoutes.fees,
    AppRoutes.attendance,
    AppRoutes.results,
    AppRoutes.staffList,
    AppRoutes.branchesList,
  },
  AppRole.staff: {AppRoutes.staff},
  AppRole.student: {AppRoutes.student},
  AppRole.unauthenticated: _publicRoutes,
};

/// Maps a role to its home route.
String homeForRole(AppRole role) => switch (role) {
  AppRole.superAdmin => AppRoutes.superAdmin,
  AppRole.academyAdmin => AppRoutes.academyAdmin,
  AppRole.staff => AppRoutes.staff,
  AppRole.student => AppRoutes.student,
  AppRole.unauthenticated => AppRoutes.welcome,
};

String? _redirect(AuthState auth, String location) {
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

  final home = homeForRole(user.role);
  if (_entryRoutes.contains(location)) return home;

  final allowed = _roleRoutes[user.role] ?? const <String>{};
  return allowed.contains(location) ? null : home;
}

/// Provides the application router with auth- and role-aware redirects.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        _redirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
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
            path: AppRoutes.subscriptions,
            builder: (context, state) => const ComingSoonScreen(),
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
            builder: (context, state) => const ComingSoonScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.academyAdmin,
        builder: (context, state) => const AcademyAdminShell(),
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
        path: AppRoutes.staffList,
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: AppRoutes.branchesList,
        builder: (context, state) => const BranchesListScreen(),
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
