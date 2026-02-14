class PurchaseTax {
  final String purchasetaxId;
  final String purchasetaxName;
  final double purchasetaxPercentage;
  final String status;
  final String randomId;

  PurchaseTax({
    required this.purchasetaxId,
    required this.purchasetaxName,
    required this.purchasetaxPercentage,
    required this.status,
    required this.randomId,
  });

  factory PurchaseTax.fromJson(Map<String, dynamic> json) {
    return PurchaseTax(
      purchasetaxId: json['purchasetaxId'] ?? '',
      purchasetaxName: json['purchasetaxName'] ?? '',
      purchasetaxPercentage: (json['purchasetaxPercentage'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      randomId: json['randomId'] ?? '',
    );
  }
}
