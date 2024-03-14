import 'dart:async';
import 'package:async_status_builder/async_status_builder.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FuturePage(),
    );
  }
}

class FuturePage extends StatefulWidget {
  const FuturePage({super.key});

  @override
  FuturePageState createState() => FuturePageState();
}

class FuturePageState extends State<FuturePage> {
  Future<int>? _future;
  bool _hasWaitedTooLong = false;

  @override
  void initState() {
    super.initState();
  }

  void _normalFuture() {
    setState((){
    _future = Future.value(200);
    _hasWaitedTooLong = false;
    });
  }

  void _futureWithError() {
    setState((){
    _future = Future.error('An error occurred!');
    _hasWaitedTooLong = false;
    });
  }

  void _futureWithLargeTimeout() {
    setState((){
    _future = Future.delayed(const Duration(seconds: 100), () => 500);
    _hasWaitedTooLong = false;
    });
  }

  void _futureWithSmallTimeout() {
    setState((){
    _future = Future.delayed(const Duration(seconds: 2), () => 100);
    _hasWaitedTooLong = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureStatusBuilder example'),
      ),
      body: _hasWaitedTooLong ? const Center(child: Text("Waited too long, callback invoked")) : (_future == null
          ? const Center(child: Text("No future selected."))
          : FutureStatusBuilder<int>(
              future: _future!,
              waitingTimeoutAction: WaitingTimeoutCallback(const Duration(seconds: 5), () {
                setState(() {
                  _hasWaitedTooLong = true;
                });
              }),
              builder: (BuildContext context, FutureStatus<int> status) {
                return Center(
                    child: switch (status) {
                  Waiting() => const Text('Waiting for data...'),
                  Data<int>(:final data) => Text('Future completed without error. Data: $data'),
                  Error<int>(:final error) =>
                    Text('Future completed with error. Error: $error'),
                });
              },
            )),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _future = null;
                _hasWaitedTooLong = false;
              });
            },
            tooltip: 'Restart',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _normalFuture,
            tooltip: 'Normal future',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _futureWithLargeTimeout,
            tooltip: 'Future with large timeout',
            child: const Icon(Icons.error),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _futureWithSmallTimeout,
            tooltip: 'Future with small timeout',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _futureWithError,
            tooltip: 'Future with error',
            backgroundColor: Colors.red,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
