import 'dart:async';

import 'package:flutter/widgets.dart';

import 'common.dart';

/// A [StreamBuilder] which the state of the stream can be pattern matched.
class StreamStatusBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, StreamStatus<T> value) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the stream is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  /// If true, the state will be reset when the stream object changes. Otherwise, the last emitted data will be kept.
  final bool resetOnStreamObjectChange;

  /// If true, the last data will be preserved between builds. This is useful to not losing data when the stream becomes [Error] or [Closed].
  final bool preserveLastData;

  const StreamStatusBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.initialData,
    this.waitingTimeoutAction,
    this.resetOnStreamObjectChange = true,
    this.preserveLastData = true,
  });

  @override
  State<StatefulWidget> createState() => StreamStatusBuilderState<T>();
}

class StreamStatusBuilderState<T> extends State<StreamStatusBuilder<T>> {
  StreamSubscription<T>? _subscription;
  StreamStatus<T>? _status;
  T? _lastData;
  Timer? timeoutCallbackOperation;

  @override
  void initState() {
    super.initState();
    // _status = const Waiting(); // change if we need another initial state, [StreamBuilder] uses none here but it is immediately override in [_subscribe] so there is not point in doing it.
    if (widget.waitingTimeoutAction != null) {
      _setTimeout();
    }
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamStatusBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      if (widget.resetOnStreamObjectChange) {
        _lastData = null;
      }
      if (_subscription != null) {
        _unsubscribe();
        _status = null;
      }
      _subscribe();
      if (widget.waitingTimeoutAction != oldWidget.waitingTimeoutAction) {
        if (oldWidget.waitingTimeoutAction != null) {
          _cancelTimeout();
        }
        if (widget.waitingTimeoutAction != null) {
          _setTimeout();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _status!);

  @override
  void dispose() {
    _unsubscribe();
    _cancelTimeout();
    super.dispose();
  }

  void _subscribe() {
    _subscription = widget.stream.listen((T data) {
      _cancelTimeout();
      setState(() {
        final newData = Data(data);
        _status = newData;
        _lastData = data;
      });
    }, onError: (Object error, StackTrace stackTrace) {
      _cancelTimeout();
      setState(() {
        _status = Error(error, stackTrace, _lastData);
      });
    }, onDone: () {
      _cancelTimeout();
      setState(() {
        _status = Closed(_lastData);
      });
    });
    if(widget.initialData != null) {
      _lastData = widget.initialData;
      _status = Data(widget.initialData as T);
    }
    else {
      _status = const Waiting();
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
  }

  void _setTimeout() {
    timeoutCallbackOperation?.cancel();
    switch (widget.waitingTimeoutAction!) {
      case WaitingTimeoutCallback(:final loadingTimeout, :final onTimeout):
        timeoutCallbackOperation = Timer(loadingTimeout, onTimeout);
    }
  }

  void _cancelTimeout() {
    if (timeoutCallbackOperation != null) {
      timeoutCallbackOperation!.cancel();
      timeoutCallbackOperation = null;
    }
  }
}
