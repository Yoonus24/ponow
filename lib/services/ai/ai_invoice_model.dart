class AIInvoiceResponse {
  final bool success;

  final String poId;

  final String poNumber;

  final String invoiceNumber;
  final String vendorName;
  final String invoiceDate;

  final List<AIMatchedItem> matchedItems;

  AIInvoiceResponse({
    required this.success,

    required this.poId,

    required this.poNumber,

    required this.invoiceNumber,

    required this.invoiceDate,
required this.vendorName,
    required this.matchedItems,
  });

  factory AIInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return AIInvoiceResponse(
      success: json["success"] ?? false,

      poId: json["poId"] ?? "",

      poNumber: json["poNumber"] ?? "",

      invoiceNumber: json["invoiceNumber"] ?? "",

      invoiceDate: json["invoiceDate"] ?? "",

      vendorName: json["vendorName"] ?? "",

      matchedItems: (json["matchedItems"] as List? ?? [])
          .map((e) => AIMatchedItem.fromJson(e))
          .toList(),
    );
  }
}

class AIMatchedItem {
  final String itemName;

  final double receivedQuantity;

  final double newPrice;

  final double befTaxDiscount;

  final double afTaxDiscount;

  final String expiryDate;

  final double confidence;

  AIMatchedItem({
    required this.itemName,

    required this.receivedQuantity,

    required this.newPrice,

    required this.befTaxDiscount,

    required this.afTaxDiscount,

    required this.expiryDate,

    required this.confidence,
  });

  factory AIMatchedItem.fromJson(Map<String, dynamic> json) {
    return AIMatchedItem(
      itemName: json["itemName"] ?? "",

      receivedQuantity: (json["receivedQuantity"] ?? 0).toDouble(),

      newPrice: (json["newPrice"] ?? 0).toDouble(),

      befTaxDiscount: (json["befTaxDiscount"] ?? 0).toDouble(),

      afTaxDiscount: (json["afTaxDiscount"] ?? 0).toDouble(),

      expiryDate: json["expiryDate"] ?? "",

      confidence: (json["confidence"] ?? 0).toDouble(),
    );
  }
}
