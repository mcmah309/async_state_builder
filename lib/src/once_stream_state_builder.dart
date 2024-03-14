import 'package:async_state_builder/async_state_builder.dart';
import 'package:flutter/widgets.dart';

/// [OnceStreamStateBuilder] is a wrapper around [FutureStateBuilder] that allows you specify a function that builds the
/// stream. The [streamFn] will only be called once for each unique [streamFnKey]. This is useful when you want to create the stream in the
/// build method of a widget, but you don't want to rebuild the stream every time the widget is rebuilt.
/// e.g. If you want the [streamFn] to be called anytime a parameter changes, you can use those parameters as the key (A,B,C,...).
/// e.g. You want the [streamFn] to be called on every build, you can use Object() as the key.
class OnceStreamStateBuilder<T> extends StatefulWidget {
  final Stream<T> Function() streamFn;
  final Object streamFnKey;
  final Widget Function(BuildContext context, StreamState<T> value) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the stream is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  const OnceStreamStateBuilder({
    super.key,
    required this.streamFn,
    required this.streamFnKey,
    required this.builder,
    this.initialData,
    this.waitingTimeoutAction,
  });

  @override
  OnceStreamStateBuilderState<T> createState() => OnceStreamStateBuilderState<T>();
}

class OnceStreamStateBuilderState<T> extends State<OnceStreamStateBuilder<T>> {
  late final Stream<T> stream;

  @override
  void initState() {
    super.initState();
    stream = widget.streamFn();
  }

  @override
  void didUpdateWidget(OnceStreamStateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamFnKey != widget.streamFnKey) {
      stream = widget.streamFn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder(
        stream: stream,
        builder: widget.builder,
        initialData: widget.initialData,
        waitingTimeoutAction: widget.waitingTimeoutAction);
  }
}