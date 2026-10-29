// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'academy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Academy {

 String get id; String get code; String get name; String get logoUrl; String get ownerName; String get ownerEmail; String get ownerPhone; String get address; String get city; String get province; int get branchCount; String get status; DateTime? get registrationDate;
/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyCopyWith<Academy> get copyWith => _$AcademyCopyWithImpl<Academy>(this as Academy, _$identity);

  /// Serializes this Academy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Academy&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.ownerEmail, ownerEmail) || other.ownerEmail == ownerEmail)&&(identical(other.ownerPhone, ownerPhone) || other.ownerPhone == ownerPhone)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.province, province) || other.province == province)&&(identical(other.branchCount, branchCount) || other.branchCount == branchCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.registrationDate, registrationDate) || other.registrationDate == registrationDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,logoUrl,ownerName,ownerEmail,ownerPhone,address,city,province,branchCount,status,registrationDate);

@override
String toString() {
  return 'Academy(id: $id, code: $code, name: $name, logoUrl: $logoUrl, ownerName: $ownerName, ownerEmail: $ownerEmail, ownerPhone: $ownerPhone, address: $address, city: $city, province: $province, branchCount: $branchCount, status: $status, registrationDate: $registrationDate)';
}


}

/// @nodoc
abstract mixin class $AcademyCopyWith<$Res>  {
  factory $AcademyCopyWith(Academy value, $Res Function(Academy) _then) = _$AcademyCopyWithImpl;
@useResult
$Res call({
 String id, String code, String name, String logoUrl, String ownerName, String ownerEmail, String ownerPhone, String address, String city, String province, int branchCount, String status, DateTime? registrationDate
});




}
/// @nodoc
class _$AcademyCopyWithImpl<$Res>
    implements $AcademyCopyWith<$Res> {
  _$AcademyCopyWithImpl(this._self, this._then);

  final Academy _self;
  final $Res Function(Academy) _then;

/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? logoUrl = null,Object? ownerName = null,Object? ownerEmail = null,Object? ownerPhone = null,Object? address = null,Object? city = null,Object? province = null,Object? branchCount = null,Object? status = null,Object? registrationDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,logoUrl: null == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,ownerEmail: null == ownerEmail ? _self.ownerEmail : ownerEmail // ignore: cast_nullable_to_non_nullable
as String,ownerPhone: null == ownerPhone ? _self.ownerPhone : ownerPhone // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,branchCount: null == branchCount ? _self.branchCount : branchCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,registrationDate: freezed == registrationDate ? _self.registrationDate : registrationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Academy].
extension AcademyPatterns on Academy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Academy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Academy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Academy value)  $default,){
final _that = this;
switch (_that) {
case _Academy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Academy value)?  $default,){
final _that = this;
switch (_that) {
case _Academy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String name,  String logoUrl,  String ownerName,  String ownerEmail,  String ownerPhone,  String address,  String city,  String province,  int branchCount,  String status,  DateTime? registrationDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Academy() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.logoUrl,_that.ownerName,_that.ownerEmail,_that.ownerPhone,_that.address,_that.city,_that.province,_that.branchCount,_that.status,_that.registrationDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String name,  String logoUrl,  String ownerName,  String ownerEmail,  String ownerPhone,  String address,  String city,  String province,  int branchCount,  String status,  DateTime? registrationDate)  $default,) {final _that = this;
switch (_that) {
case _Academy():
return $default(_that.id,_that.code,_that.name,_that.logoUrl,_that.ownerName,_that.ownerEmail,_that.ownerPhone,_that.address,_that.city,_that.province,_that.branchCount,_that.status,_that.registrationDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String name,  String logoUrl,  String ownerName,  String ownerEmail,  String ownerPhone,  String address,  String city,  String province,  int branchCount,  String status,  DateTime? registrationDate)?  $default,) {final _that = this;
switch (_that) {
case _Academy() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.logoUrl,_that.ownerName,_that.ownerEmail,_that.ownerPhone,_that.address,_that.city,_that.province,_that.branchCount,_that.status,_that.registrationDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Academy implements Academy {
  const _Academy({required this.id, required this.code, this.name = '', this.logoUrl = '', this.ownerName = '', this.ownerEmail = '', this.ownerPhone = '', this.address = '', this.city = '', this.province = '', this.branchCount = 0, this.status = 'pending', this.registrationDate});
  factory _Academy.fromJson(Map<String, dynamic> json) => _$AcademyFromJson(json);

@override final  String id;
@override final  String code;
@override@JsonKey() final  String name;
@override@JsonKey() final  String logoUrl;
@override@JsonKey() final  String ownerName;
@override@JsonKey() final  String ownerEmail;
@override@JsonKey() final  String ownerPhone;
@override@JsonKey() final  String address;
@override@JsonKey() final  String city;
@override@JsonKey() final  String province;
@override@JsonKey() final  int branchCount;
@override@JsonKey() final  String status;
@override final  DateTime? registrationDate;

/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyCopyWith<_Academy> get copyWith => __$AcademyCopyWithImpl<_Academy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcademyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Academy&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.ownerEmail, ownerEmail) || other.ownerEmail == ownerEmail)&&(identical(other.ownerPhone, ownerPhone) || other.ownerPhone == ownerPhone)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.province, province) || other.province == province)&&(identical(other.branchCount, branchCount) || other.branchCount == branchCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.registrationDate, registrationDate) || other.registrationDate == registrationDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,logoUrl,ownerName,ownerEmail,ownerPhone,address,city,province,branchCount,status,registrationDate);

@override
String toString() {
  return 'Academy(id: $id, code: $code, name: $name, logoUrl: $logoUrl, ownerName: $ownerName, ownerEmail: $ownerEmail, ownerPhone: $ownerPhone, address: $address, city: $city, province: $province, branchCount: $branchCount, status: $status, registrationDate: $registrationDate)';
}


}

/// @nodoc
abstract mixin class _$AcademyCopyWith<$Res> implements $AcademyCopyWith<$Res> {
  factory _$AcademyCopyWith(_Academy value, $Res Function(_Academy) _then) = __$AcademyCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String name, String logoUrl, String ownerName, String ownerEmail, String ownerPhone, String address, String city, String province, int branchCount, String status, DateTime? registrationDate
});




}
/// @nodoc
class __$AcademyCopyWithImpl<$Res>
    implements _$AcademyCopyWith<$Res> {
  __$AcademyCopyWithImpl(this._self, this._then);

  final _Academy _self;
  final $Res Function(_Academy) _then;

/// Create a copy of Academy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? logoUrl = null,Object? ownerName = null,Object? ownerEmail = null,Object? ownerPhone = null,Object? address = null,Object? city = null,Object? province = null,Object? branchCount = null,Object? status = null,Object? registrationDate = freezed,}) {
  return _then(_Academy(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,logoUrl: null == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,ownerEmail: null == ownerEmail ? _self.ownerEmail : ownerEmail // ignore: cast_nullable_to_non_nullable
as String,ownerPhone: null == ownerPhone ? _self.ownerPhone : ownerPhone // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,branchCount: null == branchCount ? _self.branchCount : branchCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,registrationDate: freezed == registrationDate ? _self.registrationDate : registrationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
