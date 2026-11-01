// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceRecord {

 String get id; String get academyId; String get studentId; DateTime get date;@AttendanceStatusConverter() AttendanceStatus get status; String get courseId; String get batchId; String get markedById;
/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceRecordCopyWith<AttendanceRecord> get copyWith => _$AttendanceRecordCopyWithImpl<AttendanceRecord>(this as AttendanceRecord, _$identity);

  /// Serializes this AttendanceRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.markedById, markedById) || other.markedById == markedById));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,studentId,date,status,courseId,batchId,markedById);

@override
String toString() {
  return 'AttendanceRecord(id: $id, academyId: $academyId, studentId: $studentId, date: $date, status: $status, courseId: $courseId, batchId: $batchId, markedById: $markedById)';
}


}

/// @nodoc
abstract mixin class $AttendanceRecordCopyWith<$Res>  {
  factory $AttendanceRecordCopyWith(AttendanceRecord value, $Res Function(AttendanceRecord) _then) = _$AttendanceRecordCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String studentId, DateTime date,@AttendanceStatusConverter() AttendanceStatus status, String courseId, String batchId, String markedById
});




}
/// @nodoc
class _$AttendanceRecordCopyWithImpl<$Res>
    implements $AttendanceRecordCopyWith<$Res> {
  _$AttendanceRecordCopyWithImpl(this._self, this._then);

  final AttendanceRecord _self;
  final $Res Function(AttendanceRecord) _then;

/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? studentId = null,Object? date = null,Object? status = null,Object? courseId = null,Object? batchId = null,Object? markedById = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,markedById: null == markedById ? _self.markedById : markedById // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceRecord].
extension AttendanceRecordPatterns on AttendanceRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceRecord value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceRecord value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String studentId,  DateTime date, @AttendanceStatusConverter()  AttendanceStatus status,  String courseId,  String batchId,  String markedById)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
return $default(_that.id,_that.academyId,_that.studentId,_that.date,_that.status,_that.courseId,_that.batchId,_that.markedById);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String studentId,  DateTime date, @AttendanceStatusConverter()  AttendanceStatus status,  String courseId,  String batchId,  String markedById)  $default,) {final _that = this;
switch (_that) {
case _AttendanceRecord():
return $default(_that.id,_that.academyId,_that.studentId,_that.date,_that.status,_that.courseId,_that.batchId,_that.markedById);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String studentId,  DateTime date, @AttendanceStatusConverter()  AttendanceStatus status,  String courseId,  String batchId,  String markedById)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceRecord() when $default != null:
return $default(_that.id,_that.academyId,_that.studentId,_that.date,_that.status,_that.courseId,_that.batchId,_that.markedById);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceRecord implements AttendanceRecord {
  const _AttendanceRecord({required this.id, required this.academyId, required this.studentId, required this.date, @AttendanceStatusConverter() this.status = AttendanceStatus.present, this.courseId = '', this.batchId = '', this.markedById = ''});
  factory _AttendanceRecord.fromJson(Map<String, dynamic> json) => _$AttendanceRecordFromJson(json);

@override final  String id;
@override final  String academyId;
@override final  String studentId;
@override final  DateTime date;
@override@JsonKey()@AttendanceStatusConverter() final  AttendanceStatus status;
@override@JsonKey() final  String courseId;
@override@JsonKey() final  String batchId;
@override@JsonKey() final  String markedById;

/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceRecordCopyWith<_AttendanceRecord> get copyWith => __$AttendanceRecordCopyWithImpl<_AttendanceRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.markedById, markedById) || other.markedById == markedById));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,studentId,date,status,courseId,batchId,markedById);

@override
String toString() {
  return 'AttendanceRecord(id: $id, academyId: $academyId, studentId: $studentId, date: $date, status: $status, courseId: $courseId, batchId: $batchId, markedById: $markedById)';
}


}

/// @nodoc
abstract mixin class _$AttendanceRecordCopyWith<$Res> implements $AttendanceRecordCopyWith<$Res> {
  factory _$AttendanceRecordCopyWith(_AttendanceRecord value, $Res Function(_AttendanceRecord) _then) = __$AttendanceRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String studentId, DateTime date,@AttendanceStatusConverter() AttendanceStatus status, String courseId, String batchId, String markedById
});




}
/// @nodoc
class __$AttendanceRecordCopyWithImpl<$Res>
    implements _$AttendanceRecordCopyWith<$Res> {
  __$AttendanceRecordCopyWithImpl(this._self, this._then);

  final _AttendanceRecord _self;
  final $Res Function(_AttendanceRecord) _then;

/// Create a copy of AttendanceRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? studentId = null,Object? date = null,Object? status = null,Object? courseId = null,Object? batchId = null,Object? markedById = null,}) {
  return _then(_AttendanceRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AttendanceStatus,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,markedById: null == markedById ? _self.markedById : markedById // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
