// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExamResult {

 String get id; String get academyId; String get examId; String get studentId; double get obtainedMarks; double get totalMarks; String get grade; bool get passed; bool get isPublished;
/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamResultCopyWith<ExamResult> get copyWith => _$ExamResultCopyWithImpl<ExamResult>(this as ExamResult, _$identity);

  /// Serializes this ExamResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamResult&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.examId, examId) || other.examId == examId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.obtainedMarks, obtainedMarks) || other.obtainedMarks == obtainedMarks)&&(identical(other.totalMarks, totalMarks) || other.totalMarks == totalMarks)&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,examId,studentId,obtainedMarks,totalMarks,grade,passed,isPublished);

@override
String toString() {
  return 'ExamResult(id: $id, academyId: $academyId, examId: $examId, studentId: $studentId, obtainedMarks: $obtainedMarks, totalMarks: $totalMarks, grade: $grade, passed: $passed, isPublished: $isPublished)';
}


}

/// @nodoc
abstract mixin class $ExamResultCopyWith<$Res>  {
  factory $ExamResultCopyWith(ExamResult value, $Res Function(ExamResult) _then) = _$ExamResultCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String examId, String studentId, double obtainedMarks, double totalMarks, String grade, bool passed, bool isPublished
});




}
/// @nodoc
class _$ExamResultCopyWithImpl<$Res>
    implements $ExamResultCopyWith<$Res> {
  _$ExamResultCopyWithImpl(this._self, this._then);

  final ExamResult _self;
  final $Res Function(ExamResult) _then;

/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? examId = null,Object? studentId = null,Object? obtainedMarks = null,Object? totalMarks = null,Object? grade = null,Object? passed = null,Object? isPublished = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,examId: null == examId ? _self.examId : examId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,obtainedMarks: null == obtainedMarks ? _self.obtainedMarks : obtainedMarks // ignore: cast_nullable_to_non_nullable
as double,totalMarks: null == totalMarks ? _self.totalMarks : totalMarks // ignore: cast_nullable_to_non_nullable
as double,grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamResult].
extension ExamResultPatterns on ExamResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamResult value)  $default,){
final _that = this;
switch (_that) {
case _ExamResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamResult value)?  $default,){
final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String examId,  String studentId,  double obtainedMarks,  double totalMarks,  String grade,  bool passed,  bool isPublished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
return $default(_that.id,_that.academyId,_that.examId,_that.studentId,_that.obtainedMarks,_that.totalMarks,_that.grade,_that.passed,_that.isPublished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String examId,  String studentId,  double obtainedMarks,  double totalMarks,  String grade,  bool passed,  bool isPublished)  $default,) {final _that = this;
switch (_that) {
case _ExamResult():
return $default(_that.id,_that.academyId,_that.examId,_that.studentId,_that.obtainedMarks,_that.totalMarks,_that.grade,_that.passed,_that.isPublished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String examId,  String studentId,  double obtainedMarks,  double totalMarks,  String grade,  bool passed,  bool isPublished)?  $default,) {final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
return $default(_that.id,_that.academyId,_that.examId,_that.studentId,_that.obtainedMarks,_that.totalMarks,_that.grade,_that.passed,_that.isPublished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamResult implements ExamResult {
  const _ExamResult({required this.id, required this.academyId, required this.examId, required this.studentId, this.obtainedMarks = 0, this.totalMarks = 0, this.grade = '', this.passed = false, this.isPublished = false});
  factory _ExamResult.fromJson(Map<String, dynamic> json) => _$ExamResultFromJson(json);

@override final  String id;
@override final  String academyId;
@override final  String examId;
@override final  String studentId;
@override@JsonKey() final  double obtainedMarks;
@override@JsonKey() final  double totalMarks;
@override@JsonKey() final  String grade;
@override@JsonKey() final  bool passed;
@override@JsonKey() final  bool isPublished;

/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamResultCopyWith<_ExamResult> get copyWith => __$ExamResultCopyWithImpl<_ExamResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamResult&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.examId, examId) || other.examId == examId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.obtainedMarks, obtainedMarks) || other.obtainedMarks == obtainedMarks)&&(identical(other.totalMarks, totalMarks) || other.totalMarks == totalMarks)&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,examId,studentId,obtainedMarks,totalMarks,grade,passed,isPublished);

@override
String toString() {
  return 'ExamResult(id: $id, academyId: $academyId, examId: $examId, studentId: $studentId, obtainedMarks: $obtainedMarks, totalMarks: $totalMarks, grade: $grade, passed: $passed, isPublished: $isPublished)';
}


}

/// @nodoc
abstract mixin class _$ExamResultCopyWith<$Res> implements $ExamResultCopyWith<$Res> {
  factory _$ExamResultCopyWith(_ExamResult value, $Res Function(_ExamResult) _then) = __$ExamResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String examId, String studentId, double obtainedMarks, double totalMarks, String grade, bool passed, bool isPublished
});




}
/// @nodoc
class __$ExamResultCopyWithImpl<$Res>
    implements _$ExamResultCopyWith<$Res> {
  __$ExamResultCopyWithImpl(this._self, this._then);

  final _ExamResult _self;
  final $Res Function(_ExamResult) _then;

/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? examId = null,Object? studentId = null,Object? obtainedMarks = null,Object? totalMarks = null,Object? grade = null,Object? passed = null,Object? isPublished = null,}) {
  return _then(_ExamResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,examId: null == examId ? _self.examId : examId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,obtainedMarks: null == obtainedMarks ? _self.obtainedMarks : obtainedMarks // ignore: cast_nullable_to_non_nullable
as double,totalMarks: null == totalMarks ? _self.totalMarks : totalMarks // ignore: cast_nullable_to_non_nullable
as double,grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
