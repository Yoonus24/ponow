class AIInvoiceResponse {
  final bool success;

  final String poId;

  final String poNumber;

  final double confidence;

  final String invoiceNumber;

  final double vendorMatchConfidence;

  final double itemMatchConfidence;

  final String vendorName;

  final String invoiceDate;

  final List<AIMatchedItem> matchedItems;

  final String aiSummary;

  final String summaryConfidence;

  final String recommendation;

  final Map<String, dynamic> analysisData;

  final String processedAt;

  AIInvoiceResponse({
    required this.success,

    required this.poId,

    required this.poNumber,

    required this.invoiceNumber,

    required this.vendorMatchConfidence,

    required this.itemMatchConfidence,

    required this.confidence,

    required this.invoiceDate,

    required this.vendorName,

    required this.matchedItems,

    required this.aiSummary,

    required this.summaryConfidence,

    required this.recommendation,

    required this.analysisData,

    required this.processedAt,
  });

  factory AIInvoiceResponse.fromJson(Map<String, dynamic> json) {
    return AIInvoiceResponse(
      success: json["success"] ?? false,

      poId: json["poId"] ?? "",

      poNumber: json["poNumber"] ?? "",

      invoiceNumber: json["invoiceNumber"] ?? "",

      invoiceDate: json["invoiceDate"] ?? "",

      vendorName: json["vendorName"] ?? "",

      confidence: (json["itemMatchConfidence"] ?? 0).toDouble(),

      vendorMatchConfidence: (json["vendorMatchConfidence"] ?? 0).toDouble(),

      itemMatchConfidence: (json["itemMatchConfidence"] ?? 0).toDouble(),

      matchedItems: (json["matchedItems"] as List? ?? [])
          .map((e) => AIMatchedItem.fromJson(e))
          .toList(),

      aiSummary: json["analysis"]?["summary"] ?? "",

      summaryConfidence: json["analysis"]?["riskLevel"] ?? "medium",

      recommendation: json["analysis"]?["recommendation"] ?? "",

      analysisData: json["analysis"]?["analysisData"] ?? {},

      processedAt: json["processedAt"] ?? "",
    );
  }
}

class AIMatchedItem {
  // =====================================================
  // BASIC
  // =====================================================

  final String itemName;

  final double receivedQuantity;

  final double newPrice;

  // =====================================================
  // AMOUNTS
  // =====================================================

  final double amount;

  final double taxableAmount;

  final double finalAmount;

  // =====================================================
  // DISCOUNT
  // =====================================================

  final double befTaxDiscount;

  final double afTaxDiscount;

  final double discountPercent;

  final double discountAmount;

  // =====================================================
  // TAX
  // =====================================================

  final double taxPercent;

  final double taxAmount;

  // =====================================================
  // CGST
  // =====================================================

  final double cgstPercent;

  final double cgstAmount;

  // =====================================================
  // SGST
  // =====================================================

  final double sgstPercent;

  final double sgstAmount;

  // =====================================================
  // IGST
  // =====================================================

  final double igstPercent;

  final double igstAmount;

  // =====================================================
  // OTHER
  // =====================================================

  final String expiryDate;

  final double confidence;

  AIMatchedItem({
    required this.itemName,

    required this.receivedQuantity,

    required this.newPrice,

    required this.amount,

    required this.taxableAmount,

    required this.finalAmount,

    required this.befTaxDiscount,

    required this.afTaxDiscount,

    required this.discountPercent,

    required this.discountAmount,

    required this.taxPercent,

    required this.taxAmount,

    required this.cgstPercent,

    required this.cgstAmount,

    required this.sgstPercent,

    required this.sgstAmount,

    required this.igstPercent,

    required this.igstAmount,

    required this.expiryDate,

    required this.confidence,
  });

