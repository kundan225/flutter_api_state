## 0.0.9

* Fix: `enablePullToRefresh: true` inside an unbounded vertical parent
  (e.g. `SingleChildScrollView` + `Column` without `Expanded`) silently
  rendered nothing because the inner `ListView` asserted on unbounded
  height. The widget now detects unbounded constraints, skips the
  `RefreshIndicator` wrap, logs a debug warning explaining the fix,
  and still renders the current state.

## 0.0.8

* Fix: error / no-network states with `enableRetry: true` now lay out
  correctly even when the parent provides unbounded vertical constraints
  (e.g. inside a `SingleChildScrollView` / `Column`). The retry column no
  longer uses `Flexible`; it sizes to its children.

## 0.0.7

* Improve pub.dev platform-support score by switching the network checker
  to the canonical three-file conditional-import pattern (stub + `dart:io`
  + web). Behaviour is unchanged: `dart:io` DNS lookup on
  Android / iOS / Linux / macOS / Windows, no-op on web, sensible default
  when the platform can't be determined statically.

## 0.0.6

* Fix: "Null check operator used on a null value" crash when the no-network
  (or error) branch rendered with `enablePullToRefresh: true` and
  `enableRetry: true`. The pull-to-refresh scrollable shell now bounds its
  child to the viewport height so the inner `Column` + `Flexible` /
  `MainAxisAlignment.center` lay out correctly.

## 0.0.3

* New: optional pre-flight connectivity check. Set `enableNetworkCheck: true`
  to skip the future when offline and show the `noNetwork` widget instead.
  Default check uses `dart:io` DNS lookup on mobile/desktop; web is a no-op.
  Override via `hasNetwork: () async => ...` to plug in `connectivity_plus`
  or your own logic. Works with `enableRetry` (tap to recheck) and
  `enablePullToRefresh`.

## 0.0.2

* Fix: `enablePullToRefresh: true` crashed with "RenderBox was not laid out"
  when the success child was an already-scrollable widget (e.g. `ListView.builder`).
  The widget no longer wraps scrollable children in a `SingleChildScrollView`;
  non-scrollable error/empty branches are wrapped in a `ListView` so pull
  still works.

## 0.0.1

* Initial release of `flutter_api_state`.
* `ApiStateBuilder<T>` with loading / error / empty / success branches.
* `EmptyDetector` for null / empty list / map / set / string detection.
* Built-in retry button (`enableRetry`, optional `retryButtonBuilder`).
* Built-in pull-to-refresh (`enablePullToRefresh`).
