import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:purchaseorders2/services/dio_client.dart';

import 'ai_invoice_model.dart';

class AIInvoiceService {
  final Dio dio = DioClient.dio;

  Future<AIInvoiceResponse> scanInvoice({
    required File imageFile,

    required List<String> poItems,
  }) async {
    try {
      print("AI IMAGE PATH: ${imageFile.path}");

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path),

        "po_items": jsonEncode(
          poItems.map((e) {
            return {"itemName": e};
          }).toList(),
        ),
      });

      print("AI API CALL STARTED");

      print("AI URL: ${dio.options.baseUrl}/ai/scan-invoice");

      final response = await dio.post("ai/scan-invoice", data: formData);

      print("AI STATUS CODE: ${response.statusCode}");

      print("AI RAW RESPONSE: ${response.data}");

      return AIInvoiceResponse.fromJson(response.data);
    } catch (e) {
      print("AI SERVICE ERROR: $e");

      rethrow;
    }
  }
}
