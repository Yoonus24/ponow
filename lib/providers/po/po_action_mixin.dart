import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/errors/app_exception.dart';
import 'package:purchaseorders2/core/utils/app_snackbar.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/models/po/po_item.dart';
import 'package:purchaseorders2/models/po/vendorpurchasemodel.dart';
import 'package:purchaseorders2/pdfs/approved_pdf.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'po_state.dart';
import 'po_helper_mixin.dart';

mixin POActionMixin on POState, POHelperMixin {
  bool isPdfLoading(String poId) {
    return pdfLoadingMapInternal[poId] ?? false;
  }

  Future<void> generatePdf(PO po, BuildContext context) async {
    final id = po.purchaseOrderId;

    pdfLoadingMapInternal[id] = true;
    notifyListeners();

    try {
      final poService = PurchaseOrderService();

      final pdfFile = await poService.generatePurchaseOrderPdf(id);

      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint("PDF failed: ${exception.message}");

      if (context.mounted) {
        AppSnackbar.showError(context, exception);
      }
    } finally {
      pdfLoadingMapInternal[id] = false;
      notifyListeners();
    }
  }

  // ==================== PO ACTIONS ====================
  Future<void> approvePo(String purchaseOrderId) async {
    try {
      final response = await dio.patch(
        '/purchaseorders/approved/$purchaseOrderId',
      );
      if (response.statusCode == 200) {
        debugPrint("PO Approved Successfully");
        await (this as dynamic).fetchPendingPOsFromBackend(clearExisting: true);
        notifyListeners();
      } else {
        throw const AppException("Failed to approve PO");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "Approve PO Error: "
        "${exception.message}",
      );

      setErrorInternal(exception.message);
    }
  }

  Future<void> rejectPo(String purchaseOrderId) async {
    try {
      final response = await dio.patch(
        '/purchaseorders/rejected/$purchaseOrderId',
      );
      if (response.statusCode == 200) {
        debugPrint("PO Rejected Successfully");
        await (this as dynamic).fetchPendingPOsFromBackend(clearExisting: true);
        notifyListeners();
      } else {
        throw const AppException("Failed to reject PO");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "Reject PO Error: "
        "${exception.message}",
      );

      setErrorInternal(exception.message);
    }
  }

  Future<void> approveAndRemovePO(String purchaseOrderId) async {
    try {
      setLoadingStateInternal(true);
      await approvePo(purchaseOrderId);
      await (this as dynamic).fetchPendingPOsFromBackend(clearExisting: true);
      notifyListeners();
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      setErrorInternal(exception.message);

      rethrow;
    } finally {
      setLoadingStateInternal(false);
    }
  }

  Future<void> revertPOToPending(String purchaseOrderId) async {
    setLoadingStateInternal(true);
    setErrorInternal(null);

    try {
      await dio.put(
        '/purchaseorders/$purchaseOrderId',
        data: {"poStatus": "Pending"},
      );
      await (this as dynamic).fetchPendingPOsFromBackend(clearExisting: true);
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      setErrorInternal(exception.message);
    } finally {
      setLoadingStateInternal(false);
    }
  }

  Future<void> changePoStatusToPending(String id) async {
    await dio.put('/purchaseorders/$id', data: {"poStatus": "Pending"});
  }

  Future<void> updatePO(PO po) async {
    setLoadingStateInternal(true);
    setErrorInternal(null);

    try {
      final String now = ServerTimeService.now.toIso8601String();
      final updatedItems = buildUpdatedItemsInternal(po.items);

      final double totalFreightAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.amount ?? 0),
      );
      final double totalFreightTaxAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.taxAmount ?? 0),
      );

      final double totalPendingAmount = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingFinalPrice ?? 0),
      );
      final double totalPendingDiscount = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingDiscountAmount ?? 0),
      );
      final double totalPendingTax = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingTaxAmount ?? 0),
      );

      final double roundOffValue = po.roundOffAdjustment ?? 0.0;
      final double finalAmount =
          totalPendingAmount +
          totalFreightAmount +
          totalFreightTaxAmount +
          roundOffValue;

      final Map<String, dynamic> updateData = {
        "lastUpdatedDate": now,
        "vendorName": po.vendorName,
        "vendorContact": po.vendorContact,
        "items": updatedItems,
        "totalOrderAmount": finalAmount,
        "pendingOrderAmount": finalAmount,
        "pendingDiscountAmount": totalPendingDiscount,
        "pendingTaxAmount": totalPendingTax,
        "roundOffAdjustment": roundOffValue,
        "roundOffValue": roundOffValue,
        "freights": po.freights?.map((f) => f.toJson()).toList() ?? [],
        "totalFreightAmount": totalFreightAmount,
        "totalFreightTaxAmount": totalFreightTaxAmount,
        "location": po.location,
        "locationName": po.locationName,
        "orderDate": po.orderDate,
        "expectedDeliveryDate": po.expectedDeliveryDate,
      };

      final response = await dio.patch(
        '/purchaseorders/${po.purchaseOrderId}',
        data: updateData,
      );

      if (response.statusCode == 200) {
        await (this as dynamic).fetchPOsWithFilters(clearExisting: true);
      } else {
        throw const AppException("Failed to update PO");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      setErrorInternal(exception.message);
    } finally {
      setLoadingStateInternal(false);
    }
  }

  Future<Map<String, dynamic>> updatePoDetails(
    String poId,
    List<Item> items,
    String invoiceNumber,
    DateTime invoiceDate,
    double discount, {
    double? roundOffAdjustment,
    List<dynamic>?
    freights, // Keeping exact reference signature mapping dynamically
    double? totalFreightAmount,
    double? totalFreightTaxAmount,
  }) async {
    debugPrint("🟢 updatePoDetails() CALLED");
    debugPrint("📌 PO ID: $poId");

    try {
      final dateFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");
      final formattedInvoiceDate = dateFormatter.format(invoiceDate);

      debugPrint("📅 Invoice Date (formatted): $formattedInvoiceDate");
      debugPrint("🧾 Invoice No: $invoiceNumber");
      debugPrint("🔄 Round Off Adjustment: ${roundOffAdjustment ?? 0.0}");
      debugPrint("🌐 Fetching PO directly from backend...");

      final PO? po = await (this as dynamic).fetchPOById(poId);

      if (po == null) {
        throw const AppException("PO not found from backend");
      }

      debugPrint("✅ PO fetched: ${po.randomId}");
      debugPrint("📦 Preparing items for API...");

      final receivedItems = items.map((item) => item.copyWith()).toList();

      final itemsList = receivedItems.map((item) {
        String? formattedExpiryDate;

        if (item.expiryDate.isNotEmpty) {
          formattedExpiryDate = normalizeDateInternal(item.expiryDate);
        }

        debugPrint("=========== ITEM DEBUG START ===========");
        debugPrint("➡️ Item Name: ${item.itemName}");
        debugPrint("🆔 Item ID: ${item.itemId}");
        debugPrint("🎯 Random ID: ${item.randomId}");
        debugPrint("📥 Received Qty: ${item.receivedQuantity}");
        debugPrint("💰 New Price (grnPrice): ${item.newPrice}");
        debugPrint("🏷 Existing Price: ${item.existingPrice}");
        debugPrint("📉 BefTax Discount: ${item.befTaxDiscount}");
        debugPrint("📉 AfTax Discount: ${item.afTaxDiscount}");
        debugPrint("📅 Expiry Date: $formattedExpiryDate");
        debugPrint("📍 Location ID: ${item.locationId}");
        debugPrint("📦 Available Stock: ${item.availableStock}");
        debugPrint("=========== ITEM DEBUG END ===========");

        return {
          "itemId": item.itemId,
          "receivedQuantity": item.receivedQuantity ?? 0,
          "grnPrice": item.newPrice ?? 0.0,
          "damagedQuantity": 0.0,
          "befTaxDiscount": item.befTaxDiscount ?? 0.0,
          "afTaxDiscount": item.afTaxDiscount ?? 0.0,
          "expiryDate": formattedExpiryDate,
        };
      }).toList();

      debugPrint("📦 Total Items Sent: ${itemsList.length}");

      final Map<String, dynamic> body = {
        "items": itemsList,
        "invoiceNo": invoiceNumber,
        "invoiceDate": formattedInvoiceDate,
        "discountPrice": 0,
        "grnRoundOffAmount": roundOffAdjustment ?? 0.0,
        "poId": poId,
        "freights": po.freights?.map((f) => f.toJson()).toList() ?? [],
        "totalFreightAmount": po.totalFreightAmount ?? 0.0,
        "totalFreightTaxAmount": po.totalFreightTaxAmount ?? 0.0,
      };

      debugPrint("=========== UPDATE PO API PAYLOAD START ===========");
      debugPrint(body.toString());
      debugPrint("=========== UPDATE PO API PAYLOAD END ===========");

      debugPrint("🌐 Calling API: PATCH /purchaseorders/receivedupdates/$poId");

      final response = await dio.patch(
        '/purchaseorders/receivedupdates/$poId',
        data: body,
      );

      debugPrint("📡 Status Code: ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("❌ API FAILED");
        debugPrint("❌ Response Data: ${response.data}");
        throw Exception(response.data?["detail"] ?? "PO update failed");
      }

      debugPrint("=========== UPDATE PO RESPONSE START ===========");
      debugPrint(response.data.toString());
      debugPrint("🔎 GRN Created: ${response.data["grnCreated"]}");
      debugPrint("🆔 GRN ID: ${response.data["grnId"]}");
      debugPrint("🎯 GRN Random ID: ${response.data["grnRandomId"]}");
      debugPrint(
        "📦 Newly Received Items: ${response.data["newlyReceivedItems"]}",
      );
      debugPrint("📍 Location Used: ${response.data["locationUsed"]}");
      debugPrint("💰 Price Updates: ${response.data["priceUpdates"]}");

      debugPrint("=========== STOCK UPDATE DEBUG START ===========");
      if (response.data["stockUpdate"] != null) {
        final stockUpdate = response.data["stockUpdate"];
        debugPrint("✅ stockUpdate.success: ${stockUpdate["success"]}");
        debugPrint(
          "📦 stockUpdate.total_processed: ${stockUpdate["total_processed"]}",
        );
        debugPrint("✔ stockUpdate.successful: ${stockUpdate["successful"]}");
        debugPrint("❌ stockUpdate.failed: ${stockUpdate["failed"]}");
        debugPrint(
          "📈 stockUpdate.stock_updates: ${stockUpdate["stock_updates"]}",
        );
        debugPrint(
          "💰 stockUpdate.price_updates: ${stockUpdate["price_updates"]}",
        );
        debugPrint(
          "📍 stockUpdate.receiving_location: ${stockUpdate["receiving_location"]}",
        );
        debugPrint("📝 stockUpdate.items: ${stockUpdate["items"]}");

        if ((stockUpdate["stock_updates"] ?? 0) == 0) {
          debugPrint("🚨 WARNING: STOCK NOT UPDATED");
        } else {
          debugPrint("🎉 SUCCESS: STOCK UPDATED");
        }

        if ((stockUpdate["price_updates"] ?? 0) == 0) {
          debugPrint("⚠️ No price updates happened");
        } else {
          debugPrint("🎉 SUCCESS: PRICE UPDATED");
        }
      } else {
        debugPrint("❌ stockUpdate is NULL");
      }
      debugPrint("=========== STOCK UPDATE DEBUG END ===========");
      debugPrint("=========== UPDATE PO RESPONSE END ===========");
      debugPrint("✅ updatePoDetails SUCCESS");

      return response.data;
    } catch (e, stack) {
      final exception = AppErrorHandler.handle(e, stackTrace: stack);

      debugPrint(
        "❌ updatePoDetails FAILED: "
        "${exception.message}",
      );

      debugPrintStack(stackTrace: stack);

      throw exception;
    }
  }

  Future<void> postPO(PO po, VendorAll selectedVendorDetails) async {
    setLoadingStateInternal(true);
    errorInternal = null;

    try {
      final String now = ServerTimeService.now.toIso8601String();

      final formattedOrderedDate = formatDateForBackendInternal(
        po.orderedDate ?? "",
      );
      final formattedExpectedDate = formatDateForBackendInternal(
        po.expectedDeliveryDate ?? "",
      );

      final updatedItems = buildPostItemsInternal(po.items);

      final double totalFreightAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.amount ?? 0),
      );

      final double totalFreightTaxAmount = (po.freights ?? []).fold(
        0.0,
        (a, b) => a + (b.taxAmount ?? 0),
      );

      final double totalPendingAmount = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingFinalPrice ?? 0),
      );

      final double totalPendingDiscount = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingDiscountAmount ?? 0),
      );

      final double totalPendingTax = po.items.fold(
        0.0,
        (s, i) => s + (i.pendingTaxAmount ?? 0),
      );

      final double roundOffValue = po.roundOffAdjustment ?? 0.0;

      final double finalAmount =
          totalPendingAmount +
          totalFreightAmount +
          totalFreightTaxAmount +
          roundOffValue;

      final bool isHoldOrder = finalAmount > selectedVendorDetails.creditLimit;

      final updatedPO = po.copyWith(
        vendorId: selectedVendorDetails.vendorId,
        vendorName: selectedVendorDetails.vendorName,
        vendorcode: selectedVendorDetails.randomId,
        orderDate: now,
        createdDate: now,
        lastUpdatedDate: now,
        approvedDate: null,
        rejectedDate: null,
        invoiceDate: null,
        orderedDate: formattedOrderedDate,
        expectedDeliveryDate: formattedExpectedDate,
        totalOrderAmount: finalAmount,
        pendingOrderAmount: finalAmount,
        pendingDiscountAmount: totalPendingDiscount,
        pendingTaxAmount: totalPendingTax,
        roundOffAdjustment: roundOffValue,
        poStatus: isHoldOrder
            ? 'CreditLimit for Approve'
            : 'Pending for Approve',
      );

      final Map<String, dynamic> poJson = updatedPO.toJson()
        ..['vendorcode'] = selectedVendorDetails.randomId
        ..['vendorId'] = selectedVendorDetails.vendorId
        ..['vendorName'] = selectedVendorDetails.vendorName
        ..['freights'] = po.freights?.map((f) => f.toJson()).toList() ?? []
        ..['items'] = updatedItems
        ..['totalFreightAmount'] = totalFreightAmount
        ..['totalFreightTaxAmount'] = totalFreightTaxAmount
        ..['discountMode'] = po.overallDiscount?.backendMode ?? "percentage"
        ..['overallDiscountValue'] = totalPendingDiscount
        ..['discountPrice'] = totalPendingDiscount
        ..['totalDiscount'] = totalPendingDiscount
        ..['totalTax'] = totalPendingTax
        ..removeWhere(
          (key, value) =>
              (key == "approvedDate" ||
                  key == "rejectedDate" ||
                  key == "invoiceDate") &&
              (value == "" || value == null),
        );

      debugPrint("🔥 FINAL POST API HIT");
      debugPrint("🔥 DISCOUNT MODE = ${poJson["discountMode"]}");
      debugPrint("🔥 DISCOUNT VALUE = ${poJson["overallDiscountValue"]}");
      debugPrint("🔥 FINAL JSON = ${jsonEncode(poJson)}");

      final response = await dio.post('/purchaseorders/', data: poJson);

      debugPrint("✅ POST RESPONSE STATUS: ${response.statusCode}");
      debugPrint("✅ POST RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
      } else {
        throw const AppException("Failed to post PO");
      }
    } catch (e, stackTrace) {
      final exception = AppErrorHandler.handle(e, stackTrace: stackTrace);

      debugPrint(
        "❌ POST PO ERROR: "
        "${exception.message}",
      );

      debugPrint("❌ STACKTRACE: $stackTrace");

      setErrorInternal(exception.message);
    }
    // finalAmount() {
    //   setLoadingStateInternal(false);
    // }

    // Make sure finally context executes safely preserving signature
    setLoadingStateInternal(false);
  }
}
