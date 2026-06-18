/// Web stub: the browser handles its own offline behavior, so the default
/// check is a no-op that always reports "online". Pass a custom
/// `hasNetwork` callback to `ApiStateBuilder` if you need browser-aware
/// detection (e.g. via `dart:html`'s `window.navigator.onLine`).
Future<bool> defaultHasNetwork({
  String host = 'one.one.one.one',
  Duration timeout = const Duration(seconds: 3),
}) async =>
    true;
