// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'processor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RsvpWord {

 String get left; String get center; String get right; double get delayFactor;
/// Create a copy of RsvpWord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RsvpWordCopyWith<RsvpWord> get copyWith => _$RsvpWordCopyWithImpl<RsvpWord>(this as RsvpWord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RsvpWord&&(identical(other.left, left) || other.left == left)&&(identical(other.center, center) || other.center == center)&&(identical(other.right, right) || other.right == right)&&(identical(other.delayFactor, delayFactor) || other.delayFactor == delayFactor));
}


@override
int get hashCode => Object.hash(runtimeType,left,center,right,delayFactor);

@override
String toString() {
  return 'RsvpWord(left: $left, center: $center, right: $right, delayFactor: $delayFactor)';
}


}

/// @nodoc
abstract mixin class $RsvpWordCopyWith<$Res>  {
  factory $RsvpWordCopyWith(RsvpWord value, $Res Function(RsvpWord) _then) = _$RsvpWordCopyWithImpl;
@useResult
$Res call({
 String left, String center, String right, double delayFactor
});




}
/// @nodoc
class _$RsvpWordCopyWithImpl<$Res>
    implements $RsvpWordCopyWith<$Res> {
  _$RsvpWordCopyWithImpl(this._self, this._then);

  final RsvpWord _self;
  final $Res Function(RsvpWord) _then;

/// Create a copy of RsvpWord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? center = null,Object? right = null,Object? delayFactor = null,}) {
  return _then(_self.copyWith(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as String,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as String,delayFactor: null == delayFactor ? _self.delayFactor : delayFactor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RsvpWord].
extension RsvpWordPatterns on RsvpWord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RsvpWord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RsvpWord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RsvpWord value)  $default,){
final _that = this;
switch (_that) {
case _RsvpWord():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RsvpWord value)?  $default,){
final _that = this;
switch (_that) {
case _RsvpWord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String left,  String center,  String right,  double delayFactor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RsvpWord() when $default != null:
return $default(_that.left,_that.center,_that.right,_that.delayFactor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String left,  String center,  String right,  double delayFactor)  $default,) {final _that = this;
switch (_that) {
case _RsvpWord():
return $default(_that.left,_that.center,_that.right,_that.delayFactor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String left,  String center,  String right,  double delayFactor)?  $default,) {final _that = this;
switch (_that) {
case _RsvpWord() when $default != null:
return $default(_that.left,_that.center,_that.right,_that.delayFactor);case _:
  return null;

}
}

}

/// @nodoc


class _RsvpWord implements RsvpWord {
  const _RsvpWord({required this.left, required this.center, required this.right, required this.delayFactor});
  

@override final  String left;
@override final  String center;
@override final  String right;
@override final  double delayFactor;

/// Create a copy of RsvpWord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RsvpWordCopyWith<_RsvpWord> get copyWith => __$RsvpWordCopyWithImpl<_RsvpWord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RsvpWord&&(identical(other.left, left) || other.left == left)&&(identical(other.center, center) || other.center == center)&&(identical(other.right, right) || other.right == right)&&(identical(other.delayFactor, delayFactor) || other.delayFactor == delayFactor));
}


@override
int get hashCode => Object.hash(runtimeType,left,center,right,delayFactor);

@override
String toString() {
  return 'RsvpWord(left: $left, center: $center, right: $right, delayFactor: $delayFactor)';
}


}

/// @nodoc
abstract mixin class _$RsvpWordCopyWith<$Res> implements $RsvpWordCopyWith<$Res> {
  factory _$RsvpWordCopyWith(_RsvpWord value, $Res Function(_RsvpWord) _then) = __$RsvpWordCopyWithImpl;
@override @useResult
$Res call({
 String left, String center, String right, double delayFactor
});




}
/// @nodoc
class __$RsvpWordCopyWithImpl<$Res>
    implements _$RsvpWordCopyWith<$Res> {
  __$RsvpWordCopyWithImpl(this._self, this._then);

  final _RsvpWord _self;
  final $Res Function(_RsvpWord) _then;

/// Create a copy of RsvpWord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? left = null,Object? center = null,Object? right = null,Object? delayFactor = null,}) {
  return _then(_RsvpWord(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as String,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as String,delayFactor: null == delayFactor ? _self.delayFactor : delayFactor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
