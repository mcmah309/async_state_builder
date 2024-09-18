import 'dart:async';

import 'package:async_state_builder/src/common.dart';
import 'package:flutter/widgets.dart';

class _StreamWatcherContainer {
  static const int cleanUpTimeInMilliseconds = 5000;

  static final Map<Stream, _StreamWidgetSubscription> map = {};
  static bool cleanUpStarted = false;

  /// Since flutter does not allow us to hook into an [Element]s lifecycle. We periodically check
  /// if the element is mounted. Removing it if so.
  static void cleanUp() {
    cleanUpStarted = true;
    Future.delayed(const Duration(milliseconds: cleanUpTimeInMilliseconds), _cleanUp);
    if (map.isEmpty) {
      cleanUpStarted = false;
    } else {
      cleanUp();
    }
  }

  static void _cleanUp() {
    List<void Function()> removeFunctions = [];
    for (final streamWidgetSubscription in map.values) {
      for (final watcher in streamWidgetSubscription.watchers) {
        if (!watcher.mounted) {
          removeFunctions.add(() => streamWidgetSubscription.removeWatcher(watcher));
        }
      }
    }
  }
}

class _StreamWidgetSubscription<T> {
  final Stream<T> stream;
  late final StreamSubscription<T> subscription;
  StreamState<T> lastValue;
  Set<Element> watchers = {};

  _StreamWidgetSubscription(this.stream, this.lastValue, Element initialWatcher) {
    watchers.add(initialWatcher);
    if (!_StreamWatcherContainer.cleanUpStarted) {
      _StreamWatcherContainer.cleanUp();
    }
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
  /// Watches a stream, rebuilding the current widget each time the stream updates.
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
