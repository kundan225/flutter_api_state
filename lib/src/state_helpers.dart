import 'package:flutter/widgets.dart';

/// Builder that receives the resolved data and returns the success UI.
typedef SuccessBuilder<T> = Widget Function(BuildContext context, T data);

/// Builder that receives the error (and stack trace) and returns the error UI.
typedef ErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// Callback invoked when the user taps the retry button or pulls to refresh.
/// Must return the new [Future] to await.
typedef FutureFactory<T> = Future<T> Function();
