import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps a query snapshot into typed model instances.
List<T> mapQueryDocs<T>(
  QuerySnapshot<Map<String, dynamic>> snapshot,
  T Function(String id, Map<String, dynamic> data) mapper,
) {
  return snapshot.docs
      .map((doc) => mapper(doc.id, fromFirestoreData(doc.data())))
      .toList(growable: false);
}

/// Maps a single document snapshot into a typed model, or null when absent.
T? mapDocument<T>(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  T Function(String id, Map<String, dynamic> data) mapper,
) {
  final data = snapshot.data();
  if (data == null) return null;
  return mapper(snapshot.id, fromFirestoreData(data));
}

/// Converts Firestore [Timestamp]s and [DateTime]s back to ISO strings for JSON models.
Map<String, dynamic> fromFirestoreData(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is Timestamp) {
      return MapEntry(key, value.toDate().toIso8601String());
    }
    if (value is DateTime) {
      return MapEntry(key, value.toIso8601String());
    }
    if (value is Map<String, dynamic>) {
      return MapEntry(key, fromFirestoreData(value));
    }
    if (value is List) {
      return MapEntry(
        key,
        value
            .map((e) {
              if (e is Timestamp) return e.toDate().toIso8601String();
              if (e is DateTime) return e.toIso8601String();
              if (e is Map<String, dynamic>) return fromFirestoreData(e);
              return e;
            })
            .toList(growable: false),
      );
    }
    return MapEntry(key, value);
  });
}

/// Converts [DateTime]s to Firestore [Timestamp]s for writes.
Map<String, dynamic> toFirestoreData(Map<String, dynamic> json) {
  return json.map((key, value) {
    if (value is DateTime) return MapEntry(key, Timestamp.fromDate(value));
    if (value is List) {
      return MapEntry(
        key,
        value
            .map((e) => e is DateTime ? Timestamp.fromDate(e) : e)
            .toList(growable: false),
      );
    }
    return MapEntry(key, value);
  });
}
