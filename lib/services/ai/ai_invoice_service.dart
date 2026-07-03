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

  Future<POSuggestionResponse> suggestPO({
    File? imageFile,
    List<File>? imageFiles,
    File? pdfFile,
  }) async {
    try {
      debugPrint("======================================");
      debugPrint("SUGGEST PO API START");
      debugPrint("======================================");

      // =====================================================
      // Validate Upload Mode
      // =====================================================

      int uploadModes = 0;
      if (imageFile != null) uploadModes++;
      if (imageFiles != null && imageFiles.isNotEmpty) uploadModes++;
      if (pdfFile != null) uploadModes++;

      if (uploadModes == 0) {
        throw Exception(
          "No file provided. Please provide an image, multiple images, or a PDF.",
        );
      }

      if (uploadModes > 1) {
        throw Exception(
          "Please provide only one upload type: image, multiple images, or PDF.",
        );
      }

      // =====================================================
      // Build FormData
      // =====================================================

      final formData = FormData();

      // ─── SINGLE IMAGE MODE ────────────────────────────

      if (imageFile != null) {
        debugPrint("SINGLE IMAGE MODE: ${imageFile.path}");

        formData.files.add(
          MapEntry(
            "image", // Changed from "file" to "image" to match backend
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ),
        );
      }
      // ─── PDF MODE ──────────────────────────────────────
      else if (pdfFile != null) {
        debugPrint("PDF MODE: ${pdfFile.path}");

        formData.files.add(
          MapEntry(
            "pdf", // Changed from "file" to "pdf" to match backend
            await MultipartFile.fromFile(
              pdfFile.path,
              filename: pdfFile.path.split('/').last,
            ),
          ),
        );
      }
      // ─── MULTIPLE IMAGES MODE ─────────────────────────
      else if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint("MULTI IMAGE MODE: ${imageFiles.length} images");

        // Send each image as a separate entry with key "images"
        for (int i = 0; i < imageFiles.length; i++) {
          final file = imageFiles[i];
          debugPrint("  Image ${i + 1}: ${file.path}");

          formData.files.add(
            MapEntry(
              "images", // Use "images" key for multiple files
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        }
      }

      // =====================================================
      // API Call
      // =====================================================

      final response = await dio.post("ai/suggest-po", data: formData);

      debugPrint("======================================");
      debugPrint("SUGGEST PO RESPONSE");
      debugPrint("======================================");

      debugPrint(const JsonEncoder.withIndent("  ").convert(response.data));

      final responseModel = POSuggestionResponse.fromJson(response.data);

      debugPrint("======================================");
      debugPrint("SUGGESTED POS");
      debugPrint("======================================");

      for (final po in responseModel.suggestedPOs) {
        debugPrint(
          "PO => ${po.poNumber}"
          " | ID => ${po.poId}"
          " | SCORE => ${po.score}"
          " | MATCHED ITEMS => ${po.matchedItems}/${po.totalItems}"
          " | REASON => ${po.reason}",
        );
      }

      debugPrint("======================================");
      debugPrint("AUTO SUGGESTED PO");
      debugPrint("======================================");

      if (responseModel.autoSuggestedPO != null) {
        debugPrint(
          "AUTO => ${responseModel.autoSuggestedPO!.poNumber}"
          " | ID => ${responseModel.autoSuggestedPO!.poId}"
          " | SCORE => ${responseModel.autoSuggestedPO!.score}",
        );
      } else {
        debugPrint("NO AUTO SUGGESTED PO");
      }

      return responseModel;
    } on DioException catch (e) {
      debugPrint("SUGGEST PO ERROR: ${e.response?.data}");
      rethrow;
    }
  }

  // =====================================================
  // SCAN INVOICE
  // =====================================================

  Future<AIInvoiceResponse> scanInvoice({
    File? imageFile,
    List<File>? imageFiles,
    File? pdfFile,
    required List<String> poItems,
    String? selectedPoId,
    String? cacheKey, // ← ADD THIS
  }) async {
    try {
      debugPrint("======================================");
      debugPrint("SCAN INVOICE API START");
      debugPrint("======================================");

      // =====================================================
      // Validate Upload Mode (Only if no cacheKey)
      // =====================================================

      int uploadModes = 0;
      if (imageFile != null) uploadModes++;
      if (imageFiles != null && imageFiles.isNotEmpty) uploadModes++;
      if (pdfFile != null) uploadModes++;

      // If cacheKey is provided, we don't need files
      if (cacheKey == null) {
        if (uploadModes == 0) {
          throw Exception(
            "No file provided. Please provide an image, multiple images, or a PDF.",
          );
        }

        if (uploadModes > 1) {
          throw Exception(
            "Please provide only one upload type: image, multiple images, or PDF.",
          );
        }
      }

      // =====================================================
      // Build FormData
      // =====================================================

      final formData = FormData();

      // ─── ADD CACHE KEY (if provided) ────────────────────

      if (cacheKey != null) {
        formData.fields.add(MapEntry("cache_key", cacheKey));
        debugPrint("USING CACHED DATA: $cacheKey");
        debugPrint("SKIPPING FILE UPLOAD (using cached extraction)");
      } else {
        debugPrint("NO CACHE KEY - USING FILE UPLOAD");

        // ─── SINGLE IMAGE MODE ────────────────────────────

        if (imageFile != null) {
          debugPrint("SINGLE IMAGE MODE: ${imageFile.path}");

          formData.files.add(
            MapEntry(
              "image",
              await MultipartFile.fromFile(
                imageFile.path,
                filename: imageFile.path.split('/').last,
              ),
            ),
          );
        }
        // ─── PDF MODE ──────────────────────────────────────
        else if (pdfFile != null) {
          debugPrint("PDF MODE: ${pdfFile.path}");

          formData.files.add(
            MapEntry(
              "pdf",
              await MultipartFile.fromFile(
                pdfFile.path,
                filename: pdfFile.path.split('/').last,
              ),
            ),
          );
        }
        // ─── MULTIPLE IMAGES MODE ─────────────────────────
        else if (imageFiles != null && imageFiles.isNotEmpty) {
          debugPrint("MULTI IMAGE MODE: ${imageFiles.length} images");
          for (int i = 0; i < imageFiles.length; i++) {
            debugPrint("  Image ${i + 1}: ${imageFiles[i].path}");
          }

          for (int i = 0; i < imageFiles.length; i++) {
            final file = imageFiles[i];

            formData.files.add(
              MapEntry(
                "images",
                await MultipartFile.fromFile(
                  file.path,
                  filename: file.path.split('/').last,
                ),
              ),
            );
          }
        }
      }

      // ─── ADD PO ITEMS ──────────────────────────────────

      formData.fields.add(
        MapEntry(
          "po_items",
          jsonEncode(
            poItems.map((e) {
              return {"itemName": e};
            }).toList(),
          ),
        ),
      );

      // ─── ADD SELECTED PO ID (if provided) ─────────────

      if (selectedPoId != null) {
        formData.fields.add(MapEntry("selected_po_id", selectedPoId));
        debugPrint("SELECTED PO ID: $selectedPoId");
      }

      // =====================================================
      // API Call
      // =====================================================

      debugPrint("AI API CALL STARTED");

      debugPrint(
        "AI URL: "
        "${dio.options.baseUrl}ai/scan-invoice",
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
