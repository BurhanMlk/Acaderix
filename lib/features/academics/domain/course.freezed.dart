// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Course {

 String get id; String get academyId; String get branchId; String get name; String get courseCode; String get description; String get teacherId; String get teacherName; List<String> get enrolledStudentIds; String get schedule; String get room; double get fee; bool get isActive;
/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseCopyWith<Course> get copyWith => _$CourseCopyWithImpl<Course>(this as Course, _$identity);

  /// Serializes this Course to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Course&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.name, name) || other.name == name)&&(identical(other.courseCode, courseCode) || other.courseCode == courseCode)&&(identical(other.description, description) || other.description == description)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&const DeepCollectionEquality().equals(other.enrolledStudentIds, enrolledStudentIds)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.room, room) || other.room == room)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,branchId,name,courseCode,description,teacherId,teacherName,const DeepCollectionEquality().hash(enrolledStudentIds),schedule,room,fee,isActive);

@override
String toString() {
  return 'Course(id: $id, academyId: $academyId, branchId: $branchId, name: $name, courseCode: $courseCode, description: $description, teacherId: $teacherId, teacherName: $teacherName, enrolledStudentIds: $enrolledStudentIds, schedule: $schedule, room: $room, fee: $fee, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $CourseCopyWith<$Res>  {
  factory $CourseCopyWith(Course value, $Res Function(Course) _then) = _$CourseCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String branchId, String name, String courseCode, String description, String teacherId, String teacherName, List<String> enrolledStudentIds, String schedule, String room, double fee, bool isActive
});




}
/// @nodoc
class _$CourseCopyWithImpl<$Res>
    implements $CourseCopyWith<$Res> {
  _$CourseCopyWithImpl(this._self, this._then);

  final Course _self;
  final $Res Function(Course) _then;

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? branchId = null,Object? name = null,Object? courseCode = null,Object? description = null,Object? teacherId = null,Object? teacherName = null,Object? enrolledStudentIds = null,Object? schedule = null,Object? room = null,Object? fee = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,courseCode: null == courseCode ? _self.courseCode : courseCode // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,enrolledStudentIds: null == enrolledStudentIds ? _self.enrolledStudentIds : enrolledStudentIds // ignore: cast_nullable_to_non_nullable
as List<String>,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Course].
extension CoursePatterns on Course {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Course value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Course() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Course value)  $default,){
final _that = this;
switch (_that) {
case _Course():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Course value)?  $default,){
final _that = this;
switch (_that) {
case _Course() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String branchId,  String name,  String courseCode,  String description,  String teacherId,  String teacherName,  List<String> enrolledStudentIds,  String schedule,  String room,  double fee,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Course() when $default != null:
return $default(_that.id,_that.academyId,_that.branchId,_that.name,_that.courseCode,_that.description,_that.teacherId,_that.teacherName,_that.enrolledStudentIds,_that.schedule,_that.room,_that.fee,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String branchId,  String name,  String courseCode,  String description,  String teacherId,  String teacherName,  List<String> enrolledStudentIds,  String schedule,  String room,  double fee,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Course():
return $default(_that.id,_that.academyId,_that.branchId,_that.name,_that.courseCode,_that.description,_that.teacherId,_that.teacherName,_that.enrolledStudentIds,_that.schedule,_that.room,_that.fee,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String branchId,  String name,  String courseCode,  String description,  String teacherId,  String teacherName,  List<String> enrolledStudentIds,  String schedule,  String room,  double fee,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Course() when $default != null:
return $default(_that.id,_that.academyId,_that.branchId,_that.name,_that.courseCode,_that.description,_that.teacherId,_that.teacherName,_that.enrolledStudentIds,_that.schedule,_that.room,_that.fee,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Course implements Course {
  const _Course({required this.id, required this.academyId, this.branchId = '', this.name = '', this.courseCode = '', this.description = '', this.teacherId = '', this.teacherName = '', final  List<String> enrolledStudentIds = const <String>[], this.schedule = '', this.room = '', this.fee = 0.0, this.isActive = true}): _enrolledStudentIds = enrolledStudentIds;
  factory _Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String branchId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String courseCode;
@override@JsonKey() final  String description;
@override@JsonKey() final  String teacherId;
@override@JsonKey() final  String teacherName;
 final  List<String> _enrolledStudentIds;
@override@JsonKey() List<String> get enrolledStudentIds {
  if (_enrolledStudentIds is EqualUnmodifiableListView) return _enrolledStudentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enrolledStudentIds);
}

@override@JsonKey() final  String schedule;
@override@JsonKey() final  String room;
@override@JsonKey() final  double fee;
@override@JsonKey() final  bool isActive;

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseCopyWith<_Course> get copyWith => __$CourseCopyWithImpl<_Course>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Course&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.name, name) || other.name == name)&&(identical(other.courseCode, courseCode) || other.courseCode == courseCode)&&(identical(other.description, description) || other.description == description)&&(identical(other.teacherId, teacherId) || other.teacherId == teacherId)&&(identical(other.teacherName, teacherName) || other.teacherName == teacherName)&&const DeepCollectionEquality().equals(other._enrolledStudentIds, _enrolledStudentIds)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.room, room) || other.room == room)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,branchId,name,courseCode,description,teacherId,teacherName,const DeepCollectionEquality().hash(_enrolledStudentIds),schedule,room,fee,isActive);

@override
String toString() {
  return 'Course(id: $id, academyId: $academyId, branchId: $branchId, name: $name, courseCode: $courseCode, description: $description, teacherId: $teacherId, teacherName: $teacherName, enrolledStudentIds: $enrolledStudentIds, schedule: $schedule, room: $room, fee: $fee, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$CourseCopyWith<$Res> implements $CourseCopyWith<$Res> {
  factory _$CourseCopyWith(_Course value, $Res Function(_Course) _then) = __$CourseCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String branchId, String name, String courseCode, String description, String teacherId, String teacherName, List<String> enrolledStudentIds, String schedule, String room, double fee, bool isActive
});




}
/// @nodoc
class __$CourseCopyWithImpl<$Res>
    implements _$CourseCopyWith<$Res> {
  __$CourseCopyWithImpl(this._self, this._then);

  final _Course _self;
  final $Res Function(_Course) _then;

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? branchId = null,Object? name = null,Object? courseCode = null,Object? description = null,Object? teacherId = null,Object? teacherName = null,Object? enrolledStudentIds = null,Object? schedule = null,Object? room = null,Object? fee = null,Object? isActive = null,}) {
  return _then(_Course(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,courseCode: null == courseCode ? _self.courseCode : courseCode // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,teacherId: null == teacherId ? _self.teacherId : teacherId // ignore: cast_nullable_to_non_nullable
as String,teacherName: null == teacherName ? _self.teacherName : teacherName // ignore: cast_nullable_to_non_nullable
as String,enrolledStudentIds: null == enrolledStudentIds ? _self._enrolledStudentIds : enrolledStudentIds // ignore: cast_nullable_to_non_nullable
as List<String>,schedule: null == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
