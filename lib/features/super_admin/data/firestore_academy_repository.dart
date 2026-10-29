import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/academy.dart';
import '../domain/academy_repository.dart';

/// Firestore-backed [AcademyRepository].
final class FirestoreAcademyRepository implements AcademyRepository {
  FirestoreAcademyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.academies);

  @override
  Stream<List<Academy>> watchAll() => _collection
      .orderBy('name')
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));

  @override
  Future<List<Academy>> getAll() async {
    final snapshot = await _collection.orderBy('name').get();
    return mapQueryDocs(snapshot, _fromDoc);
  }

  @override
  Future<Academy?> getById(String id) async {
    final snapshot = await _collection.doc(id).get();
    return mapDocument(snapshot, _fromDoc);
  }

  @override
  Future<void> create(Academy academy) {
    final data = toFirestoreData(academy.toJson())..remove('id');
    return _collection.doc(academy.id).set(data);
  }

  @override
  Future<void> updateStatus(String id, String status) {
    return _collection.doc(id).update({'status': status});
  }

  Academy _fromDoc(String id, Map<String, dynamic> data) =>
      Academy.fromJson({...data, 'id': id});
}
