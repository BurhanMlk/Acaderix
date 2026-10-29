// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fee_invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeeInvoice {

 String get id; String get academyId; String get studentId; String get invoiceNo; String get title; double get baseAmount; double get fine; double get discount; double get scholarship; double get paidAmount; DateTime? get dueDate; DateTime? get issuedAt; String get status;
/// Create a copy of FeeInvoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeeInvoiceCopyWith<FeeInvoice> get copyWith => _$FeeInvoiceCopyWithImpl<FeeInvoice>(this as FeeInvoice, _$identity);

  /// Serializes this FeeInvoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeeInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.invoiceNo, invoiceNo) || other.invoiceNo == invoiceNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.baseAmount, baseAmount) || other.baseAmount == baseAmount)&&(identical(other.fine, fine) || other.fine == fine)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.scholarship, scholarship) || other.scholarship == scholarship)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,studentId,invoiceNo,title,baseAmount,fine,discount,scholarship,paidAmount,dueDate,issuedAt,status);

@override
String toString() {
  return 'FeeInvoice(id: $id, academyId: $academyId, studentId: $studentId, invoiceNo: $invoiceNo, title: $title, baseAmount: $baseAmount, fine: $fine, discount: $discount, scholarship: $scholarship, paidAmount: $paidAmount, dueDate: $dueDate, issuedAt: $issuedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $FeeInvoiceCopyWith<$Res>  {
  factory $FeeInvoiceCopyWith(FeeInvoice value, $Res Function(FeeInvoice) _then) = _$FeeInvoiceCopyWithImpl;
@useResult
$Res call({
 String id, String academyId, String studentId, String invoiceNo, String title, double baseAmount, double fine, double discount, double scholarship, double paidAmount, DateTime? dueDate, DateTime? issuedAt, String status
});




}
/// @nodoc
class _$FeeInvoiceCopyWithImpl<$Res>
    implements $FeeInvoiceCopyWith<$Res> {
  _$FeeInvoiceCopyWithImpl(this._self, this._then);

  final FeeInvoice _self;
  final $Res Function(FeeInvoice) _then;

/// Create a copy of FeeInvoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? academyId = null,Object? studentId = null,Object? invoiceNo = null,Object? title = null,Object? baseAmount = null,Object? fine = null,Object? discount = null,Object? scholarship = null,Object? paidAmount = null,Object? dueDate = freezed,Object? issuedAt = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,invoiceNo: null == invoiceNo ? _self.invoiceNo : invoiceNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,baseAmount: null == baseAmount ? _self.baseAmount : baseAmount // ignore: cast_nullable_to_non_nullable
as double,fine: null == fine ? _self.fine : fine // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,scholarship: null == scholarship ? _self.scholarship : scholarship // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FeeInvoice].
extension FeeInvoicePatterns on FeeInvoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeeInvoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeeInvoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeeInvoice value)  $default,){
final _that = this;
switch (_that) {
case _FeeInvoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeeInvoice value)?  $default,){
final _that = this;
switch (_that) {
case _FeeInvoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String academyId,  String studentId,  String invoiceNo,  String title,  double baseAmount,  double fine,  double discount,  double scholarship,  double paidAmount,  DateTime? dueDate,  DateTime? issuedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeeInvoice() when $default != null:
return $default(_that.id,_that.academyId,_that.studentId,_that.invoiceNo,_that.title,_that.baseAmount,_that.fine,_that.discount,_that.scholarship,_that.paidAmount,_that.dueDate,_that.issuedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String academyId,  String studentId,  String invoiceNo,  String title,  double baseAmount,  double fine,  double discount,  double scholarship,  double paidAmount,  DateTime? dueDate,  DateTime? issuedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _FeeInvoice():
return $default(_that.id,_that.academyId,_that.studentId,_that.invoiceNo,_that.title,_that.baseAmount,_that.fine,_that.discount,_that.scholarship,_that.paidAmount,_that.dueDate,_that.issuedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String academyId,  String studentId,  String invoiceNo,  String title,  double baseAmount,  double fine,  double discount,  double scholarship,  double paidAmount,  DateTime? dueDate,  DateTime? issuedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _FeeInvoice() when $default != null:
return $default(_that.id,_that.academyId,_that.studentId,_that.invoiceNo,_that.title,_that.baseAmount,_that.fine,_that.discount,_that.scholarship,_that.paidAmount,_that.dueDate,_that.issuedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeeInvoice extends FeeInvoice {
  const _FeeInvoice({required this.id, required this.academyId, required this.studentId, this.invoiceNo = '', this.title = '', this.baseAmount = 0, this.fine = 0, this.discount = 0, this.scholarship = 0, this.paidAmount = 0, this.dueDate, this.issuedAt, this.status = 'unpaid'}): super._();
  factory _FeeInvoice.fromJson(Map<String, dynamic> json) => _$FeeInvoiceFromJson(json);

@override final  String id;
@override final  String academyId;
@override final  String studentId;
@override@JsonKey() final  String invoiceNo;
@override@JsonKey() final  String title;
@override@JsonKey() final  double baseAmount;
@override@JsonKey() final  double fine;
@override@JsonKey() final  double discount;
@override@JsonKey() final  double scholarship;
@override@JsonKey() final  double paidAmount;
@override final  DateTime? dueDate;
@override final  DateTime? issuedAt;
@override@JsonKey() final  String status;

/// Create a copy of FeeInvoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeeInvoiceCopyWith<_FeeInvoice> get copyWith => __$FeeInvoiceCopyWithImpl<_FeeInvoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeeInvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeeInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.academyId, academyId) || other.academyId == academyId)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.invoiceNo, invoiceNo) || other.invoiceNo == invoiceNo)&&(identical(other.title, title) || other.title == title)&&(identical(other.baseAmount, baseAmount) || other.baseAmount == baseAmount)&&(identical(other.fine, fine) || other.fine == fine)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.scholarship, scholarship) || other.scholarship == scholarship)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,academyId,studentId,invoiceNo,title,baseAmount,fine,discount,scholarship,paidAmount,dueDate,issuedAt,status);

@override
String toString() {
  return 'FeeInvoice(id: $id, academyId: $academyId, studentId: $studentId, invoiceNo: $invoiceNo, title: $title, baseAmount: $baseAmount, fine: $fine, discount: $discount, scholarship: $scholarship, paidAmount: $paidAmount, dueDate: $dueDate, issuedAt: $issuedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$FeeInvoiceCopyWith<$Res> implements $FeeInvoiceCopyWith<$Res> {
  factory _$FeeInvoiceCopyWith(_FeeInvoice value, $Res Function(_FeeInvoice) _then) = __$FeeInvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String academyId, String studentId, String invoiceNo, String title, double baseAmount, double fine, double discount, double scholarship, double paidAmount, DateTime? dueDate, DateTime? issuedAt, String status
});




}
/// @nodoc
class __$FeeInvoiceCopyWithImpl<$Res>
    implements _$FeeInvoiceCopyWith<$Res> {
  __$FeeInvoiceCopyWithImpl(this._self, this._then);

  final _FeeInvoice _self;
  final $Res Function(_FeeInvoice) _then;

/// Create a copy of FeeInvoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? academyId = null,Object? studentId = null,Object? invoiceNo = null,Object? title = null,Object? baseAmount = null,Object? fine = null,Object? discount = null,Object? scholarship = null,Object? paidAmount = null,Object? dueDate = freezed,Object? issuedAt = freezed,Object? status = null,}) {
  return _then(_FeeInvoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,academyId: null == academyId ? _self.academyId : academyId // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,invoiceNo: null == invoiceNo ? _self.invoiceNo : invoiceNo // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,baseAmount: null == baseAmount ? _self.baseAmount : baseAmount // ignore: cast_nullable_to_non_nullable
as double,fine: null == fine ? _self.fine : fine // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,scholarship: null == scholarship ? _self.scholarship : scholarship // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
