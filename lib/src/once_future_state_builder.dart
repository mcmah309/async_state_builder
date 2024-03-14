import 'package:async_state_builder/async_state_builder.dart';
import 'package:flutter/widgets.dart';

/// [OnceFutureStateBuilder] is a wrapper around [FutureStateBuilder] that allows you specify a function that builds the
/// future. The [futureFn] will only be called once for each unique [futureFnKey]. This is useful when you want to create the future in the
/// build method of a widget, but you don't want to rebuild the future every time the widget is rebuilt.
/// e.g. If you want the [futureFn] to be called anytime a parameter changes, you can use those parameters as the key (A,B,C,...).
/// e.g. You want the [futureFn] to be called on every build, you can use Object() as the key.
class OnceFutureStateBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureFn;
  final Object futureFnKey;
  final Widget Function(BuildContext context, FutureState<T> value) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the future is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  const OnceFutureStateBuilder({
    super.key,
    required this.futureFn,
    required this.futureFnKey,
    required this.builder,
    this.initialData,
    this.waitingTimeoutAction,
  });

  @override
  OnceFutureStateBuilderState<T> createState() => OnceFutureStateBuilderState<T>();
}

class OnceFutureStateBuilderState<T> extends State<OnceFutureStateBuilder<T>> {
  late final Future<T> future;

  @override
  void initState() {
    super.initState();
    future = widget.futureFn();
  }

  @override
  void didUpdateWidget(OnceFutureStateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.futureFnKey != widget.futureFnKey) {
      future = widget.futureFn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureStateBuilder(
        future: future,
        builder: widget.builder,
        initialData: widget.initialData,
        waitingTimeoutAction: widget.waitingTimeoutAction);
  }
}
