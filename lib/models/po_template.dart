import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/po_item.dart';

class POTemplate {
  final String templateId;
  final String templateName;
  final String vendorName;
  final String vendorContact;
  final List<Item> items;
  final double totalOrderAmount;
  final String paymentTerms;
  final String shippingAddress;
  final String billingAddress;
  final String contactpersonEmail;
  final String address;
  final String country;
  final String state;
  final String city;
  final int postalCode;
  final String gstNumber;
  final int creditLimit;
  final DateTime createdDate;
  final String randomId;

  /// ⭐ NEW FIELD for Active/Inactive
  final bool isActive;

  POTemplate({
    required this.templateId,
    required this.templateName,
    required this.vendorName,
    required this.vendorContact,
    required this.items,
    required this.totalOrderAmount,
    required this.paymentTerms,
    required this.shippingAddress,
    required this.billingAddress,
    required this.contactpersonEmail,
    required this.address,
    required this.country,
    required this.state,
    required this.city,
    required this.postalCode,
    required this.gstNumber,
    required this.creditLimit,
    required this.createdDate,
    required this.randomId,
    required this.isActive,
  });

  factory POTemplate.fromPO(PO po, String templateName) {
    return POTemplate(
      templateId: '',
      templateName: templateName,
      vendorName: po.vendorName ?? '',
      vendorContact: po.vendorContact ?? '',
      items: po.items.map((item) => item.copyWith()).toList(),
      totalOrderAmount: po.totalOrderAmount ?? 0.0,
      paymentTerms: po.paymentTerms ?? '',
      shippingAddress: po.shippingAddress ?? '',
      billingAddress: po.billingAddress ?? '',
      contactpersonEmail: po.contactpersonEmail ?? '',
      address: po.address ?? '',
      country: po.country ?? '',
      state: po.state ?? '',
      city: po.city ?? '',
      postalCode: po.postalCode ?? 0,
      gstNumber: po.gstNumber ?? '',
      creditLimit: po.creditLimit ?? 0,
      createdDate: DateTime.now(),
      randomId: po.randomId ?? '',
      isActive: true, // NEW default value
    );
  }

  factory POTemplate.fromJson(Map<String, dynamic> json) {
    return POTemplate(
      templateId: json['templateId'] ?? json['_id']?.toString() ?? '',
      templateName:
          json['templateName'] ??
          json['template_name'] ??
          json['templatename'] ??
          json['name'] ??
          json['title'] ??
          '',
      vendorName: json['vendorName']?.toString() ?? '',
      vendorContact: json['vendorContact']?.toString() ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((i) => Item.fromJson(i))
              .toList() ??
          [],
      totalOrderAmount: (json['totalOrderAmount'] ?? 0.0).toDouble(),
      paymentTerms: json['paymentTerms']?.toString() ?? '',
      shippingAddress: json['shippingAddress']?.toString() ?? '',
      billingAddress: json['billingAddress']?.toString() ?? '',
      contactpersonEmail: json['contactpersonEmail']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      postalCode: json['postalCode'] ?? 0,
      gstNumber: json['gstNumber']?.toString() ?? '',
      creditLimit: json['creditLimit'] ?? 0,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      randomId: json['randomId']?.toString() ?? '',

      /// ⭐ The FIX: Backend must send isActive, but we default to true if missing
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateName': templateName,
      'vendorName': vendorName,
      'vendorContact': vendorContact,
      'items': items.map((item) => item.toJson()).toList(),
      'totalOrderAmount': totalOrderAmount,
      'paymentTerms': paymentTerms,
      'shippingAddress': shippingAddress,
      'billingAddress': billingAddress,
      'contactpersonEmail': contactpersonEmail,
      'address': address,
      'country': country,
      'state': state,
      'city': city,
      'postalCode': postalCode,
      'gstNumber': gstNumber,
      'creditLimit': creditLimit,
      'isTemplate': true,
      'createdDate': createdDate.toIso8601String(),
      'randomId': randomId,

      /// NEW FIELD
      'isActive': isActive,
    };
  }

  int get itemCount => items.length;

  String get formattedCreatedDate {
    return '${createdDate.day.toString().padLeft(2, '0')}/'
        '${createdDate.month.toString().padLeft(2, '0')}/'
        '${createdDate.year}';
  }
}
