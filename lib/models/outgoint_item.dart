class ItemDetail {
  final String itemId;
  final String? itemName;
  double? taxAmount;
  double? discountAmount;
  double? finalPrice;
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

  ItemDetail({
    required this.itemId,
    this.itemName,
    this.taxAmount,
    this.discountAmount,
    this.finalPrice,
    this.quantity,
    this.uom,
    this.discount,
    this.purchasetaxName,
    this.stockQuantity,
    this.unitPrice,
    this.totalPrice,
    this.sgst,
    this.cgst,
    this.igst,
    this.status,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) {
    return ItemDetail(
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String?,
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      uom: json['uom'] as String?,
      discount: (json['discount'] as num?)?.toDouble(),
      purchasetaxName: (json['purchasetaxName'] as num?)?.toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      sgst: (json['sgst'] as num?)?.toDouble(),
      cgst: (json['cgst'] as num?)?.toDouble(),
       igst: (json['igst'] as num?)?.toDouble(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      'quantity': quantity,
      'uom': uom,
      'discount': discount,
      'purchasetaxName': purchasetaxName,
      'stockQuantity': stockQuantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'sgst': sgst,
      'cgst': cgst,
      'igst': igst,
      'status': status,
    };
  }
}
