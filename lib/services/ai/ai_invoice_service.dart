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
      debugPrint("📤 SUGGEST PO API START");
      debugPrint("======================================");
      debugPrint("⏰ Timestamp: ${DateTime.now().toIso8601String()}");
      debugPrint("");

      // =====================================================
      // Validate Upload Mode
      // =====================================================

      debugPrint("🔍 VALIDATING UPLOAD MODE");
      debugPrint("──────────────────────────────────────");

      int uploadModes = 0;
      if (imageFile != null) uploadModes++;
      if (imageFiles != null && imageFiles.isNotEmpty) uploadModes++;
      if (pdfFile != null) uploadModes++;

      debugPrint("📊 Upload mode count: $uploadModes");
      debugPrint("   ├─ Single Image: ${imageFile != null ? '✅' : '❌'}");
      debugPrint("   ├─ Multiple Images: ${imageFiles != null && imageFiles.isNotEmpty ? '✅ (${imageFiles!.length} files)' : '❌'}");
      debugPrint("   └─ PDF: ${pdfFile != null ? '✅' : '❌'}");

      if (uploadModes == 0) {
        debugPrint("❌ ERROR: No file provided");
        throw Exception(
          "No file provided. Please provide an image, multiple images, or a PDF.",
        );
      }

      if (uploadModes > 1) {
        debugPrint("❌ ERROR: Multiple upload types detected");
        throw Exception(
          "Please provide only one upload type: image, multiple images, or PDF.",
        );
      }

      debugPrint("✅ Upload validation passed");
      debugPrint("");

      // =====================================================
      // Build FormData
      // =====================================================

      debugPrint("🔧 BUILDING FORMDATA");
      debugPrint("──────────────────────────────────────");

      final formData = FormData();

      // ─── SINGLE IMAGE MODE ────────────────────────────

      if (imageFile != null) {
        debugPrint("📸 SINGLE IMAGE MODE");
        debugPrint("   ├─ Path: ${imageFile.path}");
        debugPrint("   ├─ Size: ${await imageFile.length()} bytes");
        debugPrint("   └─ Filename: ${imageFile.path.split('/').last}");

        formData.files.add(
          MapEntry(
            "image",
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ),
        );
        debugPrint("✅ Image added to FormData with key 'image'");
      }
      // ─── PDF MODE ──────────────────────────────────────
      else if (pdfFile != null) {
        debugPrint("📄 PDF MODE");
        debugPrint("   ├─ Path: ${pdfFile.path}");
        debugPrint("   ├─ Size: ${await pdfFile.length()} bytes");
        debugPrint("   └─ Filename: ${pdfFile.path.split('/').last}");

        formData.files.add(
          MapEntry(
            "pdf",
            await MultipartFile.fromFile(
              pdfFile.path,
              filename: pdfFile.path.split('/').last,
            ),
          ),
        );
        debugPrint("✅ PDF added to FormData with key 'pdf'");
      }
      // ─── MULTIPLE IMAGES MODE ─────────────────────────
      else if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint("🖼️ MULTI IMAGE MODE: ${imageFiles.length} images");
        debugPrint("   └─ Files:");

        for (int i = 0; i < imageFiles.length; i++) {
          final file = imageFiles[i];
          debugPrint("      ${i + 1}. ${file.path} (${await file.length()} bytes)");

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
        debugPrint("✅ ${imageFiles.length} images added to FormData with key 'images'");
      }

      debugPrint("");

      // =====================================================
      // API Call
      // =====================================================

      debugPrint("🌐 MAKING API CALL");
      debugPrint("──────────────────────────────────────");
      debugPrint("📡 Endpoint: ai/suggest-po");
      debugPrint("📡 Method: POST");
      debugPrint("📡 FormData fields: ${formData.fields.length}");
      debugPrint("📡 FormData files: ${formData.files.length}");
      debugPrint("");

      final response = await dio.post("ai/suggest-po", data: formData);

      debugPrint("");
      debugPrint("📥 RESPONSE RECEIVED");
      debugPrint("──────────────────────────────────────");
      debugPrint("📊 Status Code: ${response.statusCode}");
      debugPrint("📊 Status Message: ${response.statusMessage}");
      debugPrint("");

      debugPrint("📄 RESPONSE BODY");
      debugPrint("──────────────────────────────────────");
      debugPrint(const JsonEncoder.withIndent("  ").convert(response.data));
      debugPrint("");

      final responseModel = POSuggestionResponse.fromJson(response.data);

      // =====================================================
      // Print Results
      // =====================================================

      debugPrint("======================================");
      debugPrint("📊 SUGGEST PO RESULTS");
      debugPrint("======================================");
      debugPrint("");

      debugPrint("🏷️ INVOICE DATA (from suggestion)");
      debugPrint("──────────────────────────────────────");
      debugPrint("   ├─ Invoice Number: ${responseModel.invoiceData['invoiceNumber'] ?? 'N/A'}");
      debugPrint("   ├─ Vendor Name: ${responseModel.invoiceData['vendorName'] ?? 'N/A'}");
      debugPrint("   ├─ Invoice Date: ${responseModel.invoiceData['invoiceDate'] ?? 'N/A'}");
      debugPrint("   └─ Grand Total: ${responseModel.invoiceData['grandTotal'] ?? 'N/A'}");
      debugPrint("");

      debugPrint("📋 SUGGESTED POS (${responseModel.suggestedPOs.length})");
      debugPrint("──────────────────────────────────────");

      for (int i = 0; i < responseModel.suggestedPOs.length; i++) {
        final po = responseModel.suggestedPOs[i];
        debugPrint("");
        debugPrint("  #${i + 1}:");
        debugPrint("     ├─ PO Number: ${po.poNumber}");
        debugPrint("     ├─ PO ID: ${po.poId}");
        debugPrint("     ├─ Score: ${po.score}%");
        debugPrint("     ├─ Matched Items: ${po.matchedItems}/${po.totalItems}");
        debugPrint("     └─ Reason: ${po.reason}");
      }

      debugPrint("");
      debugPrint("🎯 AUTO SUGGESTED PO");
      debugPrint("──────────────────────────────────────");

      if (responseModel.autoSuggestedPO != null) {
        final auto = responseModel.autoSuggestedPO!;
        debugPrint("  ✅ Auto-selected:");
        debugPrint("     ├─ PO Number: ${auto.poNumber}");
        debugPrint("     ├─ PO ID: ${auto.poId}");
        debugPrint("     └─ Score: ${auto.score}%");
      } else {
        debugPrint("  ⚠️ No auto-suggested PO (score below threshold)");
      }

      debugPrint("");
      debugPrint("======================================");
      debugPrint("✅ SUGGEST PO API COMPLETED");
      debugPrint("======================================");

      return responseModel;
    } on DioException catch (e) {
      debugPrint("");
      debugPrint("======================================");
      debugPrint("❌ SUGGEST PO ERROR");
      debugPrint("======================================");
      debugPrint("📊 Dio Exception:");
      debugPrint("   ├─ Type: ${e.type}");
      debugPrint("   ├─ Message: ${e.message}");
      debugPrint("   ├─ Status Code: ${e.response?.statusCode}");
      debugPrint("   └─ Response: ${e.response?.data}");
      debugPrint("");
      debugPrint("🔄 Stack Trace:");
      debugPrint(e.stackTrace?.toString() ?? "No stack trace available");
      debugPrint("======================================");
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("");
      debugPrint("======================================");
      debugPrint("❌ SUGGEST PO UNEXPECTED ERROR");
      debugPrint("======================================");
      debugPrint("📊 Error: $e");
      debugPrint("🔄 Stack Trace: $stackTrace");
      debugPrint("======================================");
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
    String? cacheKey,
  }) async {
    try {
      debugPrint("======================================");
      debugPrint("📤 SCAN INVOICE API START");
      debugPrint("======================================");
      debugPrint("⏰ Timestamp: ${DateTime.now().toIso8601String()}");
      debugPrint("");

      // =====================================================
      // Validate Upload Mode (Only if no cacheKey)
      // =====================================================

      debugPrint("🔍 VALIDATING INPUT");
      debugPrint("──────────────────────────────────────");

      int uploadModes = 0;
      if (imageFile != null) uploadModes++;
      if (imageFiles != null && imageFiles.isNotEmpty) uploadModes++;
      if (pdfFile != null) uploadModes++;

      debugPrint("📊 Upload mode count: $uploadModes");
      debugPrint("   ├─ Single Image: ${imageFile != null ? '✅' : '❌'}");
      debugPrint("   ├─ Multiple Images: ${imageFiles != null && imageFiles.isNotEmpty ? '✅ (${imageFiles!.length} files)' : '❌'}");
      debugPrint("   ├─ PDF: ${pdfFile != null ? '✅' : '❌'}");
      debugPrint("   └─ Cache Key: ${cacheKey != null ? '✅ ($cacheKey)' : '❌'}");
      
      debugPrint("");
      debugPrint("📋 PO Items: ${poItems.length} items");
      for (int i = 0; i < poItems.length; i++) {
        debugPrint("   ${i + 1}. ${poItems[i]}");
      }
      debugPrint("📋 Selected PO ID: ${selectedPoId ?? 'None'}");

      // If cacheKey is provided, we don't need files
      if (cacheKey == null) {
        if (uploadModes == 0) {
          debugPrint("❌ ERROR: No file provided and no cache key");
          throw Exception(
            "No file provided. Please provide an image, multiple images, or a PDF.",
          );
        }

        if (uploadModes > 1) {
          debugPrint("❌ ERROR: Multiple upload types detected");
          throw Exception(
            "Please provide only one upload type: image, multiple images, or PDF.",
          );
        }
      }

      debugPrint("✅ Validation passed");
      debugPrint("");

      // =====================================================
      // Build FormData
      // =====================================================

      debugPrint("🔧 BUILDING FORMDATA");
      debugPrint("──────────────────────────────────────");

      final formData = FormData();

      // ─── ADD CACHE KEY (if provided) ────────────────────

      if (cacheKey != null) {
        debugPrint("🔑 USING CACHED DATA");
        debugPrint("   └─ Cache Key: $cacheKey");
        formData.fields.add(MapEntry("cache_key", cacheKey));
      } else {
        debugPrint("📁 USING FILE UPLOAD (no cache key)");

        // ─── SINGLE IMAGE MODE ────────────────────────────

        if (imageFile != null) {
          debugPrint("📸 SINGLE IMAGE MODE");
          debugPrint("   ├─ Path: ${imageFile.path}");
          debugPrint("   ├─ Size: ${await imageFile.length()} bytes");
          debugPrint("   └─ Filename: ${imageFile.path.split('/').last}");

          formData.files.add(
            MapEntry(
              "image",
              await MultipartFile.fromFile(
                imageFile.path,
                filename: imageFile.path.split('/').last,
              ),
            ),
          );
          debugPrint("✅ Image added to FormData with key 'image'");
        }
        // ─── PDF MODE ──────────────────────────────────────
        else if (pdfFile != null) {
          debugPrint("📄 PDF MODE");
          debugPrint("   ├─ Path: ${pdfFile.path}");
          debugPrint("   ├─ Size: ${await pdfFile.length()} bytes");
          debugPrint("   └─ Filename: ${pdfFile.path.split('/').last}");

          formData.files.add(
            MapEntry(
              "pdf",
              await MultipartFile.fromFile(
                pdfFile.path,
                filename: pdfFile.path.split('/').last,
              ),
            ),
          );
          debugPrint("✅ PDF added to FormData with key 'pdf'");
        }
        // ─── MULTIPLE IMAGES MODE ─────────────────────────
        else if (imageFiles != null && imageFiles.isNotEmpty) {
          debugPrint("🖼️ MULTI IMAGE MODE: ${imageFiles.length} images");
          debugPrint("   └─ Files:");

          for (int i = 0; i < imageFiles.length; i++) {
            final file = imageFiles[i];
            debugPrint("      ${i + 1}. ${file.path} (${await file.length()} bytes)");

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
          debugPrint("✅ ${imageFiles.length} images added to FormData with key 'images'");
        }
      }

      // ─── ADD PO ITEMS ──────────────────────────────────

      debugPrint("");
      debugPrint("📋 ADDING PO ITEMS TO FORMDATA");
      debugPrint("   └─ Items: ${poItems.length}");
      
      final poItemsJson = poItems.map((e) {
        return {"itemName": e};
      }).toList();
      
      debugPrint("   └─ JSON: ${jsonEncode(poItemsJson)}");
      
      formData.fields.add(
        MapEntry(
          "po_items",
          jsonEncode(poItemsJson),
        ),
      );

      // ─── ADD SELECTED PO ID (if provided) ─────────────

      if (selectedPoId != null) {
        debugPrint("");
        debugPrint("📋 ADDING SELECTED PO ID");
        debugPrint("   └─ PO ID: $selectedPoId");
        formData.fields.add(MapEntry("selected_po_id", selectedPoId));
      }

      debugPrint("");
      debugPrint("📊 FORMDATA SUMMARY");
      debugPrint("──────────────────────────────────────");
      debugPrint("   ├─ Fields: ${formData.fields.length}");
      debugPrint("   └─ Files: ${formData.files.length}");
      
      debugPrint("");
      debugPrint("📝 FORMDATA FIELDS");
      debugPrint("──────────────────────────────────────");
      for (final field in formData.fields) {
        debugPrint("   ├─ ${field.key}: ${field.value}");
      }

      if (formData.files.isNotEmpty) {
        debugPrint("");
        debugPrint("📁 FORMDATA FILES");
        debugPrint("──────────────────────────────────────");
        for (final file in formData.files) {
          debugPrint("   ├─ Key: ${file.key}");
          debugPrint("   ├─ Filename: ${file.value.filename}");
          debugPrint("   └─ ContentType: ${file.value.contentType}");
        }
      }

      debugPrint("");

      // =====================================================
      // API Call
      // =====================================================

      debugPrint("🌐 MAKING API CALL");
      debugPrint("──────────────────────────────────────");
      debugPrint("📡 Endpoint: ai/scan-invoice");
      debugPrint("📡 Method: POST");
      debugPrint("📡 Base URL: ${dio.options.baseUrl}");
      debugPrint("📡 FormData fields: ${formData.fields.length}");
      debugPrint("📡 FormData files: ${formData.files.length}");
      debugPrint("");

      debugPrint("⏳ Sending request...");
      final response = await dio.post("ai/scan-invoice", data: formData);

      debugPrint("");
      debugPrint("📥 RESPONSE RECEIVED");
      debugPrint("──────────────────────────────────────");
      debugPrint("📊 Status Code: ${response.statusCode}");
      debugPrint("📊 Status Message: ${response.statusMessage}");
      debugPrint("");

      debugPrint("📄 RESPONSE BODY");
      debugPrint("──────────────────────────────────────");
      debugPrint(const JsonEncoder.withIndent("  ").convert(response.data));
      debugPrint("");

      final parsedResponse = AIInvoiceResponse.fromJson(response.data);

      // =====================================================
      // Print Results
      // =====================================================

      debugPrint("======================================");
      debugPrint("📊 SCAN INVOICE RESULTS");
      debugPrint("======================================");
      debugPrint("");

      debugPrint("🏷️ INVOICE DETAILS");
      debugPrint("──────────────────────────────────────");
      debugPrint("   ├─ Invoice Number: ${parsedResponse.invoiceNumber}");
      debugPrint("   ├─ Vendor Name: ${parsedResponse.vendorName}");
      debugPrint("   ├─ Invoice Date: ${parsedResponse.invoiceDate}");
      debugPrint("   ├─ PO ID: ${parsedResponse.poId}");
      debugPrint("   ├─ PO Number: ${parsedResponse.poNumber}");
      debugPrint("   ├─ Round Off: ${parsedResponse.roundOff}");
      debugPrint("   ├─ Vendor Match Confidence: ${parsedResponse.vendorMatchConfidence}%");
      debugPrint("   └─ Item Match Confidence: ${parsedResponse.itemMatchConfidence}%");
      debugPrint("");

      debugPrint("💰 PRINTED TOTALS");
      debugPrint("──────────────────────────────────────");
      debugPrint("   ├─ Sub Total: ${parsedResponse.printedSubTotal}");
      debugPrint("   ├─ Total Tax: ${parsedResponse.printedTotalTax}");
      debugPrint("   ├─ CGST: ${parsedResponse.printedTotalCGST}");
      debugPrint("   ├─ SGST: ${parsedResponse.printedTotalSGST}");
      debugPrint("   ├─ IGST: ${parsedResponse.printedTotalIGST}");
      debugPrint("   ├─ CESS: ${parsedResponse.printedTotalCESS}");
      debugPrint("   ├─ Grand Total: ${parsedResponse.printedGrandTotal}");
      debugPrint("   └─ Freight: ${parsedResponse.freightAmount}");
      debugPrint("");

      debugPrint("📦 MATCHED ITEMS (${parsedResponse.matchedItems.length})");
      debugPrint("──────────────────────────────────────");
      for (int i = 0; i < parsedResponse.matchedItems.length; i++) {
        final item = parsedResponse.matchedItems[i];
        debugPrint("");
        debugPrint("  #${i + 1}:");
        debugPrint("     ├─ Item Name: ${item.itemName}");
        debugPrint("     ├─ Received Quantity: ${item.receivedQuantity}");
        debugPrint("     ├─ New Price: ${item.newPrice}");
        debugPrint("     ├─ Amount: ${item.amount}");
        debugPrint("     ├─ Taxable Amount: ${item.taxableAmount}");
        debugPrint("     ├─ Final Amount: ${item.finalAmount}");
        debugPrint("     ├─ Discount: ${item.discountAmount} (${item.discountPercent}%)");
        debugPrint("     ├─ Tax: ${item.taxAmount} (${item.taxPercent}%)");
        debugPrint("     ├─ CGST: ${item.cgstAmount} (${item.cgstPercent}%)");
        debugPrint("     ├─ SGST: ${item.sgstAmount} (${item.sgstPercent}%)");
        debugPrint("     ├─ IGST: ${item.igstAmount} (${item.igstPercent}%)");
        debugPrint("     ├─ Expiry: ${item.expiryDate}");
        debugPrint("     └─ Confidence: ${item.confidence}%");
      }

      debugPrint("");
      debugPrint("🤖 AI ANALYSIS");
      debugPrint("──────────────────────────────────────");
      debugPrint("   ├─ Summary: ${parsedResponse.aiSummary}");
      debugPrint("   ├─ Confidence: ${parsedResponse.summaryConfidence}");
      debugPrint("   └─ Recommendation: ${parsedResponse.recommendation}");
      debugPrint("");

      debugPrint("📊 PROCESSING INFO");
      debugPrint("──────────────────────────────────────");
      debugPrint("   └─ Processed At: ${parsedResponse.processedAt}");
      debugPrint("");

      debugPrint("======================================");
      debugPrint("✅ SCAN INVOICE API COMPLETED");
      debugPrint("======================================");

      return parsedResponse;
      
    } on DioException catch (e) {
      debugPrint("");
      debugPrint("======================================");
      debugPrint("❌ SCAN INVOICE DIO ERROR");
      debugPrint("======================================");
      debugPrint("📊 Dio Exception Details:");
      debugPrint("   ├─ Type: ${e.type}");
      debugPrint("   ├─ Message: ${e.message}");
      debugPrint("   ├─ Status Code: ${e.response?.statusCode}");
      debugPrint("   ├─ Status Message: ${e.response?.statusMessage}");
      debugPrint("   ├─ Request URL: ${e.requestOptions.uri}");
      debugPrint("   └─ Response Data: ${e.response?.data}");
      
      if (e.response?.data is Map) {
        debugPrint("");
        debugPrint("📄 ERROR RESPONSE BODY:");
        debugPrint(const JsonEncoder.withIndent("  ").convert(e.response?.data));
      }
      
      debugPrint("");
      debugPrint("🔄 Stack Trace:");
      debugPrint(e.stackTrace?.toString() ?? "No stack trace available");
      debugPrint("======================================");
      rethrow;
      
    } catch (e, stackTrace) {
      debugPrint("");
      debugPrint("======================================");
      debugPrint("❌ SCAN INVOICE UNEXPECTED ERROR");
      debugPrint("======================================");
      debugPrint("📊 Error Type: ${e.runtimeType}");
      debugPrint("📊 Error Message: $e");
      debugPrint("");
      debugPrint("🔄 Stack Trace:");
      debugPrint(stackTrace.toString());
      debugPrint("======================================");
      rethrow;
    }
  }
}