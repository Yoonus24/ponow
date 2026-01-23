// models/item_detail.dart
class ItemDetail {
  final String itemId;
  final String? itemName;
  double? nos;
  double? grnReturnNos;
  String? purchasecategoryName;
  String? purchasesubcategoryName;
  double? eachQuantity;
  double? grnReturnEachQuantity;
  final double? quantity;
  final String? uom;
  final double? purchasetaxName;
  double? totalQuantity;
  double? receivedQuantity;
  double? returnedQuantity;
  double? unitPrice;
  double? befTaxDiscount;
  double? afTaxDiscount;
  double? befTaxDiscountAmount;
  double? afTaxDiscountAmount;
  double? discountAmount;
  double? taxAmount;
  double? totalPrice;
  String? taxType;
  double? sgst;
  double? cgst;
  double? igst;
  String? status;
  String? expiryDate;
  final String? barcode;
  double? returnedTotalPrice;
  double? returnedTaxAmount;
  double? returnedDiscountAmount;
  double? returnedFinalPrice;
  double? returnedSgst;
  double? returnedCgst;
  double? finalPrice;
  List<Map<String, dynamic>>? returnHistory;

  ItemDetail({
    required this.itemId,
    this.itemName,
    this.nos,
    this.grnReturnNos,
    this.purchasecategoryName,
    this.purchasesubcategoryName,
    this.eachQuantity,
    this.grnReturnEachQuantity,
    this.quantity,
    this.uom,
    this.purchasetaxName,
    this.totalQuantity,
    this.receivedQuantity,
    this.returnedQuantity,
    this.unitPrice,
    this.befTaxDiscount,
    this.afTaxDiscount,
    this.befTaxDiscountAmount,
    this.afTaxDiscountAmount,
    this.discountAmount,
    this.taxAmount,
    this.totalPrice,
    this.taxType,
    this.sgst,
    this.cgst,
    this.igst,
    this.status,
    this.expiryDate,
    this.barcode,
    this.returnedTotalPrice,
    this.returnedTaxAmount,
    this.returnedDiscountAmount,
    this.returnedFinalPrice,
    this.returnedSgst,
    this.returnedCgst,
    this.finalPrice,
    this.returnHistory,
  }) {
    // Set taxType based on sgst, cgst, and igst values
    taxType ??= (sgst != null && sgst! > 0) || (cgst != null && cgst! > 0)
          ? 'cgst_sgst'
          : (igst != null && igst! > 0)
          ? 'igst'
          : 'cgst_sgst';
  }

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String?,
      nos:
          (json['nos'] as num?)?.toDouble() ??
          double.tryParse(json['nos']?.toString() ?? '') ??
          0.0,
      grnReturnNos:
          (json['grnReturnNos'] as num?)?.toDouble() ??
          double.tryParse(json['grnReturnNos']?.toString() ?? '') ??
          0.0,
      purchasecategoryName: json['purchasecategoryName'] as String?,
      purchasesubcategoryName: json['purchasesubcategoryName'] as String?,
      eachQuantity:
          (json['eachQuantity'] as num?)?.toDouble() ??
          double.tryParse(json['eachQuantity']?.toString() ?? '') ??
          0.0,
      grnReturnEachQuantity:
          (json['grnReturnEachQuantity'] as num?)?.toDouble() ??
          double.tryParse(json['grnReturnEachQuantity']?.toString() ?? '') ??
          0.0,
      quantity: (json['quantity'] as num?)?.toDouble(),
      uom: json['uom'] as String?,
      purchasetaxName: double.tryParse(
        json['purchasetaxName']?.toString() ?? '0.0',
      ),
      totalQuantity:
          (json['totalQuantity'] as num?)?.toDouble() ??
          double.tryParse(json['totalQuantity']?.toString() ?? '') ??
          0.0,
      receivedQuantity:
          (json['receivedQuantity'] as num?)?.toDouble() ??
          double.tryParse(json['receivedQuantity']?.toString() ?? '') ??
          0.0,
      returnedQuantity:
          (json['returnedQuantity'] as num?)?.toDouble() ??
          double.tryParse(json['returnedQuantity']?.toString() ?? '') ??
          0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      befTaxDiscount: (json['befTaxDiscount'] as num?)?.toDouble(),
      afTaxDiscount: (json['afTaxDiscount'] as num?)?.toDouble(),
      befTaxDiscountAmount: (json['befTaxDiscountAmount'] as num?)?.toDouble(),
      afTaxDiscountAmount: (json['afTaxDiscountAmount'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      taxType: json['taxType'] as String?,
      sgst: (json['sgst'] as num?)?.toDouble(),
      cgst: (json['cgst'] as num?)?.toDouble(),
      igst: (json['igst'] as num?)?.toDouble(),
      status: json['status'] as String?,
      expiryDate: json['expiryDate'] as String?,
      barcode: json['barcode'] as String?,
      returnedTotalPrice: (json['returnedTotalPrice'] as num?)?.toDouble(),
      returnedTaxAmount: (json['returnedTaxAmount'] as num?)?.toDouble(),
      returnedDiscountAmount: (json['returnedDiscountAmount'] as num?)
          ?.toDouble(),
      returnedFinalPrice: (json['returnedFinalPrice'] as num?)?.toDouble(),
      returnedSgst: (json['returnedSgst'] as num?)?.toDouble(),
      returnedCgst: (json['returnedCgst'] as num?)?.toDouble(),
      returnHistory: json['returnHistory'] != null
          ? List<Map<String, dynamic>>.from(json['returnHistory'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName ?? '',
      'nos': nos ?? 0.0,
      'grnReturnNos': grnReturnNos ?? 0.0,
      'purchasecategoryName': purchasecategoryName ?? '',
      'purchasesubcategoryName': purchasesubcategoryName ?? '',
      'eachQuantity': eachQuantity ?? 0.0,
      'grnReturnEachQuantity': grnReturnEachQuantity ?? 0.0,
      'quantity': quantity ?? 0.0,
      'uom': uom ?? '',
      'purchasetaxName': purchasetaxName ?? 0.0,
      'totalQuantity': totalQuantity ?? 0.0,
      'receivedQuantity': receivedQuantity ?? 0.0,
      'returnedQuantity': returnedQuantity ?? 0.0,
      'unitPrice': unitPrice ?? 0.0,
      'befTaxDiscount': befTaxDiscount ?? 0.0,
      'afTaxDiscount': afTaxDiscount ?? 0.0,
      'befTaxDiscountAmount': befTaxDiscountAmount ?? 0.0,
      'afTaxDiscountAmount': afTaxDiscountAmount ?? 0.0,
      'discountAmount': discountAmount ?? 0.0,
      'taxAmount': taxAmount ?? 0.0,
      'totalPrice': totalPrice ?? 0.0,
      'taxType': taxType ?? 'cgst_sgst',
      'sgst': sgst ?? 0.0,
      'cgst': cgst ?? 0.0,
      'igst': igst ?? 0.0,
      'status': status ?? '',
      'expiryDate': expiryDate ?? '',
      'barcode': barcode ?? '',
      'returnedTotalPrice': returnedTotalPrice ?? 0.0,
      'returnedTaxAmount': returnedTaxAmount ?? 0.0,
      'returnedDiscountAmount': returnedDiscountAmount ?? 0.0,
      'returnedFinalPrice': returnedFinalPrice ?? 0.0,
      'returnedSgst': returnedSgst ?? 0.0,
      'returnedCgst': returnedCgst ?? 0.0,
      'finalPrice': finalPrice ?? 0.0,
      'returnHistory': returnHistory ?? [],
    };
  }
}

class ReturnItem {
  final String itemId;
  final double? nos;
  final double? eachQuantity;
  final double? returnedQuantity;
  final String? returnReason;

  ReturnItem({
    required this.itemId,
    this.nos,
    this.eachQuantity,
    this.returnedQuantity,
    this.returnReason,
  });
  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      itemId: map['itemId'],
      nos: map['nos'] != null ? (map['nos'] as num).toDouble() : null,
      eachQuantity: map['eachQuantity'] != null
          ? (map['eachQuantity'] as num).toDouble()
          : null,
      returnedQuantity: map['returnedQuantity'] != null
          ? (map['returnedQuantity'] as num).toDouble()
          : null,
      returnReason: map['returnReason'],
    );
  }

