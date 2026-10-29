// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Student {

 String get id; String get academyId; String get fullName; String get fatherName; String get motherName; DateTime? get dateOfBirth; String get gender; String get phone; String get guardianPhone; String get guardianRelation; String get address; String get photoUrl; DateTime? get admissionDate; String get previousInstitute; String get academicSession; String get rollNumber; String get status; String get notes;
/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentCopyWith<Student> get copyWith => _$StudentCopyWithImpl<Student>(this as Student, _$identity);

  /// Serializes this Student to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Student&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.fatherName, fatherName) || other.fatherName == fatherName)&&(identical(other.motherName, motherName) || other.motherName == motherName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.guardianPhone, guardianPhone) || other.guardianPhone == guardianPhone)&&(identical(other.guardianRelation, guardianRelation) || other.guardianRelation == guardianRelation)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.admissionDate, admissionDate) || other.admissionDate == admissionDate)&&(identical(other.previousInstitute, previousInstitute) || other.previousInstitute == previousInstitute)&&(identical(other.academicSession, academicSession) || other.academicSession == academicSession)&&(identical(other.rollNumber, rollNumber) || other.rollNumber == rollNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,fullName,fatherName,motherName,dateOfBirth,gender,phone,guardianPhone,guardianRelation,address,photoUrl,admissionDate,previousInstitute,academicSession,rollNumber,status,notes);

@override
String toString() {
  return 'Student(id: $id, academyId: $academyId, fullName: $fullName, fatherName: $fatherName, motherName: $motherName, dateOfBirth: $dateOfBirth, gender: $gender, phone: $phone, guardianPhone: $guardianPhone, guardianRelation: $guardianRelation, address: $address, photoUrl: $photoUrl, admissionDate: $admissionDate, previousInstitute: $previousInstitute, academicSession: $academicSession, rollNumber: $rollNumber, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $StudentCopyWith<$Res>  {
  factory $StudentCopyWith(Student value, $Res Function(Student) _then) = _$StudentCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String fullName, String fatherName, String motherName, DateTime? dateOfBirth, String gender, String phone, String guardianPhone, String guardianRelation, String address, String photoUrl, DateTime? admissionDate, String previousInstitute, String academicSession, String rollNumber, String status, String notes
});




}
/// @nodoc
class _$StudentCopyWithImpl<$Res>
    implements $StudentCopyWith<$Res> {
  _$StudentCopyWithImpl(this._self, this._then);

  final Student _self;
  final $Res Function(Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? fullName = null,Object? fatherName = null,Object? motherName = null,Object? dateOfBirth = freezed,Object? gender = null,Object? phone = null,Object? guardianPhone = null,Object? guardianRelation = null,Object? address = null,Object? photoUrl = null,Object? admissionDate = freezed,Object? previousInstitute = null,Object? academicSession = null,Object? rollNumber = null,Object? status = null,Object? notes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,fatherName: null == fatherName ? _self.fatherName : fatherName // ignore: cast_nullable_to_non_nullable
as String,motherName: null == motherName ? _self.motherName : motherName // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,guardianPhone: null == guardianPhone ? _self.guardianPhone : guardianPhone // ignore: cast_nullable_to_non_nullable
as String,guardianRelation: null == guardianRelation ? _self.guardianRelation : guardianRelation // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,admissionDate: freezed == admissionDate ? _self.admissionDate : admissionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,previousInstitute: null == previousInstitute ? _self.previousInstitute : previousInstitute // ignore: cast_nullable_to_non_nullable
as String,academicSession: null == academicSession ? _self.academicSession : academicSession // ignore: cast_nullable_to_non_nullable
as String,rollNumber: null == rollNumber ? _self.rollNumber : rollNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Student].
extension StudentPatterns on Student {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Student value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Student value)  $default,){
final _that = this;
switch (_that) {
case _Student():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Student value)?  $default,){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String fullName,  String fatherName,  String motherName,  DateTime? dateOfBirth,  String gender,  String phone,  String guardianPhone,  String guardianRelation,  String address,  String photoUrl,  DateTime? admissionDate,  String previousInstitute,  String academicSession,  String rollNumber,  String status,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.academyId,_that.fullName,_that.fatherName,_that.motherName,_that.dateOfBirth,_that.gender,_that.phone,_that.guardianPhone,_that.guardianRelation,_that.address,_that.photoUrl,_that.admissionDate,_that.previousInstitute,_that.academicSession,_that.rollNumber,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String fullName,  String fatherName,  String motherName,  DateTime? dateOfBirth,  String gender,  String phone,  String guardianPhone,  String guardianRelation,  String address,  String photoUrl,  DateTime? admissionDate,  String previousInstitute,  String academicSession,  String rollNumber,  String status,  String notes)  $default,) {final _that = this;
switch (_that) {
case _Student():
return $default(_that.id,_that.academyId,_that.fullName,_that.fatherName,_that.motherName,_that.dateOfBirth,_that.gender,_that.phone,_that.guardianPhone,_that.guardianRelation,_that.address,_that.photoUrl,_that.admissionDate,_that.previousInstitute,_that.academicSession,_that.rollNumber,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String fullName,  String fatherName,  String motherName,  DateTime? dateOfBirth,  String gender,  String phone,  String guardianPhone,  String guardianRelation,  String address,  String photoUrl,  DateTime? admissionDate,  String previousInstitute,  String academicSession,  String rollNumber,  String status,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.academyId,_that.fullName,_that.fatherName,_that.motherName,_that.dateOfBirth,_that.gender,_that.phone,_that.guardianPhone,_that.guardianRelation,_that.address,_that.photoUrl,_that.admissionDate,_that.previousInstitute,_that.academicSession,_that.rollNumber,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Student implements Student {
  const _Student({required this.id, required this.academyId, this.fullName = '', this.fatherName = '', this.motherName = '', this.dateOfBirth, this.gender = '', this.phone = '', this.guardianPhone = '', this.guardianRelation = '', this.address = '', this.photoUrl = '', this.admissionDate, this.previousInstitute = '', this.academicSession = '', this.rollNumber = '', this.status = 'active', this.notes = ''});
  factory _Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

@override final  String id;
@override final  String academyId;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String fatherName;
@override@JsonKey() final  String motherName;
@override final  DateTime? dateOfBirth;
@override@JsonKey() final  String gender;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String guardianPhone;
@override@JsonKey() final  String guardianRelation;
@override@JsonKey() final  String address;
@override@JsonKey() final  String photoUrl;
@override final  DateTime? admissionDate;
@override@JsonKey() final  String previousInstitute;
@override@JsonKey() final  String academicSession;
@override@JsonKey() final  String rollNumber;
@override@JsonKey() final  String status;
@override@JsonKey() final  String notes;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentCopyWith<_Student> get copyWith => __$StudentCopyWithImpl<_Student>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Student&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.fatherName, fatherName) || other.fatherName == fatherName)&&(identical(other.motherName, motherName) || other.motherName == motherName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.guardianPhone, guardianPhone) || other.guardianPhone == guardianPhone)&&(identical(other.guardianRelation, guardianRelation) || other.guardianRelation == guardianRelation)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.admissionDate, admissionDate) || other.admissionDate == admissionDate)&&(identical(other.previousInstitute, previousInstitute) || other.previousInstitute == previousInstitute)&&(identical(other.academicSession, academicSession) || other.academicSession == academicSession)&&(identical(other.rollNumber, rollNumber) || other.rollNumber == rollNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,fullName,fatherName,motherName,dateOfBirth,gender,phone,guardianPhone,guardianRelation,address,photoUrl,admissionDate,previousInstitute,academicSession,rollNumber,status,notes);

