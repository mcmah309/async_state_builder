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
      home: CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  CounterPageState createState() => CounterPageState();
}

class CounterPageState extends State<CounterPage> {
  StreamController<int> _counterController = StreamController<int>();
  int _counter = 0;
  bool _hasWaitedTooLong = false;

  @override
  void initState() {
    super.initState();
  }

  void _incrementCounter() {
    _counter++;
    _counterController.add(_counter);
  }

  void _closeStream() {
    _counterController.close();
  }

  void _sendError() {
    _counterController.addError('An error occurred!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreamStatusBuilder example'),
      ),
      body: _hasWaitedTooLong
          ? const Center(child: Text("Waited too long, callback invoked"))
          : StreamStatusBuilder<int>(
              stream: _counterController.stream,
              waitingTimeoutAction: WaitingTimeoutCallback(const Duration(seconds: 5), () {
                setState(() {
                  _hasWaitedTooLong = true;
                });
              }),
              builder: (BuildContext context, StreamStatus<int> status) {
                return Center(
                    child: switch (status) {
                  Waiting() => const Text('Waiting for data...'),
                  Error<int>(:final data?, :final error) =>
                    Text('Error, recieved before error: $data. Error: $error'),
                  Closed<int>(:final data?) => Text('Closed, data recieved before closing: $data'),
                  Data<int>(:final data) => Text('Data sent without error: $data'),
                  Error<int>(:final error) =>
                    Text('Error recieved before any data was sent. Error: $error'),
                  Closed<int>() => const Text('Stream closed, before any data was sent'),
                });
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _counterController.close();
                _counterController = StreamController();
                _counter = 0;
                _hasWaitedTooLong = false;
              });
            },
            tooltip: 'Restart',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
              });
            },
            tooltip: 'Trigger rebuild',
            child: const Icon(Icons.build),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Send Data',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _sendError,
            tooltip: 'Send Error',
            child: const Icon(Icons.error),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _closeStream,
            tooltip: 'Close Stream',
            backgroundColor: Colors.red,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
