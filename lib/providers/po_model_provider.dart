// ignore_for_file: prefer_conditional_assignment

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/po.dart';

class POModalProvider with ChangeNotifier {
  final PO _po;

  POModalProvider(this._po);

  PO get po => _po;

  double get totalOrderAmount {
    return _po.items.fold(0.0, (sum, item) => sum + (item.finalPrice ?? 0.0));
  }

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
    if (index < 0 || index >= _po.items.length) return;

    final item = _po.items[index];

    if (count != null) {
      item.pendingCount = count;
    }
    if (eachQty != null) {
      item.pendingQuantity = eachQty;
    }
    if (newPrice != null) {
      item.newPrice = newPrice;
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

    final dio = Dio(
      BaseOptions(
        baseUrl: "http://192.168.29.252:8000/nextjstestapi",
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    try {
      final response = await dio.get(
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
    } catch (e) {
      debugPrint("Calculation error: $e");
    }
  }

  Future<void> saveChanges(BuildContext context) async {
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

    if (!confirm) return;

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

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Changes saved successfully!")),
      );
      notifyListeners();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save changes.")));
    }
  }

  Future<bool> _sendToBackend(
    String purchaseOrderId,
    List<Map<String, dynamic>> items,
  ) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: "http://192.168.29.252:8000/nextjstestapi",
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {"Content-Type": "application/json"},
      ),
    );

    try {
      final response = await dio.patch(
        "/purchaseorders/$purchaseOrderId/items",
        data: jsonEncode({"items": items}),
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Error sending update: $e");
      return false;
    }
  }
}
