import 'dart:async';

import 'package:async_state_builder/async_state_builder.dart';
import 'package:flutter/widgets.dart';

/// A [StreamBuilder] which the state of the stream can be pattern matched. States are not aware of the previous state, unlike [StreamStateMachineBuilder]
class StreamStateBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, StreamState<T> state) builder;
  final void Function()? onDone;
  final T? initialData;

  /// If provided, this is the action that should be taken if the stream is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  /// If true, the state will be reset when the stream object changes. Otherwise, the last emitted data will be kept.
  final bool resetOnStreamObjectChange;

  const StreamStateBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.onDone,
    this.initialData,
    this.waitingTimeoutAction,
    this.resetOnStreamObjectChange = true,
  });

  @override
  State<StatefulWidget> createState() => StreamStateBuilderState<T>();
}

class StreamStateBuilderState<T> extends State<StreamStateBuilder<T>> {
  StreamSubscription<T>? _subscription;
  StreamState<T>? _status;
  Timer? _timeoutCallbackOperation;

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
  void didUpdateWidget(StreamStateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream == widget.stream) {
      return;
    }
    if (oldWidget.waitingTimeoutAction != null) {
      _cancelTimeout();
    }
    if(widget.resetOnStreamObjectChange){
      _status = null;
    }
    _unsubscribe();
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
    _cancelTimeout();
    super.dispose();
  }

  void _subscribe() {
    _subscription = widget.stream.listen((T data) {
      _cancelTimeout();
      setState(() {
        final newData = Data(data);
        _status = newData;
      });
    }, onError: (Object error, StackTrace stackTrace) {
      _cancelTimeout();
      setState(() {
        _status = StreamError(error, stackTrace);
      });
    }, onDone: () {
      _cancelTimeout();
      widget.onDone?.call();
    });
    // An implementation like a sync stream may have already ran the above. Do not overwrite it in that case.
    if (_status == null) {
      if (widget.initialData == null) {
        _status = const Waiting();
      } else {
        _status = Data(widget.initialData as T);
      }
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
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
