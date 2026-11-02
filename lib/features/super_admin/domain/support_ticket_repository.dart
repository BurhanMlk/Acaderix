import 'support_ticket.dart';

/// Abstraction over platform support tickets storage.
abstract interface class SupportTicketRepository {
  Stream<List<SupportTicket>> watchTickets();
  Future<List<SupportTicket>> getTickets();
  Future<SupportTicket?> getTicketById(String id);
  Future<void> createTicket(SupportTicket ticket);
  Future<void> updateTicketStatus(
    String id,
    String status, {
    String? resolutionNote,
  });
  Future<void> addTicketMessage(String id, SupportTicketMessage message);
  Future<void> deleteTicket(String id);
}
