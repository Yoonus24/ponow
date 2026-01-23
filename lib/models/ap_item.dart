class ItemDetail {
  final String itemId;
  final String? itemName;
  double? taxAmount;
  double? discountAmount;
  double? finalPrice;
  final double? nos;
  final double? eachQuantity;
  final double? quantity;
  final String? uom;
  final double? discount;
  final double? purchasetaxName;
  final double? stockQuantity;
  final double? unitPrice;
  final double? totalPrice;
  final double? sgst;
  final double? cgst;
  final double? igst;
  final String? status;
  final double? befTaxDiscount;
  final double? afTaxDiscount;
  final double? befTaxDiscountAmount;
  final double? afTaxDiscountAmount;

  ItemDetail({
    required this.itemId,
    this.itemName,
    this.taxAmount,
    this.discountAmount,
    this.finalPrice,
    this.nos,
    this.eachQuantity,
    this.quantity,
    this.uom,
    this.discount,
    this.purchasetaxName,
    this.stockQuantity,
    this.unitPrice,
    this.totalPrice,
    this.sgst,
    this.cgst,
    this.status,
    this.befTaxDiscount,
    this.afTaxDiscount,
    this.befTaxDiscountAmount,
    this.afTaxDiscountAmount,
    this.igst,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    double parseTax(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

    return ItemDetail(
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String?,

      taxAmount: parseTax(json['taxAmount'] ?? json['tax'] ?? json['totalTax']),

      discountAmount: parseTax(json['discountAmount']),
      finalPrice: parseTax(json['finalPrice']),

      nos: parseTax(json['nos']),
      eachQuantity: parseTax(json['eachQuantity']),
      quantity: parseTax(json['quantity']),
      uom: json['uom'] as String?,
      discount: parseTax(json['discount']),

      purchasetaxName: double.tryParse(
        json['purchasetaxName']?.toString() ?? '0.0',
      ),

      stockQuantity: parseTax(json['stockQuantity']),
      unitPrice: parseTax(json['unitPrice']),
      totalPrice: parseTax(json['totalPrice']),

      sgst: parseTax(json['sgst'] ?? json['SGST'] ?? json['sgstAmount']),

      cgst: parseTax(json['cgst'] ?? json['CGST'] ?? json['cgstAmount']),

      igst: parseTax(json['igst'] ?? json['IGST'] ?? json['igstAmount']),

      status: json['status'] as String?,
      befTaxDiscount: parseTax(json['befTaxDiscount']),
      afTaxDiscount: parseTax(json['afTaxDiscount']),
      befTaxDiscountAmount: parseTax(json['befTaxDiscountAmount']),
      afTaxDiscountAmount: parseTax(json['afTaxDiscountAmount']),
    );
  }

  get grnReturnNos => null;

  get grnReturnEachQuantity => null;

  get returnedQuantity => null;

  get totalQuantity => null;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      'nos': nos,
      'eachQuantity': eachQuantity,
      'quantity': quantity,
      'uom': uom,
      'discount': discount,
      'purchasetaxName': purchasetaxName,
      'stockQuantity': stockQuantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'sgst': sgst,
      'cgst': cgst,
      'status': status,
      'befTaxDiscount': befTaxDiscount,
      'afTaxDiscount': afTaxDiscount,
      'befTaxDiscountAmount': befTaxDiscountAmount,
      'afTaxDiscountAmount': afTaxDiscountAmount,
    };
  }
}
