import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_state/flutter_api_state.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('ApiStateBuilder', () {
    testWidgets('shows loading widget while future is pending',
        (tester) async {
      final completer = Completer<List<int>>();
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () => completer.future,
          loading: const Text('LOADING'),
          success: (_, data) => Text('OK ${data.length}'),
        ),
      ));
      expect(find.text('LOADING'), findsOneWidget);
      completer.complete([1]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows success widget with typed data', (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<String>>(
          future: () async => ['a', 'b'],
          loading: const SizedBox.shrink(),
          success: (_, data) => Text('items=${data.length}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('items=2'), findsOneWidget);
    });

    testWidgets('shows error widget with exception', (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<int>(
          future: () async => throw Exception('boom'),
          loading: const SizedBox.shrink(),
          error: (_, e, __) => Text('ERR:$e'),
          success: (_, data) => Text('$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('ERR:Exception: boom'), findsOneWidget);
    });

    testWidgets('shows empty widget for empty list', (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () async => <int>[],
          loading: const SizedBox.shrink(),
          empty: const Text('EMPTY'),
          success: (_, data) => Text('items=${data.length}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('EMPTY'), findsOneWidget);
    });

    testWidgets('shows empty widget for empty map', (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<Map<String, dynamic>>(
          future: () async => <String, dynamic>{},
          loading: const SizedBox.shrink(),
          empty: const Text('EMPTY-MAP'),
          success: (_, data) => Text('keys=${data.length}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('EMPTY-MAP'), findsOneWidget);
    });

    testWidgets('shows empty widget for null data', (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<String?>(
          future: () async => null,
          loading: const SizedBox.shrink(),
          empty: const Text('NULL-EMPTY'),
          success: (_, data) => Text('$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('NULL-EMPTY'), findsOneWidget);
    });

    testWidgets('generic support: bool true renders as success',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<bool>(
          future: () async => true,
          loading: const SizedBox.shrink(),
          success: (_, data) => Text('bool=$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('bool=true'), findsOneWidget);
    });

    testWidgets('generic support: String passes through', (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<String>(
          future: () async => 'hi',
          loading: const SizedBox.shrink(),
          success: (_, data) => Text('s=$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('s=hi'), findsOneWidget);
    });

    testWidgets('retry button re-invokes future factory', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<int>(
          future: () async {
            attempts++;
            if (attempts < 2) throw Exception('fail');
            return 42;
          },
          loading: const SizedBox.shrink(),
          error: (_, e, __) => const Text('ERR'),
          enableRetry: true,
          success: (_, data) => Text('v=$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('ERR'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('v=42'), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('custom retry button builder is used when provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<int>(
          future: () async => throw Exception('x'),
          loading: const SizedBox.shrink(),
          error: (_, e, __) => const Text('ERR'),
          enableRetry: true,
          retryButtonBuilder: (_, onRetry) => TextButton(
            onPressed: onRetry,
            child: const Text('TRY-AGAIN'),
          ),
          success: (_, data) => Text('$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('TRY-AGAIN'), findsOneWidget);
    });

    testWidgets('pull-to-refresh wraps content in a RefreshIndicator '
        'and re-invokes the future on refresh', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () async {
            attempts++;
            return [attempts];
          },
          loading: const SizedBox.shrink(),
          enablePullToRefresh: true,
          success: (_, data) => Text('n=${data.first}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('n=1'), findsOneWidget);

      // Sanity: pull-to-refresh wraps non-scrollable child in a
      // RefreshIndicator + ListView.
      final refresh = find.byType(RefreshIndicator);
      expect(refresh, findsOneWidget);
      expect(find.descendant(of: refresh, matching: find.byType(ListView)),
          findsOneWidget);

      // Invoke the refresh callback directly (avoiding the painter's
      // size-assert quirk in the small default test surface).
      final indicator = tester.widget<RefreshIndicator>(refresh);
      await indicator.onRefresh();
      await tester.pumpAndSettle();

      expect(attempts, greaterThanOrEqualTo(2));
      expect(find.text('n=$attempts'), findsOneWidget);
    });

    testWidgets(
        'pull-to-refresh works when success child is already a ListView '
        '(regression: 0.0.1 crashed with "RenderBox was not laid out")',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () async => [1, 2, 3],
          loading: const SizedBox.shrink(),
          enablePullToRefresh: true,
          success: (_, data) => ListView.builder(
            itemCount: data.length,
            itemBuilder: (_, i) => Text('item-${data[i]}'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
      expect(find.text('item-3'), findsOneWidget);
      // The success ListView is the scrollable — we should NOT have wrapped
      // it in an extra ListView shell.
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('network check: offline -> noNetwork widget, future NOT called',
        (tester) async {
      var futureCalls = 0;
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () async {
            futureCalls++;
            return [1];
          },
          loading: const SizedBox.shrink(),
          enableNetworkCheck: true,
          hasNetwork: () async => false,
          noNetwork: const Text('OFFLINE'),
          success: (_, data) => Text('n=${data.length}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(futureCalls, 0);
    });

    testWidgets(
        'network check: offline + enableRetry shows retry; tap retries '
        'and succeeds once network is restored', (tester) async {
      var online = false;
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<int>(
          future: () async => 7,
          loading: const SizedBox.shrink(),
          enableNetworkCheck: true,
          enableRetry: true,
          hasNetwork: () async => online,
          noNetwork: const Text('OFFLINE'),
          success: (_, data) => Text('v=$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      online = true;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('v=7'), findsOneWidget);
    });

    testWidgets('network check: online -> future runs normally',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<int>(
          future: () async => 3,
          loading: const SizedBox.shrink(),
          enableNetworkCheck: true,
          hasNetwork: () async => true,
          noNetwork: const Text('OFFLINE'),
          success: (_, data) => Text('v=$data'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('v=3'), findsOneWidget);
      expect(find.text('OFFLINE'), findsNothing);
    });

    testWidgets(
        'no-network + pull-to-refresh + retry lays out without errors '
        '(regression: 0.0.5 crashed with "Null check operator used on null")',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () async => [1],
          loading: const SizedBox.shrink(),
          enableNetworkCheck: true,
          hasNetwork: () async => false,
          enableRetry: true,
          enablePullToRefresh: true,
          noNetwork: const Center(child: Text('OFFLINE')),
          success: (_, data) => Text('n=${data.length}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('does not wrap in RefreshIndicator when disabled',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<List<int>>(
          future: () async => [1],
          loading: const SizedBox.shrink(),
          success: (_, data) => Text('n=${data.first}'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets('default loading is shown when none provided',
        (tester) async {
      final completer = Completer<int>();
      await tester.pumpWidget(_wrap(
        ApiStateBuilder<int>(
          future: () => completer.future,
          success: (_, data) => Text('$data'),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(1);
      await tester.pumpAndSettle();
    });
  });
}
