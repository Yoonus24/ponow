import 'package:flutter/foundation.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/ap_item.dart';
import 'package:purchaseorders2/models/grn.dart';

class Outgoing {
  final String outgoingId;
  final String? purchaseOrderId;
  final String? invoiceId;
  final String? grnId;
  final String? vendorName;
  final DateTime? orderDate;
  final DateTime? grnDate;
  final String? receivingLocation;
  final List<ItemDetail>? itemDetails;
  final double? totalPayableAmount;
  final String? comments;
  DateTime? outgoingDate;
  DateTime? createdDate;
  final DateTime? lastUpdatedDate;
  final DateTime? invoiceDate;
  final String? invoiceNo;
  final String? poCreatedPerson;
  final DateTime? poDate;
  final DateTime? paymentDate;
  final DateTime? apinvoiceDate;
  final int? intimationDays;
  final String? paymentMode;
  final double? totalPrice;
  final double? payableAmount;
  final double? discountDetails;
  final String? grnCreatedPerson;
  final String? apCreatedPerson;
  final String? grnVerifiedPerson;
  final String? apVerifiedPerson;
  final String? paymentMethod;
  final double? advanceAmount;
  final double? partialAmount;
  double? fullPaymentAmount;
  final String? paymentType;
  final String? chequeNo;
  final double? onlinePayment;
  final String? neftNo;
  final String? rtgsNo;
  final double? cash;
  String? status;
  final String? randomId;
  final double? taxDetails;
  final String? cashVoucherNo;
  final String? contactpersonEmail;
  final String? address;
  final String? country;
  final String? state;
  final String? city;
  final String? impsNo;
  final String? upi;
  final String? bankName;
  final String? paymentCash;
  final double? pettyCashAmount;
  final int? postalCode;
  final String? gstNumber;
  final String? paymentTerms;
  final String? shippingAddress;
  final String? billingAddress;
  final GRN? grn;
  final ApInvoice? ap;
  final String? grnRandomId;
  final String? apRandomId;
  final String? poRandomId;
  final double? hoCash;

  // ✅ ✅ ✅ PAYMENT SUMMARY (MAIN FIX)
  final double? totalPaidAmount;
  final double? paidAmount;

  final double? remainingPayableAmount;
  final List<PaymentHistory>? paymentHistory;

  Outgoing({
    required this.outgoingId,
    this.purchaseOrderId,
    this.invoiceId,
    this.grnId,
    this.vendorName,
    this.orderDate,
    this.grnDate,
    this.receivingLocation,
    this.itemDetails,
    this.totalPayableAmount,
    this.comments,
    this.outgoingDate,
    this.createdDate,
    this.lastUpdatedDate,
    this.invoiceDate,
    this.invoiceNo,
    this.poCreatedPerson,
    this.poDate,
    this.paymentDate,
    this.apinvoiceDate,
    this.intimationDays,
    this.paymentMode,
    this.totalPrice,
    this.payableAmount,
    this.discountDetails,
    this.grnCreatedPerson,
    this.apCreatedPerson,
    this.grnVerifiedPerson,
    this.apVerifiedPerson,
    this.paymentMethod,
    this.advanceAmount,
    this.partialAmount,
    this.fullPaymentAmount,
    this.paymentType,
    this.chequeNo,
    this.onlinePayment,
    this.neftNo,
    this.rtgsNo,
    this.cash,
    this.status,
    this.randomId,
    this.taxDetails,
    this.cashVoucherNo,
    this.contactpersonEmail,
    this.address,
    this.country,
    this.state,
    this.city,
    this.impsNo,
    this.upi,
    this.bankName,
    this.paymentCash,
    this.pettyCashAmount,
    this.postalCode,
    this.gstNumber,
    this.paymentTerms,
    this.shippingAddress,
    this.billingAddress,
    this.grn,
    this.ap,
    this.grnRandomId,
    this.apRandomId,
    this.poRandomId,
    this.hoCash,

    // ✅ NEW
    this.totalPaidAmount,
    this.remainingPayableAmount,
    this.paymentHistory,
    this.paidAmount,
  });

