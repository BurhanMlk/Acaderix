// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fee_structure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeeStructure {

 String get id; String get academyId; String get title; String get description; double get amount; String get frequency;// monthly, quarterly, annual, one-time
 int get dueDayOfMonth;// day of month when payment is due
 double get lateFinePerDay;// PKR per day after due date
 double get lateFineMax;// max late fine cap
 String get branchId;// empty = all branches
 String get courseId;// empty = all courses
 bool get isActive; DateTime? get createdAt;
/// Create a copy of FeeStructure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeeStructureCopyWith<FeeStructure> get copyWith => _$FeeStructureCopyWithImpl<FeeStructure>(this as FeeStructure, _$identity);

  /// Serializes this FeeStructure to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeeStructure&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dueDayOfMonth, dueDayOfMonth) || other.dueDayOfMonth == dueDayOfMonth)&&(identical(other.lateFinePerDay, lateFinePerDay) || other.lateFinePerDay == lateFinePerDay)&&(identical(other.lateFineMax, lateFineMax) || other.lateFineMax == lateFineMax)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,title,description,amount,frequency,dueDayOfMonth,lateFinePerDay,lateFineMax,branchId,courseId,isActive,createdAt);

@override
String toString() {
  return 'FeeStructure(id: $id, academyId: $academyId, title: $title, description: $description, amount: $amount, frequency: $frequency, dueDayOfMonth: $dueDayOfMonth, lateFinePerDay: $lateFinePerDay, lateFineMax: $lateFineMax, branchId: $branchId, courseId: $courseId, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FeeStructureCopyWith<$Res>  {
  factory $FeeStructureCopyWith(FeeStructure value, $Res Function(FeeStructure) _then) = _$FeeStructureCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String title, String description, double amount, String frequency, int dueDayOfMonth, double lateFinePerDay, double lateFineMax, String branchId, String courseId, bool isActive, DateTime? createdAt
});




}
/// @nodoc
class _$FeeStructureCopyWithImpl<$Res>
    implements $FeeStructureCopyWith<$Res> {
  _$FeeStructureCopyWithImpl(this._self, this._then);

  final FeeStructure _self;
  final $Res Function(FeeStructure) _then;

/// Create a copy of FeeStructure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? title = null,Object? description = null,Object? amount = null,Object? frequency = null,Object? dueDayOfMonth = null,Object? lateFinePerDay = null,Object? lateFineMax = null,Object? branchId = null,Object? courseId = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dueDayOfMonth: null == dueDayOfMonth ? _self.dueDayOfMonth : dueDayOfMonth // ignore: cast_nullable_to_non_nullable
as int,lateFinePerDay: null == lateFinePerDay ? _self.lateFinePerDay : lateFinePerDay // ignore: cast_nullable_to_non_nullable
as double,lateFineMax: null == lateFineMax ? _self.lateFineMax : lateFineMax // ignore: cast_nullable_to_non_nullable
as double,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeeStructure].
extension FeeStructurePatterns on FeeStructure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeeStructure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeeStructure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeeStructure value)  $default,){
final _that = this;
switch (_that) {
case _FeeStructure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeeStructure value)?  $default,){
final _that = this;
switch (_that) {
case _FeeStructure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String title,  String description,  double amount,  String frequency,  int dueDayOfMonth,  double lateFinePerDay,  double lateFineMax,  String branchId,  String courseId,  bool isActive,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeeStructure() when $default != null:
return $default(_that.id,_that.academyId,_that.title,_that.description,_that.amount,_that.frequency,_that.dueDayOfMonth,_that.lateFinePerDay,_that.lateFineMax,_that.branchId,_that.courseId,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String title,  String description,  double amount,  String frequency,  int dueDayOfMonth,  double lateFinePerDay,  double lateFineMax,  String branchId,  String courseId,  bool isActive,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _FeeStructure():
return $default(_that.id,_that.academyId,_that.title,_that.description,_that.amount,_that.frequency,_that.dueDayOfMonth,_that.lateFinePerDay,_that.lateFineMax,_that.branchId,_that.courseId,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String title,  String description,  double amount,  String frequency,  int dueDayOfMonth,  double lateFinePerDay,  double lateFineMax,  String branchId,  String courseId,  bool isActive,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FeeStructure() when $default != null:
return $default(_that.id,_that.academyId,_that.title,_that.description,_that.amount,_that.frequency,_that.dueDayOfMonth,_that.lateFinePerDay,_that.lateFineMax,_that.branchId,_that.courseId,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeeStructure implements FeeStructure {
  const _FeeStructure({required this.id, required this.academyId, this.title = '', this.description = '', this.amount = 0, this.frequency = 'monthly', this.dueDayOfMonth = 15, this.lateFinePerDay = 0, this.lateFineMax = 500, this.branchId = '', this.courseId = '', this.isActive = true, this.createdAt});
  factory _FeeStructure.fromJson(Map<String, dynamic> json) => _$FeeStructureFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  double amount;
@override@JsonKey() final  String frequency;
// monthly, quarterly, annual, one-time
@override@JsonKey() final  int dueDayOfMonth;
// day of month when payment is due
@override@JsonKey() final  double lateFinePerDay;
// PKR per day after due date
@override@JsonKey() final  double lateFineMax;
// max late fine cap
@override@JsonKey() final  String branchId;
// empty = all branches
@override@JsonKey() final  String courseId;
// empty = all courses
@override@JsonKey() final  bool isActive;
@override final  DateTime? createdAt;

/// Create a copy of FeeStructure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeeStructureCopyWith<_FeeStructure> get copyWith => __$FeeStructureCopyWithImpl<_FeeStructure>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeeStructureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeeStructure&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.dueDayOfMonth, dueDayOfMonth) || other.dueDayOfMonth == dueDayOfMonth)&&(identical(other.lateFinePerDay, lateFinePerDay) || other.lateFinePerDay == lateFinePerDay)&&(identical(other.lateFineMax, lateFineMax) || other.lateFineMax == lateFineMax)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,title,description,amount,frequency,dueDayOfMonth,lateFinePerDay,lateFineMax,branchId,courseId,isActive,createdAt);

@override
String toString() {
  return 'FeeStructure(id: $id, academyId: $academyId, title: $title, description: $description, amount: $amount, frequency: $frequency, dueDayOfMonth: $dueDayOfMonth, lateFinePerDay: $lateFinePerDay, lateFineMax: $lateFineMax, branchId: $branchId, courseId: $courseId, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FeeStructureCopyWith<$Res> implements $FeeStructureCopyWith<$Res> {
  factory _$FeeStructureCopyWith(_FeeStructure value, $Res Function(_FeeStructure) _then) = __$FeeStructureCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String title, String description, double amount, String frequency, int dueDayOfMonth, double lateFinePerDay, double lateFineMax, String branchId, String courseId, bool isActive, DateTime? createdAt
});




}
/// @nodoc
class __$FeeStructureCopyWithImpl<$Res>
    implements _$FeeStructureCopyWith<$Res> {
  __$FeeStructureCopyWithImpl(this._self, this._then);

  final _FeeStructure _self;
  final $Res Function(_FeeStructure) _then;

/// Create a copy of FeeStructure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? title = null,Object? description = null,Object? amount = null,Object? frequency = null,Object? dueDayOfMonth = null,Object? lateFinePerDay = null,Object? lateFineMax = null,Object? branchId = null,Object? courseId = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_FeeStructure(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,dueDayOfMonth: null == dueDayOfMonth ? _self.dueDayOfMonth : dueDayOfMonth // ignore: cast_nullable_to_non_nullable
as int,lateFinePerDay: null == lateFinePerDay ? _self.lateFinePerDay : lateFinePerDay // ignore: cast_nullable_to_non_nullable
as double,lateFineMax: null == lateFineMax ? _self.lateFineMax : lateFineMax // ignore: cast_nullable_to_non_nullable
as double,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
