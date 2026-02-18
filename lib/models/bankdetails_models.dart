class Bank {
  final String bankMasterId;
  final String bankName;
  
  Bank({
    required this.bankMasterId,
    required this.bankName,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      bankMasterId: json['bankMasterId'] as String,
      bankName: json['bankName'] as String,
    );
  }
}