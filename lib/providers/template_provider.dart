// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/po.dart';
import '../models/po_template.dart';

class TemplateProvider extends ChangeNotifier {
  List<POTemplate> _templates = [];
  bool _isLoading = false;
  String? _error;

  Dio get _dio => DioClient.dio;
  List<POTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int _skip = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  Future<void> fetchTemplates({
    String search = "",
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _skip = 0;
      _hasMore = true;
      _templates.clear();
    }

    if (!_hasMore) return;

    _isLoading = _skip == 0;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {"skip": _skip, "limit": _limit};

      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _dio.get(
        '/purchaseorder-templates',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        final newTemplates = data
            .map((json) => POTemplate.fromJson(json))
            .toList();

        if (_skip == 0) {
          _templates = newTemplates;
        } else {
          _templates.addAll(newTemplates);
        }

        // pagination control
        if (newTemplates.length < _limit) {
          _hasMore = false;
        } else {
          _skip += _limit;
        }
      } else {
        _error = "Failed to load templates";
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _error = "Request timed out. Please try again.";
        } else if (e.type == DioExceptionType.connectionError) {
          _error = "No internet connection. Please check your network.";
        } else if (e.response != null) {
          final backendMessage =
              e.response?.data?['detail'] ?? e.response?.data?['message'];

          _error = backendMessage ?? "Something went wrong. Please try again.";
        } else {
          _error = "Unable to connect to server. Please try again later.";
        }
      } else {
        _error = "Unexpected error occurred. Please try again.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTemplates({String search = ""}) async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    await fetchTemplates(search: search);
    _isFetchingMore = false;
  }

  Future<bool> createTemplate(PO po, String templateName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final template = POTemplate.fromPO(po, templateName);

      print("🌍 API CALL → /purchaseorder-templates");
      print("📤 REQUEST DATA: ${template.toJson()}");

      final response = await _dio.post(
        '/purchaseorder-templates',
        data: template.toJson(), 
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      print("✅ RESPONSE STATUS: ${response.statusCode}");
      print("📥 RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTemplates();
        return true;
      } else {
        throw Exception('Failed to create template');
      }
    } catch (e) {
      print("❌ CREATE TEMPLATE ERROR: $e");

      if (e is DioException) {
        final backendMessage = e.response?.data?['detail'];
        throw Exception(backendMessage ?? "Failed to create template");
      }

      throw Exception("Something went wrong");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PO?> createPOFromTemplate(String templateId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.post(
        '/purchaseorder-templates/$templateId/create-order',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
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

  Future<bool> _setTemplateActive(String templateId, bool isActive) async {
    _isLoading = true;
    notifyListeners();

    final action = isActive ? 'activate' : 'deactivate';

    try {
      final response = await _dio.patch(
        '/purchaseorder-templates/$templateId/$action',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        await fetchTemplates();
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

  Future<bool> deleteTemplate(String templateId) async {
    try {
      final response = await _dio.delete(
        '/purchaseorder-templates/$templateId',
        options: Options(headers: {'Content-Type': 'application/json'}),
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

  PO convertTemplateToPO(POTemplate template) {
    final now = ServerTimeService.now.toIso8601String();

    return PO(
      purchaseOrderId: '',
      vendorName: template.vendorName,
      vendorContact: template.vendorContact,
      location: template.location,
      locationName: template.locationName,
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
      orderDate: now,
      createdDate: now,
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
