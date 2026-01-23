enum DiscountMode { percentage, fixedAmount, none }

class PurchaseOrderDiscount {
  final DiscountMode mode;
  final double value;

  PurchaseOrderDiscount({this.mode = DiscountMode.none, this.value = 0.0});

  double calculateDiscount(double subtotal) {
    switch (mode) {
      case DiscountMode.percentage:
        return subtotal * (value / 100);
      case DiscountMode.fixedAmount:
        return value;
      case DiscountMode.none:
        return 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {'mode': mode.toString().split('.').last, 'value': value};
  }

  factory PurchaseOrderDiscount.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDiscount(
      mode: _parseDiscountMode(json['mode']),
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  static DiscountMode _parseDiscountMode(String mode) {
    switch (mode) {
      case 'percentage':
        return DiscountMode.percentage;
      case 'fixedAmount':
        return DiscountMode.fixedAmount;
      default:
        return DiscountMode.none;
    }
  }
}