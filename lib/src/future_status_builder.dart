import 'package:flutter/widgets.dart';

import 'common.dart';

/// A [FutureBuilder] which the state of the future can be pattern matched.
class FutureStatusBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, FutureStatus<T> value) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the future is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? loadingTimeoutAction;

  /// If true, the state will be reset when the future changes. Otherwise, the last emitted data will be kept.
  final bool resetOnFutureChange;

  const FutureStatusBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.loadingTimeoutAction,
    this.resetOnFutureChange = true,
  });

  /// Whether the latest error received by the asynchronous computation should
  /// be rethrown or swallowed. This property is useful for debugging purposes.
  ///
  /// When set to true, will rethrow the latest error only in debug mode.
  ///
  /// Defaults to `false`, resulting in swallowing of errors.
  static bool debugRethrowError = false;

  @override
  State<StatefulWidget> createState() => FutureStatusBuilderState<T>();
}


class FutureStatusBuilderState<T> extends State<FutureStatusBuilder<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  FutureStatus<T>? _status;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureStatusBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future == widget.future) {
      return;
    }
    if (_activeCallbackIdentity != null) {
      _unsubscribe();
    }
    _subscribe();
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
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _status = Data(data);
        });
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (_activeCallbackIdentity == callbackIdentity) {
        setState(() {
          _status = Error(error, stackTrace);
        });
      }
      assert(() {
        if (FutureStatusBuilder.debugRethrowError) {
          Future<Object>.error(error, stackTrace);
        }
        return true;
      }());
    });
    // An implementation like `SynchronousFuture` may have already ran the above future and called the
    // .then closure. Do not overwrite it in that case.
    if (_status is! Data<T>) {
      if (widget.initialData != null) {
        _status = Data(widget.initialData as T);
      }
      else {
        _status = const Waiting();
      }
    } else {
      _status = const Waiting();
    } 
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
    _status = null;
  }
}