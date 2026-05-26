import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/models/po/freight.dart';
import 'package:purchaseorders2/models/po/purchase_tax_model.dart';
import 'package:purchaseorders2/models/po/freight_name_model.dart';
import 'po_state.dart';

mixin POCalculationMixin on POState {
  // ==================== TAX & FREIGHT METHODS ====================
  Future<void> fetchPurchaseTaxes() async {
    try {
      final response = await dio.get('/purchasetaxes/');
      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        purchaseTaxes = (response.data as List)
            .map((e) => PurchaseTax.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  Future<void> fetchFreightNames() async {
    try {
      final response = await dio.get('/freights/');
      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        freightNames = (response.data as List)
            .map((e) => FreightName.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  Future<FreightData> calculateFreightTotals({
    required double amount,
    required String taxCode,
    required String taxType,
  }) async {
    try {
      final response = await dio.get(
        '/purchaseorders/freight/totals',
        queryParameters: {"amt": amount, "tCode": taxCode, "taxType": taxType},
      );

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw const AppException("Failed to calculate freight totals");
      }

      return FreightData.fromJson(response.data);
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>> calculatePOTotals({
    required List items,
    required List freights,
  }) async {
    try {
      final response = await dio.post(
        '/purchaseorders/calculate-totals',
        data: {"items": items, "freights": freights},
      );

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw const AppException("Failed to calculate PO totals");
      }

      return response.data;
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  // ==================== CALCULATION METHODS ====================
  Future<Map<String, dynamic>> calculateGrnOverallDiscount({
    required List<Map<String, dynamic>> items,
    required double discountAmount,
    required String discountType,
  }) async {
    try {
      final response = await dio.post(
        '/purchaseorders/items/grn/calculate-overall-discount',
        data: {
          "applyOverallDiscount": true,
          "overallDiscountAmount": discountAmount,
          "discount_type": discountType,
          "items": items,
        },
      );

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw const AppException("Failed to calculate GRN overall discount");
      }

      return response.data;
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>> calculateItemTotalsBackend({
    required double pendingTotalQuantity,
    required double poQuantity,
    required double newPrice,
    double? befTaxDiscount,
    double? afTaxDiscount,
    double? befTaxDiscountAmount,
    double? afTaxDiscountAmount,
    String befTaxDiscountType = 'percentage',
    String afTaxDiscountType = 'percentage',
    double taxPercentage = 0,
    String taxType = 'cgst_sgst',
  }) async {
    try {
      if (pendingTotalQuantity <= 0 || newPrice <= 0) {
        return {
          'pendingTotalPrice': 0.0,
          'pendingBefTaxDiscountAmount': 0.0,
          'pendingAfTaxDiscountAmount': 0.0,
          'pendingTaxAmount': 0.0,
          'pendingFinalPrice': 0.0,
          'pendingDiscountAmount': 0.0,
          'pendingSgst': 0.0,
          'pendingCgst': 0.0,
          'pendingIgst': 0.0,
          'befTaxDiscount': befTaxDiscount ?? 0.0,
          'afTaxDiscount': afTaxDiscount ?? 0.0,
          'poQuantity': poQuantity,
          'quantity': pendingTotalQuantity,
        };
      }

      final queryParameters = {
        'pendingTotalQuantity': pendingTotalQuantity,
        'poQuantity': poQuantity,
        'newPrice': newPrice,
        'taxPercentage': taxPercentage,
        'taxType': taxType,
      };

      if (befTaxDiscountType == 'amount') {
        queryParameters['befTaxDiscountAmount'] = befTaxDiscountAmount ?? 0.0;
        queryParameters['befTaxDiscount'] = 0.0;
      } else {
        queryParameters['befTaxDiscount'] = befTaxDiscount ?? 0.0;
        queryParameters['befTaxDiscountAmount'] = 0.0;
      }

      if (afTaxDiscountType == 'amount') {
        queryParameters['afTaxDiscountAmount'] = afTaxDiscountAmount ?? 0.0;
        queryParameters['afTaxDiscount'] = 0.0;
      } else {
        queryParameters['afTaxDiscount'] = afTaxDiscount ?? 0.0;
        queryParameters['afTaxDiscountAmount'] = 0.0;
      }

      queryParameters['befTaxDiscountType'] = befTaxDiscountType;
      queryParameters['afTaxDiscountType'] = afTaxDiscountType;

      final response = await dio.get(
        '/purchaseorders/items/totals',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw AppException(
          'Failed to calculate item totals: '
          '${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  Future<Map<String, dynamic>> calculateOverallDiscountAPI({
    required List<Map<String, dynamic>> items,
    required bool applyOverallDiscount,
    required String overallDiscountType,
    required double overallDiscount,
    required double overallDiscountAmount,
  }) async {
    final payload = {
      "applyOverallDiscount": applyOverallDiscount,
      "overallDiscountType": overallDiscountType,
      "overallDiscount": overallDiscount,
      "overallDiscountAmount": overallDiscountAmount,
      "items": items,
      "roundOffAdjustment": 0.0,
      "taxType": "cgst_sgst",
    };

    debugPrint("========== OVERALL DISCOUNT API REQUEST ==========");
    debugPrint("applyOverallDiscount: $applyOverallDiscount");
    debugPrint("overallDiscountType: $overallDiscountType");
    debugPrint("overallDiscount: $overallDiscount");
    debugPrint("overallDiscountAmount: $overallDiscountAmount");
    debugPrint("Payload: $payload");
    debugPrint("==================================================");

    try {
      final response = await dio.post(
        '/purchaseorders/items/calculate-overall-discount',
        data: payload,
      );

      debugPrint("========== OVERALL DISCOUNT API RESPONSE ==========");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Data: ${response.data}");
      debugPrint("===================================================");

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        return response.data;
      } else {
        throw AppException("HTTP ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("========== OVERALL DISCOUNT API ERROR ==========");

      debugPrint("Error: ${exception.message}");

      debugPrint("=================================================");

      rethrow;
    }
  }
}
