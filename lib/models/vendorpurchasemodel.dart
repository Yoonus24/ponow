class Vendor {
  final String vendorName;
  final String vendorId;

  Vendor({required this.vendorName, required this.vendorId});

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      vendorName: json['vendorName'] ?? '',
      vendorId: json['vendorId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'vendorName': vendorName, 'vendorId': vendorId};
  }
}

class VendorAll {
  final String vendorName;
  final String contactpersonPhone;
  final String contactpersonEmail;
  final String address;
  final String country;
  final String paymentTerms;
  final String state;
  final String city;
  final int postalCode;
  final String gstNumber;
  final int creditLimit;
  final String vendorId;

  VendorAll({
    required this.vendorName,
    required this.contactpersonPhone,
    required this.vendorId,
    required this.contactpersonEmail,
    required this.address,
    required this.country,
    required this.paymentTerms,
    required this.state,
    required this.city,
    required this.postalCode,
    required this.gstNumber,
    required this.creditLimit,
  });

  factory VendorAll.fromJson(Map<String, dynamic> json) {
    return VendorAll(
      vendorName: json['vendorName'] ?? '',
      contactpersonPhone: json['contactpersonPhone'] ?? '',
      vendorId: json['vendorId'] ?? '',
      contactpersonEmail: json['contactpersonEmail'] ?? '',
      address: json['address'] ?? '',
      country: json['country'] ?? '',
      paymentTerms: json['paymentTerms'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      postalCode: int.tryParse(json['postalCode']?.toString() ?? '0') ?? 0,
      creditLimit: int.tryParse(json['creditLimit']?.toString() ?? '0') ?? 0,
      gstNumber: json['gstNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorName': vendorName,
      'contactpersonPhone': contactpersonPhone,
      'vendorId': vendorId,
      'contactpersonEmail': contactpersonEmail,
      'address': address,
      'country': country,
      'paymentTerms': paymentTerms,
      'state': state,
      'city': city,
      'postalCode': postalCode,
      'gstNumber': gstNumber,
      'creditLimit': creditLimit,
    };
  }

  Vendor toVendor() {
    return Vendor(vendorName: vendorName, vendorId: vendorId);
  }
}

class VendorDetails {
  final String vendorName;
  final int count;
  final double totalAmount;
  final List<String> statuses;

  VendorDetails({
    required this.vendorName,
    required this.count,
    required this.totalAmount,
    required this.statuses,
  });

  factory VendorDetails.fromJson(Map<String, dynamic> json) {
    return VendorDetails(
      vendorName: json['vendorName'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      statuses: List<String>.from(json['statuses'] ?? []),
    );
  }
}

class PurchaseItem {
  final String itemName;
  final String itemCode; // ✅ ADDED
  final double purchasePrice;
  final double purchasetaxName;
  final String purchasecategoryName;
  final String purchasesubcategoryName;
  final String hsnCode;
  final String purchaseItemId;
  final String uom;

  PurchaseItem({
    required this.itemName,
    required this.itemCode, // ✅ ADDED
    required this.purchasePrice,
    required this.purchasetaxName,
    required this.purchaseItemId,
    required this.uom,
    required this.purchasecategoryName,
    required this.purchasesubcategoryName,
    required this.hsnCode,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      itemName: json['itemName'] ?? '',
      itemCode: json['itemCode'] ?? '', // ✅ ADDED
      purchasePrice: json['purchasePrice']?.toDouble() ?? 0.0,
      purchasetaxName: json['purchasetaxName']?.toDouble() ?? 0.0,
      purchaseItemId: json['purchaseItemId'] ?? json['purchaseitemId'] ?? '',
      uom: json['uom'] ?? '',
      purchasecategoryName: json['purchasecategoryName'] ?? '',
      purchasesubcategoryName: json['purchasesubcategoryName'] ?? '',
      hsnCode: json['hsnCode'] ?? '',
    );
  }
}
