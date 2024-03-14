import 'dart:async';
import 'package:async_status_builder/async_status_builder.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  @override
  _CounterPageState createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  Future<int>? _future;

  @override
  void initState() {
    super.initState();
  }

  void _normalFuture() {
    setState((){
    _future = Future.value(200);
    });
  }

  void _futureWithError() {
    setState((){
    _future = Future.error('An error occurred!');
    });
  }

  void _futureWithLargeTimeout() {
    setState((){
    _future = Future.delayed(const Duration(seconds: 100), () => 500);
    });
  }

  void _futureWithSmallTimeout() {
    setState((){
    _future = Future.delayed(const Duration(seconds: 2), () => 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureStatusBuilder example'),
      ),
      body: _future == null
          ? const Center(child: Text("No future selected."))
          : FutureStatusBuilder<int>(
              future: _future!,
              builder: (BuildContext context, FutureStatus<int> status) {
                return Center(
                    child: switch (status) {
                  Waiting() => const Text('Waiting for data...'),
                  Data<int>(:final data) => Text('Future completed without error. Data: $data'),
                  Error<int>(:final error) =>
                    Text('Future completed with error. Error: $error'),
                });
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _future = null;
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
