import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/student/application/student_providers.dart';

/// Shows the modal bottom sheet displaying the student's digital ID card,
/// personal details, parent/guardian info, and account controls.
Future<void> showStudentProfileModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _StudentProfileSheet(),
  );
}

class _StudentProfileSheet extends ConsumerWidget {
  const _StudentProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProfileProvider);
    final branch = ref.watch(currentStudentBranchProvider);
    final theme = Theme.of(context);

    final fullName = student?.fullName.isNotEmpty == true
        ? student!.fullName
        : 'Student Profile';
    final rollNumber = student?.rollNumber.isNotEmpty == true
        ? student!.rollNumber
        : '100001';
    final branchName = branch?.name ?? 'Main Campus';
    final session = student?.academicSession.isNotEmpty == true
        ? student!.academicSession
        : '2026-2027';

    final dobStr = student?.dateOfBirth != null
        ? DateFormat('dd MMM yyyy').format(student!.dateOfBirth!)
        : 'Not recorded';
    final admissionStr = student?.admissionDate != null
        ? DateFormat('dd MMM yyyy').format(student!.admissionDate!)
        : 'Not recorded';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Student Digital Pass',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Scrollable content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // Digital ID Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E1B4B),
                        Color(0xFF312E81),
                        Color(0xFF1E3A8A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Academy watermark top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Color(0xFF38BDF8),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ACADERIX ACADEMY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar + Primary Info
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Roll #$rollNumber',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$branchName • $session',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),

                      // Barcode simulation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STUDENT ID',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student?.id.toUpperCase().substring(0, 10) ??
                                    'ACD-STD-01',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Stylized vertical barcode lines
                          Row(
                            children: List.generate(
                              18,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                width: (index % 3 == 0)
                                    ? 3
                                    : (index % 2 == 0 ? 1.5 : 2),
                                height: 26,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Personal Details Card
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.cake_outlined,
                        'Date of Birth',
                        dobStr,
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildInfoRow(
                        Icons.wc_outlined,
                        'Gender',
                        student?.gender.isNotEmpty == true
                            ? student!.gender
                            : 'Not specified',
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Student Contact',
                        student?.phone.isNotEmpty == true
                            ? student!.phone
                            : 'Not specified',
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Admission Date',
                        admissionStr,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Guardian Details Card
                const Text(
                  'Parent / Guardian Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 14,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.person_outline,
                        'Father / Guardian',
                        student?.fatherName.isNotEmpty == true
                            ? student!.fatherName
                            : 'Not specified',
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildInfoRow(
                        Icons.phone_in_talk_outlined,
                        'Guardian Phone',
                        student?.guardianPhone.isNotEmpty == true
                            ? student!.guardianPhone
                            : 'Not specified',
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildInfoRow(
                        Icons.people_outline,
                        'Relationship',
                        student?.guardianRelation.isNotEmpty == true
                            ? student!.guardianRelation
                            : 'Parent',
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildInfoRow(
                        Icons.home_outlined,
                        'Address',
                        student?.address.isNotEmpty == true
                            ? student!.address
                            : 'Not specified',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: BorderSide(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Sign Out of Student Portal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Are you sure you want to log out of the student portal?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Sign Out'),
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      Navigator.of(context).pop();
                      await ref.read(authControllerProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
