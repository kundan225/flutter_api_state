/// Default stub used when neither `dart:io` nor `dart:html` is available
/// (e.g. during static analysis without a platform context). Returns `true`
/// so the wrapped future is allowed to run; pass a custom `hasNetwork`
/// callback to `ApiStateBuilder` if you need a real check.
Future<bool> defaultHasNetwork({
  String host = 'one.one.one.one',
  Duration timeout = const Duration(seconds: 3),
}) async =>
    true;
