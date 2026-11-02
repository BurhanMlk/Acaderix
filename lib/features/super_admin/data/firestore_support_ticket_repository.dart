import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/support_ticket.dart';
import '../domain/support_ticket_repository.dart';

/// Firestore-backed [SupportTicketRepository] with demo fallbacks.
class FirestoreSupportTicketRepository implements SupportTicketRepository {
  FirestoreSupportTicketRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.supportTickets);

  static final List<SupportTicket> _seededDemoTickets = [
    SupportTicket(
      id: 'ticket_1',
      ticketNumber: 'TICK-1042',
      academyId: 'acad_1',
      academyName: 'Premier Science Academy',
      academyCode: 'ACD-PSA10',
      contactName: 'Dr. Tariq',
      contactEmail: 'tariq@test.com',
      contactPhone: '03001234567',
      subject: 'Request to add branch quota to Standard plan',
      description:
          'We are inaugurating our second campus in Model Town Lahore and would like to confirm our branch allowance for the upcoming term.',
      category: 'billing',
      priority: 'high',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      messages: [
        SupportTicketMessage(
          id: 'msg_1',
          senderName: 'Dr. Tariq',
          senderRole: 'academyAdmin',
          message:
              'We are inaugurating our second campus in Model Town Lahore and would like to confirm our branch allowance for the upcoming term.',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          isStaffReply: false,
        ),
      ],
    ),
    SupportTicket(
      id: 'ticket_2',
      ticketNumber: 'TICK-1038',
      academyId: 'acad_2',
      academyName: 'Apex Coaching Center',
      academyCode: 'ACD-ACC22',
      contactName: 'Prof. Aslam',
      contactEmail: 'aslam@test.com',
      contactPhone: '03009876543',
      subject: 'Bulk Student Enrollment Verification',
      description:
          'Our admissions team enrolled 120 new session students. Please confirm Cloud Firestore synchronization status.',
      category: 'technical',
      priority: 'medium',
      status: 'in_progress',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      messages: [
        SupportTicketMessage(
          id: 'msg_2',
          senderName: 'Prof. Aslam',
          senderRole: 'academyAdmin',
          message:
              'Our admissions team enrolled 120 new session students. Please confirm Cloud Firestore synchronization status.',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          isStaffReply: false,
        ),
        SupportTicketMessage(
          id: 'msg_3',
          senderName: 'Super Admin Desk',
          senderRole: 'superAdmin',
          message:
              'Synchronization logs verified. All 120 student documents and counters have synced cleanly with 100% integrity.',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          isStaffReply: true,
        ),
      ],
    ),
    SupportTicket(
      id: 'ticket_3',
      ticketNumber: 'TICK-1015',
      academyId: 'acad_1',
      academyName: 'Premier Science Academy',
      academyCode: 'ACD-PSA10',
      contactName: 'Dr. Tariq',
      contactEmail: 'tariq@test.com',
      contactPhone: '03001234567',
      subject: 'Custom fee voucher PDF layout inquiry',
      description:
          'Inquiry regarding whether academy tax registration NTN can be reflected in the printable invoice header.',
      category: 'feature_request',
      priority: 'low',
      status: 'resolved',
      resolutionNote:
          'Provided guidance on updating academy tax registration details in Academy Profile settings.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      messages: [
        SupportTicketMessage(
          id: 'msg_4',
          senderName: 'Dr. Tariq',
          senderRole: 'academyAdmin',
          message:
              'Inquiry regarding whether academy tax registration NTN can be reflected in the printable invoice header.',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          isStaffReply: false,
        ),
        SupportTicketMessage(
          id: 'msg_5',
          senderName: 'Super Admin Desk',
          senderRole: 'superAdmin',
          message:
              'Resolved: NTN number is now included dynamically from the academy record into invoice headers.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isStaffReply: true,
        ),
      ],
    ),
  ];

  SupportTicket _fromDoc(String id, Map<String, dynamic> data) {
    return SupportTicket.fromJson(data, id);
  }

  @override
  Stream<List<SupportTicket>> watchTickets() async* {
    yield _seededDemoTickets;
    try {
      await for (final snapshot in _collection
          .orderBy('updatedAt', descending: true)
          .snapshots()) {
        final list = mapQueryDocs<SupportTicket>(snapshot, _fromDoc);
        if (list.isNotEmpty) {
          yield list;
        } else {
          yield _seededDemoTickets;
        }
      }
    } catch (_) {
      // Retain seeded demo data on network or permissions error
    }
  }

  @override
  Future<List<SupportTicket>> getTickets() async {
    try {
      final snapshot =
          await _collection.orderBy('updatedAt', descending: true).get();
      final list = mapQueryDocs<SupportTicket>(snapshot, _fromDoc);
      return list.isNotEmpty ? list : _seededDemoTickets;
    } catch (_) {
      return _seededDemoTickets;
    }
  }

  @override
  Future<SupportTicket?> getTicketById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return mapDocument<SupportTicket>(doc, _fromDoc);
      }
    } catch (_) {}
    return _seededDemoTickets.where((t) => t.id == id).firstOrNull;
  }

  @override
  Future<void> createTicket(SupportTicket ticket) async {
    _seededDemoTickets.removeWhere((t) => t.id == ticket.id);
    _seededDemoTickets.insert(0, ticket);
    try {
      final data = toFirestoreData(ticket.toJson())..remove('id');
      await _collection.doc(ticket.id).set(data);
    } catch (_) {}
  }

  @override
  Future<void> updateTicketStatus(
    String id,
    String status, {
    String? resolutionNote,
  }) async {
    final i = _seededDemoTickets.indexWhere((t) => t.id == id);
    if (i != -1) {
      _seededDemoTickets[i] = _seededDemoTickets[i].copyWith(
        status: status,
        updatedAt: DateTime.now(),
        resolutionNote: resolutionNote ?? _seededDemoTickets[i].resolutionNote,
      );
    }
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (resolutionNote != null) {
        updates['resolutionNote'] = resolutionNote;
      }
      await _collection.doc(id).set(updates, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> addTicketMessage(String id, SupportTicketMessage message) async {
    final i = _seededDemoTickets.indexWhere((t) => t.id == id);
    if (i != -1) {
      final updatedMessages =
          List<SupportTicketMessage>.from(_seededDemoTickets[i].messages)
            ..add(message);
      _seededDemoTickets[i] = _seededDemoTickets[i].copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
    }
    try {
      await _collection.doc(id).set({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': FieldValue.arrayUnion([message.toJson()]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> deleteTicket(String id) async {
    _seededDemoTickets.removeWhere((t) => t.id == id);
    try {
      await _collection.doc(id).delete();
    } catch (_) {}
  }
}
