import 'package:flutter/widgets.dart';

import 'common.dart';

/// A [FutureBuilder] which the state of the future can be pattern matched.
class FutureStatusBuilder<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, FutureStatus<T> value) builder;

  /// If provided, this is the action that should be taken if the future is still in [Waiting] after the specified duration.
  final LoadingTimeoutAction? loadingTimeoutAction;

  /// If true, the state will be reset when the future changes. Otherwise, the last emitted data will be kept.
  final bool resetOnFutureChange;

  const FutureStatusBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingTimeoutAction,
    this.resetOnFutureChange = true,
  });

  @override
  State<StatefulWidget> createState() => FutureStatusBuilderState<T>();
}

class FutureStatusBuilderState<T> extends State<FutureStatusBuilder<T>> {
  Data<T>? _lastData;
  bool _isWaiting = true;

  @override
  void initState() {
    super.initState();
    if (widget.loadingTimeoutAction != null) {
      switch (widget.loadingTimeoutAction!) {
        case LoadingTimeoutCallback(:final loadingTimeout, :final onTimeout):
          Future.delayed(loadingTimeout, onTimeout).then((value) {
            if (mounted && _isWaiting) {
              onTimeout();
            }
          });
      }
    }
  }

  @override
  void didUpdateWidget(covariant FutureStatusBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetOnFutureChange && widget.future != oldWidget.future) {
      _lastData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      key: widget.resetOnFutureChange ? ObjectKey(widget.future) : null,
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          assert(snapshot.error != null,
              "FutureBuilder contract violated: `hasError` is true but `error` is null.");
          assert(snapshot.stackTrace != null,
              "FutureBuilder contract violated: `hasError` is true but `stackTrace` is null.");
          _isWaiting = false;
          return widget.builder(
              context, Error(snapshot.error!, snapshot.stackTrace!, _lastData?.data));
        }
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            throw "StreamStatusBuilder contract violated: Since the provided stream is not null, `connectionState` cannot be `none`.";
          case ConnectionState.waiting:
            _isWaiting = true;
            return widget.builder(context, const Waiting());
          case ConnectionState.active:
            throw "StreamStatusBuilder contract violated: `connectionState` cannot be `active` for a Future.";
          case ConnectionState.done:
            _isWaiting = false;
            return widget.builder(context, Data(snapshot.data as T));
        }
      },
    );
  }
}
