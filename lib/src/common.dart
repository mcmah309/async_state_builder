

import 'package:flutter/widgets.dart';

sealed class LoadingTimeoutAction {
  final Duration loadingTimeout;

  const LoadingTimeoutAction(this.loadingTimeout);
}

class LoadingTimeoutCallback extends LoadingTimeoutAction {
  final VoidCallback onTimeout;

  const LoadingTimeoutCallback(super.loadingTimeout, this.onTimeout);
}

//************************************************************************//

/// The status of a stream.

sealed class StreamStatus<T> {
  const StreamStatus();
}

sealed class FutureStatus<T> {
  const FutureStatus();
}

/// The status of a stream that has been closed.
class Closed<T> extends StreamStatus<T> {
  /// The last data that was received before the stream was closed.
  final T? data;

  const Closed(this.data);
}

/// The status of a stream that is waiting for data.
final class Waiting implements FutureStatus<Never>, StreamStatus<Never> {
  const Waiting();
}

/// The status of a stream that has received data.
final class Data<T> implements FutureStatus<T>, StreamStatus<T> {
  final T data;

  const Data(this.data);
}

/// The status of a stream that has received an error.
final class Error<T> implements FutureStatus<T>, StreamStatus<T> {
  final Object error;
  final StackTrace stackTrace;
  /// The last data that was received before the error occurred. Will always be null for [FutureStatus].
  final T? data;

  const Error(this.error, this.stackTrace, this.data);
}