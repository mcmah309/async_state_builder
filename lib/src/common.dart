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

sealed class StreamState<T> {
  const StreamState();
}

sealed class StreamStateMachineState<T> {
  const StreamStateMachineState();
}

sealed class FutureState<T> {
  const FutureState();
}

/// The state of a stream that has been closed.
class Closed<T> extends StreamStateMachineState<T> {
  /// The last data that was received before the stream was closed.
  final T? data;

  const Closed(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Closed && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// The state of waiting for initial data.
final class Waiting
    implements FutureState<Never>, StreamStateMachineState<Never>, StreamState<Never> {
  const Waiting();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Waiting;
  }

  @override
  int get hashCode => 0;
}

/// The state of has received data.
final class Data<T>
    implements FutureState<T>, StreamStateMachineState<T>, StreamState<Never> {
  final T data;

  const Data(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Data && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// The state of has received an error.
final class StreamError<T> implements StreamStateMachineState<T>, StreamState<Never> {
  final Object error;
  final StackTrace stackTrace;
  final T? data;

  const StreamError(this.error, this.stackTrace, [this.data]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StreamError &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.data == data;
  }

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode ^ data.hashCode;
}

/// The state of has received an error.
final class FutureError<T> implements FutureState<T> {
  final Object error;
  final StackTrace stackTrace;

  const FutureError(this.error, this.stackTrace);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StreamError && other.error == error && other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;
}
