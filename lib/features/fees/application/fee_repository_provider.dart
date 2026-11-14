import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_fee_repository.dart';
import '../domain/fee_invoice.dart';
import '../domain/fee_payment.dart';
import '../domain/fee_repository.dart';
import '../domain/fee_structure.dart';

final feeRepositoryProvider = Provider<FeeRepository>(
  (ref) => FirestoreFeeRepository(ref.watch(firestoreProvider)),
);

final feeStructuresStreamProvider =
    StreamProvider.family<List<FeeStructure>, String>(
      (ref, academyId) =>
          ref.watch(feeRepositoryProvider).watchFeeStructures(academyId),
    );

final invoicesStreamProvider = StreamProvider.family<List<FeeInvoice>, String>(
  (ref, academyId) => ref.watch(feeRepositoryProvider).watchInvoices(academyId),
);

final paymentsStreamProvider = StreamProvider.family<List<FeePayment>, String>(
  (ref, academyId) => ref.watch(feeRepositoryProvider).watchPayments(academyId),
);
