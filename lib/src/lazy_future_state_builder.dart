import 'package:async_state_builder/async_state_builder.dart';
import 'package:flutter/widgets.dart';

/// [LazyFutureStateBuilder] is a wrapper around [FutureStateBuilder], designed to initiate a future 
/// through [futureFn] just once for each unique [futureFnKey]. 
/// This feature is particularly handy for initiating futures within a widget's build phase without 
/// triggering unnecessary future rebuilds with every widget update.
/// e.g. If you want the [futureFn] to be called anytime a parameter changes, you can use those parameters as the key (A,B,C,...).
/// e.g. You want the [futureFn] to be called on every build, you can use Object() as the key.
/// e.g. You want the [futureFn] to never be called on rebuild, you can use `const Object()` or `0`.
class LazyFutureStateBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureFn;
  final Object futureFnKey;
  final Widget Function(BuildContext context, FutureState<T> value) builder;
  final T? initialData;

  /// If provided, this is the action that should be taken if the future is still in [Waiting] after the specified duration.
  final WaitingTimeoutAction? waitingTimeoutAction;

  const LazyFutureStateBuilder({
    super.key,
    required this.futureFn,
    required this.futureFnKey,
    required this.builder,
    this.initialData,
    this.waitingTimeoutAction,
  });

  @override
  LazyFutureStateBuilderState<T> createState() => LazyFutureStateBuilderState<T>();
}

class LazyFutureStateBuilderState<T> extends State<LazyFutureStateBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureFn();
  }

  @override
  void didUpdateWidget(LazyFutureStateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.futureFnKey != widget.futureFnKey) {
      _future = widget.futureFn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureStateBuilder(
        future: _future,
        builder: widget.builder,
        initialData: widget.initialData,
        waitingTimeoutAction: widget.waitingTimeoutAction);
  }
}
