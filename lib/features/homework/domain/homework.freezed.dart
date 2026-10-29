// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'homework.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Homework {

 String get id; String get academyId; String get title; String get description; String get subjectId; String get batchId; DateTime? get dueDate; List<String> get attachmentUrls; String get assignedById;
/// Create a copy of Homework
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeworkCopyWith<Homework> get copyWith => _$HomeworkCopyWithImpl<Homework>(this as Homework, _$identity);

  /// Serializes this Homework to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Homework&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&const DeepCollectionEquality().equals(other.attachmentUrls, attachmentUrls)&&(identical(other.assignedById, assignedById) || other.assignedById == assignedById));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,title,description,subjectId,batchId,dueDate,const DeepCollectionEquality().hash(attachmentUrls),assignedById);

@override
String toString() {
  return 'Homework(id: $id, academyId: $academyId, title: $title, description: $description, subjectId: $subjectId, batchId: $batchId, dueDate: $dueDate, attachmentUrls: $attachmentUrls, assignedById: $assignedById)';
}


}

/// @nodoc
abstract mixin class $HomeworkCopyWith<$Res>  {
  factory $HomeworkCopyWith(Homework value, $Res Function(Homework) _then) = _$HomeworkCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String title, String description, String subjectId, String batchId, DateTime? dueDate, List<String> attachmentUrls, String assignedById
});




}
/// @nodoc
class _$HomeworkCopyWithImpl<$Res>
    implements $HomeworkCopyWith<$Res> {
  _$HomeworkCopyWithImpl(this._self, this._then);

  final Homework _self;
  final $Res Function(Homework) _then;

/// Create a copy of Homework
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? title = null,Object? description = null,Object? subjectId = null,Object? batchId = null,Object? dueDate = freezed,Object? attachmentUrls = null,Object? assignedById = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,attachmentUrls: null == attachmentUrls ? _self.attachmentUrls : attachmentUrls // ignore: cast_nullable_to_non_nullable
as List<String>,assignedById: null == assignedById ? _self.assignedById : assignedById // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Homework].
extension HomeworkPatterns on Homework {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Homework value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Homework() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Homework value)  $default,){
final _that = this;
switch (_that) {
case _Homework():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Homework value)?  $default,){
final _that = this;
switch (_that) {
case _Homework() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String title,  String description,  String subjectId,  String batchId,  DateTime? dueDate,  List<String> attachmentUrls,  String assignedById)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Homework() when $default != null:
return $default(_that.id,_that.academyId,_that.title,_that.description,_that.subjectId,_that.batchId,_that.dueDate,_that.attachmentUrls,_that.assignedById);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String title,  String description,  String subjectId,  String batchId,  DateTime? dueDate,  List<String> attachmentUrls,  String assignedById)  $default,) {final _that = this;
switch (_that) {
case _Homework():
return $default(_that.id,_that.academyId,_that.title,_that.description,_that.subjectId,_that.batchId,_that.dueDate,_that.attachmentUrls,_that.assignedById);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String title,  String description,  String subjectId,  String batchId,  DateTime? dueDate,  List<String> attachmentUrls,  String assignedById)?  $default,) {final _that = this;
switch (_that) {
case _Homework() when $default != null:
return $default(_that.id,_that.academyId,_that.title,_that.description,_that.subjectId,_that.batchId,_that.dueDate,_that.attachmentUrls,_that.assignedById);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Homework implements Homework {
  const _Homework({required this.id, required this.academyId, this.title = '', this.description = '', this.subjectId = '', this.batchId = '', this.dueDate, final  List<String> attachmentUrls = const <String>[], this.assignedById = ''}): _attachmentUrls = attachmentUrls;
  factory _Homework.fromJson(Map<String, dynamic> json) => _$HomeworkFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String subjectId;
@override@JsonKey() final  String batchId;
@override final  DateTime? dueDate;
 final  List<String> _attachmentUrls;
@override@JsonKey() List<String> get attachmentUrls {
  if (_attachmentUrls is EqualUnmodifiableListView) return _attachmentUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachmentUrls);
}

@override@JsonKey() final  String assignedById;

/// Create a copy of Homework
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeworkCopyWith<_Homework> get copyWith => __$HomeworkCopyWithImpl<_Homework>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeworkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Homework&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&const DeepCollectionEquality().equals(other._attachmentUrls, _attachmentUrls)&&(identical(other.assignedById, assignedById) || other.assignedById == assignedById));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,title,description,subjectId,batchId,dueDate,const DeepCollectionEquality().hash(_attachmentUrls),assignedById);

@override
String toString() {
  return 'Homework(id: $id, academyId: $academyId, title: $title, description: $description, subjectId: $subjectId, batchId: $batchId, dueDate: $dueDate, attachmentUrls: $attachmentUrls, assignedById: $assignedById)';
}


}

/// @nodoc
abstract mixin class _$HomeworkCopyWith<$Res> implements $HomeworkCopyWith<$Res> {
  factory _$HomeworkCopyWith(_Homework value, $Res Function(_Homework) _then) = __$HomeworkCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String title, String description, String subjectId, String batchId, DateTime? dueDate, List<String> attachmentUrls, String assignedById
});




}
/// @nodoc
class __$HomeworkCopyWithImpl<$Res>
    implements _$HomeworkCopyWith<$Res> {
  __$HomeworkCopyWithImpl(this._self, this._then);

  final _Homework _self;
  final $Res Function(_Homework) _then;

/// Create a copy of Homework
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? title = null,Object? description = null,Object? subjectId = null,Object? batchId = null,Object? dueDate = freezed,Object? attachmentUrls = null,Object? assignedById = null,}) {
  return _then(_Homework(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,attachmentUrls: null == attachmentUrls ? _self._attachmentUrls : attachmentUrls // ignore: cast_nullable_to_non_nullable
as List<String>,assignedById: null == assignedById ? _self.assignedById : assignedById // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
