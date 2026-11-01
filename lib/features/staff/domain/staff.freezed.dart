// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Staff {

 String get id; String get academyId; String get staffId; String get fullName; String get phone; String get email; String get address; String get photoUrl; String get jobTitle; String get branchId; DateTime? get joiningDate; double get salary; String get status; List<String> get permissions; int get leaveBalance; String get password;
/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffCopyWith<Staff> get copyWith => _$StaffCopyWithImpl<Staff>(this as Staff, _$identity);

  /// Serializes this Staff to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Staff&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.joiningDate, joiningDate) || other.joiningDate == joiningDate)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.leaveBalance, leaveBalance) || other.leaveBalance == leaveBalance)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,staffId,fullName,phone,email,address,photoUrl,jobTitle,branchId,joiningDate,salary,status,const DeepCollectionEquality().hash(permissions),leaveBalance,password);

@override
String toString() {
  return 'Staff(id: $id, academyId: $academyId, staffId: $staffId, fullName: $fullName, phone: $phone, email: $email, address: $address, photoUrl: $photoUrl, jobTitle: $jobTitle, branchId: $branchId, joiningDate: $joiningDate, salary: $salary, status: $status, permissions: $permissions, leaveBalance: $leaveBalance, password: $password)';
}


}

/// @nodoc
abstract mixin class $StaffCopyWith<$Res>  {
  factory $StaffCopyWith(Staff value, $Res Function(Staff) _then) = _$StaffCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String staffId, String fullName, String phone, String email, String address, String photoUrl, String jobTitle, String branchId, DateTime? joiningDate, double salary, String status, List<String> permissions, int leaveBalance, String password
});




}
/// @nodoc
class _$StaffCopyWithImpl<$Res>
    implements $StaffCopyWith<$Res> {
  _$StaffCopyWithImpl(this._self, this._then);

  final Staff _self;
  final $Res Function(Staff) _then;

/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? staffId = null,Object? fullName = null,Object? phone = null,Object? email = null,Object? address = null,Object? photoUrl = null,Object? jobTitle = null,Object? branchId = null,Object? joiningDate = freezed,Object? salary = null,Object? status = null,Object? permissions = null,Object? leaveBalance = null,Object? password = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,joiningDate: freezed == joiningDate ? _self.joiningDate : joiningDate // ignore: cast_nullable_to_non_nullable
as DateTime?,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,leaveBalance: null == leaveBalance ? _self.leaveBalance : leaveBalance // ignore: cast_nullable_to_non_nullable
as int,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Staff].
extension StaffPatterns on Staff {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Staff value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Staff() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Staff value)  $default,){
final _that = this;
switch (_that) {
case _Staff():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Staff value)?  $default,){
final _that = this;
switch (_that) {
case _Staff() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String staffId,  String fullName,  String phone,  String email,  String address,  String photoUrl,  String jobTitle,  String branchId,  DateTime? joiningDate,  double salary,  String status,  List<String> permissions,  int leaveBalance,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Staff() when $default != null:
return $default(_that.id,_that.academyId,_that.staffId,_that.fullName,_that.phone,_that.email,_that.address,_that.photoUrl,_that.jobTitle,_that.branchId,_that.joiningDate,_that.salary,_that.status,_that.permissions,_that.leaveBalance,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String staffId,  String fullName,  String phone,  String email,  String address,  String photoUrl,  String jobTitle,  String branchId,  DateTime? joiningDate,  double salary,  String status,  List<String> permissions,  int leaveBalance,  String password)  $default,) {final _that = this;
switch (_that) {
case _Staff():
return $default(_that.id,_that.academyId,_that.staffId,_that.fullName,_that.phone,_that.email,_that.address,_that.photoUrl,_that.jobTitle,_that.branchId,_that.joiningDate,_that.salary,_that.status,_that.permissions,_that.leaveBalance,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String staffId,  String fullName,  String phone,  String email,  String address,  String photoUrl,  String jobTitle,  String branchId,  DateTime? joiningDate,  double salary,  String status,  List<String> permissions,  int leaveBalance,  String password)?  $default,) {final _that = this;
switch (_that) {
case _Staff() when $default != null:
return $default(_that.id,_that.academyId,_that.staffId,_that.fullName,_that.phone,_that.email,_that.address,_that.photoUrl,_that.jobTitle,_that.branchId,_that.joiningDate,_that.salary,_that.status,_that.permissions,_that.leaveBalance,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Staff implements Staff {
  const _Staff({required this.id, required this.academyId, this.staffId = '', this.fullName = '', this.phone = '', this.email = '', this.address = '', this.photoUrl = '', this.jobTitle = '', this.branchId = '', this.joiningDate, this.salary = 0, this.status = 'active', final  List<String> permissions = const <String>[], this.leaveBalance = 0, this.password = ''}): _permissions = permissions;
  factory _Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String staffId;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String email;
@override@JsonKey() final  String address;
@override@JsonKey() final  String photoUrl;
@override@JsonKey() final  String jobTitle;
@override@JsonKey() final  String branchId;
@override final  DateTime? joiningDate;
@override@JsonKey() final  double salary;
@override@JsonKey() final  String status;
 final  List<String> _permissions;
@override@JsonKey() List<String> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

@override@JsonKey() final  int leaveBalance;
@override@JsonKey() final  String password;

/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffCopyWith<_Staff> get copyWith => __$StaffCopyWithImpl<_Staff>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Staff&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.staffId, staffId) || other.staffId == staffId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.joiningDate, joiningDate) || other.joiningDate == joiningDate)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.leaveBalance, leaveBalance) || other.leaveBalance == leaveBalance)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,staffId,fullName,phone,email,address,photoUrl,jobTitle,branchId,joiningDate,salary,status,const DeepCollectionEquality().hash(_permissions),leaveBalance,password);

@override
String toString() {
  return 'Staff(id: $id, academyId: $academyId, staffId: $staffId, fullName: $fullName, phone: $phone, email: $email, address: $address, photoUrl: $photoUrl, jobTitle: $jobTitle, branchId: $branchId, joiningDate: $joiningDate, salary: $salary, status: $status, permissions: $permissions, leaveBalance: $leaveBalance, password: $password)';
}


}

/// @nodoc
abstract mixin class _$StaffCopyWith<$Res> implements $StaffCopyWith<$Res> {
  factory _$StaffCopyWith(_Staff value, $Res Function(_Staff) _then) = __$StaffCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String staffId, String fullName, String phone, String email, String address, String photoUrl, String jobTitle, String branchId, DateTime? joiningDate, double salary, String status, List<String> permissions, int leaveBalance, String password
});




}
/// @nodoc
class __$StaffCopyWithImpl<$Res>
    implements _$StaffCopyWith<$Res> {
  __$StaffCopyWithImpl(this._self, this._then);

  final _Staff _self;
  final $Res Function(_Staff) _then;

/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? staffId = null,Object? fullName = null,Object? phone = null,Object? email = null,Object? address = null,Object? photoUrl = null,Object? jobTitle = null,Object? branchId = null,Object? joiningDate = freezed,Object? salary = null,Object? status = null,Object? permissions = null,Object? leaveBalance = null,Object? password = null,}) {
  return _then(_Staff(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,staffId: null == staffId ? _self.staffId : staffId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,joiningDate: freezed == joiningDate ? _self.joiningDate : joiningDate // ignore: cast_nullable_to_non_nullable
as DateTime?,salary: null == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>,leaveBalance: null == leaveBalance ? _self.leaveBalance : leaveBalance // ignore: cast_nullable_to_non_nullable
as int,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
