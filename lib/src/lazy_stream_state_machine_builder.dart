import 'package:async_state_builder/async_state_builder.dart';
import 'package:flutter/widgets.dart';

/// [LazyStreamStateMachineBuilder] is a wrapper around [StreamStateMachineBuilder], designed to initiate a stream
/// through [streamFn] just once for each unique [streamFnKey].
/// This feature is particularly handy for initiating streams within a widget's build phase without
/// triggering unnecessary stream rebuilds with every widget update.
/// e.g. If you want the [streamFn] to be called anytime a parameter changes, you can use those parameters as the key `(A,B,C,...)`.
/// e.g. You want the [streamFn] to be called on every build, you can use `Object()` as the key.
/// e.g. You want the [streamFn] to never be called on rebuild, you can use `const Object()` or `0`.
class LazyStreamStateMachineBuilder<T> extends StatefulWidget {
  final Stream<T> Function() streamFn;
  final Object streamFnKey;
  final Widget Function(BuildContext context, StreamStateMachineState<T> state) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the stream is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  const LazyStreamStateMachineBuilder({
    super.key,
    required this.streamFn,
    required this.streamFnKey,
    required this.builder,
    this.initialData,
    this.waitingTimeoutAction,
  });

  @override
  LazyStreamStateMachineBuilderState<T> createState() =>
      LazyStreamStateMachineBuilderState<T>();
}

class LazyStreamStateMachineBuilderState<T> extends State<LazyStreamStateMachineBuilder<T>> {
  late Stream<T> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.streamFn();
  }

  @override
  void didUpdateWidget(LazyStreamStateMachineBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamFnKey != widget.streamFnKey) {
      _stream = widget.streamFn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamStateMachineBuilder(
        stream: _stream,
        builder: widget.builder,
        initialData: widget.initialData,
        waitingTimeoutAction: widget.waitingTimeoutAction);
  }
}