  factory AIMatchedItem.fromJson(Map<String, dynamic> json) {
    return AIMatchedItem(
      // =================================================
      // BASIC
      // =================================================
      itemName: json["itemName"] ?? "",

      receivedQuantity: (json["receivedQuantity"] ?? 0).toDouble(),

      newPrice: (json["newPrice"] ?? 0).toDouble(),

      // =================================================
      // AMOUNTS
      // =================================================
      amount: (json["amount"] ?? 0).toDouble(),

      taxableAmount: (json["taxableAmount"] ?? 0).toDouble(),

      finalAmount: (json["finalAmount"] ?? 0).toDouble(),

      // =================================================
      // DISCOUNT
      // =================================================
      befTaxDiscount: (json["befTaxDiscount"] ?? 0).toDouble(),

      afTaxDiscount: (json["afTaxDiscount"] ?? 0).toDouble(),

      discountPercent: (json["discountPercent"] ?? 0).toDouble(),

      discountAmount: (json["discountAmount"] ?? 0).toDouble(),

      // =================================================
      // TAX
      // =================================================
      taxPercent: (json["taxPercent"] ?? 0).toDouble(),

      taxAmount: (json["taxAmount"] ?? 0).toDouble(),

      // =================================================
      // CGST
      // =================================================
      cgstPercent: (json["cgstPercent"] ?? 0).toDouble(),

      cgstAmount: (json["cgstAmount"] ?? 0).toDouble(),

      // =================================================
      // SGST
      // =================================================
      sgstPercent: (json["sgstPercent"] ?? 0).toDouble(),

      sgstAmount: (json["sgstAmount"] ?? 0).toDouble(),

      // =================================================
      // IGST
      // =================================================
      igstPercent: (json["igstPercent"] ?? 0).toDouble(),

      igstAmount: (json["igstAmount"] ?? 0).toDouble(),

      // =================================================
      // OTHER
      // =================================================
      expiryDate: json["expiryDate"] ?? "",

      confidence: (json["confidence"] ?? 0).toDouble(),
    );
  }
}

class POSuggestionResponse {
  final bool success;

  final List<POSuggestion> suggestedPOs;

  final AutoSuggestedPO? autoSuggestedPO;

  final Map<String, dynamic> invoiceData;

  POSuggestionResponse({
    required this.success,
    required this.suggestedPOs,
    required this.autoSuggestedPO,
    required this.invoiceData,
  });

  factory POSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return POSuggestionResponse(
      success: json["success"] ?? false,

      invoiceData: Map<String, dynamic>.from(json["invoiceData"] ?? {}),

      suggestedPOs: (json["suggestedPOs"] as List? ?? [])
          .map((e) => POSuggestion.fromJson(e))
          .toList(),

      autoSuggestedPO: json["autoSuggestedPO"] == null
          ? null
          : AutoSuggestedPO.fromJson(json["autoSuggestedPO"]),
    );
  }
}

class POSuggestion {
  final String poId;

  final String poNumber;

  final int score;

  final int matchedItems;

  final int totalItems;

  final String reason;

  POSuggestion({
    required this.poId,
    required this.poNumber,
    required this.score,
    required this.matchedItems,
    required this.totalItems,
    required this.reason,
  });

  factory POSuggestion.fromJson(Map<String, dynamic> json) {
    return POSuggestion(
      poId: json["poId"] ?? "",
      poNumber: json["poNumber"] ?? "",
      score: json["score"] ?? 0,
      matchedItems: json["matchedItems"] ?? 0,
      totalItems: json["totalItems"] ?? 0,
      reason: json["reason"] ?? "",
    );
  }
}

class AutoSuggestedPO {
  final String poId;

  final String poNumber;

  final int score;

  AutoSuggestedPO({
    required this.poId,
    required this.poNumber,
    required this.score,
  });

  factory AutoSuggestedPO.fromJson(Map<String, dynamic> json) {
    return AutoSuggestedPO(
      poId: json["poId"] ?? "",
      poNumber: json["poNumber"] ?? "",
      score: json["score"] ?? 0,
    );
  }
}
