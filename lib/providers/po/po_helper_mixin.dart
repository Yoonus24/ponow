import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/models/po/po_item.dart';
import 'po_state.dart';

mixin POHelperMixin on POState {
  // ==================== PRIVATE HELPER METHODS ====================
  void setLoadingStateInternal(bool loading) {
    isLoadingInternal = loading;
    notifyListeners();
  }

  void setErrorInternal(String? err) {
    errorInternal = err;
    notifyListeners();
  }

  Map<String, dynamic> buildPOQueryParamsInternal({
    String? status,
    String? vendorName,
    String? itemName,
    String? randomId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTimeRange? dateRange,
    String? searchQuery,
    String? filterByField,
    bool? includeInactive,
    int skip = 0,
    int limit = 50,
  }) {
    final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status;
    }
    if (vendorName != null && vendorName.isNotEmpty) {
      queryParams['vendorName'] = vendorName;
    }
    if (itemName != null && itemName.isNotEmpty) {
      queryParams['itemName'] = itemName;
    }
    if (randomId != null && randomId.isNotEmpty) {
      queryParams['randomId'] = randomId;
    }

    final dateFormatter = DateFormat('yyyy-MM-dd');

    if (dateRange != null) {
      queryParams['fromDate'] = dateFormatter.format(dateRange.start);
      queryParams['toDate'] = dateFormatter.format(dateRange.end);
    } else if (fromDate != null && toDate != null) {
      queryParams['fromDate'] = dateFormatter.format(fromDate);
      queryParams['toDate'] = dateFormatter.format(toDate);
    } else if (fromDate != null) {
      queryParams['fromDate'] = dateFormatter.format(fromDate);
    } else if (toDate != null) {
      queryParams['toDate'] = dateFormatter.format(toDate);
    }

    if (filterByField != null && filterByField.isNotEmpty) {
      queryParams['filterBy'] = filterByField;
    }
    if (includeInactive != null) {
      queryParams['includeInactive'] = includeInactive.toString();
    }

    return queryParams;
  }

  List<PO> parsePOsFromDataInternal(List data) {
    return data
        .map((e) {
          final po = PO.fromJson(e);
          po.items.removeWhere((item) => (item.pendingTotalQuantity ?? 0) <= 0);
          return po;
        })
        .whereType<PO>()
        .toList();
  }

  void updatePOListInternal(
    List<PO> fetchedPOs,
    bool clearExisting,
    bool append,
    int skip,
    int limit,
  ) {
    if (clearExisting && !append) {
      posInternal = List.from(fetchedPOs);
      poListInternal
        ..clear()
        ..addAll(posInternal);
    } else if (append) {
      final existingIds = posInternal.map((p) => p.purchaseOrderId).toSet();
      final newPOs = fetchedPOs.where(
        (po) => !existingIds.contains(po.purchaseOrderId),
      );
      posInternal.addAll(newPOs);
      poListInternal.addAll(newPOs);
    } else {
      posInternal = List.from(fetchedPOs);
      poListInternal
        ..clear()
        ..addAll(posInternal);
    }

    hasMoreInternal = fetchedPOs.length >= limit;
    skipInternal = skip + fetchedPOs.length;
  }

  List<Map<String, dynamic>> buildUpdatedItemsInternal(List<Item> items) {
    return items.map((item) {
      final double qty = item.quantity ?? 0.0;
      final double price = item.newPrice ?? item.existingPrice ?? 0.0;
      final double safeCount =
          (item.pendingCount == null || item.pendingCount == 0)
          ? (item.count == null || item.count == 0 ? 1.0 : item.count!)
          : item.pendingCount!;
      final double safeQty =
          item.pendingQuantity ?? item.eachQuantity ?? item.quantity ?? 0.0;
      final double safeTotal = safeCount * safeQty;
      final double pendingFinal =
          item.pendingFinalPrice ?? item.finalPrice ?? 0.0;
      final double pendingTotal =
          item.pendingTotalPrice ?? item.totalPrice ?? 0.0;
      final double pendingDiscount = item.pendingDiscountAmount ?? 0.0;
      final double pendingTax = item.pendingTaxAmount ?? 0.0;

      double sgst = 0, cgst = 0, igst = 0;
      if ((item.taxType ?? 'cgst_sgst') == 'igst') {
        igst = pendingTax;
      } else {
        cgst = pendingTax / 2;
        sgst = pendingTax / 2;
      }

      return {
        "itemId": item.itemId ?? "",
        "itemName": item.itemName ?? "",
        "quantity": qty,
        "poQuantity": item.poQuantity ?? qty,
        "uom": item.uom ?? "",
        "count": safeCount,
        "pendingCount": safeCount,
        "eachQuantity": safeQty,
        "pendingQuantity": safeQty,
        "pendingTotalQuantity": safeTotal,
        "existingPrice": item.existingPrice ?? 0.0,
        "newPrice": price,
        "taxPercentage": item.taxPercentage ?? 0.0,
        "taxType": item.taxType ?? "cgst_sgst",
        "befTaxDiscount": item.befTaxDiscount ?? 0.0,
        "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,
        "befTaxDiscountType": item.befTaxDiscountType ?? "percentage",
        "afTaxDiscount": item.afTaxDiscount ?? 0.0,
        "afTaxDiscountAmount": item.afTaxDiscountAmount ?? 0.0,
        "afTaxDiscountType": item.afTaxDiscountType ?? "percentage",
        "pendingTaxAmount": pendingTax,
        "pendingDiscountAmount": pendingDiscount,
        "pendingTotalPrice": pendingTotal,
        "pendingFinalPrice": pendingFinal,
        "poQuantitysgst": cgst,
        "poQuantitycgst": sgst,
        "poQuantityigst": igst,
      };
    }).toList();
  }

  List<Map<String, dynamic>> buildPostItemsInternal(List<Item> items) {
    return items.map((item) {
      final double qty = item.quantity ?? 0.0;
      final double price = item.newPrice ?? item.existingPrice ?? 0.0;
      final double pendingFinal =
          item.pendingFinalPrice ?? item.finalPrice ?? 0.0;
      final double pendingTotal =
          item.pendingTotalPrice ?? item.totalPrice ?? 0.0;
      final double pendingDiscount = item.pendingDiscountAmount ?? 0.0;
      final double pendingTax = item.pendingTaxAmount ?? 0.0;

      double sgst = 0, cgst = 0, igst = 0;
      if ((item.taxType ?? 'cgst_sgst') == 'igst') {
        igst = pendingTax;
      } else {
        cgst = pendingTax / 2;
        sgst = pendingTax / 2;
      }

      return {
        "itemId": item.itemId ?? "",
        "itemCode": item.itemCode ?? "",
        "barcode": item.barcode ?? "",
        "itemName": item.itemName ?? "",
        "randomId": item.randomId ?? "",
        "purchasecategoryName": item.purchasecategoryName ?? "",
        "purchasesubcategoryName": item.purchasesubcategoryName ?? "",
        "hsnCode": item.hsnCode ?? "",
        "quantity": qty,
        "poQuantity": qty,
        "count": item.count ?? 1.0,
        "eachQuantity": item.eachQuantity ?? 0.0,
        "pendingCount": item.pendingCount ?? 1.0,
        "pendingQuantity": item.pendingQuantity ?? qty,
        "pendingTotalQuantity": item.pendingTotalQuantity ?? qty,
        "receivedQuantity": item.receivedQuantity ?? 0.0,
        "damagedQuantity": item.damagedQuantity ?? 0.0,
        "existingPrice": item.existingPrice ?? 0.0,
        "newPrice": price,
        "totalPrice": item.totalPrice ?? pendingTotal,
        "finalPrice": item.finalPrice ?? pendingFinal,
        "pendingTotalPrice": pendingTotal,
        "pendingFinalPrice": pendingFinal,
        "taxPercentage": item.taxPercentage ?? 0.0,
        "taxType": item.taxType ?? "cgst_sgst",
        "taxAmount": item.taxAmount ?? pendingTax,
        "pendingTaxAmount": pendingTax,
        "sgst": sgst,
        "cgst": cgst,
        "igst": igst,
        "pendingSgst": item.pendingSgst ?? sgst,
        "pendingCgst": item.pendingCgst ?? cgst,
        "pendingIgst": item.pendingIgst ?? igst,
        "befTaxDiscount": item.befTaxDiscount ?? 0.0,
        "afTaxDiscount": item.afTaxDiscount ?? 0.0,
        "befTaxDiscountAmount": item.befTaxDiscountAmount ?? 0.0,
        "afTaxDiscountAmount": item.afTaxDiscountAmount ?? 0.0,
        "befTaxDiscountType": item.befTaxDiscountType.isNotEmpty
            ? item.befTaxDiscountType
            : "percentage",
        "afTaxDiscountType": item.afTaxDiscountType.isNotEmpty
            ? item.afTaxDiscountType
            : "percentage",
        "discountAmount": item.discountAmount ?? pendingDiscount,
        "pendingDiscountAmount": pendingDiscount,
        "pendingBefTaxDiscountAmount": item.pendingBefTaxDiscountAmount ?? 0.0,
        "pendingAfTaxDiscountAmount": item.pendingAfTaxDiscountAmount ?? 0.0,
        "poQuantityTaxAmount": item.poQuantityTaxAmount ?? pendingTax,
        "poQuantityDiscountAmount":
            item.poQuantityDiscountAmount ?? pendingDiscount,
        "poQuantitypendingTotalPrice":
            item.poQuantitypendingTotalPrice ?? pendingTotal,
        "poQuantitypendingFinalPrice":
            item.poQuantitypendingFinalPrice ?? pendingFinal,
        "poQuantitysgst": item.poQuantitysgst ?? sgst,
        "poQuantitycgst": item.poQuantitycgst ?? cgst,
        "poQuantityigst": item.poQuantityigst ?? igst,
        "uom": item.uom ?? "",
        "status": item.status ?? "",
        "expiryDate": (item.expiryDate.isNotEmpty) ? item.expiryDate : null,
        "poPhoto": item.poPhoto ?? "",
        "variance": item.variance ?? 0.0,
        "stockQuantity": item.stockQuantity ?? 0.0,
      };
    }).toList();
  }

  String formatDateForBackendInternal(String dateString) {
    if (dateString.isEmpty) return "";
    try {
      final parts = dateString.split('-');
      if (parts.length == 3 &&
          parts[0].length == 2 &&
          parts[1].length == 2 &&
          parts[2].length == 4) {
        return "${parts[2]}-${parts[1]}-${parts[0]}";
      }
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  String normalizeDateInternal(String date) {
    try {
      if (date.contains('-')) {
        List<String> parts = date.split('-');
        if (parts[0].length == 2 && parts[1].length == 2) {
          return "${parts[2]}-${parts[1]}-${parts[0]}";
        }
      }
      return DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(date).toUtc().toLocal());
    } catch (e) {
      return date;
    }
  }

  // ==================== UTILITY METHODS ====================
  Map<String, int> getFilterCounts() {
    return {
      'All': posInternal.length,
      'Pending': posInternal.where((po) => po.poStatus == 'Pending').length,
      'Approved': posInternal.where((po) => po.poStatus == 'Approved').length,
      'PartiallyReceived': posInternal
          .where((po) => po.poStatus == 'PartiallyReceived')
          .length,
      'GRNConverted': posInternal
          .where((po) => po.poStatus == 'GRNConverted')
          .length,
      'APInvoiceConverted': posInternal
          .where((po) => po.poStatus == 'APInvoiceConverted')
          .length,
    };
  }

  void cleanupUnusedKeys(List<PO> currentPOs) {
    final currentRandomIds = currentPOs
        .map((po) => po.randomId)
        .whereType<String>()
        .toSet();
  }

  void removeApprovedPO(String poId) {
    posInternal.removeWhere((po) => po.purchaseOrderId == poId);
    poListInternal.removeWhere((po) => po.purchaseOrderId == poId);
    notifyListeners();
  }

  void setSelectedPO(PO? po) {
    selectedPOInternal = po;
    notifyListeners();
  }

  void setPos(List<PO> newOrders) {
    posInternal = newOrders;
    poListInternal
      ..clear()
      ..addAll(posInternal);
    notifyListeners();
  }

  void setApprovedItems(List<Item> items) {
    approvedItems = items;
    notifyListeners();
  }

  void setTaxData(Map<String, dynamic> data) {
    taxDataInternal = data;
    notifyListeners();
  }

  void addItem(Item newItem) {
    itemsInternal.add(newItem);
    notifyListeners();
  }

  void updateItem(
    int index, {
    double? count,
    double? eachQuantity,
    required String poId,
  }) {
    final item = itemsInternal[index];
    if (count != null) item.pendingCount = count;
    if (eachQuantity != null) item.eachQuantity = eachQuantity;
    notifyListeners();
    // Intentionally abstract loop configuration dynamically inside master entry po_provider.dart
    (this as dynamic).updateItemFromBackend(index, poId);
  }

  Future<bool> checkInvoiceNumberExists({
    required String invoiceNo,
    required String currentPurchaseOrderId,
    required String currentVendorName,
  }) async {
    try {
      final response = await dio.get('/purchaseorders/getByInvoiceNo');
      if (response.statusCode == 200) {
        final List<dynamic> purchaseOrders = response.data;
        final searchInvoiceNo = invoiceNo.toLowerCase().trim();
        final searchVendorName = currentVendorName.toLowerCase().trim();

        for (final order in purchaseOrders) {
          final existingInvoice =
              order['invoiceNo']?.toString().toLowerCase().trim() ?? '';
          final poId = order['purchaseOrderId']?.toString() ?? '';
          final existingVendor =
              order['vendorName']?.toString().toLowerCase().trim() ?? '';

          if (existingInvoice == searchInvoiceNo &&
              existingVendor == searchVendorName &&
              poId != currentPurchaseOrderId) {
            return true;
          }
        }
        return false;
      }
      return false;
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "Invoice check error: "
        "${exception.message}",
      );

      return false;
    }
  }

  Future<Response> postWithRedirectHandling(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await dio.post(url, data: body);
      if (response.statusCode! >= 300 && response.statusCode! < 400) {
        final location = response.headers['location'];
        if (location != null) {
          return await dio.get(location.first);
        }
      }
      return response;
    } catch (e, stackTrace) {
      throw AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }
}
