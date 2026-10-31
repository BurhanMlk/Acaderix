import 'package:academy_management/core/network/firestore_ext.dart';
import 'package:academy_management/features/super_admin/domain/academy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsing academy with timestamp', () {
    final rawData = {
      'code': 'ACAD1',
      'name': 'Test Academy',
      'registrationDate': Timestamp.now(),
    };
    final converted = fromFirestoreData(rawData);
    final academy = Academy.fromJson({'id': '1', ...converted});
    expect(academy.name, equals('Test Academy'));
  });
}
