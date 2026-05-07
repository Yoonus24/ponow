enum DiscountMode { percentage, amount, none }

class PurchaseOrderDiscount {
  final DiscountMode mode;
  final double value;

  PurchaseOrderDiscount({this.mode = DiscountMode.none, this.value = 0.0});

  double calculateDiscount(double subtotal) {
    switch (mode) {
      case DiscountMode.percentage:
        return subtotal * (value / 100);
      case DiscountMode.amount:
        return value;
      case DiscountMode.none:
        return 0.0;
    }
  }

  ///IMPORTANT
  String get backendMode {
    switch (mode) {
      case DiscountMode.percentage:
        return "percentage";
      case DiscountMode.amount:
        return "amount";
      case DiscountMode.none:
        return "percentage";
    }
  }

  ///USE THIS ONLY FOR API
  Map<String, dynamic> toBackendJson() {
    return {"discountMode": backendMode, "overallDiscountValue": value};
  }

  factory PurchaseOrderDiscount.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDiscount(
      mode: _parseDiscountMode(json['discountMode']),
      value: (json['overallDiscountValue'] ?? 0).toDouble(),
    );
  }

  static DiscountMode _parseDiscountMode(String? mode) {
    switch (mode) {
      case 'percentage':
        return DiscountMode.percentage;
      case 'amount':
        return DiscountMode.amount;
      default:
        return DiscountMode.none;
    }
  }
}