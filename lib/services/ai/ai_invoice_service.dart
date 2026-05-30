import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/services/dio_client.dart';

import 'ai_invoice_model.dart';

class AIInvoiceService {
  final Dio dio = DioClient.dio;

  // =====================================================
  // SUGGEST PURCHASE ORDERS
  // =====================================================

  Future<POSuggestionResponse> suggestPO({required File imageFile}) async {
    try {
      debugPrint("SUGGEST PO IMAGE PATH: ${imageFile.path}");

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path),
      });

      debugPrint("SUGGEST PO API CALL STARTED");

      debugPrint(
        "SUGGEST PO URL: "
        "${dio.options.baseUrl}/ai/suggest-po",
      );

      final response = await dio.post("ai/suggest-po", data: formData);

      debugPrint(
        "SUGGEST PO STATUS CODE: "
        "${response.statusCode}",
      );

      debugPrint(
        "SUGGEST PO RESPONSE: "
        "${response.data}",
      );

      return POSuggestionResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("SUGGEST PO ERROR: $e");

      rethrow;
    }
  }

  // =====================================================
  // SCAN INVOICE
  // =====================================================

  Future<AIInvoiceResponse> scanInvoice({
    required File imageFile,
    required List<String> poItems,
    String? selectedPoId,
  }) async {
    try {
      debugPrint("AI IMAGE PATH: ${imageFile.path}");

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path),

        "po_items": jsonEncode(
          poItems.map((e) {
            return {"itemName": e};
          }).toList(),
        ),

        if (selectedPoId != null) "selected_po_id": selectedPoId,
      });

      debugPrint("AI API CALL STARTED");

      debugPrint(
        "AI URL: "
        "${dio.options.baseUrl}/ai/scan-invoice",
      );

      debugPrint(
        "SELECTED PO ID: "
        "$selectedPoId",
      );

      final response = await dio.post("ai/scan-invoice", data: formData);

      debugPrint(
        "AI STATUS CODE: "
        "${response.statusCode}",
      );

      debugPrint(
        "AI RAW RESPONSE: "
        "${response.data}",
      );

      return AIInvoiceResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("AI SERVICE ERROR: $e");

      rethrow;
    }
  }
}
