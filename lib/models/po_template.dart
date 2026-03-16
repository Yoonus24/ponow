import 'package:purchaseorders2/models/freight.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

class POTemplate {
  final String templateId;
  final String templateName;
  final String vendorName;
  final String vendorContact;
  final List<Item> items;
  final List<FreightData> freights;
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
  final String? location;
  final String? locationName;
  final bool isActive;

  POTemplate({
    required this.templateId,
    required this.templateName,
    required this.vendorName,
    required this.vendorContact,
    required this.items,
    required this.freights,
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
    required this.location,
    required this.locationName,
  });

  /// Create template from existing PO
  factory POTemplate.fromPO(PO po, String templateName) {
    return POTemplate(
      templateId: '',
      templateName: templateName,
      vendorName: po.vendorName ?? '',
      vendorContact: po.vendorContact ?? '',
      items: po.items.map((item) => item.copyWith()).toList(),

      // ✅ FIX: Directly copy freights
      freights: po.freights ?? [],

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
      location: po.location,
      locationName: po.locationName,
      createdDate: ServerTimeService.now,
      randomId: po.randomId ?? '',
      isActive: true,
    );
  }

  /// Parse template from API response
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

      freights:
          (json['freights'] as List<dynamic>?)
              ?.map((f) => FreightData.fromJson(f))
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
          : ServerTimeService.now,

      randomId: json['randomId']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      location: json['location'],
      locationName: json['locationName'],
    );
  }

  /// Convert template to JSON for API
  Map<String, dynamic> toJson() {
    double freightAmount = freights.fold(0.0, (sum, f) => sum + f.amount);

    double freightTax = freights.fold(0.0, (sum, f) => sum + f.taxAmount);

    return {
      'templateName': templateName,
      'vendorName': vendorName,
      'vendorContact': vendorContact,

      'items': items.map((item) => item.toJson()).toList(),

      'freights': freights.map((f) => f.toJson()).toList(),

      'totalFreightAmount': freightAmount,
      'totalFreightTaxAmount': freightTax,

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
      'isActive': isActive,
      'location': location,
      'locationName': locationName,
    };
  }

  int get itemCount => items.length;

  String get formattedCreatedDate {
    return '${createdDate.day.toString().padLeft(2, '0')}/'
        '${createdDate.month.toString().padLeft(2, '0')}/'
        '${createdDate.year}';
  }
}