  factory Outgoing.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Parsing Outgoing from JSON. Keys: ${json.keys}');
    }

    try {
      return Outgoing(
        outgoingId: _parseString(json['outgoingId'] ?? json['_id'])!,
        purchaseOrderId: _parseString(json['purchaseOrderId']),
        invoiceId: _parseString(json['invoiceId']),
        grnId: _parseString(json['grnId']),
        vendorName: _parseString(json['vendorName']),
        orderDate: _parseDateTime(json['orderDate']),
        grnDate: _parseDateTime(json['grnDate']),
        receivingLocation: _parseString(json['receivingLocation']),
        itemDetails: _parseItemDetails(json['itemDetails']),
        totalPayableAmount: _parseDouble(json['totalPayableAmount']),
        comments: _parseString(json['comments']),
        outgoingDate: _parseDateTime(json['outgoingDate']),
        createdDate: _parseDateTime(json['createdDate']),
        lastUpdatedDate: _parseDateTime(json['lastUpdatedDate']),
        invoiceDate: _parseDateTime(json['invoiceDate']),
        invoiceNo: _parseString(json['invoiceNo']),
        poCreatedPerson: _parseString(json['poCreatedPerson']),
        poDate: _parseDateTime(json['poDate']),
        paymentDate: _parseDateTime(json['paymentDate']),
        apinvoiceDate: _parseDateTime(json['apinvoiceDate']),
        intimationDays: _parseInt(json['intimationDays']),
        paymentMode: _parseString(json['paymentMode']),
        totalPrice: _parseDouble(json['totalPrice']),
        payableAmount: _parseDouble(json['payableAmount']),
        discountDetails: _parseDouble(json['discountDetails']),
        grnCreatedPerson: _parseString(json['grnCreatedPerson']),
        apCreatedPerson: _parseString(json['apCreatedPerson']),
        grnVerifiedPerson: _parseString(json['grnVerifiedPerson']),
        apVerifiedPerson: _parseString(json['apVerifiedPerson']),
        paymentMethod: _parseString(json['paymentMethod']),
        advanceAmount: _parseDouble(json['advanceAmount']),
        partialAmount: _parseDouble(json['partialAmount']),
        fullPaymentAmount: _parseDouble(json['fullPaymentAmount']),
        paymentType: _parseString(json['paymentType']),
        chequeNo: _parseString(json['chequeNo']),
        onlinePayment: _parseDouble(json['onlinePayment']),
        neftNo: _parseString(json['neftNo']),
        rtgsNo: _parseString(json['rtgsNo']),
        cash: _parseDouble(json['cash']),
        status: _parseString(json['status']),
        randomId: _parseString(json['randomId']),
        taxDetails: _parseDouble(json['taxDetails']),
        cashVoucherNo: _parseString(json['cashVoucherNo']),
        contactpersonEmail: _parseString(json['contactpersonEmail']),
        address: _parseString(json['address']),
        country: _parseString(json['country']),
        state: _parseString(json['state']),
        city: _parseString(json['city']),
        impsNo: _parseString(json['impsNo']),
        upi: _parseString(json['upi']),
        bankName: _parseString(json['bankName']),
        paymentCash: _parseString(json['paymentCash']),
        pettyCashAmount: _parseDouble(json['pettyCashAmount']),
        hoCash: _parseDouble(json['hoCash']),
        postalCode: _parseInt(json['postalCode']),
        gstNumber: _parseString(json['gstNumber']),
        paymentTerms: _parseString(json['paymentTerms']),
        shippingAddress: _parseString(json['shippingAddress']),
        billingAddress: _parseString(json['billingAddress']),
        grnRandomId: _parseString(json['grnRandomId']),
        apRandomId: _parseString(json['apRandomId']),
        poRandomId: _parseString(json['poRandomId']),

        paidAmount:
            (json['paidAmount'] as num?)?.toDouble() ??
            (json['totalPaidAmount'] as num?)?.toDouble() ??
            0.0,

        totalPaidAmount:
            (json['totalPaidAmount'] as num?)?.toDouble() ??
            (json['paidAmount'] as num?)?.toDouble() ??
            0.0,

        remainingPayableAmount:
            (json['remainingPayableAmount'] as num?)?.toDouble() ?? 0.0,

        paymentHistory: _parsePaymentHistory(json['paymentHistory']),
      );
    } catch (e, stackTrace) {
      print('Error parsing Outgoing: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  // ----------------- HELPERS -----------------

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<ItemDetail>? _parseItemDetails(dynamic value) {
    if (value == null || value is! List) return null;
    try {
      return value.map((e) => ItemDetail.fromJson(e)).toList();
    } catch (e) {
      print('Error parsing item details: $e');
      return null;
    }
  }

  static List<PaymentHistory>? _parsePaymentHistory(dynamic value) {
    if (value == null || value is! List) return null;
    try {
      return value.map((e) => PaymentHistory.fromJson(e)).toList();
    } catch (e) {
      print('Error parsing paymentHistory: $e');
      return null;
    }
  }

  // ✅ ✅ ✅ RESTORED toJson() (FIXES YOUR PROVIDER ERROR)
  Map<String, dynamic> toJson() {
    return {
      'outgoingId': outgoingId,
      'purchaseOrderId': purchaseOrderId,
      'invoiceId': invoiceId,
      'grnId': grnId,
      'vendorName': vendorName,
      'orderDate': orderDate?.toIso8601String(),
      'grnDate': grnDate?.toIso8601String(),
      'receivingLocation': receivingLocation,
      'itemDetails': itemDetails?.map((e) => e.toJson()).toList(),
      'totalPayableAmount': totalPayableAmount,
      'comments': comments,
      'outgoingDate': outgoingDate?.toIso8601String(),
      'createdDate': createdDate?.toIso8601String(),
      'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
      'invoiceDate': invoiceDate?.toIso8601String(),
      'invoiceNo': invoiceNo,
      'poCreatedPerson': poCreatedPerson,
      'poDate': poDate?.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'apinvoiceDate': apinvoiceDate?.toIso8601String(),
      'intimationDays': intimationDays,
      'paymentMode': paymentMode,
      'totalPrice': totalPrice,
      'payableAmount': payableAmount,
      'discountDetails': discountDetails,
      'grnCreatedPerson': grnCreatedPerson,
      'apCreatedPerson': apCreatedPerson,
      'grnVerifiedPerson': grnVerifiedPerson,
      'apVerifiedPerson': apVerifiedPerson,
      'paymentMethod': paymentMethod,
      'advanceAmount': advanceAmount,
      'partialAmount': partialAmount,
      'fullPaymentAmount': fullPaymentAmount,
      'paymentType': paymentType,
      'chequeNo': chequeNo,
      'onlinePayment': onlinePayment,
      'neftNo': neftNo,
      'rtgsNo': rtgsNo,
      'cash': cash,
      'status': status,
      'randomId': randomId,
      'taxDetails': taxDetails,
      'cashVoucherNo': cashVoucherNo,
      'contactpersonEmail': contactpersonEmail,
      'address': address,
      'country': country,
      'state': state,
      'city': city,
      'impsNo': impsNo,
      'upi': upi,
      'bankName': bankName,
      'paymentCash': paymentCash,
      'pettyCashAmount': pettyCashAmount,
      'hoCash': hoCash,
      'postalCode': postalCode,
      'gstNumber': gstNumber,
      'paymentTerms': paymentTerms,
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,
      'grnRandomId': grnRandomId,
      'apRandomId': apRandomId,
      'poRandomId': poRandomId,

      // ✅ PAYMENT SUMMARY
      'totalPaidAmount': totalPaidAmount,
      'remainingPayableAmount': remainingPayableAmount,
      'paymentHistory': paymentHistory?.map((e) => e.toJson()).toList(),
    };
  }

  Outgoing copyWith({
    String? status,
    double? remainingPayableAmount,
    double? totalPaidAmount,
    double? partialAmount,
    double? advanceAmount,
    double? fullPaymentAmount,
    List<PaymentHistory>? paymentHistory,
  }) {
    return Outgoing(
      outgoingId: outgoingId,
      purchaseOrderId: purchaseOrderId,
      invoiceId: invoiceId,
      grnId: grnId,
      vendorName: vendorName,
      orderDate: orderDate,
      grnDate: grnDate,
      receivingLocation: receivingLocation,
      itemDetails: itemDetails,
      totalPayableAmount: totalPayableAmount,
      comments: comments,
      outgoingDate: outgoingDate,
      createdDate: createdDate,
      lastUpdatedDate: lastUpdatedDate,
      invoiceDate: invoiceDate,
      invoiceNo: invoiceNo,
      poCreatedPerson: poCreatedPerson,
      poDate: poDate,
      paymentDate: paymentDate,
      apinvoiceDate: apinvoiceDate,
      intimationDays: intimationDays,
      paymentMode: paymentMode,
      totalPrice: totalPrice,
      payableAmount: payableAmount,
      discountDetails: discountDetails,
      grnCreatedPerson: grnCreatedPerson,
      apCreatedPerson: apCreatedPerson,
      grnVerifiedPerson: grnVerifiedPerson,
      apVerifiedPerson: apVerifiedPerson,
      paymentMethod: paymentMethod,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      partialAmount: partialAmount ?? this.partialAmount,
      fullPaymentAmount: fullPaymentAmount ?? this.fullPaymentAmount,
      paymentType: paymentType,
      chequeNo: chequeNo,
      onlinePayment: onlinePayment,
      neftNo: neftNo,
      rtgsNo: rtgsNo,
      cash: cash,
      status: status ?? this.status,
      randomId: randomId,
      taxDetails: taxDetails,
      cashVoucherNo: cashVoucherNo,
      contactpersonEmail: contactpersonEmail,
      address: address,
      country: country,
      state: state,
      city: city,
      impsNo: impsNo,
      upi: upi,
      bankName: bankName,
      paymentCash: paymentCash,
      pettyCashAmount: pettyCashAmount,
      postalCode: postalCode,
      gstNumber: gstNumber,
      paymentTerms: paymentTerms,
      shippingAddress: shippingAddress,
      billingAddress: billingAddress,
      grn: grn,
      ap: ap,
      grnRandomId: grnRandomId,
      apRandomId: apRandomId,
      poRandomId: poRandomId,
      hoCash: hoCash,
      totalPaidAmount: totalPaidAmount ?? this.totalPaidAmount,
      remainingPayableAmount:
          remainingPayableAmount ?? this.remainingPayableAmount,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}

// ✅ ✅ ✅ PAYMENT HISTORY MODEL
class PaymentHistory {
  final double? amount;
  final String? paymentType;
  final String? paymentMode;
  final String? paymentMethod;
  final DateTime? date;

  PaymentHistory({
    this.amount,
    this.paymentType,
    this.paymentMode,
    this.paymentMethod,
    this.date,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      amount: Outgoing._parseDouble(json['amount']),
      paymentType: Outgoing._parseString(json['paymentType']),
      paymentMode: Outgoing._parseString(json['paymentMode']),
      paymentMethod: Outgoing._parseString(json['paymentMethod']),
      date: Outgoing._parseDateTime(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentType': paymentType,
      'paymentMode': paymentMode,
      'paymentMethod': paymentMethod,
      'date': date?.toIso8601String(),
    };
  }
}

// ✅ ✅ ✅ BULK PAYMENT MODEL (UNCHANGED)
class BulkPayment {
  String? outgoingId;
  String? paymentMode;
  String? paymentType;
  double? fullPaymentAmount;
  double? partialAmount;
  double? advanceAmount;
  String? paymentMethod;
  String? chequeNo;
  String? transactionReference;
  double? pettyCashAmount;
  double? hoCash;
  String? bankName;
  String? cashVoucherNo;

  BulkPayment({
    this.outgoingId,
    this.paymentMode,
    this.paymentType,
    this.fullPaymentAmount,
    this.partialAmount,
    this.advanceAmount,
    this.paymentMethod,
    this.chequeNo,
    this.transactionReference,
    this.pettyCashAmount,
    this.hoCash,
    this.bankName,
    this.cashVoucherNo,
  });
}
