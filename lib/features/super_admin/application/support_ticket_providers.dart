import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/firebase_services.dart';
import '../data/firestore_support_ticket_repository.dart';
import '../domain/support_ticket.dart';
import '../domain/support_ticket_repository.dart';

/// Provides the active [SupportTicketRepository].
final supportTicketRepositoryProvider =
    Provider<SupportTicketRepository>((ref) {
  return FirestoreSupportTicketRepository(ref.watch(firestoreProvider));
});

/// Live stream of all platform support tickets.
final supportTicketsStreamProvider =
    StreamProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportTicketRepositoryProvider).watchTickets();
});
