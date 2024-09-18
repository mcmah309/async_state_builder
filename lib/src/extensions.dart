import 'dart:async';

import 'package:async_state_builder/src/common.dart';
import 'package:flutter/widgets.dart';

class _StreamWatcherContainer {
  static final Map<Stream, _StreamWidgetSubscription> map = {};
}

class _StreamWidgetSubscription<T> {
  final Stream<T> stream;
  final StreamSubscription<T> subscription;
  StreamStateMachineState<T> lastValue;
  Set<Element> watchers = {};

  _StreamWidgetSubscription(
      this.stream, this.subscription, this.lastValue, Element initialWatcher) {
    watchers.add(initialWatcher);
  }

  void removeWatcher(Element watcher) {
    watchers.remove(watcher);
    if (watchers.isNotEmpty) {
      return;
    }
    subscription.cancel();
    final removed = _StreamWatcherContainer.map.remove(stream);
    assert(removed == this);
  }

  @override
  bool operator ==(Object other) {
    return other is _StreamWidgetSubscription<T> && stream == other.stream;
  }

  @override
  int get hashCode => stream.hashCode;
}

extension BuildContextExt on BuildContext {
  StreamStateMachineState<T> watchStream<T>(Stream<T> stream, {T? initialValue}) {
    _StreamWidgetSubscription<T>? streamWidgetSubscription =
        _StreamWatcherContainer.map[stream] as _StreamWidgetSubscription<T>?;
    final StreamStateMachineState<T> state;
    if (streamWidgetSubscription == null) {
      final element = this as Element;
      final subscription = stream.listen((data) {
        if (element.mounted) {
          element.markNeedsBuild();
          streamWidgetSubscription!.lastValue = Data(data);
        } else {
          _StreamWatcherContainer.map[stream]!.removeWatcher(element);
        }
      }, onDone: () {
        _StreamWatcherContainer.map[stream]!.removeWatcher(element);
      }, onError: (Object error, StackTrace stackTrace) {
        if (element.mounted) {
          element.markNeedsBuild();
          streamWidgetSubscription!.lastValue = StreamError(error, stackTrace);
        } else {
          _StreamWatcherContainer.map[stream]!.removeWatcher(element);
        }
      });
      if (initialValue == null) {
        state = const Waiting();
      } else {
        state = Data(initialValue);
      }
      streamWidgetSubscription = _StreamWidgetSubscription(stream, subscription, state, element);
      _StreamWatcherContainer.map[stream] = streamWidgetSubscription;
    } else {
      state = streamWidgetSubscription.lastValue;
    }
    return state;
  }
}
