import 'dart:async';

import 'package:async_state_builder/src/common.dart';
import 'package:flutter/widgets.dart';

class StreamWatcherContainer {
  static Map<Stream, StreamWidgetSubscription> _map = {};
}

class StreamWidgetSubscription<T> {
  final Stream<T> stream;
  final StreamSubscription<T> subscription;
  StreamState<T> lastValue;
  Set<Element> watchers = {};

  StreamWidgetSubscription(this.stream, this.subscription, this.lastValue, Element initialWatcher) {
    watchers.add(initialWatcher);
  }

  void removeWatcher(Element watcher) {
    watchers.remove(watcher);
    if (watchers.isNotEmpty) {
      return;
    }
    subscription.cancel();
    final removed = StreamWatcherContainer._map.remove(stream);
    assert(removed == this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreamWidgetSubscription<T> && stream == other.stream;
  }

  @override
  int get hashCode => stream.hashCode;
}

extension BuildContextExt on BuildContext {
  StreamState<T> watchStream<T>(Stream<T> stream, {T? initialValue}) {
    StreamWidgetSubscription<T>? streamWidgetSubscription =
        StreamWatcherContainer._map[stream] as StreamWidgetSubscription<T>?;
    final StreamState<T> state;
    if (streamWidgetSubscription == null) {
      final element = this as Element;
      final subscription = stream.listen(
        (data) {
          if (element.mounted) {
            element.markNeedsBuild();
            streamWidgetSubscription!.lastValue = Data(data);
          } else {
            StreamWatcherContainer._map[stream]!.removeWatcher(element);
          }
        },
        onDone: () { 
          StreamWatcherContainer._map[stream]!.removeWatcher(element);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (element.mounted) {
            element.markNeedsBuild();
            streamWidgetSubscription!.lastValue = Error(error, stackTrace);
          } else {
            StreamWatcherContainer._map[stream]!.removeWatcher(element);
          }
        }
      );
      if (initialValue == null) {
        state = const Waiting();
      } else {
        state = Data(initialValue);
      }
      streamWidgetSubscription = StreamWidgetSubscription(stream, subscription, state, element);
      StreamWatcherContainer._map[stream] = streamWidgetSubscription;
    } else {
      state = streamWidgetSubscription.lastValue;
    }
    return state;
  }
}
