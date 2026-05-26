import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/services/dio_client.dart';

import 'ai_invoice_model.dart';

class AIInvoiceService {
  final Dio dio = DioClient.dio;

  Future<AIInvoiceResponse> scanInvoice({
    required File imageFile,

    required List<String> poItems,
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
      });

      debugPrint("AI API CALL STARTED");

      debugPrint("AI URL: ${dio.options.baseUrl}/ai/scan-invoice");

      final response = await dio.post("ai/scan-invoice", data: formData);

      debugPrint("AI STATUS CODE: ${response.statusCode}");

      debugPrint("AI RAW RESPONSE: ${response.data}");

      return AIInvoiceResponse.fromJson(response.data);
    } catch (e) {
      debugPrint("AI SERVICE ERROR: $e");

      rethrow;
    }
  }
}