  Map<String, dynamic> toJson(String scenario) {
    final data = <String, dynamic>{'itemId': itemId};

    if (scenario != 'partial') {
      if (nos != null) data['nos'] = nos;
      if (eachQuantity != null) data['eachQuantity'] = eachQuantity;
      if (returnedQuantity != null) data['returnedQuantity'] = returnedQuantity;
    }

    if (returnReason != null) {
      data['returnReason'] = returnReason;
    }

    return data;
  }
}


class ItemDetails {
  final String? itemId;
  final String? itemName;
  final String noteType; // "debit" or "credit"
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double taxAmount;
  final double discountAmount;
  final double finalPrice;
  final double? sgst;
  final double? cgst;
  final double? igst;
  final String reason;

  ItemDetails({
    this.itemId,
    this.itemName,
    required this.noteType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.taxAmount,
    required this.discountAmount,
    required this.finalPrice,
    this.sgst,
    this.cgst,
    this.igst,
    required this.reason,
  });

  factory ItemDetails.fromJson(Map<String, dynamic> json) {
    return ItemDetails(
      itemId: json['itemId'],
      itemName: json['itemName'],
      noteType: json['noteType'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      sgst: json['sgst'] != null ? (json['sgst']).toDouble() : null,
      cgst: json['cgst'] != null ? (json['cgst']).toDouble() : null,
      igst: json['igst'] != null ? (json['igst']).toDouble() : null,
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'noteType': noteType,
      'quantity': double.parse(quantity.toStringAsFixed(2)),
      'unitPrice': double.parse(unitPrice.toStringAsFixed(2)),
      'totalPrice': double.parse(totalPrice.toStringAsFixed(2)),
      'taxAmount': double.parse(taxAmount.toStringAsFixed(2)),
      'discountAmount': double.parse(discountAmount.toStringAsFixed(2)),
      'finalPrice': double.parse(finalPrice.toStringAsFixed(2)),
      'sgst': sgst != null ? double.parse(sgst!.toStringAsFixed(2)) : null,
      'cgst': cgst != null ? double.parse(cgst!.toStringAsFixed(2)) : null,
      'igst': igst != null ? double.parse(igst!.toStringAsFixed(2)) : null,
      'reason': reason,
    };
  }
}
