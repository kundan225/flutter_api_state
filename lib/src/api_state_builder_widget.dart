import 'package:flutter/material.dart';

import 'empty_detector.dart';
import 'network_checker.dart';
import 'state_helpers.dart';

/// A widget that resolves a [Future] and renders one of four states:
/// loading, error, empty, or success — replacing repetitive
/// [FutureBuilder] boilerplate.
///
/// Optionally supports a retry button (shown on error) and pull-to-refresh.
///
/// Example:
/// ```dart
/// ApiStateBuilder<List<User>>(
///   future: () => fetchUsers(),
///   loading: const CircularProgressIndicator(),
///   error: (ctx, e, _) => Text('$e'),
///   empty: const Text('No users'),
///   success: (ctx, users) => UserList(users),
///   enableRetry: true,
///   enablePullToRefresh: true,
/// )
/// ```
class ApiStateBuilder<T> extends StatefulWidget {
  const ApiStateBuilder({
    super.key,
    required this.future,
    required this.success,
    this.loading,
    this.error,
    this.empty,
    this.enableRetry = false,
    this.retryButtonBuilder,
    this.enablePullToRefresh = false,
    this.refreshIndicatorColor,
    this.enableNetworkCheck = false,
    this.noNetwork,
    this.hasNetwork,
  });

  /// Factory that produces the [Future] to await. A factory (rather than a
  /// raw [Future]) is required so retry and pull-to-refresh can re-invoke it.
  final FutureFactory<T> future;

  /// Widget shown while the future is pending. Defaults to a centered
  /// [CircularProgressIndicator] if omitted.
  final Widget? loading;

  /// Builder for the error UI. Receives the error and stack trace.
  final ErrorBuilder? error;

  /// Widget shown when the resolved data is considered empty
  /// (see [EmptyDetector]).
  final Widget? empty;

  /// Builder for the success UI. Receives the resolved (non-empty) data.
  final SuccessBuilder<T> success;

  /// If `true`, a retry button is appended below the error widget.
  final bool enableRetry;

  /// Optional custom retry button builder. If omitted and [enableRetry] is
  /// `true`, a default [ElevatedButton] with label "Retry" is used.
  final Widget Function(BuildContext context, VoidCallback onRetry)?
      retryButtonBuilder;

  /// If `true`, wraps the success/empty/error UI in a [RefreshIndicator]
  /// so the user can pull down to re-invoke [future].
  final bool enablePullToRefresh;

  /// Optional color for the pull-to-refresh indicator.
  final Color? refreshIndicatorColor;

  /// If `true`, runs a connectivity check before invoking [future]. When the
  /// device is offline, the [noNetwork] widget is shown instead of running
  /// the request — and the user can retry once they reconnect (the retry
  /// button is shown automatically if [enableRetry] is `true`).
  final bool enableNetworkCheck;

  /// Widget shown when [enableNetworkCheck] is `true` and the device is
  /// offline. Defaults to a centered "No internet connection" message.
  final Widget? noNetwork;

  /// Custom connectivity check. Defaults to a DNS lookup via `dart:io` on
  /// mobile/desktop and a no-op (always `true`) on web. Provide your own
  /// callback (e.g. wrapping `connectivity_plus`) for finer control.
  final Future<bool> Function()? hasNetwork;

  @override
  State<ApiStateBuilder<T>> createState() => _ApiStateBuilderState<T>();
}

/// Sentinel thrown internally when the connectivity check reports offline.
/// Caught by the widget to render the `noNetwork` branch.
class _NoNetworkException implements Exception {
  const _NoNetworkException();
}

class _ApiStateBuilderState<T> extends State<ApiStateBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = _start();
  }

  Future<T> _start() async {
    if (widget.enableNetworkCheck) {
      final check = widget.hasNetwork ?? defaultHasNetwork;
      final online = await check();
      if (!online) throw const _NoNetworkException();
    }
    return widget.future();
  }

  void _retry() {
    setState(() {
      _future = _start();
    });
  }

  Future<void> _refresh() {
    final next = _start();
    setState(() {
      _future = next;
    });
    return next.catchError((_) => null as T);
  }

  Widget _wrapWithRefresh(Widget child) {
    if (!widget.enablePullToRefresh) return child;

    // RefreshIndicator requires a scrollable descendant.
    // - If the child is already a ScrollView (ListView, GridView,
    //   CustomScrollView, SingleChildScrollView, ...) or a raw Scrollable,
    //   pass it through untouched. Wrapping an unbounded scrollable in
    //   another SingleChildScrollView causes "RenderBox was not laid out".
    // - Otherwise (Text, Column, Center, ...), wrap in a single-item ListView
    //   so pull-down still works.
    final scrollable = (child is ScrollView || child is Scrollable)
        ? child
        : LayoutBuilder(
            builder: (context, constraints) {
              // Bound the child to the viewport height so its descendants
              // (Column / Flexible / mainAxisAlignment.center in the
              // no-network / error widgets) have a finite parent height.
              // ListView gives its direct children unbounded height by
              // default, which breaks Flexible.
              final wrapped = constraints.hasBoundedHeight
                  ? SizedBox(height: constraints.maxHeight, child: child)
                  : child;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [wrapped],
              );
            },
          );

    return RefreshIndicator(
      color: widget.refreshIndicatorColor,
      onRefresh: _refresh,
      child: scrollable,
    );
  }

  Widget _buildNoNetwork(BuildContext context) {
    final body = widget.noNetwork ??
        const Center(child: Text('No internet connection'));
    if (!widget.enableRetry) return body;
    final retryBtn = widget.retryButtonBuilder?.call(context, _retry) ??
        ElevatedButton(onPressed: _retry, child: const Text('Retry'));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: body),
        const SizedBox(height: 12),
        retryBtn,
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error, StackTrace? stack) {
    final errorWidget = widget.error?.call(context, error, stack) ??
        Center(child: Text('$error'));
    if (!widget.enableRetry) return errorWidget;
    final retryBtn = widget.retryButtonBuilder?.call(context, _retry) ??
        ElevatedButton(onPressed: _retry, child: const Text('Retry'));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: errorWidget),
        const SizedBox(height: 12),
        retryBtn,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (snapshot.error is _NoNetworkException) {
            return _wrapWithRefresh(_buildNoNetwork(context));
          }
          return _wrapWithRefresh(
            _buildError(context, snapshot.error!, snapshot.stackTrace),
          );
        }

        final data = snapshot.data;
        if (EmptyDetector.isEmpty(data)) {
          return _wrapWithRefresh(
            widget.empty ?? const Center(child: Text('No data')),
          );
        }

        return _wrapWithRefresh(widget.success(context, data as T));
      },
    );
  }
}
