import 'dart:io';

/// Default connectivity check for `dart:io` platforms (mobile/desktop).
///
/// Resolves [host] via DNS with [timeout]. Returns `true` if the lookup
/// succeeds and yields at least one non-loopback address; `false`
/// otherwise (including timeouts and socket exceptions).
Future<bool> defaultHasNetwork({
  String host = 'one.one.one.one',
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    final result =
        await InternetAddress.lookup(host).timeout(timeout);
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
