import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/services/ai/ai_analyzing_overlay.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/widgets/ai/ai_match_summary_dialog.dart';

import 'ai_invoice_service.dart';

Future<void> scanAndOpenPOFlow({
  required BuildContext context,
  required File file,
}) async {
  bool loaderOpened = false;

  try {
    debugPrint("SELECTED FILE PATH: ${file.path}");

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
    // SHOW AI LOADER
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
    // API CALL
    // =====================================================

    final response = await service
        .scanInvoice(imageFile: file, poItems: allPoItems)
        .timeout(const Duration(seconds: 120));

    // =====================================================
    // CLOSE LOADER
    // =====================================================

    if (context.mounted && loaderOpened) {
      Navigator.of(context, rootNavigator: true).pop();

      loaderOpened = false;
    }

    provider.pendingAIResponse = response as AIInvoiceResponse?;

    debugPrint("AI RESPONSE PO: ${response.poNumber}");

    // =====================================================
    // EMPTY ITEMS CHECK
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
    // SHOW AI SUMMARY DIALOG
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
    // CLEAR AI RESPONSE
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
