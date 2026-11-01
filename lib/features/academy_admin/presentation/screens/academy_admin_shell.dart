import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../shared/selected_branch_provider.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../application/academy_access_provider.dart';
import '../../application/academy_admin_providers.dart';
import '../../domain/academy_access_models.dart';
import '../academy_admin_modules.dart';
import 'academy_admin_dashboard.dart';
import 'academy_status_notice_screen.dart';

/// Top-level responsive scaffold for the Academy Admin experience with persistent
/// frosted glass sidebar on desktop and drawer on mobile, multi-branch scope filter,
/// and unified ambient dark glass theme.
class AcademyAdminShell extends ConsumerWidget {
  const AcademyAdminShell({
    super.key,
    this.location = AppRoutes.academyAdmin,
    this.child,
  });

  final String location;
  final Widget? child;

  String get _title {
    if (location == AppRoutes.academyAdmin) return 'Dashboard';
    if (location == AppRoutes.branchesList) return 'Branches';
    if (location == AppRoutes.addBranch) return 'Add Branch';
    if (location == AppRoutes.editBranch) return 'Edit Branch';
    if (location == AppRoutes.studentsList) return 'Students';
    if (location == AppRoutes.addStudent) return 'Admit Student';
    if (location == AppRoutes.editStudent) return 'Edit Student';
    if (location == AppRoutes.staffList) return 'Staff Members';
    if (location == AppRoutes.addStaff) return 'Add Staff Member';
    if (location == AppRoutes.editStaff) return 'Edit Staff Member';
    if (location == AppRoutes.coursesList) return 'Courses & Batches';
    if (location == AppRoutes.addCourse) return 'Add Course';
    if (location == AppRoutes.editCourse) return 'Edit Course';
    if (location == AppRoutes.attendance) return 'Attendance Monitoring';
    if (location == AppRoutes.fees) return 'Fee Management';
    if (location == AppRoutes.results) return 'Exams & Results';
    for (final module in academyAdminModules) {
      if (module.route == location) return module.label;
    }
    return 'Academy Admin';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(academyAccessProvider);

    return accessAsync.when(
      loading: () => const DashboardBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text(
                  'Checking academy status...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (err, _) => DashboardBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load academy status: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(academyAccessProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (access) {
        if (!access.isActive) {
          Future.microtask(() {
            ref.read(authControllerProvider.notifier).signOut();
          });
          return AcademyStatusNoticeScreen(accessInfo: access);
        }

        final effectiveChild = child ?? const AcademyAdminDashboard();

        return DashboardBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Row(
                    children: [
                      _AcademyAdminSidebar(
                        location: location,
                        access: access,
                        isDrawer: false,
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AcademyAdminContentHeader(
                              title: _title,
                              access: access,
                            ),
                            Expanded(child: effectiveChild),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  actions: [
                    _MobileBranchSelectorButton(academyId: access.academyId),
                  ],
                ),
                drawer: Drawer(
                  backgroundColor: const Color(0xFF0B1120).withValues(alpha: 0.95),
                  child: _AcademyAdminSidebar(
                    location: location,
                    access: access,
                    isDrawer: true,
                  ),
                ),
                body: effectiveChild,
              );
            },
          ),
        );
      },
    );
  }
}

/// Content header for desktop view with current section title, global branch selector,
/// and live plan badge.
class AcademyAdminContentHeader extends ConsumerWidget {
  const AcademyAdminContentHeader({
    super.key,
    required this.title,
    required this.access,
  });

