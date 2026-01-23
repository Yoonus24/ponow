import 'package:purchaseorders2/models/grnitem.dart';

// models/grn.dart
class GRN {
  final String? grnId;
  final String? purchaseOrderId;
  final String? poRandomID;
  final String? vendorName;
  final String? grnDate;
  final String? grnVerifiedDate;
  final String? grnReturnedDate;
  final int? agingDay;
  final String? poDate;
  final String? invoiceDate;
  final String? invoiceNo;
  final String? receivingLocation;
  final List<ItemDetail>? itemDetails;
  final String? inspectionStatus;
  final String? receivedBy;
  double? totalReceivedAmount;
  double? totalAmountBeforeRoundOff;
  double? totalDiscount;
  double? totalTax;
  double? grnRoundOffAmount;
  final double? totalReturnedAmount;
  final double? totalReturnedTax;
  final double? totalReturnedDiscount;
  double? discountPrice;
  double? roundOffAdjustment; // ADD THIS FIELD
  String? comments;
  final String? attachments;
  final String? createdDate;
  String? lastUpdatedDate;
  final String? contactpersonEmail;
  final String? address;
  final String? country;
  final String? state;
  final String? city;
  final int? postalCode;
  final String? paymentTerms;
  final String? gstNumber;
  final String? shippingAddress;
  final String? billingAddress;
  String? status;
  final String? randomId;
  final String? grnVerifiedPerson;
  final String? grnReturnedPerson;
  double? grnAmount;
  final double? totalDebitAmount;
  final bool? hasDebitCreditNotes;

  GRN({
    this.grnId,
    this.purchaseOrderId,
    this.poRandomID,
    this.vendorName,
    this.grnDate,
    this.grnVerifiedDate,
    this.grnReturnedDate,
    this.agingDay,
    this.poDate,
    this.invoiceDate,
    this.invoiceNo,
    this.receivingLocation,
    this.itemDetails,
    this.inspectionStatus,
    this.receivedBy,
    this.totalReceivedAmount,
    this.totalAmountBeforeRoundOff,
    this.totalDiscount,
    this.totalTax,
    this.grnRoundOffAmount,
    this.totalReturnedAmount,
    this.totalReturnedTax,
    this.totalReturnedDiscount,
    this.discountPrice,
    this.roundOffAdjustment, // ADD THIS PARAMETER
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
    this.paymentTerms,
    this.gstNumber,
    this.shippingAddress,
    this.billingAddress,
    this.status,
    this.randomId,
    this.grnVerifiedPerson,
    this.grnReturnedPerson,
    this.grnAmount,
    this.totalDebitAmount,
    this.hasDebitCreditNotes,
  });

