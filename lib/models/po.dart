import 'package:purchaseorders2/models/po_item.dart';
import 'package:intl/intl.dart';
import 'discount_model.dart';

class PO {
  // ------------------------------
  // MAIN FIELDS
  // ------------------------------
  final String purchaseOrderId;
  final String? vendorName;
  final String? vendorContact;
  final String? orderDate;
  final String? orderedDate;
  List<Item> items;
  double? totalOrderAmount;
  double? pendingOrderAmount;
  double? pendingDiscountAmount;
  double? pendingTaxAmount;
  final String? expectedDeliveryDate;
  String? poStatus;
  final String paymentTerms;
  final String? shippingAddress;
  final String? billingAddress;
  final String? comments;
  final String? invoiceNo;
  final String? attachments;
  final String? createdDate;
  final String? lastUpdatedDate;
  final String? randomId;
  final String? approvedDate;
  final String? rejectedDate;
  final String? invoiceDate;
  final double? discountPrice;
  final double? newPrice;
  final String? contactpersonEmail;
  final String address;
  final String country;
  final String state;
  final String city;
  final int postalCode;
  final String gstNumber;
  final int creditLimit;
  final PurchaseOrderDiscount? overallDiscount;
  final double? roundOffAdjustment;
  final bool? isHoldOrder;
  final double? overallDiscountValue;
  double? manualTotalDiscount;

  // ------------------------------
  // TEMPLATE FIELDS
  // ------------------------------
  final bool? isTemplate;
  final String? templateName;
  final String? templateCreatedDate;
  final String? templateId;
  final String? location;
  final String? locationName;

  PO({
    required this.purchaseOrderId,
    this.vendorName,
    this.newPrice,
    this.vendorContact,
    this.orderDate,
    this.orderedDate,
    List<Item>? items,
    this.totalOrderAmount,
    this.pendingOrderAmount,
    this.pendingDiscountAmount,
    this.pendingTaxAmount,
    this.expectedDeliveryDate,
    this.poStatus,
    required this.paymentTerms,
    this.shippingAddress,
    this.billingAddress,
    this.invoiceNo,
    this.discountPrice,
    this.comments,
    this.attachments,
    this.createdDate,
    this.lastUpdatedDate,
    this.approvedDate,
    this.rejectedDate,
    this.invoiceDate,
    this.randomId,
    required this.address,
    required this.contactpersonEmail,
    required this.country,
    required this.state,
    required this.city,
    required this.postalCode,
    required this.gstNumber,
    required this.creditLimit,
    this.overallDiscount,
    this.roundOffAdjustment = 0.0,
    this.isHoldOrder = false,
    // TEMPLATE
    this.isTemplate = false,
    this.templateName,
    this.templateCreatedDate,
    this.templateId,
    this.overallDiscountValue,

    this.location,
    this.locationName,
  }) : items = items ?? [];

  // ------------------------------
  // COMPUTED VALUES
  // ------------------------------

