import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'po_state.dart';
import 'po_helper_mixin.dart';
import 'po_fetch_mixin.dart';
import 'po_vendor_mixin.dart';
import 'po_item_mixin.dart';
import 'po_action_mixin.dart';
import 'po_calculation_mixin.dart';
import 'po_filter_mixin.dart';

class POProvider extends POState
    with
        POHelperMixin,
        POCalculationMixin,
        POItemMixin,
        POFetchMixin,
        POVendorMixin,
        POActionMixin,
        POFilterMixin {
  // Implements the isolated execution link needed by the Helper layer
  Future<void> updateItemFromBackend(int index, String poId) async {
    final item = itemsInternal[index];

    final payload = {
      "items": [
        {
          "itemId": item.itemId,
          "newPrice": item.newPrice,
          "pendingCount": item.pendingCount,
          "eachQuantity": item.eachQuantity,
          "befTaxDiscount": item.befTaxDiscount,
          "afTaxDiscount": item.afTaxDiscount,
          "befTaxDiscountAmount": item.befTaxDiscountAmount,
          "afTaxDiscountAmount": item.afTaxDiscountAmount,
          "befTaxDiscountType": item.befTaxDiscountType,
          "afTaxDiscountType": item.afTaxDiscountType,
          "taxPercentage": item.taxPercentage,
          "taxType": item.taxType,
        },
      ],
    };

    try {
      final response = await dio.patch(
        "/purchaseorders/$poId/items",
        data: payload,
      );

      if (response.statusCode == 200) {
        final decoded = response.data;
        final serverItem = decoded["items"][0];
        itemsInternal[index].pendingTotalQuantity =
            serverItem["pendingTotalQuantity"];
        itemsInternal[index].pendingTotalPrice =
            serverItem["pendingTotalPrice"];
        itemsInternal[index].pendingDiscountAmount =
            serverItem["pendingDiscountAmount"];
        itemsInternal[index].pendingTaxAmount = serverItem["pendingTaxAmount"];
        itemsInternal[index].pendingFinalPrice =
            serverItem["pendingFinalPrice"];
        itemsInternal[index].pendingSgst = serverItem["pendingSgst"];
        itemsInternal[index].pendingCgst = serverItem["pendingCgst"];
        itemsInternal[index].pendingIgst = serverItem["pendingIgst"];
        itemsInternal[index].status = serverItem["status"];
        notifyListeners();
      } else {
        debugPrint("❌ Backend error: ${response.data}");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "❌ Error updating item: "
        "${exception.message}",
      );
    }
  }
}
