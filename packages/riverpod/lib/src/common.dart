import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

import 'framework/framework.dart';

part 'common.freezed.dart';

typedef Create<Res, Context extends ProviderReference> = Res Function(
    Context ref);

typedef VoidCallback = void Function();

@freezed
abstract class AsyncValue<T> with _$AsyncValue<T> {
  factory AsyncValue.data(T value) = _Data<T>;
  const factory AsyncValue.loading() = _Loading<T>;
  factory AsyncValue.error(Object error, [StackTrace stackTrace]) = _Error<T>;
}