  double get subTotal {
    return items.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0.0));
  }

  double get itemWiseDiscount {
    return items.fold(0.0, (sum, item) {
      final q = item.quantity ?? 0.0;
      final p = item.newPrice ?? 0.0;
      final d = item.discount ?? 0.0;
      return sum + (q * p * d / 100);
    });
  }

  double get overallDiscountAmount {
    return overallDiscount?.calculateDiscount(subTotal) ?? 0.0;
  }

  double get totalDiscount {
    if (manualTotalDiscount != null) return manualTotalDiscount!;

    // If backend already calculated, trust it
    if (overallDiscountValue != null) {
      return overallDiscountValue!;
    }

    // UI-side fallback
    return itemWiseDiscount + overallDiscountAmount;
  }

  double get finalAmount {
    if (totalOrderAmount != null) {
      return totalOrderAmount!;
    }

    final roundOff = roundOffAdjustment ?? 0.0;
    final amount = subTotal - totalDiscount + roundOff;
    return amount > 0 ? amount : 0.0;
  }

  // ------------------------------
  // COPY WITH
  // ------------------------------

  PO copyWith({
    String? purchaseOrderId,
    String? vendorName,
    String? vendorContact,
    String? orderDate,
    String? orderedDate,
    List<Item>? items,
    double? totalOrderAmount,
    double? pendingOrderAmount,
    double? pendingDiscountAmount,
    double? pendingTaxAmount,
    String? expectedDeliveryDate,
    String? poStatus,
    String? paymentTerms,
    String? shippingAddress,
    String? billingAddress,
    String? comments,
    String? attachments,
    String? createdDate,
    String? lastUpdatedDate,
    String? randomId,
    String? approvedDate,
    String? rejectedDate,
    String? invoiceDate,
    String? invoiceNo,
    double? discountPrice,
    double? newPrice,
    String? contactpersonEmail,
    String? address,
    String? country,
    String? state,
    String? city,
    int? postalCode,
    String? gstNumber,
    int? creditLimit,
    PurchaseOrderDiscount? overallDiscount,
    double? roundOffAdjustment,
    bool? isHoldOrder,
    bool? isTemplate,
    String? templateName,
    String? templateCreatedDate,
    String? templateId,

    String? location,
    String? locationName,
  }) {
    return PO(
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      vendorName: vendorName ?? this.vendorName,
      vendorContact: vendorContact ?? this.vendorContact,
      orderDate: orderDate ?? this.orderDate,
      orderedDate: orderedDate ?? this.orderedDate,
      items: items ?? this.items,
      totalOrderAmount: totalOrderAmount ?? this.totalOrderAmount,
      pendingOrderAmount: pendingOrderAmount ?? this.pendingOrderAmount,
      pendingDiscountAmount:
          pendingDiscountAmount ?? this.pendingDiscountAmount,
      pendingTaxAmount: pendingTaxAmount ?? this.pendingTaxAmount,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      poStatus: poStatus ?? this.poStatus,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      createdDate: createdDate ?? this.createdDate,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      randomId: randomId ?? this.randomId,
      approvedDate: approvedDate ?? this.approvedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      discountPrice: discountPrice ?? this.discountPrice,
      newPrice: newPrice ?? this.newPrice,
      contactpersonEmail: contactpersonEmail ?? this.contactpersonEmail,
      address: address ?? this.address,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      gstNumber: gstNumber ?? this.gstNumber,
      creditLimit: creditLimit ?? this.creditLimit,
      overallDiscount: overallDiscount ?? this.overallDiscount,
      roundOffAdjustment: roundOffAdjustment ?? this.roundOffAdjustment,
      isHoldOrder: isHoldOrder ?? this.isHoldOrder,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
      templateCreatedDate: templateCreatedDate ?? this.templateCreatedDate,
      templateId: templateId ?? this.templateId,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
    );
  }

  // ------------------------------
  // TO JSON
  // ------------------------------

  Map<String, dynamic> toJson() => {
    'purchaseOrderId': purchaseOrderId,
    'vendorName': vendorName ?? '',
    'vendorContact': vendorContact ?? '',
    'orderDate': orderDate ?? '',
    'orderedDate': orderedDate ?? '',
    'items': items.map((item) => item.toJson()).toList(),
    'totalOrderAmount': totalOrderAmount ?? 0.0,
    'pendingOrderAmount': pendingOrderAmount ?? 0.0,
    'pendingDiscountAmount': pendingDiscountAmount ?? 0.0,
    'pendingTaxAmount': pendingTaxAmount ?? 0.0,
    'expectedDeliveryDate': expectedDeliveryDate ?? '',
    'poStatus': poStatus ?? '',
    'paymentTerms': paymentTerms,
    'shippingAddress': shippingAddress ?? '',
    'billingAddress': billingAddress ?? '',
    'comments': comments ?? '',
    'attachments': attachments ?? '',
    'createdDate': createdDate ?? '',
    'lastUpdatedDate': lastUpdatedDate ?? '',
    'randomId': randomId ?? '',
    'approvedDate': approvedDate ?? '',
    'rejectedDate': rejectedDate ?? '',
    'invoiceDate': invoiceDate ?? '',
    'invoiceNo': invoiceNo ?? '',
    'discountPrice': discountPrice ?? 0.0,
    'newPrice': newPrice ?? 0.0,
    'contactpersonEmail': contactpersonEmail ?? '',
    'address': address,
    'country': country,
    'state': state,
    'city': city,
    'postalCode': postalCode,
    'gstNumber': gstNumber,
    'creditLimit': creditLimit,
    'overallDiscount': overallDiscount?.toJson(),
    'overallDiscountValue': overallDiscountValue ?? totalDiscount,

    'roundOffAdjustment': roundOffAdjustment ?? 0.0,
    'isHoldOrder': isHoldOrder ?? false,
    // TEMPLATE
    'isTemplate': isTemplate ?? false,
    'templateName': templateName ?? '',
    'templateCreatedDate': templateCreatedDate ?? '',
    'templateId': templateId ?? '',
    'location': location ?? '',
    'locationName': locationName ?? '',
  };

  // ------------------------------
  // FROM JSON
  // ------------------------------

  factory PO.fromJson(Map<String, dynamic> json) => PO(
    purchaseOrderId: json['purchaseOrderId'] ?? '',
    vendorName: json['vendorName'] ?? '',
    vendorContact: json['vendorContact'] ?? '',
    orderDate: json['orderDate']?.toString() ?? '',
    orderedDate: json['orderedDate']?.toString() ?? '',
    expectedDeliveryDate: json['expectedDeliveryDate']?.toString() ?? '',
    poStatus: json['poStatus'] ?? '',
    paymentTerms: json['paymentTerms'] ?? '',
    shippingAddress: json['shippingAddress'] ?? '',
    billingAddress: json['billingAddress'] ?? '',
    comments: json['comments'] ?? '',
    attachments: json['attachments']?.toString() ?? '',
    createdDate: json['createdDate']?.toString() ?? '',
    lastUpdatedDate: json['lastUpdatedDate']?.toString() ?? '',
    randomId: json['randomId'] ?? '',
    totalOrderAmount: (json['totalOrderAmount'] ?? 0.0).toDouble(),
    pendingOrderAmount: (json['pendingOrderAmount'] ?? 0.0).toDouble(),
    pendingDiscountAmount: (json['pendingDiscountAmount'] ?? 0.0).toDouble(),
    pendingTaxAmount: (json['pendingTaxAmount'] ?? 0.0).toDouble(),
    approvedDate: json['approvedDate']?.toString() ?? '',
    rejectedDate: json['rejectedDate']?.toString() ?? '',
    invoiceNo: json['invoiceNo']?.toString() ?? '',
    discountPrice: (json['discountPrice'] ?? 0.0).toDouble(),
    invoiceDate: json['invoiceDate']?.toString() ?? '',
    contactpersonEmail: json['contactpersonEmail']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
    country: json['country']?.toString() ?? '',
    state: json['state']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    postalCode: json['postalCode'] ?? 0,
    gstNumber: json['gstNumber'] ?? '',
    creditLimit: json['creditLimit'] ?? 0,
    overallDiscount: json['overallDiscount'] != null
        ? PurchaseOrderDiscount.fromJson(json['overallDiscount'])
        : null,
    overallDiscountValue:
        (json['overallDiscountValue'] ?? json['overallDiscount'] ?? 0.0)
            .toDouble(),

    roundOffAdjustment:
        (json['roundOffAdjustment'] ?? json['roundOffValue'] ?? 0.0).toDouble(),
    isHoldOrder: json['isHoldOrder'] ?? false,
    items:
        (json['items'] as List<dynamic>?)
            ?.map((i) => Item.fromJson(i))
            .toList() ??
        [],
    // TEMPLATE
    isTemplate: json['isTemplate'] ?? false,
    templateName: json['templateName'] ?? '',
    templateCreatedDate: json['templateCreatedDate']?.toString() ?? '',
    templateId: json['templateId'] ?? json['randomId'] ?? '',
    location: json['location']?.toString() ?? '',
    locationName: json['locationName']?.toString() ?? '',
  );

  // ------------------------------
  // DATE HELPERS
  // ------------------------------

  String get formattedOrderDate {
    if (orderDate == null || orderDate!.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(orderDate!);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return orderDate!;
    }
  }

  String get formattedOrderedDate {
    if (orderedDate == null || orderedDate!.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(orderedDate!);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return orderedDate!;
    }
  }
}