  factory GRN.fromJson(Map<String, dynamic> json) {
    return GRN(
      grnId: json['grnId'] as String?,
      purchaseOrderId: json['purchaseOrderId'] as String?,
      poRandomID: json['poRandomID'] as String?,
      vendorName: json['vendorName'] as String?,
      grnDate: json['grnDate'] as String?,
      grnVerifiedDate: json['grnVerifiedDate'] as String?,
      grnReturnedDate: json['grnReturnedDate'] as String?,
      agingDay: json['agingDay'] as int?,
      poDate: json['poDate'] as String?,
      invoiceDate: json['invoiceDate'] as String?,
      invoiceNo: json['invoiceNo'] as String?,
      receivingLocation: json['receivingLocation'] as String?,
      itemDetails: (json['itemDetails'] as List<dynamic>?)
          ?.map((e) => ItemDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      inspectionStatus: json['inspectionStatus'] as String?,
      receivedBy: json['receivedBy'] as String?,
      totalReceivedAmount: (json['totalReceivedAmount'] as num?)?.toDouble(),
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble(),
      totalTax: (json['totalTax'] as num?)?.toDouble(),
      totalReturnedAmount: (json['totalReturnedAmount'] as num?)?.toDouble(),
      totalReturnedTax: (json['totalReturnedTax'] as num?)?.toDouble(),
      totalReturnedDiscount: (json['totalReturnedDiscount'] as num?)
          ?.toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      totalAmountBeforeRoundOff: // ✅ ADD
      (json['totalAmountBeforeRoundOff'] as num?)
          ?.toDouble(),

      grnRoundOffAmount: // ✅ ADD
      (json['grnRoundOffAmount'] as num?)
          ?.toDouble(),
      // FIX: Load from grnRoundOffAmount field, not roundOffAdjustment
      roundOffAdjustment:
          (json['grnRoundOffAmount'] as num?)?.toDouble() ??
          (json['roundOffAdjustment'] as num?)?.toDouble() ??
          0.0,
      comments: json['comments'] as String?,
      attachments: json['attachments'] as String?,
      createdDate: json['createdDate'] as String?,
      lastUpdatedDate: json['lastUpdatedDate'] as String?,
      contactpersonEmail: json['contactpersonEmail'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as int?,
      paymentTerms: json['paymentTerms'] as String?,
      gstNumber: json['gstNumber'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      billingAddress: json['billingAddress'] as String?,
      status: json['status'] as String?,
      randomId: json['randomId'] as String?,
      grnVerifiedPerson: json['grnVerifiedPerson'] as String?,
      grnReturnedPerson: json['grnReturnedPerson'] as String?,
      grnAmount: (json['grnAmount'] as num?)?.toDouble(),
      totalDebitAmount: (json['totalDebitAmount'] as num?)?.toDouble(),
      hasDebitCreditNotes: json['hasDebitCreditNotes'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ================= IDS =================
      'grnId': grnId,
      'purchaseOrderId': purchaseOrderId,
      'poRandomID': poRandomID ?? '',
      'randomId': randomId,

      // ================= BASIC INFO =================
      'vendorName': vendorName,
      'grnDate': grnDate,
      'grnVerifiedDate': grnVerifiedDate,
      'grnReturnedDate': grnReturnedDate,
      'agingDay': agingDay,
      'poDate': poDate,
      'invoiceDate': invoiceDate,
      'invoiceNo': invoiceNo,
      'receivingLocation': receivingLocation,

      // ================= ITEMS =================
      'itemDetails': itemDetails?.map((e) => e.toJson()).toList(),

      // ================= STATUS =================
      'inspectionStatus': inspectionStatus,
      'receivedBy': receivedBy,
      'status': status,

      // ================= AMOUNTS (VERY IMPORTANT) =================
      // 🔒 Backend-calculated values (SOURCE OF TRUTH)
      'totalAmountBeforeRoundOff': totalAmountBeforeRoundOff,
      'grnRoundOffAmount': grnRoundOffAmount,
      'grnAmount': grnAmount,

      // 👤 User-entered (manual input only)
      'roundOffAdjustment': roundOffAdjustment,

      // ================= OTHER TOTALS =================
      'totalReceivedAmount': totalReceivedAmount,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'totalReturnedAmount': totalReturnedAmount,
      'totalReturnedTax': totalReturnedTax,
      'totalReturnedDiscount': totalReturnedDiscount,
      'discountPrice': discountPrice,

      // ================= META =================
      'comments': comments ?? '',
      'attachments': attachments,
      'createdDate': createdDate,
      'lastUpdatedDate': lastUpdatedDate,
      'contactpersonEmail': contactpersonEmail,
      'address': address,
      'country': country,
      'state': state,
      'city': city,
      'postalCode': postalCode,
      'paymentTerms': paymentTerms,
      'gstNumber': gstNumber,
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,

      // ================= EXTRA =================
      'grnVerifiedPerson': grnVerifiedPerson,
      'grnReturnedPerson': grnReturnedPerson,
      'totalDebitAmount': totalDebitAmount,
      'hasDebitCreditNotes': hasDebitCreditNotes,
    };
  }
}

class ReturnGRNRequest {
  String scenario;
  final DateTime returnedDate;
  final String returnedBy;
  final String? comments;
  final List<ReturnItem>? items;

  ReturnGRNRequest({
    required this.scenario,
    required this.returnedDate,
    required this.returnedBy,
    this.comments,
    this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'scenario': scenario,
      'returnedDate': returnedDate.toUtc().toIso8601String(),
      'returnedBy': returnedBy,
      if (comments != null) 'comments': comments,
      if (items != null)
        'items': items!.map((item) => item.toJson(scenario)).toList(),
    };
  }
}

class DebitCreditNote {
  final String? noteId;
  final String grnId;
  final String? vendorName;
  final List<ItemDetails> itemDetails;
  final DateTime createdDate;
  final String createdBy;
  final DateTime? lastUpdatedDate;
  final double? roundOffAdjustment; // Consider adding this for consistency

  DebitCreditNote({
    this.noteId,
    required this.grnId,
    this.vendorName,
    required this.itemDetails,
    required this.createdDate,
    required this.createdBy,
    this.lastUpdatedDate,
    this.roundOffAdjustment,
  });

  factory DebitCreditNote.fromJson(Map<String, dynamic> json) {
    return DebitCreditNote(
      noteId: json['noteId'],
      grnId: json['grnId'],
      vendorName: json['vendorName'],
      itemDetails: (json['itemDetails'] as List<dynamic>)
          .map((item) => ItemDetails.fromJson(item))
          .toList(),
      createdDate: DateTime.parse(json['createdDate']),
      createdBy: json['createdBy'],
      lastUpdatedDate: json['lastUpdatedDate'] != null
          ? DateTime.parse(json['lastUpdatedDate'])
          : null,
      roundOffAdjustment: (json['roundOffAdjustment'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'grnId': grnId,
      'vendorName': vendorName,
      'itemDetails': itemDetails.map((e) => e.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'createdBy': createdBy,
      'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
      'roundOffAdjustment': roundOffAdjustment,
    };
  }

  static DebitCreditNote fromGRN(GRN grn) {
    print('🔍 Starting GRN conversion. GRN comments: "${grn.comments}"');

    return DebitCreditNote(
      noteId: null,
      grnId: grn.grnId ?? '',
      vendorName: grn.vendorName ?? 'Unknown',
      itemDetails: (grn.itemDetails ?? []).map((grnItem) {
        print('🔄 Processing item: ${grnItem.itemName}');
        print(
          '   - Return history count: ${grnItem.returnHistory?.length ?? 0}',
        );

        String reason =
            grn.comments?.trim() ??
            (grnItem.returnHistory?.isNotEmpty == true
                ? grnItem.returnHistory![0]['reason'] as String? ?? ''
                : '');

        reason = reason.isEmpty ? 'No reason provided' : reason;
        print('   - Final reason: "$reason"');

        return ItemDetails(
          itemId: grnItem.itemId ?? '',
          itemName: grnItem.itemName ?? 'N/A',
          noteType: 'debit',
          quantity: grnItem.returnedQuantity?.toDouble() ?? 0.0,
          unitPrice: grnItem.unitPrice?.toDouble() ?? 0.0,
          totalPrice: grnItem.returnedTotalPrice?.toDouble() ?? 0.0,
          taxAmount: grnItem.returnedTaxAmount?.toDouble() ?? 0.0,
          discountAmount: grnItem.returnedDiscountAmount?.toDouble() ?? 0.0,
          finalPrice: grnItem.returnedFinalPrice?.toDouble() ?? 0.0,
          sgst: grnItem.returnedSgst?.toDouble(),
          cgst: grnItem.returnedCgst?.toDouble(),
          reason: reason,
        );
      }).toList(),
      createdDate: grn.createdDate != null
          ? DateTime.parse(grn.createdDate!)
          : DateTime.now(),
      createdBy: 'user123',
      lastUpdatedDate: null,
      roundOffAdjustment: grn.roundOffAdjustment, // Pass round off adjustment
    );
  }
}
