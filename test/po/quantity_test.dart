import 'package:flutter_test/flutter_test.dart';

bool isValidQty({
  required int ordered,
  required int received,
}) {
  return received <= ordered;
}

void main() {
  test('Received qty should not exceed ordered qty', () {
    final result = isValidQty(
      ordered: 10,
      received: 5,
    );

    expect(result, true);
  });

  test('Excess qty should fail', () {
    final result = isValidQty(
      ordered: 10,
      received: 15,
    );

    expect(result, false);
  });
}