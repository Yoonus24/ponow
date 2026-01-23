class Item {
  String? itemId;
  final String? itemCode;
  final String? barcode;
  final String? itemName;
  final String? purchasecategoryName;
  final String? purchasesubcategoryName;
  double? count;
  double? pendingCount;
  double? pendingQuantity;
  double? pendingTotalQuantity;
  double? pendingTaxAmount;
  double? pendingDiscountAmount;
  double? overallDiscountValue;
  double? pendingOrderAmount;
  double? pendingtotalPrice;
  double? totalOrderAmount;
  double? pendingSgst;
  double? pendingCgst;
  double? pendingIgst;
  double? pendingTotalPrice;
  double? pendingFinalPrice;
  double? pendingBefTaxDiscountAmount;
  double? pendingAfTaxDiscountAmount;
  final String? hsnCode;
  final String? poPhoto;
  double? taxAmount;
  String? taxType;
  double? befTaxDiscount;
  double? afTaxDiscount;
  double? befTaxDiscountAmount;
  double? afTaxDiscountAmount;
  double? taxPercentage;
  double? discountAmount;
  double? finalPrice;
  final double? nos;
  double? eachQuantity;
  double? receivedQuantity;
  double? discountPrice;
  double? damagedQuantity;
  double? quantity;
  double? poQuantity;
  final String? uom;
  final double? discount;
  final double? purchasetaxName;
  final double? stockQuantity;
  double? existingPrice;
  double? newPrice;
  double? totalPrice;
  double? sgst;
  double? igst;
  double? cgst;
  String? status;
  String expiryDate;
  double? variance;
  bool isDiscountPercentage;
  String befTaxDiscountType;
  String afTaxDiscountType;

  Item({
    this.itemId,
    this.itemCode,
    this.barcode,
    this.itemName,
    this.purchasecategoryName,
    this.purchasesubcategoryName,
    this.count,
    this.pendingCount,
    this.pendingQuantity,
    this.pendingTotalQuantity,
    this.pendingTaxAmount,
    this.pendingDiscountAmount,
    this.pendingOrderAmount,
    this.overallDiscountValue,
    this.totalOrderAmount,
    this.pendingSgst,
    this.pendingCgst,
    this.pendingIgst,
    this.pendingTotalPrice,
    this.pendingFinalPrice,
    this.pendingBefTaxDiscountAmount,
    this.pendingAfTaxDiscountAmount,
    this.hsnCode,
    this.poPhoto,
    this.taxAmount,
    this.discountPrice,
    this.taxType,
    this.befTaxDiscount,
    this.afTaxDiscount,
    this.befTaxDiscountAmount,
    this.afTaxDiscountAmount,
    this.taxPercentage,
    this.discountAmount,
    this.finalPrice,
    this.nos,
    this.eachQuantity,
    this.receivedQuantity,
    this.damagedQuantity,
    this.quantity,
    this.poQuantity,
    this.uom,
    this.discount,
    this.purchasetaxName,
    this.stockQuantity,
    this.existingPrice,
    this.newPrice,
    this.totalPrice,
    this.sgst,
    this.igst,
    this.cgst,
    this.status,
    this.variance,
    required this.expiryDate,
    this.afTaxDiscountType = 'percentage',
    this.befTaxDiscountType = 'percentage',
    this.isDiscountPercentage = false,
  });

  // -------------------------------------------------------
  // ✅ copyWith METHOD (fully merged)
  // -------------------------------------------------------
  Item copyWith({
    String? itemId,
    String? itemCode,
    String? barcode,
    String? itemName,
    String? purchasecategoryName,
    String? purchasesubcategoryName,
    double? count,
    double? pendingCount,
    double? pendingQuantity,
    double? pendingTotalQuantity,
    double? pendingTaxAmount,
    double? pendingDiscountAmount,
    double? overallDiscountValue,
    double? pendingOrderAmount,
    double? pendingtotalPrice,
    double? totalOrderAmount,
    double? pendingSgst,
    double? pendingCgst,
    double? pendingIgst,
    double? pendingTotalPrice,
    double? pendingFinalPrice,
    double? pendingBefTaxDiscountAmount,
    double? pendingAfTaxDiscountAmount,
    String? hsnCode,
    String? poPhoto,
    double? taxAmount,
    String? taxType,
    double? befTaxDiscount,
    double? afTaxDiscount,
    double? befTaxDiscountAmount,
    double? afTaxDiscountAmount,
    double? taxPercentage,
    double? discountAmount,
    double? finalPrice,
    double? nos,
    double? eachQuantity,
    double? receivedQuantity,
    double? discountPrice,
    double? damagedQuantity,
    double? quantity,
    double? poQuantity,
    String? uom,
    double? discount,
    double? purchasetaxName,
    double? stockQuantity,
    double? existingPrice,
    double? newPrice,
    double? totalPrice,
    double? sgst,
    double? igst,
    double? cgst,
    String? status,
    String? expiryDate,
    double? variance,
    bool? isDiscountPercentage,
    String? befTaxDiscountType,
    String? afTaxDiscountType,
  }) {
    return Item(
      itemId: itemId ?? this.itemId,
      itemCode: itemCode ?? this.itemCode,
      barcode: barcode ?? this.barcode,
      itemName: itemName ?? this.itemName,
      purchasecategoryName: purchasecategoryName ?? this.purchasecategoryName,
      purchasesubcategoryName:
          purchasesubcategoryName ?? this.purchasesubcategoryName,
      count: count ?? this.count,
      pendingCount: pendingCount ?? this.pendingCount,
      pendingQuantity: pendingQuantity ?? this.pendingQuantity,
      pendingTotalQuantity: pendingTotalQuantity ?? this.pendingTotalQuantity,
      pendingTaxAmount: pendingTaxAmount ?? this.pendingTaxAmount,
      pendingDiscountAmount:
          pendingDiscountAmount ?? this.pendingDiscountAmount,
      overallDiscountValue: overallDiscountValue ?? this.overallDiscountValue,
      pendingOrderAmount: pendingOrderAmount ?? this.pendingOrderAmount,
      totalOrderAmount: totalOrderAmount ?? this.totalOrderAmount,
      pendingSgst: pendingSgst ?? this.pendingSgst,
      pendingCgst: pendingCgst ?? this.pendingCgst,
      pendingIgst: pendingIgst ?? this.pendingIgst,
      pendingTotalPrice: pendingTotalPrice ?? this.pendingTotalPrice,
      pendingFinalPrice: pendingFinalPrice ?? this.pendingFinalPrice,
      pendingBefTaxDiscountAmount:
          pendingBefTaxDiscountAmount ?? this.pendingBefTaxDiscountAmount,
      pendingAfTaxDiscountAmount:
          pendingAfTaxDiscountAmount ?? this.pendingAfTaxDiscountAmount,
      hsnCode: hsnCode ?? this.hsnCode,
      poPhoto: poPhoto ?? this.poPhoto,
      taxAmount: taxAmount ?? this.taxAmount,
      taxType: taxType ?? this.taxType,
      befTaxDiscount: befTaxDiscount ?? this.befTaxDiscount,
      afTaxDiscount: afTaxDiscount ?? this.afTaxDiscount,
      befTaxDiscountAmount: befTaxDiscountAmount ?? this.befTaxDiscountAmount,
      afTaxDiscountAmount: afTaxDiscountAmount ?? this.afTaxDiscountAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      finalPrice: finalPrice ?? this.finalPrice,
      nos: nos ?? this.nos,
      eachQuantity: eachQuantity ?? this.eachQuantity,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      discountPrice: discountPrice ?? this.discountPrice,
      damagedQuantity: damagedQuantity ?? this.damagedQuantity,
      quantity: quantity ?? this.quantity,
      poQuantity: poQuantity ?? this.poQuantity,
      uom: uom ?? this.uom,
      discount: discount ?? this.discount,
      purchasetaxName: purchasetaxName ?? this.purchasetaxName,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      existingPrice: existingPrice ?? this.existingPrice,
      newPrice: newPrice ?? this.newPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      cgst: cgst ?? this.cgst,
      status: status ?? this.status,
      expiryDate: expiryDate ?? this.expiryDate,
      variance: variance ?? this.variance,
      isDiscountPercentage: isDiscountPercentage ?? this.isDiscountPercentage,
      befTaxDiscountType: befTaxDiscountType ?? this.befTaxDiscountType,
      afTaxDiscountType: afTaxDiscountType ?? this.afTaxDiscountType,
    );
  }

  // -------------------------------------------------------
  // validateForSubmission
  // -------------------------------------------------------
  void validateForSubmission() {
    if (befTaxDiscountType.isEmpty) befTaxDiscountType = 'percentage';
    if (afTaxDiscountType.isEmpty) afTaxDiscountType = 'percentage';

    if (befTaxDiscountType != 'percentage' && befTaxDiscountType != 'amount') {
      befTaxDiscountType = 'percentage';
    }
    if (afTaxDiscountType != 'percentage' && afTaxDiscountType != 'amount') {
      afTaxDiscountType = 'percentage';
    }

    befTaxDiscountAmount ??= 0.0;
    afTaxDiscountAmount ??= 0.0;
    taxAmount ??= 0.0;
    finalPrice ??= 0.0;
  }

  // -------------------------------------------------------
  // fromJson
  // -------------------------------------------------------
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'] as String? ?? '',
      itemCode: json['itemCode'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      purchasecategoryName: json['purchasecategoryName'] as String? ?? '',
      purchasesubcategoryName: json['purchasesubcategoryName'] as String? ?? '',
      count: (json['count'] as num?)?.toDouble() ?? 0.0,
      pendingCount: (json['pendingCount'] as num?)?.toDouble() ?? 0.0,
      pendingQuantity: (json['pendingQuantity'] as num?)?.toDouble() ?? 0.0,
      pendingTotalQuantity:
          (json['pendingTotalQuantity'] as num?)?.toDouble() ?? 0.0,
      hsnCode: json['hsnCode'] as String? ?? '',
      poPhoto: json['poPhoto'] as String? ?? '',
      status: json['status'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      befTaxDiscountType: json['befTaxDiscountType'] as String? ?? 'percentage',
      afTaxDiscountType: json['afTaxDiscountType'] as String? ?? 'percentage',
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      pendingTaxAmount: (json['pendingTaxAmount'] as num?)?.toDouble() ?? 0.0,
      pendingDiscountAmount:
          (json['pendingDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      pendingSgst: (json['pendingSgst'] as num?)?.toDouble() ?? 0.0,
      pendingCgst: (json['pendingCgst'] as num?)?.toDouble() ?? 0.0,
      pendingIgst: (json['pendingIgst'] as num?)?.toDouble() ?? 0.0,
      pendingTotalPrice: (json['pendingTotalPrice'] as num?)?.toDouble() ?? 0.0,
      pendingFinalPrice: (json['pendingFinalPrice'] as num?)?.toDouble() ?? 0.0,
      pendingBefTaxDiscountAmount:
          (json['pendingBefTaxDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      pendingAfTaxDiscountAmount:
          (json['pendingAfTaxDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      taxType: json['taxType'] is String ? json['taxType'] : 'cgst_sgst',
      discountPrice: (json['discountPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      nos: (json['nos'] as num?)?.toDouble() ?? 0.0,
      eachQuantity: (json['eachQuantity'] as num?)?.toDouble() ?? 0.0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toDouble() ?? 0.0,
      damagedQuantity: (json['damagedQuantity'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      poQuantity: (json['poQuantity'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      igst: (json['igst'] as num?)?.toDouble() ?? 0.0,
      befTaxDiscountAmount:
          (json['befTaxDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      afTaxDiscountAmount:
          (json['afTaxDiscountAmount'] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 0.0,
      existingPrice: (json['existingPrice'] as num?)?.toDouble() ?? 0.0,
      newPrice: (json['newPrice'] as num?)?.toDouble() ?? 0.0,
      befTaxDiscount: (json['befTaxDiscount'] as num?)?.toDouble() ?? 0.0,
      afTaxDiscount: (json['afTaxDiscount'] as num?)?.toDouble() ?? 0.0,
      variance: (json['variance'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate']?.toString() ?? '',
      isDiscountPercentage: json['isDiscountPercentage'] as bool? ?? false,
    );
  }

  // -------------------------------------------------------
  // toJson
  // -------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId ?? '',
      'itemCode': itemCode ?? '',
      'barcode': barcode ?? '',
      'itemName': itemName ?? '',
      'purchasecategoryName': purchasecategoryName ?? '',
      'purchasesubcategoryName': purchasesubcategoryName ?? '',
      'count': count ?? 0,
      'pendingCount': pendingCount ?? 0,
      'pendingQuantity': pendingQuantity ?? 0,
      'befTaxDiscount': befTaxDiscount ?? 0.0,
      'afTaxDiscount': afTaxDiscount ?? 0.0,
      'befTaxDiscountType': befTaxDiscountType.isNotEmpty
          ? befTaxDiscountType
          : 'percentage',
      'afTaxDiscountType': afTaxDiscountType.isNotEmpty
          ? afTaxDiscountType
          : 'percentage',
      'taxPercentage': taxPercentage ?? 0,
      'discountPrice': discountPrice ?? 0,
      'pendingTotalQuantity': pendingTotalQuantity ?? 0,
      'hsnCode': hsnCode ?? '',
      'poPhoto': poPhoto ?? '',
      'status': status ?? '',
      'uom': uom ?? '',
      'poQuantity': poQuantity ?? 0,
      'befTaxDiscountAmount': befTaxDiscountAmount ?? 0.0,
      'afTaxDiscountAmount': afTaxDiscountAmount ?? 0.0,
      'pendingBefTaxDiscountAmount': pendingBefTaxDiscountAmount ?? 0.0,
      'pendingAfTaxDiscountAmount': pendingAfTaxDiscountAmount ?? 0.0,
      'taxAmount': taxAmount ?? 0.0,
      'pendingTaxAmount': pendingTaxAmount ?? 0.0,
      'pendingDiscountAmount': pendingDiscountAmount ?? 0.0,
      'pendingSgst': pendingSgst ?? 0.0,
      'pendingCgst': pendingCgst ?? 0.0,
      'pendingIgst': pendingIgst ?? 0.0,
      'receivedQuantity': receivedQuantity ?? 0.0,
      'pendingTotalPrice': pendingTotalPrice ?? 0.0,
      'pendingFinalPrice': pendingFinalPrice ?? 0.0,
      'discountAmount': discountAmount ?? 0.0,
      'finalPrice': finalPrice ?? 0.0,
      'nos': nos ?? 0,
      'eachQuantity': eachQuantity ?? 0,
      'quantity': quantity ?? 0,
      'stockQuantity': stockQuantity ?? 0,
      'newPrice': newPrice ?? 0.0,
      'existingPrice': existingPrice ?? 0.0,
      'totalPrice': totalPrice ?? 0.0,
      'sgst': sgst ?? 0.0,
      'cgst': cgst ?? 0.0,
      'igst': igst ?? 0.0,
      'taxType': taxType ?? 'cgst_sgst',
      'variance': variance ?? 0.0,
      'expiryDate': expiryDate.isNotEmpty ? expiryDate : null,
      'isDiscountPercentage': isDiscountPercentage,
    };
  }

  // -------------------------------------------------------
  // calculateTotals
  // -------------------------------------------------------
  // void calculateTotals() {
  //   final quantity = this.quantity ?? 0.0;
  //   final newPrice = this.newPrice ?? 0.0;
  //   final befTaxDiscount = this.befTaxDiscount ?? 0.0;
  //   final afTaxDiscount = this.afTaxDiscount ?? 0.0;
  //   final taxPercentage = this.taxPercentage ?? 0.0;

  //   totalPrice = quantity * newPrice;

  //   if (isDiscountPercentage) {
  //     befTaxDiscountAmount = (totalPrice! * befTaxDiscount) / 100;
  //   } else {
  //     befTaxDiscountAmount = befTaxDiscount;
  //   }

  //   final priceAfterBefTaxDiscount = totalPrice! - befTaxDiscountAmount!;

  //   if (isDiscountPercentage) {
  //     afTaxDiscountAmount = (priceAfterBefTaxDiscount * afTaxDiscount) / 100;
  //   } else {
  //     afTaxDiscountAmount = afTaxDiscount;
  //   }

  //   final priceAfterAllDiscounts =
  //       priceAfterBefTaxDiscount - afTaxDiscountAmount!;

  //   taxAmount = (priceAfterAllDiscounts * taxPercentage) / 100;

  //   finalPrice = priceAfterAllDiscounts + taxAmount!;

  //   variance = (newPrice - (existingPrice ?? 0.0));

  //   if (taxType == 'igst') {
  //     pendingIgst = taxAmount;
  //     pendingCgst = 0;
  //     pendingSgst = 0;
  //   } else {
  //     pendingCgst = taxAmount! / 2;
  //     pendingSgst = taxAmount! / 2;
  //     pendingIgst = 0;
  //   }
  // }

  double get totalItemDiscount {
    return (befTaxDiscountAmount ?? 0.0) + (afTaxDiscountAmount ?? 0.0);
  }

  double get netAmountAfterDiscounts {
    final total = totalPrice ?? 0.0;
    return total - totalItemDiscount;
  }

  get unitPrice => null;
}
