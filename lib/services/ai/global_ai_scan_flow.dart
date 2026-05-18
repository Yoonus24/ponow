import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/services/ai/ai_analyzing_overlay.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/widgets/ai/ai_match_summary_dialog.dart';
import 'package:purchaseorders2/widgets/approved%20po/approved_po_dialog.dart';

import 'ai_invoice_service.dart';

Future<void> scanAndOpenPOFlow({
  required BuildContext context,
  required ImageSource source,
}) async {
  bool loaderOpened = false;

  try {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: source);

    if (picked == null) {
      return;
    }

    final file = File(picked.path);

    final provider = Provider.of<POProvider>(context, listen: false);

    final service = AIInvoiceService();

    // GET ALL PO ITEM NAMES
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

    print("TOTAL PO ITEMS SENT: ${allPoItems.length}");

    // SHOW AI LOADER
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

    // API CALL
    final response = await service
        .scanInvoice(imageFile: file, poItems: allPoItems)
        .timeout(const Duration(seconds: 120));

    // ✅ CLOSE LOADER
    if (context.mounted && loaderOpened) {
      Navigator.of(context, rootNavigator: true).pop();

      loaderOpened = false;
    }

    provider.pendingAIResponse = response as AIInvoiceResponse?;

    debugPrint("AI RESPONSE: ${response.poNumber}");

    // ✅ EMPTY ITEMS CHECK
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

    // ✅ NO MATCH FOUND
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

    // ✅ FETCH MATCHED PO
    await showDialog(
      context: context,
      barrierDismissible: false,

      builder: (_) =>
          AIMatchSummaryDialog(aiResponse: response, poProvider: provider),
    );
    // ✅ PO FETCH FAILED
    // if (po == null) {
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         backgroundColor: Colors.red,

    //         content: Text("Unable to load matched PO"),
    //       ),
    //     );
    //   }

    //   provider.pendingAIResponse = null;

    //   return;
    // }

    // ✅ CONTEXT SAFETY
    if (!context.mounted) {
      provider.pendingAIResponse = null;

      return;
    }

    // ✅ OPEN APPROVED PO DIALOG
    // await showDialog(
    //   context: context,

    //   barrierDismissible: false,

    //   builder: (_) {
    //     return ApprovedPODialog(
    //       po: po,

    //       poProvider: provider,

    //       onUpdated: () async {
    //         await provider.fetchApprovedPOsOnly();
    //       },
    //     );
    //   },
    // );

    // ✅ SUCCESS MESSAGE
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,

          content: Text("Matched PO: ${response.poNumber}"),
        ),
      );
    }

    // ✅ CLEAR AI RESPONSE
    provider.pendingAIResponse = null;
  } on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,

          content: Text("Invoice scan timed out"),
        ),
      );
    }
  } catch (e) {
    debugPrint("AI ERROR: $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    }
  } finally {
    // ✅ ENSURE LOADER CLOSES
    if (context.mounted && loaderOpened) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
