import 'dart:async';

import 'package:flutter/widgets.dart';

import 'common.dart';

/// A [FutureBuilder] which the state of the future can be pattern matched.
class FutureStateBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, FutureState<T> state) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the future is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  const FutureStateBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.waitingTimeoutAction,
  });

  /// Whether the latest error received by the asynchronous computation should
  /// be rethrown or swallowed. This property is useful for debugging purposes.
  ///
  /// When set to true, will rethrow the latest error only in debug mode.
  ///
  /// Defaults to `false`, resulting in swallowing of errors.
  static bool debugRethrowError = false;

  @override
  State<StatefulWidget> createState() => FutureStateBuilderState<T>();
}

class FutureStateBuilderState<T> extends State<FutureStateBuilder<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  FutureState<T>? _status;
  Timer? _timeoutCallbackOperation;

  @override
  void initState() {
    super.initState();
    if (widget.waitingTimeoutAction != null) {
      _setTimeout();
    }
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureStateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future == widget.future) {
      return;
    }
    if (oldWidget.waitingTimeoutAction != null) {
      _cancelTimeout();
    }
    if (_activeCallbackIdentity != null) {
      _unsubscribe();
    }
    _subscribe();
    if (widget.waitingTimeoutAction != null && _status is Waiting) {
      _setTimeout();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _status!);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final Object callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    widget.future.then<void>((T data) {
      _cancelTimeout();
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _status = Data(data);
        });
      }
    }, onError: (Object error, StackTrace stackTrace) {
      _cancelTimeout();
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _status = FutureError(error, stackTrace);
        });
      }
      assert(() {
        if (FutureStateBuilder.debugRethrowError) {
          Future<Object>.error(error, stackTrace);
        }
        return true;
      }());
    });
    // An implementation like `SynchronousFuture` may have already ran the above future and called the
    // .then closure. Do not overwrite it in that case.
    if (_status == null) {
      if (widget.initialData == null) {
        _status = const Waiting();
      } else {
        _status = Data(widget.initialData as T);
      }
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
    _status = null;
  }

  void _setTimeout() {
    _timeoutCallbackOperation?.cancel();
    switch (widget.waitingTimeoutAction!) {
      case WaitingTimeoutCallback(:final loadingTimeout, :final onTimeout):
        _timeoutCallbackOperation = Timer(loadingTimeout, onTimeout);
    }
  }

  void _cancelTimeout() {
    if (_timeoutCallbackOperation != null) {
      _timeoutCallbackOperation!.cancel();
      _timeoutCallbackOperation = null;
    }
  }
}
