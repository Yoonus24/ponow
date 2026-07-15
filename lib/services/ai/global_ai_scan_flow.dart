import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/services/ai/ai_analyzing_overlay.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/widgets/ai/ai_match_summary_dialog.dart';
import 'package:purchaseorders2/widgets/ai/po_suggestion_screen.dart';

import 'ai_invoice_service.dart';

Future<void> scanAndOpenPOFlow({
  required BuildContext context,
  File? file,
  List<File>? files,
}) async {
  bool loaderOpened = false;
  String? cacheKey; // ← ADDED: Store cache key from suggest response

  try {
    // =====================================================
    // Validate Upload Mode
    // =====================================================

    int uploadModes = 0;
    if (file != null) uploadModes++;
    if (files != null && files.isNotEmpty) uploadModes++;

    if (uploadModes == 0) {
      throw Exception(
        "No file provided. Please provide a single image/PDF or multiple images."
      );
    }

    if (uploadModes > 1) {
      throw Exception(
        "Please provide only one upload type: single file or multiple files."
      );
    }

    // =====================================================
    // Determine Upload Mode
    // =====================================================

    bool isMultipleImages = files != null && files.isNotEmpty;
    bool isSingleImage = file != null && !file.path.toLowerCase().endsWith('.pdf');
    bool isPDF = file != null && file.path.toLowerCase().endsWith('.pdf');

    // =====================================================
    // Log Upload Mode
    // =====================================================

    if (isMultipleImages) {
      debugPrint("MULTIPLE IMAGE MODE: ${files!.length} images");
      for (int i = 0; i < files.length; i++) {
        debugPrint("  Image ${i + 1}: ${files[i].path}");
      }
    } else if (isPDF) {
      debugPrint("PDF MODE: ${file!.path}");
    } else if (isSingleImage) {
      debugPrint("SINGLE IMAGE MODE: ${file!.path}");
    }

    final provider = Provider.of<POProvider>(context, listen: false);

    final service = AIInvoiceService();

    // =====================================================
    // GET ALL PO ITEM NAMES
    // =====================================================

    final List<String> allPoItems = provider.pos
        .expand<String>((po) {
          final pendingItems = (po.items ?? []).where((item) {
            final pendingQty = item.pendingTotalQuantity ?? 0;

            return pendingQty > 0;
          });

          return pendingItems.map<String>((e) => e.itemName ?? "");
        })
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    debugPrint("TOTAL PO ITEMS SENT: ${allPoItems.length}");

    // =====================================================
    // SHOW LOADER
    // =====================================================

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) {
          return const AIAnalyzingOverlay();
        },
      );

      loaderOpened = true;
    }

    // =====================================================
    // STEP 1
    // GET PO SUGGESTIONS
    // =====================================================

    POSuggestionResponse suggestionResponse;

    if (isMultipleImages) {
      debugPrint("CALLING SUGGEST PO WITH ${files!.length} IMAGES");
      suggestionResponse = await service
          .suggestPO(imageFiles: files)
          .timeout(const Duration(minutes: 5));
    } else if (isPDF) {
      debugPrint("CALLING SUGGEST PO WITH PDF");
      suggestionResponse = await service
          .suggestPO(pdfFile: file)
          .timeout(const Duration(seconds: 120));
    } else {
      // Single Image
      debugPrint("CALLING SUGGEST PO WITH SINGLE IMAGE");
      suggestionResponse = await service
          .suggestPO(imageFile: file)
          .timeout(const Duration(seconds: 120));
    }

    // ─── SAVE CACHE KEY FROM SUGGEST RESPONSE ────────────────
    
    cacheKey = suggestionResponse.cacheKey; // ← ADDED
    debugPrint("======================================");
    debugPrint("CACHE KEY SAVED: $cacheKey");
    debugPrint("======================================");

    // =====================================================
    // CLOSE LOADER
    // =====================================================

    if (context.mounted && loaderOpened) {
      Navigator.of(context, rootNavigator: true).pop();

      loaderOpened = false;
    }

    // =====================================================
    // NO SUGGESTIONS
    // =====================================================

    if (suggestionResponse.suggestedPOs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No matching PO suggestions found"),
          ),
        );
      }

      return;
    }

    // =====================================================
    // SHOW SUGGESTION DIALOG
    // =====================================================
    // =====================================================
    // AUTO SELECT IF ONLY ONE PO
    // =====================================================

    String? selectedPoId;

    if (suggestionResponse.suggestedPOs.length == 1) {
      selectedPoId = suggestionResponse.suggestedPOs.first.poId;

      debugPrint("AUTO SELECTED SINGLE PO => $selectedPoId");
    }
    // =====================================================
    // SHOW DIALOG ONLY IF MULTIPLE POs
    // =====================================================
    else {
      selectedPoId = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return POSuggestionDialog(
            response: suggestionResponse,
            poProvider: provider,
          );
        },
      );

      if (selectedPoId == null) {
        return;
      }
    }

    // =====================================================
    // SHOW LOADER AGAIN
    // =====================================================

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) {
          return const AIAnalyzingOverlay();
        },
      );

      loaderOpened = true;
    }

    // =====================================================
    // STEP 2
    // SCAN USING SELECTED PO
    // =====================================================

    AIInvoiceResponse response;

    // ─── PASS CACHE KEY TO SCAN INVOICE ──────────────────────

    if (isMultipleImages) {
      debugPrint("CALLING SCAN INVOICE WITH ${files!.length} IMAGES");
      debugPrint("USING CACHE KEY: $cacheKey"); // ← ADDED
      response = await service
          .scanInvoice(
            imageFiles: files,
            poItems: allPoItems,
            selectedPoId: selectedPoId,
            cacheKey: cacheKey, // ← ADDED: Pass cache key
          )
          .timeout(const Duration(seconds: 120));
    } else if (isPDF) {
      debugPrint("CALLING SCAN INVOICE WITH PDF");
      debugPrint("USING CACHE KEY: $cacheKey"); // ← ADDED
      response = await service
          .scanInvoice(
            pdfFile: file,
            poItems: allPoItems,
            selectedPoId: selectedPoId,
            cacheKey: cacheKey, // ← ADDED: Pass cache key
          )
          .timeout(const Duration(seconds: 120));
    } else {
      // Single Image
      debugPrint("CALLING SCAN INVOICE WITH SINGLE IMAGE");
      debugPrint("USING CACHE KEY: $cacheKey"); // ← ADDED
      response = await service
          .scanInvoice(
            imageFile: file,
            poItems: allPoItems,
            selectedPoId: selectedPoId,
            cacheKey: cacheKey, // ← ADDED: Pass cache key
          )
          .timeout(const Duration(seconds: 120));
    }

    // =====================================================
    // CLOSE LOADER
    // =====================================================

    if (context.mounted && loaderOpened) {
      Navigator.of(context, rootNavigator: true).pop();

      loaderOpened = false;
    }

    provider.pendingAIResponse = response;

    debugPrint("AI RESPONSE PO: ${response.poNumber}");

    // =====================================================
    // EMPTY ITEMS
    // =====================================================

    if (response.matchedItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No valid invoice items detected"),
          ),
        );
      }

      provider.pendingAIResponse = null;

      return;
    }

    // =====================================================
    // NO MATCH FOUND
    // =====================================================

    if (response.poId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("No Matching PO Found"),
          ),
        );
      }

      provider.pendingAIResponse = null;

      return;
    }

    // =====================================================
    // SHOW AI SUMMARY
    // =====================================================

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AIMatchSummaryDialog(aiResponse: response, poProvider: provider);
      },
    );

    // =====================================================
    // SAFETY CHECK
    // =====================================================

    if (!context.mounted) {
      provider.pendingAIResponse = null;

      return;
    }

    // =====================================================
    // SUCCESS MESSAGE
    // =====================================================

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Matched PO: ${response.poNumber}"),
      ),
    );

    // =====================================================
    // CLEAR RESPONSE
    // =====================================================

    provider.pendingAIResponse = null;
  }
  // =======================================================
  // TIMEOUT
  // =======================================================
  on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Invoice scan timed out"),
        ),
      );
    }
  }
  // =======================================================
  // ERROR
  // =======================================================
  catch (e) {
    debugPrint("AI ERROR: $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    }
  }
  // =======================================================
  // FINALLY
  // =======================================================
  finally {
    if (context.mounted && loaderOpened) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}