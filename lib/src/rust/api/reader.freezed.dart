// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReaderCommand {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderCommand()';
}


}

/// @nodoc
class $ReaderCommandCopyWith<$Res>  {
$ReaderCommandCopyWith(ReaderCommand _, $Res Function(ReaderCommand) __);
}


/// Adds pattern-matching-related methods to [ReaderCommand].
extension ReaderCommandPatterns on ReaderCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReaderCommand_Play value)?  play,TResult Function( ReaderCommand_Pause value)?  pause,TResult Function( ReaderCommand_SeekTo value)?  seekTo,TResult Function( ReaderCommand_Scrub value)?  scrub,TResult Function( ReaderCommand_RewindSentence value)?  rewindSentence,TResult Function( ReaderCommand_AdjustWpm value)?  adjustWpm,TResult Function( ReaderCommand_SetWpm value)?  setWpm,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReaderCommand_Play() when play != null:
return play(_that);case ReaderCommand_Pause() when pause != null:
return pause(_that);case ReaderCommand_SeekTo() when seekTo != null:
return seekTo(_that);case ReaderCommand_Scrub() when scrub != null:
return scrub(_that);case ReaderCommand_RewindSentence() when rewindSentence != null:
return rewindSentence(_that);case ReaderCommand_AdjustWpm() when adjustWpm != null:
return adjustWpm(_that);case ReaderCommand_SetWpm() when setWpm != null:
return setWpm(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReaderCommand_Play value)  play,required TResult Function( ReaderCommand_Pause value)  pause,required TResult Function( ReaderCommand_SeekTo value)  seekTo,required TResult Function( ReaderCommand_Scrub value)  scrub,required TResult Function( ReaderCommand_RewindSentence value)  rewindSentence,required TResult Function( ReaderCommand_AdjustWpm value)  adjustWpm,required TResult Function( ReaderCommand_SetWpm value)  setWpm,}){
final _that = this;
switch (_that) {
case ReaderCommand_Play():
return play(_that);case ReaderCommand_Pause():
return pause(_that);case ReaderCommand_SeekTo():
return seekTo(_that);case ReaderCommand_Scrub():
return scrub(_that);case ReaderCommand_RewindSentence():
return rewindSentence(_that);case ReaderCommand_AdjustWpm():
return adjustWpm(_that);case ReaderCommand_SetWpm():
return setWpm(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReaderCommand_Play value)?  play,TResult? Function( ReaderCommand_Pause value)?  pause,TResult? Function( ReaderCommand_SeekTo value)?  seekTo,TResult? Function( ReaderCommand_Scrub value)?  scrub,TResult? Function( ReaderCommand_RewindSentence value)?  rewindSentence,TResult? Function( ReaderCommand_AdjustWpm value)?  adjustWpm,TResult? Function( ReaderCommand_SetWpm value)?  setWpm,}){
final _that = this;
switch (_that) {
case ReaderCommand_Play() when play != null:
return play(_that);case ReaderCommand_Pause() when pause != null:
return pause(_that);case ReaderCommand_SeekTo() when seekTo != null:
return seekTo(_that);case ReaderCommand_Scrub() when scrub != null:
return scrub(_that);case ReaderCommand_RewindSentence() when rewindSentence != null:
return rewindSentence(_that);case ReaderCommand_AdjustWpm() when adjustWpm != null:
return adjustWpm(_that);case ReaderCommand_SetWpm() when setWpm != null:
return setWpm(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  play,TResult Function()?  pause,TResult Function( BigInt field0)?  seekTo,TResult Function( int field0)?  scrub,TResult Function()?  rewindSentence,TResult Function( int field0)?  adjustWpm,TResult Function( int field0)?  setWpm,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReaderCommand_Play() when play != null:
return play();case ReaderCommand_Pause() when pause != null:
return pause();case ReaderCommand_SeekTo() when seekTo != null:
return seekTo(_that.field0);case ReaderCommand_Scrub() when scrub != null:
return scrub(_that.field0);case ReaderCommand_RewindSentence() when rewindSentence != null:
return rewindSentence();case ReaderCommand_AdjustWpm() when adjustWpm != null:
return adjustWpm(_that.field0);case ReaderCommand_SetWpm() when setWpm != null:
return setWpm(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  play,required TResult Function()  pause,required TResult Function( BigInt field0)  seekTo,required TResult Function( int field0)  scrub,required TResult Function()  rewindSentence,required TResult Function( int field0)  adjustWpm,required TResult Function( int field0)  setWpm,}) {final _that = this;
switch (_that) {
case ReaderCommand_Play():
return play();case ReaderCommand_Pause():
return pause();case ReaderCommand_SeekTo():
return seekTo(_that.field0);case ReaderCommand_Scrub():
return scrub(_that.field0);case ReaderCommand_RewindSentence():
return rewindSentence();case ReaderCommand_AdjustWpm():
return adjustWpm(_that.field0);case ReaderCommand_SetWpm():
return setWpm(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  play,TResult? Function()?  pause,TResult? Function( BigInt field0)?  seekTo,TResult? Function( int field0)?  scrub,TResult? Function()?  rewindSentence,TResult? Function( int field0)?  adjustWpm,TResult? Function( int field0)?  setWpm,}) {final _that = this;
switch (_that) {
case ReaderCommand_Play() when play != null:
return play();case ReaderCommand_Pause() when pause != null:
return pause();case ReaderCommand_SeekTo() when seekTo != null:
return seekTo(_that.field0);case ReaderCommand_Scrub() when scrub != null:
return scrub(_that.field0);case ReaderCommand_RewindSentence() when rewindSentence != null:
return rewindSentence();case ReaderCommand_AdjustWpm() when adjustWpm != null:
return adjustWpm(_that.field0);case ReaderCommand_SetWpm() when setWpm != null:
return setWpm(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class ReaderCommand_Play extends ReaderCommand {
  const ReaderCommand_Play(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_Play);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderCommand.play()';
}


}




/// @nodoc


class ReaderCommand_Pause extends ReaderCommand {
  const ReaderCommand_Pause(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_Pause);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderCommand.pause()';
}


}




/// @nodoc


class ReaderCommand_SeekTo extends ReaderCommand {
  const ReaderCommand_SeekTo(this.field0): super._();
  

 final  BigInt field0;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderCommand_SeekToCopyWith<ReaderCommand_SeekTo> get copyWith => _$ReaderCommand_SeekToCopyWithImpl<ReaderCommand_SeekTo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_SeekTo&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ReaderCommand.seekTo(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ReaderCommand_SeekToCopyWith<$Res> implements $ReaderCommandCopyWith<$Res> {
  factory $ReaderCommand_SeekToCopyWith(ReaderCommand_SeekTo value, $Res Function(ReaderCommand_SeekTo) _then) = _$ReaderCommand_SeekToCopyWithImpl;
@useResult
$Res call({
 BigInt field0
});




}
/// @nodoc
class _$ReaderCommand_SeekToCopyWithImpl<$Res>
    implements $ReaderCommand_SeekToCopyWith<$Res> {
  _$ReaderCommand_SeekToCopyWithImpl(this._self, this._then);

  final ReaderCommand_SeekTo _self;
  final $Res Function(ReaderCommand_SeekTo) _then;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ReaderCommand_SeekTo(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class ReaderCommand_Scrub extends ReaderCommand {
  const ReaderCommand_Scrub(this.field0): super._();
  

 final  int field0;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderCommand_ScrubCopyWith<ReaderCommand_Scrub> get copyWith => _$ReaderCommand_ScrubCopyWithImpl<ReaderCommand_Scrub>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_Scrub&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ReaderCommand.scrub(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ReaderCommand_ScrubCopyWith<$Res> implements $ReaderCommandCopyWith<$Res> {
  factory $ReaderCommand_ScrubCopyWith(ReaderCommand_Scrub value, $Res Function(ReaderCommand_Scrub) _then) = _$ReaderCommand_ScrubCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ReaderCommand_ScrubCopyWithImpl<$Res>
    implements $ReaderCommand_ScrubCopyWith<$Res> {
  _$ReaderCommand_ScrubCopyWithImpl(this._self, this._then);

  final ReaderCommand_Scrub _self;
  final $Res Function(ReaderCommand_Scrub) _then;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ReaderCommand_Scrub(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ReaderCommand_RewindSentence extends ReaderCommand {
  const ReaderCommand_RewindSentence(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_RewindSentence);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReaderCommand.rewindSentence()';
}


}




/// @nodoc


class ReaderCommand_AdjustWpm extends ReaderCommand {
  const ReaderCommand_AdjustWpm(this.field0): super._();
  

 final  int field0;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderCommand_AdjustWpmCopyWith<ReaderCommand_AdjustWpm> get copyWith => _$ReaderCommand_AdjustWpmCopyWithImpl<ReaderCommand_AdjustWpm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_AdjustWpm&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ReaderCommand.adjustWpm(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ReaderCommand_AdjustWpmCopyWith<$Res> implements $ReaderCommandCopyWith<$Res> {
  factory $ReaderCommand_AdjustWpmCopyWith(ReaderCommand_AdjustWpm value, $Res Function(ReaderCommand_AdjustWpm) _then) = _$ReaderCommand_AdjustWpmCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ReaderCommand_AdjustWpmCopyWithImpl<$Res>
    implements $ReaderCommand_AdjustWpmCopyWith<$Res> {
  _$ReaderCommand_AdjustWpmCopyWithImpl(this._self, this._then);

  final ReaderCommand_AdjustWpm _self;
  final $Res Function(ReaderCommand_AdjustWpm) _then;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ReaderCommand_AdjustWpm(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ReaderCommand_SetWpm extends ReaderCommand {
  const ReaderCommand_SetWpm(this.field0): super._();
  

 final  int field0;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderCommand_SetWpmCopyWith<ReaderCommand_SetWpm> get copyWith => _$ReaderCommand_SetWpmCopyWithImpl<ReaderCommand_SetWpm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderCommand_SetWpm&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ReaderCommand.setWpm(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ReaderCommand_SetWpmCopyWith<$Res> implements $ReaderCommandCopyWith<$Res> {
  factory $ReaderCommand_SetWpmCopyWith(ReaderCommand_SetWpm value, $Res Function(ReaderCommand_SetWpm) _then) = _$ReaderCommand_SetWpmCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ReaderCommand_SetWpmCopyWithImpl<$Res>
    implements $ReaderCommand_SetWpmCopyWith<$Res> {
  _$ReaderCommand_SetWpmCopyWithImpl(this._self, this._then);

  final ReaderCommand_SetWpm _self;
  final $Res Function(ReaderCommand_SetWpm) _then;

/// Create a copy of ReaderCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ReaderCommand_SetWpm(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ReaderState {

 String get currentWord; BigInt get currentIndex; BigInt get totalWords; int get wpm; bool get isPlaying; bool get atEnd; int get progressPercent;
/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReaderStateCopyWith<ReaderState> get copyWith => _$ReaderStateCopyWithImpl<ReaderState>(this as ReaderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReaderState&&(identical(other.currentWord, currentWord) || other.currentWord == currentWord)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.totalWords, totalWords) || other.totalWords == totalWords)&&(identical(other.wpm, wpm) || other.wpm == wpm)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.atEnd, atEnd) || other.atEnd == atEnd)&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent));
}


@override
int get hashCode => Object.hash(runtimeType,currentWord,currentIndex,totalWords,wpm,isPlaying,atEnd,progressPercent);

@override
String toString() {
  return 'ReaderState(currentWord: $currentWord, currentIndex: $currentIndex, totalWords: $totalWords, wpm: $wpm, isPlaying: $isPlaying, atEnd: $atEnd, progressPercent: $progressPercent)';
}


}

/// @nodoc
abstract mixin class $ReaderStateCopyWith<$Res>  {
  factory $ReaderStateCopyWith(ReaderState value, $Res Function(ReaderState) _then) = _$ReaderStateCopyWithImpl;
@useResult
$Res call({
 String currentWord, BigInt currentIndex, BigInt totalWords, int wpm, bool isPlaying, bool atEnd, int progressPercent
});




}
/// @nodoc
class _$ReaderStateCopyWithImpl<$Res>
    implements $ReaderStateCopyWith<$Res> {
  _$ReaderStateCopyWithImpl(this._self, this._then);

  final ReaderState _self;
  final $Res Function(ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentWord = null,Object? currentIndex = null,Object? totalWords = null,Object? wpm = null,Object? isPlaying = null,Object? atEnd = null,Object? progressPercent = null,}) {
  return _then(_self.copyWith(
currentWord: null == currentWord ? _self.currentWord : currentWord // ignore: cast_nullable_to_non_nullable
as String,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as BigInt,totalWords: null == totalWords ? _self.totalWords : totalWords // ignore: cast_nullable_to_non_nullable
as BigInt,wpm: null == wpm ? _self.wpm : wpm // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,atEnd: null == atEnd ? _self.atEnd : atEnd // ignore: cast_nullable_to_non_nullable
as bool,progressPercent: null == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReaderState].
extension ReaderStatePatterns on ReaderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReaderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReaderState value)  $default,){
final _that = this;
switch (_that) {
case _ReaderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReaderState value)?  $default,){
final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currentWord,  BigInt currentIndex,  BigInt totalWords,  int wpm,  bool isPlaying,  bool atEnd,  int progressPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.currentWord,_that.currentIndex,_that.totalWords,_that.wpm,_that.isPlaying,_that.atEnd,_that.progressPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currentWord,  BigInt currentIndex,  BigInt totalWords,  int wpm,  bool isPlaying,  bool atEnd,  int progressPercent)  $default,) {final _that = this;
switch (_that) {
case _ReaderState():
return $default(_that.currentWord,_that.currentIndex,_that.totalWords,_that.wpm,_that.isPlaying,_that.atEnd,_that.progressPercent);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currentWord,  BigInt currentIndex,  BigInt totalWords,  int wpm,  bool isPlaying,  bool atEnd,  int progressPercent)?  $default,) {final _that = this;
switch (_that) {
case _ReaderState() when $default != null:
return $default(_that.currentWord,_that.currentIndex,_that.totalWords,_that.wpm,_that.isPlaying,_that.atEnd,_that.progressPercent);case _:
  return null;

}
}

}

/// @nodoc


class _ReaderState implements ReaderState {
  const _ReaderState({required this.currentWord, required this.currentIndex, required this.totalWords, required this.wpm, required this.isPlaying, required this.atEnd, required this.progressPercent});
  

@override final  String currentWord;
@override final  BigInt currentIndex;
@override final  BigInt totalWords;
@override final  int wpm;
@override final  bool isPlaying;
@override final  bool atEnd;
@override final  int progressPercent;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReaderStateCopyWith<_ReaderState> get copyWith => __$ReaderStateCopyWithImpl<_ReaderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReaderState&&(identical(other.currentWord, currentWord) || other.currentWord == currentWord)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.totalWords, totalWords) || other.totalWords == totalWords)&&(identical(other.wpm, wpm) || other.wpm == wpm)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.atEnd, atEnd) || other.atEnd == atEnd)&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent));
}


@override
int get hashCode => Object.hash(runtimeType,currentWord,currentIndex,totalWords,wpm,isPlaying,atEnd,progressPercent);

@override
String toString() {
  return 'ReaderState(currentWord: $currentWord, currentIndex: $currentIndex, totalWords: $totalWords, wpm: $wpm, isPlaying: $isPlaying, atEnd: $atEnd, progressPercent: $progressPercent)';
}


}

/// @nodoc
abstract mixin class _$ReaderStateCopyWith<$Res> implements $ReaderStateCopyWith<$Res> {
  factory _$ReaderStateCopyWith(_ReaderState value, $Res Function(_ReaderState) _then) = __$ReaderStateCopyWithImpl;
@override @useResult
$Res call({
 String currentWord, BigInt currentIndex, BigInt totalWords, int wpm, bool isPlaying, bool atEnd, int progressPercent
});




}
/// @nodoc
class __$ReaderStateCopyWithImpl<$Res>
    implements _$ReaderStateCopyWith<$Res> {
  __$ReaderStateCopyWithImpl(this._self, this._then);

  final _ReaderState _self;
  final $Res Function(_ReaderState) _then;

/// Create a copy of ReaderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentWord = null,Object? currentIndex = null,Object? totalWords = null,Object? wpm = null,Object? isPlaying = null,Object? atEnd = null,Object? progressPercent = null,}) {
  return _then(_ReaderState(
currentWord: null == currentWord ? _self.currentWord : currentWord // ignore: cast_nullable_to_non_nullable
as String,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as BigInt,totalWords: null == totalWords ? _self.totalWords : totalWords // ignore: cast_nullable_to_non_nullable
as BigInt,wpm: null == wpm ? _self.wpm : wpm // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,atEnd: null == atEnd ? _self.atEnd : atEnd // ignore: cast_nullable_to_non_nullable
as bool,progressPercent: null == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
