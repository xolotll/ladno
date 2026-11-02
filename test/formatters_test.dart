import 'package:flutter_test/flutter_test.dart';
import 'package:ladno/core/utils/formatters.dart';

void main() {
  test('amount parser accepts decimal comma and spaces', () {
    expect(parseAmount('1 234,50'), 1234.5);
  });
}
