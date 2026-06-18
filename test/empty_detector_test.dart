import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_api_state/flutter_api_state.dart';

void main() {
  group('EmptyDetector', () {
    test('null is empty', () => expect(EmptyDetector.isEmpty(null), isTrue));
    test('empty list is empty',
        () => expect(EmptyDetector.isEmpty(<int>[]), isTrue));
    test('empty map is empty',
        () => expect(EmptyDetector.isEmpty(<String, int>{}), isTrue));
    test('empty set is empty',
        () => expect(EmptyDetector.isEmpty(<int>{}), isTrue));
    test('empty string is empty',
        () => expect(EmptyDetector.isEmpty(''), isTrue));

    test('non-empty list is not empty',
        () => expect(EmptyDetector.isEmpty([1]), isFalse));
    test('non-empty map is not empty',
        () => expect(EmptyDetector.isEmpty({'a': 1}), isFalse));
    test('non-empty set is not empty',
        () => expect(EmptyDetector.isEmpty({1}), isFalse));
    test('non-empty string is not empty',
        () => expect(EmptyDetector.isEmpty('x'), isFalse));
    test('arbitrary object is not empty',
        () => expect(EmptyDetector.isEmpty(42), isFalse));
    test('bool false is not empty (scalar)',
        () => expect(EmptyDetector.isEmpty(false), isFalse));
  });
}
