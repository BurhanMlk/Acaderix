import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_payroll_repository.dart';
import '../domain/payroll_repository.dart';
import '../domain/salary_record.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>(
  (ref) => FirestorePayrollRepository(ref.watch(firestoreProvider)),
);

final salariesStreamProvider =
    StreamProvider.family<List<SalaryRecord>, String>(
  (ref, academyId) {
    if (academyId.isEmpty) return const Stream.empty();
    return ref.watch(payrollRepositoryProvider).watchAll(academyId);
  },
);

final staffSalariesStreamProvider = StreamProvider.family<
    List<SalaryRecord>,
    ({String academyId, String staffId})>(
  (ref, params) {
    if (params.academyId.isEmpty || params.staffId.isEmpty) {
      return const Stream.empty();
    }
    return ref
        .watch(payrollRepositoryProvider)
        .watchAll(params.academyId, staffId: params.staffId);
  },
);
