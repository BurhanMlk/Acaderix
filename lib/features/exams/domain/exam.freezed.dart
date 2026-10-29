// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Exam {

 String get id; String get academyId; String get name; String get category; String get classId; String get subjectId; double get totalMarks; DateTime? get examDate; bool get isPublished;
/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamCopyWith<Exam> get copyWith => _$ExamCopyWithImpl<Exam>(this as Exam, _$identity);

  /// Serializes this Exam to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Exam&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.totalMarks, totalMarks) || other.totalMarks == totalMarks)&&(identical(other.examDate, examDate) || other.examDate == examDate)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,name,category,classId,subjectId,totalMarks,examDate,isPublished);

@override
String toString() {
  return 'Exam(id: $id, academyId: $academyId, name: $name, category: $category, classId: $classId, subjectId: $subjectId, totalMarks: $totalMarks, examDate: $examDate, isPublished: $isPublished)';
}


}

/// @nodoc
abstract mixin class $ExamCopyWith<$Res>  {
  factory $ExamCopyWith(Exam value, $Res Function(Exam) _then) = _$ExamCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String name, String category, String classId, String subjectId, double totalMarks, DateTime? examDate, bool isPublished
});




}
/// @nodoc
class _$ExamCopyWithImpl<$Res>
    implements $ExamCopyWith<$Res> {
  _$ExamCopyWithImpl(this._self, this._then);

  final Exam _self;
  final $Res Function(Exam) _then;

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? name = null,Object? category = null,Object? classId = null,Object? subjectId = null,Object? totalMarks = null,Object? examDate = freezed,Object? isPublished = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,totalMarks: null == totalMarks ? _self.totalMarks : totalMarks // ignore: cast_nullable_to_non_nullable
as double,examDate: freezed == examDate ? _self.examDate : examDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Exam].
extension ExamPatterns on Exam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Exam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Exam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Exam value)  $default,){
final _that = this;
switch (_that) {
case _Exam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Exam value)?  $default,){
final _that = this;
switch (_that) {
case _Exam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String name,  String category,  String classId,  String subjectId,  double totalMarks,  DateTime? examDate,  bool isPublished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Exam() when $default != null:
return $default(_that.id,_that.academyId,_that.name,_that.category,_that.classId,_that.subjectId,_that.totalMarks,_that.examDate,_that.isPublished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String name,  String category,  String classId,  String subjectId,  double totalMarks,  DateTime? examDate,  bool isPublished)  $default,) {final _that = this;
switch (_that) {
case _Exam():
return $default(_that.id,_that.academyId,_that.name,_that.category,_that.classId,_that.subjectId,_that.totalMarks,_that.examDate,_that.isPublished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String name,  String category,  String classId,  String subjectId,  double totalMarks,  DateTime? examDate,  bool isPublished)?  $default,) {final _that = this;
switch (_that) {
case _Exam() when $default != null:
return $default(_that.id,_that.academyId,_that.name,_that.category,_that.classId,_that.subjectId,_that.totalMarks,_that.examDate,_that.isPublished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Exam implements Exam {
  const _Exam({required this.id, required this.academyId, this.name = '', this.category = 'monthly', this.classId = '', this.subjectId = '', this.totalMarks = 0, this.examDate, this.isPublished = false});
  factory _Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String category;
@override@JsonKey() final  String classId;
@override@JsonKey() final  String subjectId;
@override@JsonKey() final  double totalMarks;
@override final  DateTime? examDate;
@override@JsonKey() final  bool isPublished;

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamCopyWith<_Exam> get copyWith => __$ExamCopyWithImpl<_Exam>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Exam&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.totalMarks, totalMarks) || other.totalMarks == totalMarks)&&(identical(other.examDate, examDate) || other.examDate == examDate)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,name,category,classId,subjectId,totalMarks,examDate,isPublished);

@override
String toString() {
  return 'Exam(id: $id, academyId: $academyId, name: $name, category: $category, classId: $classId, subjectId: $subjectId, totalMarks: $totalMarks, examDate: $examDate, isPublished: $isPublished)';
}


}

/// @nodoc
abstract mixin class _$ExamCopyWith<$Res> implements $ExamCopyWith<$Res> {
  factory _$ExamCopyWith(_Exam value, $Res Function(_Exam) _then) = __$ExamCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String name, String category, String classId, String subjectId, double totalMarks, DateTime? examDate, bool isPublished
});




}
/// @nodoc
class __$ExamCopyWithImpl<$Res>
    implements _$ExamCopyWith<$Res> {
  __$ExamCopyWithImpl(this._self, this._then);

  final _Exam _self;
  final $Res Function(_Exam) _then;

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? name = null,Object? category = null,Object? classId = null,Object? subjectId = null,Object? totalMarks = null,Object? examDate = freezed,Object? isPublished = null,}) {
  return _then(_Exam(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,totalMarks: null == totalMarks ? _self.totalMarks : totalMarks // ignore: cast_nullable_to_non_nullable
as double,examDate: freezed == examDate ? _self.examDate : examDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
