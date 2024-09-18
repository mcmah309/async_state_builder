# async_state_builder

[![Pub Version](https://img.shields.io/pub/v/async_state_builder.svg)](https://pub.dev/packages/async_state_builder)
[![Dart Package Docs](https://img.shields.io/badge/documentation-pub.dev-blue.svg)](https://pub.dev/documentation/async_state_builder/latest/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

async_state_builder provides lightweight widgets for handling asynchronous data using state machines and pattern matching.
This package is an improved version of the standard`StreamBuilder` and `FutureBuilder` widgets,
making it easier to manage and respond to various states of asynchronous computations.

## Benefits of Using State Machines

Using state machines instead of traditional conditional logic found in `StreamBuilder`/`FutureBuilder` offers several advantages:

- **Readability**: Pattern matching provides a clear and concise way to handle various states, making the code easier to read and understand.
- **Maintainability**: State machines separate state logic from the UI, making the code easier to maintain and extend.
- **Reliability**: Explicitly defined states reduce the chances of encountering unexpected states or transitions, improving the robustness of your code.

## Usage

### StreamStateMachineBuilder
All states
```dart
StreamStateMachineBuilder<int>(
    stream: stream,
    builder: (BuildContext context, StreamState<int> state) {
        return switch (state) {
            Waiting() => const Text('Waiting for data...'),
            Data<int>(:final data) => Text('Data: $data'),
            Closed<int>(:final data?) => Text('Closed, data received before closing: $data'),
            Closed<int>() => const Text('Closed before any data was sent'),
            StreamStateMachineError<int>(:final data?, :final error) => Text('Error, data received before error: $data. Error: $error'),
            StreamStateMachineError<int>(:final error) => Text('Error received before any data was sent. Error: $error'),
        };
    },
),
```
As with pattern matching, you can code for only the states you care about
```dart
switch (state) {
    Waiting() => const Text('Waiting for data...'),
    Data<int>(:final data) => Text('Data: $data'),
    _ => Text('Unexpected state'),
};
```

### StreamStateMachineBuilder
All states
```dart
StreamStateBuilder<int>(
    stream: stream,
    builder: (BuildContext context, StreamState<int> state) {
        return switch (state) {
            Waiting() => const Text('Waiting for data...'),
            Data<int>(:final data) => Text('Data: $data'),
            StreamError<int>(:final error) => Text('Error: $error'),
        };
    },
),
```

### FutureStateBuilder
All states
```dart
FutureStateBuilder<int>(
    future: future,
    builder: (BuildContext context, FutureState<int> state) {
        return switch (state) {
            Waiting() => const Text('Waiting to finish...'),
            Data<int>(:final data) => Text('Data: $data'),
            FutureError<int>(:final error) => Text('Error: $error'),
        };
    },
)
```