@override
String toString() {
  return 'Student(id: $id, academyId: $academyId, fullName: $fullName, fatherName: $fatherName, motherName: $motherName, dateOfBirth: $dateOfBirth, gender: $gender, phone: $phone, guardianPhone: $guardianPhone, guardianRelation: $guardianRelation, address: $address, photoUrl: $photoUrl, admissionDate: $admissionDate, previousInstitute: $previousInstitute, academicSession: $academicSession, rollNumber: $rollNumber, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$StudentCopyWith<$Res> implements $StudentCopyWith<$Res> {
  factory _$StudentCopyWith(_Student value, $Res Function(_Student) _then) = __$StudentCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String fullName, String fatherName, String motherName, DateTime? dateOfBirth, String gender, String phone, String guardianPhone, String guardianRelation, String address, String photoUrl, DateTime? admissionDate, String previousInstitute, String academicSession, String rollNumber, String status, String notes
});




}
/// @nodoc
class __$StudentCopyWithImpl<$Res>
    implements _$StudentCopyWith<$Res> {
  __$StudentCopyWithImpl(this._self, this._then);

  final _Student _self;
  final $Res Function(_Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? fullName = null,Object? fatherName = null,Object? motherName = null,Object? dateOfBirth = freezed,Object? gender = null,Object? phone = null,Object? guardianPhone = null,Object? guardianRelation = null,Object? address = null,Object? photoUrl = null,Object? admissionDate = freezed,Object? previousInstitute = null,Object? academicSession = null,Object? rollNumber = null,Object? status = null,Object? notes = null,}) {
  return _then(_Student(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,fatherName: null == fatherName ? _self.fatherName : fatherName // ignore: cast_nullable_to_non_nullable
as String,motherName: null == motherName ? _self.motherName : motherName // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,guardianPhone: null == guardianPhone ? _self.guardianPhone : guardianPhone // ignore: cast_nullable_to_non_nullable
as String,guardianRelation: null == guardianRelation ? _self.guardianRelation : guardianRelation // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,admissionDate: freezed == admissionDate ? _self.admissionDate : admissionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,previousInstitute: null == previousInstitute ? _self.previousInstitute : previousInstitute // ignore: cast_nullable_to_non_nullable
as String,academicSession: null == academicSession ? _self.academicSession : academicSession // ignore: cast_nullable_to_non_nullable
as String,rollNumber: null == rollNumber ? _self.rollNumber : rollNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
