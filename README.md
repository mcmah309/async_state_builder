# async_state_builder

async_state_builder provides widgets for handling asynchronous data using state machines and pattern matching.
This package is an improved version of the standard`StreamBuilder` and `FutureBuilder` widgets,
making it easier to manage and respond to various states of asynchronous computations.

## Benefits of Using State Machines

Using state machines instead of traditional conditional logic found in `StreamBuilder`/`FutureBuilder` offers several advantages:

- **Readability**: Pattern matching provides a clear and concise way to handle various states, making the code easier to read and understand.
- **Maintainability**: State machines separate state logic from the UI, making the code easier to maintain and extend.
- **Reliability**: Explicitly defined states reduce the chances of encountering unexpected states or transitions, improving the robustness of your code.

## Usage

### StreamStateBuilder

```dart
StreamStateBuilder<int>(
    stream: stream,
    builder: (BuildContext context, StreamState<int> status) {
        return switch (status) {
            Waiting() => const Text('Waiting for data...'),
            Error<int>(:final data?, :final error) => Text('Error, received before error: $data. Error: $error'),
            Closed<int>(:final data?) => Text('Closed, data received before closing: $data'),
            Data<int>(:final data) => Text('Data sent without error: $data'),
            Error<int>(:final error) => Text('Error received before any data was sent. Error: $error'),
            Closed<int>() => const Text('Stream closed, before any data was sent'),
        };
    },
),
```
As with pattern matching you can code for only the states you care about
```dart
switch (status) {
    Waiting() => const Text('Waiting for data...'),
    Data<int>(:final data) || Closed<int>(:final data?) => Text('Data sent without error: $data'),
    _ => Text('Unexpected Error'),
};
```

### FutureStateBuilder
```dart
FutureStateBuilder<int>(
    future: future,
    builder: (BuildContext context, FutureState<int> status) {
        return switch (status) {
            Waiting() => const Text('Waiting for data...'),
            Data<int>(:final data) => Text('Future completed without error. Data: $data'),
            Error<int>(:final error) => Text('Future completed with error. Error: $error'),
        };
    },
)
```