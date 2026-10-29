// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Batch {

 String get id; String get academyId; String get name; String get classId; String get branchId; int get capacity; String get timing; String get classroom; bool get isActive;
/// Create a copy of Batch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchCopyWith<Batch> get copyWith => _$BatchCopyWithImpl<Batch>(this as Batch, _$identity);

  /// Serializes this Batch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Batch&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.classroom, classroom) || other.classroom == classroom)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,name,classId,branchId,capacity,timing,classroom,isActive);

@override
String toString() {
  return 'Batch(id: $id, academyId: $academyId, name: $name, classId: $classId, branchId: $branchId, capacity: $capacity, timing: $timing, classroom: $classroom, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $BatchCopyWith<$Res>  {
  factory $BatchCopyWith(Batch value, $Res Function(Batch) _then) = _$BatchCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String name, String classId, String branchId, int capacity, String timing, String classroom, bool isActive
});




}
/// @nodoc
class _$BatchCopyWithImpl<$Res>
    implements $BatchCopyWith<$Res> {
  _$BatchCopyWithImpl(this._self, this._then);

  final Batch _self;
  final $Res Function(Batch) _then;

/// Create a copy of Batch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? name = null,Object? classId = null,Object? branchId = null,Object? capacity = null,Object? timing = null,Object? classroom = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as String,classroom: null == classroom ? _self.classroom : classroom // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Batch].
extension BatchPatterns on Batch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Batch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Batch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Batch value)  $default,){
final _that = this;
switch (_that) {
case _Batch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Batch value)?  $default,){
final _that = this;
switch (_that) {
case _Batch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String name,  String classId,  String branchId,  int capacity,  String timing,  String classroom,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Batch() when $default != null:
return $default(_that.id,_that.academyId,_that.name,_that.classId,_that.branchId,_that.capacity,_that.timing,_that.classroom,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String name,  String classId,  String branchId,  int capacity,  String timing,  String classroom,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Batch():
return $default(_that.id,_that.academyId,_that.name,_that.classId,_that.branchId,_that.capacity,_that.timing,_that.classroom,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String name,  String classId,  String branchId,  int capacity,  String timing,  String classroom,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Batch() when $default != null:
return $default(_that.id,_that.academyId,_that.name,_that.classId,_that.branchId,_that.capacity,_that.timing,_that.classroom,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Batch implements Batch {
  const _Batch({required this.id, required this.academyId, this.name = '', this.classId = '', this.branchId = '', this.capacity = 0, this.timing = '', this.classroom = '', this.isActive = true});
  factory _Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String classId;
@override@JsonKey() final  String branchId;
@override@JsonKey() final  int capacity;
@override@JsonKey() final  String timing;
@override@JsonKey() final  String classroom;
@override@JsonKey() final  bool isActive;

/// Create a copy of Batch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchCopyWith<_Batch> get copyWith => __$BatchCopyWithImpl<_Batch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Batch&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.classId, classId) || other.classId == classId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.classroom, classroom) || other.classroom == classroom)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,name,classId,branchId,capacity,timing,classroom,isActive);

@override
String toString() {
  return 'Batch(id: $id, academyId: $academyId, name: $name, classId: $classId, branchId: $branchId, capacity: $capacity, timing: $timing, classroom: $classroom, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$BatchCopyWith<$Res> implements $BatchCopyWith<$Res> {
  factory _$BatchCopyWith(_Batch value, $Res Function(_Batch) _then) = __$BatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String name, String classId, String branchId, int capacity, String timing, String classroom, bool isActive
});




}
/// @nodoc
class __$BatchCopyWithImpl<$Res>
    implements _$BatchCopyWith<$Res> {
  __$BatchCopyWithImpl(this._self, this._then);

  final _Batch _self;
  final $Res Function(_Batch) _then;

/// Create a copy of Batch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? name = null,Object? classId = null,Object? branchId = null,Object? capacity = null,Object? timing = null,Object? classroom = null,Object? isActive = null,}) {
  return _then(_Batch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as String,classroom: null == classroom ? _self.classroom : classroom // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
