import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/async_list_state.dart';
import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../academy_admin/data/academy_data_seeder.dart';
import '../../domain/student.dart';

/// List of students for an academy with search.
class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _query = '';
  bool _isSeeding = false;

  Future<void> _seedDemoData(String academyId) async {
    if (academyId.isEmpty || _isSeeding) return;
    setState(() => _isSeeding = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seeding demo students and academic records...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      await ref.read(academyDataSeederProvider).seedAcademyData(academyId, force: true);
      ref.invalidate(studentsStreamProvider(academyId));
      ref.invalidate(staffStreamProvider(academyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('5 demo students & academic records successfully seeded!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seeding failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final students = ref.watch(studentsStreamProvider(academyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            tooltip: 'Seed Demo Records',
            icon: _isSeeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            onPressed: _isSeeding ? null : () => _seedDemoData(academyId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addStudent),
        icon: const Icon(Icons.person_add),
        label: const Text('Admit Student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or roll number',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: AsyncListState<Student>(
              value: students,
              emptyTitle: 'No students admitted',
              emptyMessage: 'Tap "Admit Student" or the wand icon to seed sample records.',
              onRetry: () => ref.invalidate(studentsStreamProvider(academyId)),
              builder: (items) {
                final filtered = items.where((s) {
                  final query = _query.toLowerCase();
                  return s.fullName.toLowerCase().contains(query) ||
                      s.rollNumber.contains(query);
                }).toList();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFF818CF8),
                          child: Text(
                            student.fullName.isNotEmpty
                                ? student.fullName.substring(0, 1).toUpperCase()
                                : 'S',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Roll #${student.rollNumber} · ${student.guardianPhone}\n${student.notes}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
