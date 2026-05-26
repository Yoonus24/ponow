import 'package:flutter_test/flutter_test.dart';

double calculateTotal({
  required double amount,
  required double discountPercent,
}) {
  return amount - (amount * discountPercent / 100);
}

void main() {
  test('Discount calculation works correctly', () {
    final result = calculateTotal(
      amount: 1000,
      discountPercent: 10,
    );

    expect(result, 900);
  });
}