  final String title;
  final AcademyAccessInfo access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider(access.academyId));
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Global Branch Selector (only when branches exist)
          branchesAsync.maybeWhen(
            data: (branches) {
              if (branches.isEmpty) return const SizedBox.shrink();
              final isBranchValid = selectedBranchId == null ||
                  branches.any((b) => b.id == selectedBranchId);
              final effectiveBranchId = isBranchValid ? selectedBranchId : null;
              if (!isBranchValid) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedBranchIdProvider.notifier).state = null;
                });
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 140,
                      maxWidth: 220,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: effectiveBranchId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          isDense: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedItemBuilder: (context) {
                            return [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'All Branches',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...branches.map(
                                (b) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    b.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ];
                          },
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'All Branches',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            ...branches.map(
                              (b) => DropdownMenuItem<String?>(
                                value: b.id,
                                child: Text(
                                  b.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (newId) {
                            ref.read(selectedBranchIdProvider.notifier).state = newId;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          // Plan Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '${access.planName} Plan',
              style: const TextStyle(
                color: Color(0xFFA5B4FC),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile branch selector action button in the AppBar.
class _MobileBranchSelectorButton extends ConsumerWidget {
  const _MobileBranchSelectorButton({required this.academyId});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesStreamProvider(academyId));
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return branchesAsync.maybeWhen(
      data: (branches) {
        final activeBranch = branches.where((b) => b.id == selectedBranchId).firstOrNull;
        final tooltip = activeBranch != null ? activeBranch.name : 'All Branches';

        return PopupMenuButton<String?>(
          tooltip: 'Select Branch ($tooltip)',
          color: const Color(0xFF1E293B),
          icon: Icon(
            Icons.account_balance_outlined,
            color: selectedBranchId != null ? const Color(0xFF38BDF8) : Colors.white70,
          ),
          onSelected: (branchId) {
            ref.read(selectedBranchIdProvider.notifier).state = branchId;
          },
          itemBuilder: (context) => [
            CheckedPopupMenuItem<String?>(
              value: null,
              checked: selectedBranchId == null,
              child: const Text(
                'All Branches',
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            ...branches.map(
              (b) => CheckedPopupMenuItem<String?>(
                value: b.id,
                checked: selectedBranchId == b.id,
                child: Text(
                  b.city.isNotEmpty ? '${b.name} (${b.city})' : b.name,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Responsive frosted glass sidebar navigation matching Super Admin.
class _AcademyAdminSidebar extends ConsumerWidget {
  const _AcademyAdminSidebar({
    required this.location,
    required this.access,
    this.isDrawer = false,
  });

  final String location;
  final AcademyAccessInfo access;
  final bool isDrawer;

  void _navigate(BuildContext context, String route) {
    if (isDrawer) {
      Navigator.of(context).pop();
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = switch (authState) {
      AuthAuthenticated(:final user) => user,
      _ => null,
    };
    final adminName = access.ownerName.isNotEmpty
        ? access.ownerName
        : (authUser?.displayName.isNotEmpty == true
            ? authUser!.displayName
            : (access.ownerEmail.isNotEmpty
                ? access.ownerEmail.split('@').first
                : 'Academy Admin'));

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: isDrawer
            ? Colors.transparent
            : const Color(0xFF0B1120).withValues(alpha: 0.75),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Profile & Academy Brand Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  if (access.logoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        access.logoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const AppLogo(size: 40, borderRadius: 12),
                      ),
                    )
                  else
                    const AppLogo(size: 40, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          access.academyName.isNotEmpty
                              ? access.academyName
                              : (access.academyCode.isNotEmpty
                                  ? access.academyCode
                                  : 'Academy Admin'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isDrawer)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      tooltip: 'Close menu',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 8),

            // Nav Modules
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final module in academyAdminModules)
                    _SidebarItem(
                      module: module,
                      selected: module.route == AppRoutes.academyAdmin
                          ? location == AppRoutes.academyAdmin
                          : location.startsWith(module.route),
                      onTap: () => _navigate(context, module.route),
                    ),
                ],
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            _SidebarAction(
              icon: Icons.logout,
              label: 'Sign out',
              onTap: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: 'Sign Out',
                  message:
                      'Are you sure you want to sign out of the Academy Admin dashboard?',
                  confirmLabel: 'Sign Out',
                  destructive: true,
                );
                if (!confirmed) return;
                if (isDrawer && context.mounted) {
                  Navigator.of(context).pop();
                }
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final AcademyAdminModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.transparent;
    final foreground = selected ? Colors.white : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(module.icon, size: 20, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.redAccent.shade100),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.redAccent.shade100,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
