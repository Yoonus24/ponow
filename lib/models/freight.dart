class FreightData {
  String id;
  String name;
  double amount;
  String taxCode;
  String taxType;
  double sgst;
  double cgst;
  double igst;
  double taxAmount;
  double total;

  FreightData({
    required this.id,  
    required this.name,
    required this.amount,
    required this.taxCode,
    required this.taxType,
    required this.sgst,
    required this.cgst,
    required this.igst,
    required this.taxAmount,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "amt": amount,
      "tAmt": taxAmount,
      "totalAmt": total,
      "sgst": sgst,
      "cgst": cgst,
      "igst": igst,
      "taxType": taxType,
      "tCode": taxCode,
    };
  }

  factory FreightData.fromJson(Map<String, dynamic> json) {
    return FreightData(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      amount: (json["amt"] ?? 0).toDouble(),
      taxCode: json["tCode"] ?? "",
      taxType: json["taxType"] ?? "",
      sgst: (json["sgst"] ?? 0).toDouble(),
      cgst: (json["cgst"] ?? 0).toDouble(),
      igst: (json["igst"] ?? 0).toDouble(),
      taxAmount: (json["tAmt"] ?? 0).toDouble(),
      total: (json["totalAmt"] ?? 0).toDouble(),
    );
  }
}
