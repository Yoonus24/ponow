import 'package:flutter/material.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/core/utils/app_snackbar.dart';
import 'package:purchaseorders2/services/dio_client.dart';
import '../models/po/po.dart';

class POModalProvider with ChangeNotifier {
  final PO _po;
  bool hasChanges = false;

  POModalProvider(this._po);

  PO get po => _po;

  double get totalOrderAmount {
    return _po.items.fold(0.0, (sum, item) => sum + (item.finalPrice ?? 0.0));
  }

  Map<int, String?> countErrors = {};
  Map<int, String?> quantityErrors = {};
  Map<int, String?> priceErrors = {};

  void updateItemRaw(
    int index, {
    double? count,
    double? eachQty,
    double? newPrice,
    double? befTaxDiscount,
    double? afTaxDiscount,
    double? taxPercentage,
    String? taxType,
  }) {
    hasChanges = true;
    if (index < 0 || index >= _po.items.length) return;

    final item = _po.items[index];

    if (count != null) {
      item.pendingCount = count;

      if (count > 0) {
        countErrors.remove(index);
      }
    }

    if (eachQty != null) {
      item.pendingQuantity = eachQty;

      if (eachQty > 0) {
        quantityErrors.remove(index);
      }
    }

    if (newPrice != null) {
      item.newPrice = newPrice;

      if (newPrice > 0) {
        priceErrors.remove(index);
      }
    }

    if (befTaxDiscount != null) {
      item.befTaxDiscount = befTaxDiscount;
    }

    if (afTaxDiscount != null) {
      item.afTaxDiscount = afTaxDiscount;
    }

    if (taxPercentage != null) {
      item.taxPercentage = taxPercentage;
    }

    if (taxType != null) {
      item.taxType = taxType;
    }

    notifyListeners();
  }

  String? validateItems() {
    countErrors.clear();
    quantityErrors.clear();
    priceErrors.clear();

    String? firstError;

    for (int i = 0; i < po.items.length; i++) {
      final item = po.items[i];

      if ((item.pendingTotalQuantity ?? 0) <= 0) {
        debugPrint("⏭ Skipping hidden item: ${item.itemName}");
        continue;
      }

      final count = item.pendingCount ?? item.count ?? 0;
      final qty = item.pendingQuantity ?? item.eachQuantity ?? 0;
      final price = item.newPrice ?? 0;

      debugPrint(
        "🔍 Checking ${item.itemName} → Count:$count Qty:$qty Price:$price",
      );

      if (count <= 0) {
        countErrors[i] = "";
        firstError ??= "Count must be greater than 0";
      }

      if (qty <= 0) {
        quantityErrors[i] = "";
        firstError ??= "Quantity must be greater than 0";
      }

      if (price <= 0) {
        priceErrors[i] = "";
        firstError ??= "Price must be greater than 0";
      }
    }

    notifyListeners();
    return firstError;
  }

  Future<void> calculateAndUpdateItem(int index) async {
    if (index < 0 || index >= _po.items.length) return;

    final item = _po.items[index];

    final pendingCount = item.pendingCount ?? item.count ?? 0;
    final pendingQty = item.pendingQuantity ?? item.eachQuantity ?? 0;
    final newPrice = item.newPrice ?? 0;
    final befDisc = item.befTaxDiscount ?? 0;
    final afDisc = item.afTaxDiscount ?? 0;
    final taxPerc = item.taxPercentage ?? 0;
    final taxType = item.taxType ?? "cgst_sgst";

    final pendingTotalQty = pendingCount * pendingQty;

    try {
      final response = await DioClient.dio.get(
        "/purchaseorders/items/totals",
        queryParameters: {
          "pendingTotalQuantity": pendingTotalQty,
          "poQuantity": pendingTotalQty,
          "newPrice": newPrice,
          "befTaxDiscount": befDisc,
          "afTaxDiscount": afDisc,
          "taxPercentage": taxPerc,
          "taxType": taxType,
        },
      );

      if (response.statusCode != 200) return;

      final data = response.data;

      item.pendingTotalQuantity = pendingTotalQty;
      item.pendingTotalPrice = data["pendingTotalPrice"];
      item.pendingBefTaxDiscountAmount = data["pendingBefTaxDiscountAmount"];
      item.pendingAfTaxDiscountAmount = data["pendingAfTaxDiscountAmount"];
      item.pendingDiscountAmount = data["pendingDiscountAmount"];
      item.pendingTaxAmount = data["pendingTaxAmount"];
      item.pendingFinalPrice = data["pendingFinalPrice"];
      item.pendingSgst = data["pendingSgst"];
      item.pendingCgst = data["pendingCgst"];
      item.pendingIgst = data["pendingIgst"];

      notifyListeners();
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("Calculation error: ${exception.message}");
    }
  }

  Future<bool> saveChangesDirect() async {
    List<Map<String, dynamic>> payloadItems = _po.items.map((item) {
      return {
        "itemId": item.itemId,
        "pendingCount": item.pendingCount ?? item.count ?? 0,
        "pendingQuantity": item.pendingQuantity ?? item.eachQuantity ?? 0,
        "newPrice": item.newPrice ?? 0,
        "befTaxDiscount": item.befTaxDiscount ?? 0,
        "afTaxDiscount": item.afTaxDiscount ?? 0,
        "taxPercentage": item.taxPercentage ?? 0,
        "taxType": item.taxType ?? "cgst_sgst",
      };
    }).toList();

    return await _sendToBackend(_po.purchaseOrderId, payloadItems);
  }

  Future<bool> saveChanges(BuildContext context) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Confirm Save"),
            content: const Text("Are you sure you want to save the changes?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Save"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return false; // 🔥 IMPORTANT

    List<Map<String, dynamic>> payloadItems = _po.items.map((item) {
      return {
        "itemId": item.itemId,
        "pendingCount": item.pendingCount ?? item.count ?? 0,
        "pendingQuantity": item.pendingQuantity ?? item.eachQuantity ?? 0,
        "newPrice": item.newPrice ?? 0,
        "befTaxDiscount": item.befTaxDiscount ?? 0,
        "afTaxDiscount": item.afTaxDiscount ?? 0,
        "taxPercentage": item.taxPercentage ?? 0,
        "taxType": item.taxType ?? "cgst_sgst",
      };
    }).toList();

    bool success = await _sendToBackend(_po.purchaseOrderId, payloadItems);

    if (!context.mounted) return false;

    if (success) {
      AppSnackbar.showSuccess(context, "Changes saved successfully!");
      notifyListeners();
      return true; // ✅ SUCCESS
    } else {
      AppSnackbar.showError(
        context,
        const AppException("Failed to save changes."),
      );
      return false;
    }
  }

  Future<bool> _sendToBackend(
    String purchaseOrderId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await DioClient.dio.patch(
        "/purchaseorders/$purchaseOrderId/items",
        data: {"items": items},
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("Error sending update: ${exception.message}");
      return false;
    }
  }
}
