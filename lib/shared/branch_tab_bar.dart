import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/academy_admin/application/academy_admin_providers.dart';
import 'selected_branch_provider.dart';

/// Unified branch selector tab bar for all Academy Admin tabs.
///
/// Renders a horizontal scrolling row of stylish glass pill tabs:
/// "All Branches" plus each campus branch with live branch scope selection.
class BranchTabBar extends ConsumerWidget {
  const BranchTabBar({
    super.key,
    required this.academyId,
    this.showAllOption = true,
    this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 10),
  });

  final String academyId;
  final bool showAllOption;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (academyId.isEmpty) return const SizedBox.shrink();

    final branchesAsync = ref.watch(branchesStreamProvider(academyId));
    final selectedBranchId = ref.watch(selectedBranchIdProvider);

    return branchesAsync.maybeWhen(
      data: (branches) {
        if (branches.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: padding,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (showAllOption)
                  _BranchTabPill(
                    label: 'All Branches',
                    icon: Icons.domain_rounded,
                    isSelected: selectedBranchId == null,
                    count: branches.length,
                    onTap: () {
                      ref.read(selectedBranchIdProvider.notifier).state = null;
                    },
                  ),
                for (final branch in branches)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _BranchTabPill(
                      label: branch.name,
                      subtitle: branch.city.isNotEmpty ? branch.city : null,
                      icon: Icons.location_on_outlined,
                      isSelected: selectedBranchId == branch.id,
                      onTap: () {
                        ref.read(selectedBranchIdProvider.notifier).state =
                            branch.id;
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BranchTabPill extends StatelessWidget {
  const _BranchTabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF6366F1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? const Color(0xFFA5B4FC) : Colors.white60,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isSelected ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isSelected ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
