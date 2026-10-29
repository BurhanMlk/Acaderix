import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admissions/application/student_repository_provider.dart';
import '../../admissions/domain/student.dart';
import '../../attendance/application/attendance_repository_provider.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../branches/application/branch_repository_provider.dart';
import '../../branches/domain/branch.dart';
import '../../exams/application/exam_repository_provider.dart';
import '../../exams/domain/exam.dart';
import '../../exams/domain/exam_result.dart';
import '../../fees/application/fee_repository_provider.dart';
import '../../fees/domain/fee_invoice.dart';
import '../../fees/domain/fee_payment.dart';
import '../../staff/application/staff_repository_provider.dart';
import '../../staff/domain/staff.dart';

final studentsStreamProvider = StreamProvider.family<List<Student>, String>(
  (ref, academyId) => ref.watch(studentRepositoryProvider).watchAll(academyId),
);

final staffStreamProvider = StreamProvider.family<List<Staff>, String>(
  (ref, academyId) => ref.watch(staffRepositoryProvider).watchAll(academyId),
);

final branchesStreamProvider = StreamProvider.family<List<Branch>, String>(
  (ref, academyId) => ref.watch(branchRepositoryProvider).watchAll(academyId),
);

final invoicesStreamProvider = StreamProvider.family<List<FeeInvoice>, String>(
  (ref, academyId) => ref.watch(feeRepositoryProvider).watchInvoices(academyId),
);

final paymentsStreamProvider = StreamProvider.family<List<FeePayment>, String>(
  (ref, academyId) => ref.watch(feeRepositoryProvider).watchPayments(academyId),
);

final attendanceForDateProvider =
    StreamProvider.family<
      List<AttendanceRecord>,
      ({String academyId, DateTime date})
    >(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchForDate(args.academyId, args.date),
    );

final examsStreamProvider = StreamProvider.family<List<Exam>, String>(
  (ref, academyId) => ref.watch(examRepositoryProvider).watchExams(academyId),
);

final resultsStreamProvider = StreamProvider.family<List<ExamResult>, String>(
  (ref, academyId) => ref.watch(examRepositoryProvider).watchResults(academyId),
);
