/// Utility for detecting whether a value should be treated as "empty".
///
/// Treated as empty:
/// * `null`
/// * Empty `Iterable` (includes `List`, `Set`)
/// * Empty `Map`
/// * Empty `String`
class EmptyDetector {
  const EmptyDetector._();

  //hello

  /// Returns `true` if [value] should render the empty state.
  static bool isEmpty(Object? value) {
    if (value == null) return true;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is String) return value.isEmpty;
    return false;
  }


}
