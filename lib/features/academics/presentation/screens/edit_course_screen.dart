import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/current_academy_provider.dart';
import '../../../academy_admin/application/academy_admin_providers.dart';
import '../../../branches/domain/branch.dart';
import '../../../staff/domain/staff.dart';
import '../../application/course_repository_provider.dart';
import '../../domain/course.dart';

/// Screen allowing an academy admin to edit an existing course.
class EditCourseScreen extends ConsumerStatefulWidget {
  const EditCourseScreen({super.key, required this.course});

  final Course course;

  @override
  ConsumerState<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends ConsumerState<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _feeCtrl;

  String? _selectedBranchId;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.course.name);
    _codeCtrl = TextEditingController(text: widget.course.courseCode);
    _scheduleCtrl = TextEditingController(text: widget.course.schedule);
    _roomCtrl = TextEditingController(text: widget.course.room);
    _feeCtrl = TextEditingController(
      text: widget.course.fee.toStringAsFixed(0),
    );
    _selectedBranchId =
        widget.course.branchId.isNotEmpty ? widget.course.branchId : null;
    _selectedTeacherId =
        widget.course.teacherId.isNotEmpty ? widget.course.teacherId : null;
    _selectedTeacherName = widget.course.teacherName;
  }

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
      final updated = widget.course.copyWith(
        branchId: _selectedBranchId ?? '',
        name: _nameCtrl.text.trim(),
        courseCode: _codeCtrl.text.trim(),
        teacherId: _selectedTeacherId ?? '',
        teacherName: _selectedTeacherName ?? '',
        schedule: _scheduleCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        fee: fee,
      );

      await ref.read(courseRepositoryProvider).saveCourse(updated);
      ref.invalidate(coursesStreamProvider(academyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course "${updated.name}" updated successfully!'),
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
            content: Text('Failed to update course: $e'),
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
        title: const Text('Edit Course / Batch'),
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
                  labelStyle: const TextStyle(color: Colors.white70),
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
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Branch Selector
              DropdownButtonFormField<String?>(
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
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Branches / Main'),
                  ),
                  if (_selectedBranchId != null &&
                      _selectedBranchId!.isNotEmpty &&
                      !branches.any((b) => b.id == _selectedBranchId))
                    DropdownMenuItem<String?>(
                      value: _selectedBranchId,
                      child: Text('Previous Branch ($_selectedBranchId)'),
                    ),
                  ...branches.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedBranchId = val),
              ),
              const SizedBox(height: 14),

              // Assigned Teacher Selector
              DropdownButtonFormField<String?>(
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
                items: [
                  if (_selectedTeacherId != null &&
                      _selectedTeacherId!.isNotEmpty &&
                      !staffMembers.any((s) => s.id == _selectedTeacherId))
                    DropdownMenuItem<String?>(
                      value: _selectedTeacherId,
                      child: Text(
                        (_selectedTeacherName != null &&
                                _selectedTeacherName!.isNotEmpty)
                            ? '$_selectedTeacherName (Legacy)'
                            : 'Previous Teacher ($_selectedTeacherId)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ...staffMembers.map((s) {
                    return DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(
                        '${s.fullName} (${s.staffId})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
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
                  labelStyle: const TextStyle(color: Colors.white70),
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
                        'Update Course',
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
