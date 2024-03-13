import 'package:flutter/widgets.dart';

typedef Builder<T> = Widget Function(BuildContext context, StreamStatus<T> value);

sealed class LoadingTimeoutAction {
  final Duration loadingTimeout;

  const LoadingTimeoutAction(this.loadingTimeout);
}

class LoadingTimeoutCallback extends LoadingTimeoutAction {
  final VoidCallback onTimeout;

  const LoadingTimeoutCallback(super.loadingTimeout, this.onTimeout);
}

class StreamStatusBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Builder<T> builder;
  /// If provided, this is the action that should be taken if the stream is still in [Waiting] after the specified duration.
  final LoadingTimeoutAction? loadingTimeoutAction;
  /// If true, the state will be reset when the stream changes. Otherwise, the last emitted data will be kept.
  final bool resetOnStreamChange;

  const StreamStatusBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingTimeoutAction,
    this.resetOnStreamChange = true,
  });

  @override
  State<StatefulWidget> createState() => StreamStatusBuilderState<T>();
}

class StreamStatusBuilderState<T> extends State<StreamStatusBuilder<T>> {
  Data<T>? _lastData;
  bool _isWaiting = true;

  @override
  void initState() {
    super.initState();
    if (widget.loadingTimeoutAction != null) {
      switch(widget.loadingTimeoutAction!) {
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
  void didUpdateWidget(covariant StreamStatusBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetOnStreamChange && widget.stream != oldWidget.stream) {
      _lastData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: widget.resetOnStreamChange ? ObjectKey(widget.stream) : null,
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          assert(snapshot.error != null, "StreamBuilder contract violated: `hasError` is true but `error` is null.");
          assert(snapshot.stackTrace != null, "StreamBuilder contract violated: `hasError` is true but `stackTrace` is null.");
          _isWaiting = false;
          return widget.builder(context, Error(snapshot.error!, snapshot.stackTrace!, _lastData?.data));
        }
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            throw "StreamStatusBuilder contract violated: Since the provided stream is not null `connectionState` `none`.";
          case ConnectionState.waiting:
            _isWaiting = true;
            return widget.builder(context, const Waiting());
          case ConnectionState.active:
            assert(snapshot.hasData, "StreamStatusBuilder contract violated: ConnectionState.active must have data.");
            _isWaiting = false;
            _lastData = Data(snapshot.data as T);
            return widget.builder(context, _lastData!);
          case ConnectionState.done:
            _isWaiting = false;
            return widget.builder(context, Closed(_lastData?.data));
        }
      },
    );
  }
}

sealed class StreamStatus<T> {
  const StreamStatus();
}

final class Waiting extends StreamStatus<Never> {
  const Waiting();
}

final class Data<T> extends StreamStatus<T> {
  final T data;

  const Data(this.data);
}

final class Error<T> extends StreamStatus<T> {
  final Object error;
  final StackTrace stackTrace;
  /// The last data that was received before the error occurred.
  final T? data;

  const Error(this.error, this.stackTrace, this.data);
}

final class Closed<T> extends StreamStatus<T> {
  /// The last data that was received before the stream was closed.
  final T? data;

  const Closed(this.data);
}