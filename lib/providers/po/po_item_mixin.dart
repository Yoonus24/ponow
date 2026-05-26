import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/models/po/vendorpurchasemodel.dart';
import 'po_state.dart';

mixin POItemMixin on POState {
  Future<bool> fetchAllItems({
    int skip = 0,
    int limit = 100,
    bool append = false,
  }) async {
    try {
      final response = await dio.get(
        '/rawMaterials/getAll',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final decoded = response.data;
        List<dynamic> data = [];

        if (decoded is Map && decoded.containsKey('items')) {
          data = decoded['items'] ?? [];
        } else if (decoded is List) {
          data = decoded;
        }

        final newItems = data
            .map((item) => PurchaseItem.fromJson(item))
            .where((item) => (item.itemName ?? '').isNotEmpty)
            .toList();

        final newItemNames = newItems
            .map((item) => item.itemName ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        if (append) {
          purchaseItemsInternal.addAll(newItems);
          filteredPurchaseItemsInternal.addAll(newItemNames);
        } else {
          purchaseItemsInternal = newItems;
          filteredPurchaseItemsInternal = newItemNames;
        }
        notifyListeners();
        return newItems.length >= limit;
      }
      return false;
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "fetchAllItems error: "
        "${exception.message}",
      );

      return false;
    }
  }

  Future<List<PurchaseItem>> searchPurchaseItems({
    required String query,
    int skip = 0,
    int limit = 50,
    bool append = false,
  }) async {
    try {
      final response = await dio.get(
        '/rawMaterials/',
        queryParameters: {"itemName": query, "skip": skip, "limit": limit},
      );

      if ((response.statusCode ?? 0) < 200 ||
          (response.statusCode ?? 0) >= 300) {
        throw const AppException("Failed to search purchase items");
      }

      List<dynamic> data = [];

      if (response.data is Map && response.data['items'] != null) {
        data = response.data['items'];
      } else if (response.data is List) {
        data = response.data;
      } else {
        debugPrint(
          "Unexpected response structure: "
          "${response.data}",
        );

        return <PurchaseItem>[];
      }

      final items = data
          .map<PurchaseItem>((e) => PurchaseItem.fromJson(e))
          .toList();

      if (!append) {
        purchaseItemsInternal = items;
      } else {
        purchaseItemsInternal.addAll(items);
      }

      notifyListeners();

      return items;
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "Search error: "
        "${exception.message}",
      );

      return <PurchaseItem>[];
    }
  }
}
