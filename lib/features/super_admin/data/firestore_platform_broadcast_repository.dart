import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/platform_broadcast.dart';
import '../domain/platform_broadcast_repository.dart';

/// Firestore-backed [PlatformBroadcastRepository] with demo fallbacks.
class FirestorePlatformBroadcastRepository
    implements PlatformBroadcastRepository {
  FirestorePlatformBroadcastRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.broadcasts);

  static final List<PlatformBroadcast> _seededDemoBroadcasts = [
    PlatformBroadcast(
      id: 'broadcast_1',
      title: 'Platform v1.2 Release & Core Upgrades',
      message:
          'New message broadcast capabilities and student communication channels have been deployed across all academy instances.',
      category: 'feature',
      priority: 'high',
      targetAudience: 'all',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      authorEmail: 'admin@acadrix.com',
      sentPushNotification: true,
      deliveryCount: 24,
    ),
    PlatformBroadcast(
      id: 'broadcast_2',
      title: 'Scheduled Cloud Maintenance Notice',
      message:
          'Database index optimizations and Cloud Functions scaling will occur this Sunday from 02:00 AM to 04:00 AM PKT. Minimal downtime expected.',
      category: 'maintenance',
      priority: 'urgent',
      targetAudience: 'all',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      authorEmail: 'admin@acadrix.com',
      sentPushNotification: true,
      deliveryCount: 24,
    ),
    PlatformBroadcast(
      id: 'broadcast_3',
      title: 'Quarterly Invoicing & Subscription Policy',
      message:
          'Automated invoice generation for standard and premium tiers has been finalized. Ensure payment receipts are uploaded on time.',
      category: 'billing',
      priority: 'normal',
      targetAudience: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      authorEmail: 'billing@acadrix.com',
      sentPushNotification: false,
      deliveryCount: 18,
    ),
  ];

  PlatformBroadcast _fromDoc(String id, Map<String, dynamic> data) {
    return PlatformBroadcast.fromJson(data, id);
  }

  @override
  Stream<List<PlatformBroadcast>> watchBroadcasts() async* {
    yield _seededDemoBroadcasts;
    try {
      await for (final snapshot in _collection
          .orderBy('createdAt', descending: true)
          .snapshots()) {
        final list = mapQueryDocs<PlatformBroadcast>(snapshot, _fromDoc);
        if (list.isNotEmpty) {
          yield list;
        } else {
          yield _seededDemoBroadcasts;
        }
      }
    } catch (_) {
      // Retain seeded demo data on network or permissions error
    }
  }

  @override
  Future<List<PlatformBroadcast>> getBroadcasts() async {
    try {
      final snapshot =
          await _collection.orderBy('createdAt', descending: true).get();
      final list = mapQueryDocs<PlatformBroadcast>(snapshot, _fromDoc);
      return list.isNotEmpty ? list : _seededDemoBroadcasts;
    } catch (_) {
      return _seededDemoBroadcasts;
    }
  }

  @override
  Future<void> createBroadcast(PlatformBroadcast broadcast) async {
    _seededDemoBroadcasts.removeWhere((b) => b.id == broadcast.id);
    _seededDemoBroadcasts.insert(0, broadcast);
    try {
      final data = toFirestoreData(broadcast.toJson())..remove('id');
      await _collection.doc(broadcast.id).set(data);
    } catch (_) {}
  }

  @override
  Future<void> toggleBroadcastActive(String id, bool isActive) async {
    final i = _seededDemoBroadcasts.indexWhere((b) => b.id == id);
    if (i != -1) {
      _seededDemoBroadcasts[i] =
          _seededDemoBroadcasts[i].copyWith(isActive: isActive);
    }
    try {
      await _collection
          .doc(id)
          .set({'isActive': isActive}, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> deleteBroadcast(String id) async {
    _seededDemoBroadcasts.removeWhere((b) => b.id == id);
    try {
      await _collection.doc(id).delete();
    } catch (_) {}
  }
}
