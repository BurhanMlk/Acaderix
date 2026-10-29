// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fee_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeePayment {

 String get id; String get academyId; String get studentId; String get invoiceId; double get amount; String get method; String get reference; DateTime? get paidAt; String get receivedById;
/// Create a copy of FeePayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeePaymentCopyWith<FeePayment> get copyWith => _$FeePaymentCopyWithImpl<FeePayment>(this as FeePayment, _$identity);

  /// Serializes this FeePayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeePayment&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.receivedById, receivedById) || other.receivedById == receivedById));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,studentId,invoiceId,amount,method,reference,paidAt,receivedById);

@override
String toString() {
  return 'FeePayment(id: $id, academyId: $academyId, studentId: $studentId, invoiceId: $invoiceId, amount: $amount, method: $method, reference: $reference, paidAt: $paidAt, receivedById: $receivedById)';
}


}

/// @nodoc
abstract mixin class $FeePaymentCopyWith<$Res>  {
  factory $FeePaymentCopyWith(FeePayment value, $Res Function(FeePayment) _then) = _$FeePaymentCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String studentId, String invoiceId, double amount, String method, String reference, DateTime? paidAt, String receivedById
});




}
/// @nodoc
class _$FeePaymentCopyWithImpl<$Res>
    implements $FeePaymentCopyWith<$Res> {
  _$FeePaymentCopyWithImpl(this._self, this._then);

  final FeePayment _self;
  final $Res Function(FeePayment) _then;

/// Create a copy of FeePayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? studentId = null,Object? invoiceId = null,Object? amount = null,Object? method = null,Object? reference = null,Object? paidAt = freezed,Object? receivedById = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,invoiceId: null == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,receivedById: null == receivedById ? _self.receivedById : receivedById // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FeePayment].
extension FeePaymentPatterns on FeePayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeePayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeePayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeePayment value)  $default,){
final _that = this;
switch (_that) {
case _FeePayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeePayment value)?  $default,){
final _that = this;
switch (_that) {
case _FeePayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String studentId,  String invoiceId,  double amount,  String method,  String reference,  DateTime? paidAt,  String receivedById)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeePayment() when $default != null:
return $default(_that.id,_that.academyId,_that.studentId,_that.invoiceId,_that.amount,_that.method,_that.reference,_that.paidAt,_that.receivedById);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String studentId,  String invoiceId,  double amount,  String method,  String reference,  DateTime? paidAt,  String receivedById)  $default,) {final _that = this;
switch (_that) {
case _FeePayment():
return $default(_that.id,_that.academyId,_that.studentId,_that.invoiceId,_that.amount,_that.method,_that.reference,_that.paidAt,_that.receivedById);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String studentId,  String invoiceId,  double amount,  String method,  String reference,  DateTime? paidAt,  String receivedById)?  $default,) {final _that = this;
switch (_that) {
case _FeePayment() when $default != null:
return $default(_that.id,_that.academyId,_that.studentId,_that.invoiceId,_that.amount,_that.method,_that.reference,_that.paidAt,_that.receivedById);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeePayment implements FeePayment {
  const _FeePayment({required this.id, required this.academyId, required this.studentId, this.invoiceId = '', this.amount = 0, this.method = '', this.reference = '', this.paidAt, this.receivedById = ''});
  factory _FeePayment.fromJson(Map<String, dynamic> json) => _$FeePaymentFromJson(json);

@override final  String id;
@override final  String academyId;
@override final  String studentId;
@override@JsonKey() final  String invoiceId;
@override@JsonKey() final  double amount;
@override@JsonKey() final  String method;
@override@JsonKey() final  String reference;
@override final  DateTime? paidAt;
@override@JsonKey() final  String receivedById;

/// Create a copy of FeePayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeePaymentCopyWith<_FeePayment> get copyWith => __$FeePaymentCopyWithImpl<_FeePayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeePaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeePayment&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.receivedById, receivedById) || other.receivedById == receivedById));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,studentId,invoiceId,amount,method,reference,paidAt,receivedById);

@override
String toString() {
  return 'FeePayment(id: $id, academyId: $academyId, studentId: $studentId, invoiceId: $invoiceId, amount: $amount, method: $method, reference: $reference, paidAt: $paidAt, receivedById: $receivedById)';
}


}

/// @nodoc
abstract mixin class _$FeePaymentCopyWith<$Res> implements $FeePaymentCopyWith<$Res> {
  factory _$FeePaymentCopyWith(_FeePayment value, $Res Function(_FeePayment) _then) = __$FeePaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String studentId, String invoiceId, double amount, String method, String reference, DateTime? paidAt, String receivedById
});




}
/// @nodoc
class __$FeePaymentCopyWithImpl<$Res>
    implements _$FeePaymentCopyWith<$Res> {
  __$FeePaymentCopyWithImpl(this._self, this._then);

  final _FeePayment _self;
  final $Res Function(_FeePayment) _then;

/// Create a copy of FeePayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? studentId = null,Object? invoiceId = null,Object? amount = null,Object? method = null,Object? reference = null,Object? paidAt = freezed,Object? receivedById = null,}) {
  return _then(_FeePayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,invoiceId: null == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,receivedById: null == receivedById ? _self.receivedById : receivedById // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
