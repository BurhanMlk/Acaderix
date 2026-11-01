import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../../staff/domain/staff.dart';
import '../../application/course_repository_provider.dart';
import '../../domain/course.dart';

/// Screen allowing an academy admin to create a new course/batch.
class AddCourseScreen extends ConsumerStatefulWidget {
  const AddCourseScreen({super.key});

  @override
  ConsumerState<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends ConsumerState<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '0');

  String? _selectedBranchId;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _scheduleCtrl.dispose();
    _roomCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String academyId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final fee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;
      final course = Course(
        id: const Uuid().v4(),
        academyId: academyId,
        branchId: _selectedBranchId ?? '',
        name: _nameCtrl.text.trim(),
        courseCode: _codeCtrl.text.trim(),
        teacherId: _selectedTeacherId ?? '',
        teacherName: _selectedTeacherName ?? '',
        schedule: _scheduleCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        fee: fee,
      );

      await ref.read(courseRepositoryProvider).saveCourse(course);
      ref.invalidate(coursesStreamProvider(academyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course "${course.name}" created successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create course: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyId = ref.watch(currentAcademyIdProvider) ?? '';
    final branches =
        ref.watch(branchesStreamProvider(academyId)).value ?? const <Branch>[];
    final staffMembers =
        ref.watch(staffStreamProvider(academyId)).value ?? const <Staff>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add Course / Batch'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Name
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Course Name *',
                  hintText: 'e.g. Physics 10th - Batch A',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter course name' : null,
              ),
              const SizedBox(height: 14),

              // Course Code
              TextFormField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g. PHY-101',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Branch Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Campus Branch',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Branches / Main'),
                  ),
                  ...branches.map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedBranchId = val),
              ),
              const SizedBox(height: 14),

              // Assigned Teacher Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedTeacherId,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Assigned Teacher / Staff Member *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: staffMembers.map((s) {
                  return DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      '${s.fullName} (${s.staffId})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final staff =
                        staffMembers.where((s) => s.id == val).firstOrNull;
                    setState(() {
                      _selectedTeacherId = val;
                      _selectedTeacherName = staff?.fullName ?? '';
                    });
                  }
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select a primary teacher' : null,
              ),
              const SizedBox(height: 14),

              // Schedule
              TextFormField(
                controller: _scheduleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Schedule / Timetable',
                  hintText: 'e.g. Mon, Wed, Fri • 4:00 PM - 5:30 PM',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Room & Monthly Fee Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Room #',
                        hintText: 'e.g. Room 3',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _feeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Monthly Fee (PKR)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : () => _submit(academyId),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Course',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
