import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:purchaseorders2/models/po_item.dart';
import '../models/po.dart';
import '../models/po_template.dart';

class TemplateProvider extends ChangeNotifier {
  List<POTemplate> _templates = [];
  bool _isLoading = false;
  String? _error;

  final String baseUrl = 'http://192.168.29.252:8000/nextjstestapi';

  List<POTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // =========================================================
  // FETCH TEMPLATES (with backend search filter)
  // =========================================================
  Future<void> fetchTemplates({String search = ""}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // If search is empty → no filter
      final uri = search.trim().isEmpty
          ? Uri.parse('$baseUrl/purchaseorders/templates')
          : Uri.parse(
              '$baseUrl/purchaseorders/templates?search=${Uri.encodeQueryComponent(search.trim())}',
            );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _templates = data.map((json) => POTemplate.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to load templates: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Failed to load templates: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // CREATE TEMPLATE FROM PO
  // =========================================================
  Future<bool> createTemplate(PO po, String templateName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final template = POTemplate.fromPO(po, templateName);

      final response = await http.post(
        Uri.parse('$baseUrl/purchaseorders/templates'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(template.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTemplates();
        return true;
      } else {
        _error = 'Failed to create template: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Failed to create template: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // CREATE PO FROM TEMPLATE
  // =========================================================
  Future<PO?> createPOFromTemplate(String templateId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/purchaseorders/templates/$templateId/create-order'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PO.fromJson(data['purchaseOrder']);
      } else {
        _error = 'Failed to create PO from template: ${response.statusCode}';
        return null;
      }
    } catch (e) {
      _error = 'Failed to create PO from template: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // ACTIVATE / DEACTIVATE TEMPLATE
  // =========================================================
  Future<bool> _setTemplateActive(String templateId, bool isActive) async {
    _isLoading = true;
    notifyListeners();

    final action = isActive ? 'activate' : 'deactivate';

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/purchaseorders/templates/$templateId/$action'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchTemplates(); // Reload from backend
        return true;
      } else {
        _error =
            'Failed to ${isActive ? 'activate' : 'deactivate'} template: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Failed to ${isActive ? 'activate' : 'deactivate'} template: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activateTemplate(String templateId) {
    return _setTemplateActive(templateId, true);
  }

  Future<bool> deactivateTemplate(String templateId) {
    return _setTemplateActive(templateId, false);
  }

  // =========================================================
  // DELETE TEMPLATE
  // =========================================================
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/purchaseorders/templates/$templateId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _templates.removeWhere((t) => t.templateId == templateId);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete template: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete template: $e';
      return false;
    }
  }

  // =========================================================
  // Convert Template → PO
  // =========================================================
  PO convertTemplateToPO(POTemplate template) {
    return PO(
      purchaseOrderId: '',
      vendorName: template.vendorName,
      vendorContact: template.vendorContact,
      items: template.items.map((item) => _createNewItem(item)).toList(),
      totalOrderAmount: template.totalOrderAmount,
      pendingOrderAmount: template.totalOrderAmount,
      paymentTerms: template.paymentTerms,
      shippingAddress: template.shippingAddress,
      billingAddress: template.billingAddress,
      contactpersonEmail: template.contactpersonEmail,
      address: template.address,
      country: template.country,
      state: template.state,
      city: template.city,
      postalCode: template.postalCode,
      gstNumber: template.gstNumber,
      creditLimit: template.creditLimit,
      poStatus: 'Pending for Approve',
      orderDate: DateTime.now().toIso8601String(),
      createdDate: DateTime.now().toIso8601String(),
      randomId: '',
    );
  }

  Item _createNewItem(Item original) {
    return Item(
      itemId: '',
      itemCode: original.itemCode,
      barcode: original.barcode,
      itemName: original.itemName,
      purchasecategoryName: original.purchasecategoryName,
      purchasesubcategoryName: original.purchasesubcategoryName,
      count: original.count,
      pendingCount: original.pendingCount,
      pendingQuantity: original.pendingQuantity,
      pendingTotalQuantity: original.pendingTotalQuantity,
      pendingTaxAmount: original.pendingTaxAmount,
      pendingDiscountAmount: original.pendingDiscountAmount,

      pendingSgst: original.pendingSgst,
      pendingCgst: original.pendingCgst,
      pendingIgst: original.pendingIgst,
      pendingTotalPrice: original.pendingTotalPrice,
      pendingFinalPrice: original.pendingFinalPrice,
      pendingBefTaxDiscountAmount: original.pendingBefTaxDiscountAmount,
      pendingAfTaxDiscountAmount: original.pendingAfTaxDiscountAmount,
      hsnCode: original.hsnCode,
      poPhoto: original.poPhoto,
      taxAmount: original.taxAmount,
      taxType: original.taxType,
      befTaxDiscount: original.befTaxDiscount,
      afTaxDiscount: original.afTaxDiscount,
      befTaxDiscountAmount: original.befTaxDiscountAmount,
      afTaxDiscountAmount: original.afTaxDiscountAmount,
      taxPercentage: original.taxPercentage,
      discountAmount: original.discountAmount,
      finalPrice: original.finalPrice,
      nos: original.nos,
      eachQuantity: original.eachQuantity,
      receivedQuantity: original.receivedQuantity,
      discountPrice: original.discountPrice,
      damagedQuantity: original.damagedQuantity,
      quantity: original.quantity,
      poQuantity: original.poQuantity,
      uom: original.uom,
      discount: original.discount,
      purchasetaxName: original.purchasetaxName,
      stockQuantity: original.stockQuantity,
      existingPrice: original.existingPrice,
      newPrice: original.newPrice,
      totalPrice: original.totalPrice,
      sgst: original.sgst,
      igst: original.igst,
      cgst: original.cgst,
      status: original.status,
      expiryDate: original.expiryDate,
      variance: original.variance,
      isDiscountPercentage: original.isDiscountPercentage,
      befTaxDiscountType: original.befTaxDiscountType,
      afTaxDiscountType: original.afTaxDiscountType,
    );
  }

  // =========================================================
  // GET TEMPLATE BY ID
  // =========================================================
  POTemplate? getTemplateById(String templateId) {
    try {
      return _templates.firstWhere((t) => t.templateId == templateId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
