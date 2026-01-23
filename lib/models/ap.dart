import 'package:purchaseorders2/models/ap_item.dart';

class ApInvoice {
  final String? invoiceId;
  final String? grnId;
  final String? purchaseOrderId;
  final String? vendorName;
  final String? apinvoiceDate;
  final String? invoiceDate;
  final String? grnDate;
  final String? invoiceNo;
  final String? dueDate;
  final List<ItemDetail>? itemDetails;
  final double? invoiceAmount;
  final double? taxDetails;
  final double? discountDetails;
  final String? paymentTerms;
  final String? paymentStatus;
  final String? comments;
  final String? attachments;
  final String? createdDate;
  final String? lastUpdatedDate;
  final String? contactpersonEmail;
  final String? address;
  final String? country;
  final String? state;
  final String? city;
  final int? postalCode;
  final String? gstNumber;
  final String randomId;
  final String? status;
  final String? poDate;
  final String? apReturnedDate;
  final String? apPerson;
  final String? apReturnedPerson;
  final double? discountPrice;
  double? apDiscountPrice;
  final String? shippingAddress;
  final String? billingAddress;
  final double? roundOffAdjustment;

  ApInvoice({
    this.invoiceId,
    this.grnId,
    this.purchaseOrderId,
    this.vendorName,
    this.apinvoiceDate,
    this.invoiceDate,
    this.grnDate,
    this.invoiceNo,
    this.dueDate,
    this.itemDetails,
    this.invoiceAmount,
    this.taxDetails,
    this.discountDetails,
    this.paymentTerms,
    this.paymentStatus,
    this.comments,
    this.attachments,
    this.createdDate,
    this.lastUpdatedDate,
    this.contactpersonEmail,
    this.address,
    this.country,
    this.state,
    this.city,
    this.postalCode,
    this.gstNumber,
    required this.randomId,
    this.status,
    this.poDate,
    this.apReturnedDate,
    this.apPerson,
    this.apReturnedPerson,
    this.discountPrice,
    this.apDiscountPrice,
    this.shippingAddress,
    this.billingAddress,
    this.roundOffAdjustment,
  });

  factory ApInvoice.fromJson(Map<String, dynamic> json) {
    return ApInvoice(
      invoiceId: json['invoiceId'] as String?,
      grnId: json['grnId'] as String?,
      purchaseOrderId: json['purchaseOrderId'] as String?,
      vendorName: json['vendorName'] as String?,
      apinvoiceDate: json['apinvoiceDate'] as String?,
      invoiceDate: json['invoiceDate'] as String?,
      grnDate: json['grnDate'] as String?,
      invoiceNo: json['invoiceNo'] as String?,
      dueDate: json['dueDate'] as String?,
      itemDetails: (json['itemDetails'] as List<dynamic>?)
          ?.map((item) => ItemDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
      invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble(),
      taxDetails: (json['taxDetails'] as num?)?.toDouble(),
      discountDetails: (json['discountDetails'] as num?)?.toDouble(),
      paymentTerms: json['paymentTerms'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      comments: json['comments'] as String?,
      attachments: json['attachments'] as String?,
      createdDate: json['createdDate'] as String?,
      lastUpdatedDate: json['lastUpdatedDate'] as String?,
      contactpersonEmail: json['contactpersonEmail'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      postalCode: (json['postalCode'] as num?)?.toInt(),
      gstNumber: json['gstNumber'] as String?,
      randomId: json['randomId'] as String,
      status: json['status'] as String?,
      poDate: json['poDate'] as String?,
      apReturnedDate: json['apReturnedDate'] as String?,
      apPerson: json['apPerson'] as String?,
      apReturnedPerson: json['apReturnedPerson'] as String?,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      apDiscountPrice: (json['apDiscountPrice'] as num?)?.toDouble(),
      shippingAddress: json['shippingAddress'] as String?,
      billingAddress: json['billingAddress'] as String?,

      // ✅ FIX: Prefer apRoundOff, fallback to roundOffAdjustment
      roundOffAdjustment:
          (json['apRoundOff'] as num?)?.toDouble() ??
          (json['roundOffAdjustment'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'grnId': grnId,
      'purchaseOrderId': purchaseOrderId,
      'vendorName': vendorName,
      'apinvoiceDate': apinvoiceDate,
      'invoiceDate': invoiceDate,
      'grnDate': grnDate,
      'invoiceNo': invoiceNo,
      'dueDate': dueDate,
      'itemDetails': itemDetails?.map((item) => item.toJson()).toList(),
      'invoiceAmount': invoiceAmount,
      'taxDetails': taxDetails,
      'discountDetails': discountDetails,
      'paymentTerms': paymentTerms,
      'paymentStatus': paymentStatus,
      'comments': comments,
      'attachments': attachments,
      'createdDate': createdDate,
      'lastUpdatedDate': lastUpdatedDate,
      'contactpersonEmail': contactpersonEmail,
      'address': address,
      'country': country,
      'state': state,
      'city': city,
      'postalCode': postalCode,
      'gstNumber': gstNumber,
      'randomId': randomId,
      'status': status,
      'poDate': poDate,
      'apReturnedDate': apReturnedDate,
      'apPerson': apPerson,
      'apReturnedPerson': apReturnedPerson,
      'discountPrice': discountPrice,
      'apDiscountPrice': apDiscountPrice,
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,

      // ✅ Send as apRoundOff (and keep old key for safety)
      'apRoundOff': roundOffAdjustment ?? 0.0,
      'roundOffAdjustment': roundOffAdjustment ?? 0.0,
    };
  }
}
