

import 'package:flutter/widgets.dart';

sealed class WaitingTimeoutAction {
  final Duration loadingTimeout;

  const WaitingTimeoutAction(this.loadingTimeout);
}

/// An action to be taken if the stream is still in [Waiting] after the specified duration.
/// The function should likely not be created in the build method, as this may cause the timer to be reset.
class WaitingTimeoutCallback extends WaitingTimeoutAction {
  final VoidCallback onTimeout;

  const WaitingTimeoutCallback(super.loadingTimeout, this.onTimeout);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WaitingTimeoutCallback &&
        other.loadingTimeout == loadingTimeout &&
        other.onTimeout == onTimeout;
  }

  @override
  int get hashCode => loadingTimeout.hashCode ^ onTimeout.hashCode;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Closed &&
        other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// The status of waiting for initial data.
final class Waiting implements FutureStatus<Never>, StreamStatus<Never> {
  const Waiting();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Waiting;
  }

  @override
  int get hashCode => 0;
}

/// The status of has received data.
final class Data<T> implements FutureStatus<T>, StreamStatus<T> {
  final T data;

  const Data(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Data &&
        other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// The status of has received an error.
final class Error<T> implements FutureStatus<T>, StreamStatus<T> {
  final Object error;
  final StackTrace stackTrace;
  /// The last data that was received before the error occurred. Will always be null for [FutureStatus].
  final T? data;

  const Error(this.error, this.stackTrace, this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Error &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.data == data;
    }

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode ^ data.hashCode;
}