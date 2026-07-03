import 'package:flutter/material.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/widgets/approved_po/approved_po_dialog.dart';

class AIMatchSummaryDialog extends StatelessWidget {
  final AIInvoiceResponse aiResponse;
  final POProvider poProvider;

  const AIMatchSummaryDialog({
    super.key,
    required this.aiResponse,
    required this.poProvider,
  });

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) {
      return Colors.green;
    } else if (confidence >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final double confidence = aiResponse.confidence;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // Compact App Bar with Blue Accent
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "AI Invoice Analysis",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Main Content - Compact
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder(
                  future: poProvider.fetchPOById(aiResponse.poId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text("Loading..."),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load PO\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text(
                          "PO not found",
                          style: TextStyle(fontSize: 14),
                        ),
                      );
                    }

                    final po = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Matched PO Card
                        _buildCompactMatchedPOCard(po),
                        const SizedBox(height: 12),

                        // Compact Items Section
                        _buildCompactItemsSection(),
                        const SizedBox(height: 12),

                        // Compact AI Analysis
                        _buildCompactAIAnalysisCard(),
                        const SizedBox(height: 20),

                        // Action Buttons
                        _buildCompactActionButtons(context, po),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMatchedPOCard(dynamic po) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                "Matched Purchase Order",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoCard("PO Number", po.randomId ?? "-"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInfoCard("Status", po.poStatus ?? "-"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCompactInfoCard(
                  "Vendor Match",
                  "${aiResponse.vendorMatchConfidence.toStringAsFixed(0)}%",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInfoCard(
                  "Item Match",
                  "${aiResponse.itemMatchConfidence.toStringAsFixed(0)}%",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),

          const SizedBox(height: 4),

          Text(
            value,

            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisChip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Text(
            value,

            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
          ),

          const SizedBox(width: 4),

          Text(title, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCompactItemsSection() {
    final subtotal = aiResponse.matchedItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.taxableAmount > 0
              ? item.taxableAmount
              : (item.receivedQuantity * item.newPrice)),
    );

    final gstTotal = aiResponse.matchedItems.fold<double>(
      0,
      (sum, item) => sum + item.taxAmount,
    );

    final grandTotal = (aiResponse.analysisData["totalInvoiceValue"] ?? 0)
        .toDouble();

    final roundOff = aiResponse.roundOff;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================
          // HEADER
          // =================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                const Text(
                  "Detected Items",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  "${aiResponse.matchedItems.length} items",
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),

          // =================================================
          // TABLE
          // =================================================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 820),
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 40,
                dataRowHeight: 56,
                horizontalMargin: 12,
                dividerThickness: 0,
                columns: const [
                  DataColumn(
                    label: Text(
                      "S.No",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Item",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Qty",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Price",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "GST",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Confidence",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                rows: aiResponse.matchedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final total = item.finalAmount > 0
                      ? item.finalAmount
                      : (item.receivedQuantity * item.newPrice);

                  final taxableUnitPrice = item.receivedQuantity > 0
                      ? item.taxableAmount / item.receivedQuantity
                      : item.newPrice;

                  final finalUnitPrice = item.receivedQuantity > 0
                      ? item.finalAmount / item.receivedQuantity
                      : item.newPrice;

                  final isHighConfidence = item.confidence >= 80;

                  return DataRow(
                    cells: [
                      DataCell(
                        Center(
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            item.itemName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.receivedQuantity.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${taxableUnitPrice.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (item.taxPercent > 0)
                              Text(
                                "Incl GST ₹${finalUnitPrice.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item.taxPercent.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "₹${item.taxAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            if (item.taxAmount > 0)
                              Text(
                                "Incl GST",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(
                              item.confidence,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${item.confidence.toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: _getConfidenceColor(item.confidence),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isHighConfidence
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHighConfidence
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                size: 12,
                                color: isHighConfidence
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isHighConfidence ? "Matched" : "Review",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isHighConfidence
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // =================================================
          // FOOTER SUMMARY
          // =================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal", style: TextStyle(fontSize: 12)),
                    Text(
                      "₹${subtotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("GST Total", style: TextStyle(fontSize: 12)),
                    Text(
                      "₹${gstTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (roundOff != 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Round Off", style: TextStyle(fontSize: 12)),
                      Text(
                        "₹${roundOff.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                Divider(color: Colors.grey.shade300),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Grand Total",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹${grandTotal.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAIAnalysisCard() {
    final String summary = (aiResponse.aiSummary).trim();

    final bool hasSummary = summary.isNotEmpty;

    final risk = aiResponse.summaryConfidence.toLowerCase();

    final Color primaryColor = risk == "high"
        ? Colors.red.shade700
        : risk == "medium"
        ? Colors.orange.shade700
        : Colors.green.shade700;

    final Color backgroundColor = risk == "high"
        ? Colors.red.shade50
        : risk == "medium"
        ? Colors.orange.shade50
        : Colors.green.shade50;

    final Color chipColor = risk == "high"
        ? Colors.red.shade100
        : risk == "medium"
        ? Colors.orange.shade100
        : Colors.green.shade100;

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: primaryColor.withOpacity(0.25), width: 1.5),

        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),

            blurRadius: 10,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =================================================
          // HEADER
          // =================================================
          Row(
            children: [
              Container(
                width: 4,
                height: 22,

                decoration: BoxDecoration(
                  color: primaryColor,

                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 10),

              Icon(Icons.auto_awesome, size: 17, color: primaryColor),

              const SizedBox(width: 8),

              const Text(
                "AI Audit Analysis",

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: chipColor,

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  risk.toUpperCase(),

                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =================================================
          // SUMMARY
          // =================================================
          if (hasSummary)
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: backgroundColor,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: primaryColor.withOpacity(0.18)),
              ),

              child: SelectableText(
                summary,

                style: const TextStyle(
                  fontSize: 13,
                  height: 1.75,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.orange.shade50,

                borderRadius: BorderRadius.circular(10),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      "AI summary not available.",

                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

          // =================================================
          // ANALYSIS CHIPS
          // =================================================
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: [
              _buildAnalysisChip(
                "Qty Mismatch",

                aiResponse.analysisData["quantityMismatchCount"].toString(),

                Colors.orange,
              ),

              _buildAnalysisChip(
                "Extra Items",

                aiResponse.analysisData["extraItemCount"].toString(),

                Colors.red,
              ),

              _buildAnalysisChip(
                "Missing Items",

                aiResponse.analysisData["missingItemCount"].toString(),

                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =================================================
          // FOOTER INFO
          // =================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              color: Colors.grey.shade50,

              borderRadius: BorderRadius.circular(10),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Row(
              children: [
                Icon(Icons.verified_outlined, size: 16, color: primaryColor),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    "Summary generated using AI-powered invoice and PO audit analysis.",

                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionButtons(BuildContext context, dynamic po) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            side: BorderSide(color: Colors.blue.shade300),
            foregroundColor: Colors.blue.shade700,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("Cancel"),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () async {
            Navigator.pop(context);
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => ApprovedPODialog(
                po: po,
                poProvider: poProvider,
                aiResponse: aiResponse,
                onUpdated: () async {
                  await poProvider.fetchApprovedPOsOnly();
                },
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Continue"),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}
