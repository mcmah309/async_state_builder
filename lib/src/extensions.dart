import 'dart:async';

import 'package:async_state_builder/src/common.dart';
import 'package:flutter/widgets.dart';

class _StreamWatcherContainer {
  static final Map<Stream, _StreamWidgetSubscription> map = {};
}

class _StreamWidgetSubscription<T> {
  final Stream<T> stream;
  late final StreamSubscription<T> subscription;
  StreamState<T> lastValue;
  Set<Element> watchers = {};

  _StreamWidgetSubscription(this.stream, this.lastValue, Element initialWatcher) {
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
  StreamState<T> watchStream<T>(Stream<T> stream, {T? initialValue}) {
    _StreamWidgetSubscription<T>? streamWidgetSubscription =
        _StreamWatcherContainer.map[stream] as _StreamWidgetSubscription<T>?;
    final StreamState<T> state;
    if (streamWidgetSubscription == null) {
      final element = this as Element;
      if (initialValue == null) {
        state = const Waiting();
      } else {
        state = Data(initialValue);
      }
      streamWidgetSubscription = _StreamWidgetSubscription(stream, state, element);
      _StreamWatcherContainer.map[stream] = streamWidgetSubscription;
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
      // An implementation like a sync stream may have already ran the above, so this added later.
      streamWidgetSubscription.subscription = subscription;
    } else {
      state = streamWidgetSubscription.lastValue;
    }
    return state;
  }
}
