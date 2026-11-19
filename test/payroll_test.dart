import 'dart:async';

import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/communication/application/communication_providers.dart';
import 'package:academy_management/features/communication/domain/app_notification.dart';
import 'package:academy_management/features/communication/domain/communication_repository.dart';
import 'package:academy_management/features/payroll/application/payroll_providers.dart';
import 'package:academy_management/features/payroll/domain/payroll_repository.dart';
import 'package:academy_management/features/payroll/domain/salary_record.dart';
import 'package:academy_management/features/payroll/presentation/screens/payroll_screen.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/shared/current_academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePayrollRepo implements PayrollRepository {
  final List<SalaryRecord> records = [];
  final _controller = StreamController<List<SalaryRecord>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(records));

  @override
  Stream<List<SalaryRecord>> watchAll(
    String academyId, {
    String? staffId,
    String? monthKey,
  }) async* {
    yield List.unmodifiable(records);
    yield* _controller.stream;
  }

  @override
  Future<void> createOrUpdate(SalaryRecord record) async {
    final idx = records.indexWhere((r) => r.id == record.id);
    if (idx == -1) {
      records.add(record);
    } else {
      records[idx] = record;
    }
    _emit();
  }

  @override
  Future<int> generateMonthlyPayroll({
    required String academyId,
    required List<Staff> staffList,
    required String monthKey,
    required String monthLabel,
  }) async {
    var count = 0;
    for (final s in staffList.where((s) => s.status == 'active' && s.salary > 0)) {
      final exists = records.any((r) => r.staffId == s.id && r.monthKey == monthKey);
      if (!exists) {
        records.add(
          SalaryRecord(
            id: '${monthKey}_${s.id}',
            academyId: academyId,
            staffId: s.id,
            staffCode: s.staffId,
            staffName: s.fullName,
            jobTitle: s.jobTitle,
            branchId: s.branchId,
            monthKey: monthKey,
            monthLabel: monthLabel,
            baseSalary: s.salary,
            status: 'pending',
          ),
        );
        count++;
      }
    }
    _emit();
    return count;
  }

  @override
  Future<void> markAsPaid(
    String academyId,
    String recordId, {
    required String paymentMethod,
    String notes = '',
  }) async {
    final idx = records.indexWhere((r) => r.id == recordId);
    if (idx != -1) {
      records[idx] = records[idx].copyWith(
        status: 'paid',
        paymentMethod: paymentMethod,
        notes: notes,
        paidAt: DateTime.now(),
      );
      _emit();
    }
  }

  @override
  Future<void> delete(String academyId, String recordId) async {
    records.removeWhere((r) => r.id == recordId);
    _emit();
  }
}

class _FakeCommRepo implements CommunicationRepository {
  final List<AppNotification> sentNotifications = [];

  @override
  Future<void> sendNotification(AppNotification notification) async {
    sentNotifications.add(notification);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('SalaryRecord computes netSalary and clamps at 0', () {
    const r1 = SalaryRecord(
      id: '1',
      academyId: 'a1',
      staffId: 's1',
      monthKey: '2026-11',
      monthLabel: 'November 2026',
      baseSalary: 50000,
      bonus: 5000,
      deductions: 2000,
    );
    expect(r1.netSalary, 53000);

    const r2 = SalaryRecord(
      id: '2',
      academyId: 'a1',
      staffId: 's1',
      monthKey: '2026-11',
      monthLabel: 'November 2026',
      baseSalary: 1000,
      deductions: 5000,
    );
    expect(r2.netSalary, 0);
  });

  testWidgets('PayrollScreen generates payroll and marks paid with notification', (tester) async {
    final payrollRepo = _FakePayrollRepo();
    final commRepo = _FakeCommRepo();
    final staffList = [
      const Staff(
        id: 'stf_1',
        academyId: 'acad_1',
        staffId: 'STF-1001',
        fullName: 'Prof. Tariq Mehmood',
        jobTitle: 'Physics Lecturer',
        salary: 90000,
        status: 'active',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue('acad_1'),
          payrollRepositoryProvider.overrideWithValue(payrollRepo),
          communicationRepositoryProvider.overrideWithValue(commRepo),
          staffStreamProvider('acad_1').overrideWith((ref) => Stream.value(staffList)),
          branchesStreamProvider('acad_1').overrideWith((ref) => Stream.value(const <Branch>[])),
        ],
        child: const MaterialApp(home: PayrollScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No payroll records'), findsOneWidget);

    // Generate monthly payroll
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();
    expect(find.text('Generate Monthly Payroll'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate').last);
    await tester.pumpAndSettle();

    expect(payrollRepo.records.length, 1);
    expect(find.text('Prof. Tariq Mehmood'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);

    // Mark as paid
    await tester.tap(find.text('Mark Paid'));
    await tester.pumpAndSettle();
    expect(find.text('Disburse Salary'), findsOneWidget);

    await tester.tap(find.text('Confirm Payment'));
    await tester.pumpAndSettle();

    expect(payrollRepo.records.first.isPaid, isTrue);
    expect(find.text('PAID'), findsOneWidget);
    expect(commRepo.sentNotifications.length, 1);
    expect(commRepo.sentNotifications.first.recipientId, 'STF-1001');
    expect(commRepo.sentNotifications.first.type, 'payroll_alert');
  });
}
