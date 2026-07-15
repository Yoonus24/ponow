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
  final double roundOff;

  // =====================================================
  // NEW SUMMARY FIELDS FROM BACKEND
  // =====================================================
  final double printedSubTotal;
  final double printedTotalTax;
  final double printedTotalCGST;
  final double printedTotalSGST;
  final double printedTotalIGST;
  final double printedTotalCESS;
  final double printedGrandTotal;
  final double freightAmount;

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
    required this.roundOff,
    // =====================================================
    // NEW SUMMARY FIELDS
    // =====================================================
    required this.printedSubTotal,
    required this.printedTotalTax,
    required this.printedTotalCGST,
    required this.printedTotalSGST,
    required this.printedTotalIGST,
    required this.printedTotalCESS,
    required this.printedGrandTotal,
    required this.freightAmount,
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
      roundOff: (json["roundOff"] ?? 0).toDouble(),

      // =====================================================
      // NEW SUMMARY FIELDS FROM JSON
      // =====================================================
      printedSubTotal: (json["printedSubTotal"] ?? 0).toDouble(),
      printedTotalTax: (json["printedTotalTax"] ?? 0).toDouble(),
      printedTotalCGST: (json["printedTotalCGST"] ?? 0).toDouble(),
      printedTotalSGST: (json["printedTotalSGST"] ?? 0).toDouble(),
      printedTotalIGST: (json["printedTotalIGST"] ?? 0).toDouble(),
      printedTotalCESS: (json["printedTotalCESS"] ?? 0).toDouble(),
      printedGrandTotal: (json["printedGrandTotal"] ?? 0).toDouble(),
      freightAmount: (json["freightAmount"] ?? 0).toDouble(),
    );
  }

  // =====================================================
  // OPTIONAL: toJson method for debugging/serialization
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'poId': poId,
      'poNumber': poNumber,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate,
      'vendorName': vendorName,
      'confidence': confidence,
      'vendorMatchConfidence': vendorMatchConfidence,
      'itemMatchConfidence': itemMatchConfidence,
      'matchedItems': matchedItems.map((e) => e.toJson()).toList(),
      'aiSummary': aiSummary,
      'summaryConfidence': summaryConfidence,
      'recommendation': recommendation,
      'analysisData': analysisData,
      'processedAt': processedAt,
      'roundOff': roundOff,
      'printedSubTotal': printedSubTotal,
      'printedTotalTax': printedTotalTax,
      'printedTotalCGST': printedTotalCGST,
      'printedTotalSGST': printedTotalSGST,
      'printedTotalIGST': printedTotalIGST,
      'printedTotalCESS': printedTotalCESS,
      'printedGrandTotal': printedGrandTotal,
      'freightAmount': freightAmount,
    };
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

  // =====================================================
  // OPTIONAL: toJson method for debugging/serialization
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'receivedQuantity': receivedQuantity,
      'newPrice': newPrice,
      'amount': amount,
      'taxableAmount': taxableAmount,
      'finalAmount': finalAmount,
      'befTaxDiscount': befTaxDiscount,
      'afTaxDiscount': afTaxDiscount,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'taxPercent': taxPercent,
      'taxAmount': taxAmount,
      'cgstPercent': cgstPercent,
      'cgstAmount': cgstAmount,
      'sgstPercent': sgstPercent,
      'sgstAmount': sgstAmount,
      'igstPercent': igstPercent,
      'igstAmount': igstAmount,
      'expiryDate': expiryDate,
      'confidence': confidence,
    };
  }
}

class POSuggestionResponse {
  final bool success;
  final List<POSuggestion> suggestedPOs;
  final AutoSuggestedPO? autoSuggestedPO;
  final Map<String, dynamic> invoiceData;
  final String? cacheKey;

  POSuggestionResponse({
    required this.success,
    required this.suggestedPOs,
    required this.autoSuggestedPO,
    required this.invoiceData,
    this.cacheKey,
  });

  factory POSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return POSuggestionResponse(
      success: json["success"] ?? false,
      cacheKey: json["cacheKey"],
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
