import 'package:flutter/widgets.dart';

import 'common.dart';

/// A [StreamBuilder] which the state of the stream can be pattern matched.
class StreamStatusBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, StreamStatus<T> value) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the stream is still in [Waiting] after the specified duration.
  final LoadingTimeoutAction? loadingTimeoutAction;

  /// If true, the state will be reset when the stream object changes. Otherwise, the last emitted data will be kept.
  final bool resetOnStreamObjectChange;

  /// If true, the last data will be preserved between builds. This is useful to not losing data when the stream becomes [Error] or [Closed].
  final bool preserveLastData;

  const StreamStatusBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.loadingTimeoutAction,
    this.resetOnStreamObjectChange = true,
    this.preserveLastData = true,
  });

  @override
  State<StatefulWidget> createState() => StreamStatusBuilderState<T>();
}

class StreamStatusBuilderState<T> extends State<StreamStatusBuilder<T>> {
  /// Will exist if [preserveLastData] is true and the stream has emitted data at least once.
  Data<T>? _lastData;
  /// Will be true if the stream is in [Waiting] state.
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
  void didUpdateWidget(covariant StreamStatusBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetOnStreamObjectChange && widget.stream != oldWidget.stream) {
      _lastData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: widget.resetOnStreamObjectChange ? ObjectKey(widget.stream) : null,
      initialData: widget.initialData,
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          assert(snapshot.error != null,
              "StreamBuilder contract violated: `hasError` is true but `error` is null.");
          assert(snapshot.stackTrace != null,
              "StreamBuilder contract violated: `hasError` is true but `stackTrace` is null.");
          _isWaiting = false;
          return widget.builder(
              context, Error(snapshot.error!, snapshot.stackTrace!, _lastData?.data));
        }
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            throw "StreamStatusBuilder contract violated: Since the provided stream is not null, `connectionState` cannot be `none`.";
          case ConnectionState.waiting:
            _isWaiting = true;
            _lastData = null;
            return widget.builder(context, const Waiting());
          case ConnectionState.active:
            assert(snapshot.hasData,
                "StreamStatusBuilder contract violated: ConnectionState.active must have data.");
            _isWaiting = false;
            if (widget.preserveLastData) {
              _lastData = Data(snapshot.data as T);
              return widget.builder(context, _lastData!);
            }
            else {
              return widget.builder(context, Data(snapshot.data as T));
            }
          case ConnectionState.done:
            _isWaiting = false;
            return widget.builder(context, Closed(_lastData?.data));
        }
      },
    );
  }
}
