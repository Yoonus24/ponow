import 'package:flutter_test/flutter_test.dart';

double calculateGST({required double amount, required double gstPercent}) {
  return amount * gstPercent / 100;
}

void main() {
  test('GST calculation works', () {
    final gst = calculateGST(amount: 1000, gstPercent: 18);

    expect(gst, 180);
  });
}
