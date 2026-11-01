import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/attendance_calculator.dart';

part 'attendance_record.freezed.dart';
part 'attendance_record.g.dart';

/// JSON converter for [AttendanceStatus].
class AttendanceStatusConverter
    implements JsonConverter<AttendanceStatus, String> {
  const AttendanceStatusConverter();

  @override
  AttendanceStatus fromJson(String json) => AttendanceStatus.values.firstWhere(
    (s) => s.name == json,
    orElse: () => AttendanceStatus.absent,
  );

  @override
  String toJson(AttendanceStatus status) => status.name;
}

/// A single student attendance record for a course and date.
@freezed
abstract class AttendanceRecord with _$AttendanceRecord {
  const factory AttendanceRecord({
    required String id,
    required String academyId,
    required String studentId,
    required DateTime date,
    @AttendanceStatusConverter()
    @Default(AttendanceStatus.present)
    AttendanceStatus status,
    @Default('') String courseId,
    @Default('') String batchId,
    @Default('') String markedById,
  }) = _AttendanceRecord;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordFromJson(json);
}
