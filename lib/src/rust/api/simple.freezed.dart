// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'simple.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RsvpFrame {

 String get text; int get orpIndex; int get delayMs;
/// Create a copy of RsvpFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RsvpFrameCopyWith<RsvpFrame> get copyWith => _$RsvpFrameCopyWithImpl<RsvpFrame>(this as RsvpFrame, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RsvpFrame&&(identical(other.text, text) || other.text == text)&&(identical(other.orpIndex, orpIndex) || other.orpIndex == orpIndex)&&(identical(other.delayMs, delayMs) || other.delayMs == delayMs));
}


@override
int get hashCode => Object.hash(runtimeType,text,orpIndex,delayMs);

@override
String toString() {
  return 'RsvpFrame(text: $text, orpIndex: $orpIndex, delayMs: $delayMs)';
}


}

/// @nodoc
abstract mixin class $RsvpFrameCopyWith<$Res>  {
  factory $RsvpFrameCopyWith(RsvpFrame value, $Res Function(RsvpFrame) _then) = _$RsvpFrameCopyWithImpl;
@useResult
$Res call({
 String text, int orpIndex, int delayMs
});




}
/// @nodoc
class _$RsvpFrameCopyWithImpl<$Res>
    implements $RsvpFrameCopyWith<$Res> {
  _$RsvpFrameCopyWithImpl(this._self, this._then);

  final RsvpFrame _self;
  final $Res Function(RsvpFrame) _then;

/// Create a copy of RsvpFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? orpIndex = null,Object? delayMs = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,orpIndex: null == orpIndex ? _self.orpIndex : orpIndex // ignore: cast_nullable_to_non_nullable
as int,delayMs: null == delayMs ? _self.delayMs : delayMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RsvpFrame].
extension RsvpFramePatterns on RsvpFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RsvpFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RsvpFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RsvpFrame value)  $default,){
final _that = this;
switch (_that) {
case _RsvpFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RsvpFrame value)?  $default,){
final _that = this;
switch (_that) {
case _RsvpFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int orpIndex,  int delayMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RsvpFrame() when $default != null:
return $default(_that.text,_that.orpIndex,_that.delayMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int orpIndex,  int delayMs)  $default,) {final _that = this;
switch (_that) {
case _RsvpFrame():
return $default(_that.text,_that.orpIndex,_that.delayMs);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int orpIndex,  int delayMs)?  $default,) {final _that = this;
switch (_that) {
case _RsvpFrame() when $default != null:
return $default(_that.text,_that.orpIndex,_that.delayMs);case _:
  return null;

}
}

}

/// @nodoc


class _RsvpFrame implements RsvpFrame {
  const _RsvpFrame({required this.text, required this.orpIndex, required this.delayMs});
  

@override final  String text;
@override final  int orpIndex;
@override final  int delayMs;

/// Create a copy of RsvpFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RsvpFrameCopyWith<_RsvpFrame> get copyWith => __$RsvpFrameCopyWithImpl<_RsvpFrame>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RsvpFrame&&(identical(other.text, text) || other.text == text)&&(identical(other.orpIndex, orpIndex) || other.orpIndex == orpIndex)&&(identical(other.delayMs, delayMs) || other.delayMs == delayMs));
}


@override
int get hashCode => Object.hash(runtimeType,text,orpIndex,delayMs);

@override
String toString() {
  return 'RsvpFrame(text: $text, orpIndex: $orpIndex, delayMs: $delayMs)';
}


}

/// @nodoc
abstract mixin class _$RsvpFrameCopyWith<$Res> implements $RsvpFrameCopyWith<$Res> {
  factory _$RsvpFrameCopyWith(_RsvpFrame value, $Res Function(_RsvpFrame) _then) = __$RsvpFrameCopyWithImpl;
@override @useResult
$Res call({
 String text, int orpIndex, int delayMs
});




}
/// @nodoc
class __$RsvpFrameCopyWithImpl<$Res>
    implements _$RsvpFrameCopyWith<$Res> {
  __$RsvpFrameCopyWithImpl(this._self, this._then);

  final _RsvpFrame _self;
  final $Res Function(_RsvpFrame) _then;

/// Create a copy of RsvpFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? orpIndex = null,Object? delayMs = null,}) {
  return _then(_RsvpFrame(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,orpIndex: null == orpIndex ? _self.orpIndex : orpIndex // ignore: cast_nullable_to_non_nullable
as int,delayMs: null == delayMs ? _self.delayMs : delayMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
