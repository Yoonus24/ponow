import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/pdfs/grn_debit_pdf.dart';
import 'package:printing/printing.dart';

class DebitNoteViewDialog extends StatefulWidget {
  final DebitCreditNote grn;
  final GRN grns;

  const DebitNoteViewDialog({super.key, required this.grn, required this.grns});

  @override
  State<DebitNoteViewDialog> createState() => _DebitNoteViewDialogState();
}

class _DebitNoteViewDialogState extends State<DebitNoteViewDialog> {
  late ScrollController _leftVertical;
  late ScrollController _rightVertical;

  // ⭐ NEW: Horizontal scroll controller
  late ScrollController _rightHorizontal;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    _leftVertical = ScrollController();
    _rightVertical = ScrollController();

    _rightHorizontal = ScrollController(); // ⭐ IMPORTANT FIX

    // Sync vertical scroll
    _leftVertical.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _rightVertical.jumpTo(_leftVertical.offset);
      _syncing = false;
    });

    _rightVertical.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _leftVertical.jumpTo(_rightVertical.offset);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _leftVertical.dispose();
    _rightVertical.dispose();
    _rightHorizontal.dispose(); // ⭐ DISPOSE FIX
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grn = widget.grn;
    final grns = widget.grns;

    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            _buildStickyHeader(grn, grns),
            Expanded(child: _buildTable(grn)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSummarySection(grn),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // STICKY HEADER
  // ===========================================================
  Widget _buildStickyHeader(DebitCreditNote grn, GRN grns) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade700,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Credit / Debit Note",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () async {
                  try {
                    final pdfService = GRNDebitPdf();
                    final pdfFile = await pdfService.generateGrnPdf(
                      grn.grnId ?? "",
                    );

                    await Printing.layoutPdf(
                      onLayout: (_) => pdfFile.readAsBytesSync(),
                    );
                  } catch (e) {}
                },
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            "GRN No: ${grns.randomId ?? "N/A"}",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            "Vendor: ${grn.vendorName ?? "N/A"}",
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTable(DebitCreditNote grn) {
    final items = grn.itemDetails;

    const double noColWidth = 50;
    const double nameColWidth = 120;

    final rightColumns = [
      {"title": "Price", "width": 90.0},
      {"title": "Type", "width": 90.0},
      {"title": "Qty", "width": 80.0},
      {"title": "Final", "width": 100.0},
      {"title": "Reason", "width": 150.0},
    ];

    final double totalRightWidth = rightColumns.fold(
      0.0,
      (s, col) => s + (col["width"] as double),
    );

    return Column(
      children: [
        // ⭐ Wrap HEADER + BODY right side in ONE horizontal scroll
        Expanded(
          child: Row(
            children: [
              // ---------------- LEFT FIXED SIDE ----------------
              SizedBox(
                width: noColWidth + nameColWidth,
                child: Column(
                  children: [
                    // Header left
                    Container(
                      height: 40,
                      color: Colors.grey.shade300,
                      child: Row(
                        children: [
                          Container(
                            width: noColWidth,
                            alignment: Alignment.center,
                            child: const Text(
                              "No",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            width: nameColWidth,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 6),
                            child: const Text(
                              "Item Name",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body left
                    Expanded(
                      child: ListView.builder(
                        controller: _leftVertical,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: noColWidth,
                                  alignment: Alignment.center,
                                  child: Text("${i + 1}"),
                                ),
                                Container(
                                  width: nameColWidth,
                                  padding: const EdgeInsets.only(left: 6),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.itemName ?? "N/A",
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow
                                        .visible, // important for wrapping
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------- RIGHT SCROLLABLE SIDE ----------------
              Expanded(
                child: SingleChildScrollView(
                  controller: _rightHorizontal,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalRightWidth,
                    child: Column(
                      children: [
                        // HEADER RIGHT
                        Container(
                          height: 40,
                          color: Colors.grey.shade300,
                          child: Row(
                            children: rightColumns.map((col) {
                              return Container(
                                width: col["width"] as double,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  col["title"] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // BODY RIGHT
                        Expanded(
                          child: ListView.builder(
                            controller: _rightVertical,
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final item = items[i];
                              return Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _cell(_formatCurrency(item.unitPrice), 90),
                                    _cell(item.noteType ?? "N/A", 90),
                                    _cell(_formatNumber(item.quantity), 80),
                                    _cell(
                                      _formatCurrency(item.finalPrice),
                                      100,
                                    ),
                                    _cell(item.reason ?? "N/A", 150),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(String v, double w) {
    return Container(
      width: w,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(v, overflow: TextOverflow.ellipsis),
    );
  }

  // ===========================================================
  // SUMMARY
  // ===========================================================
  Widget _buildSummarySection(DebitCreditNote grn) {
    double totalWithoutTax = grn.itemDetails.fold(
      0.0,
      (s, i) => s + (i.totalPrice),
    );

    double totalCgst = grn.itemDetails.fold(0.0, (s, i) => s + (i.cgst ?? 0));

    double totalSgst = grn.itemDetails.fold(0.0, (s, i) => s + (i.sgst ?? 0));

    double totalIgst = grn.itemDetails.fold(0.0, (s, i) => s + (i.igst ?? 0));

    double totalFinal = grn.itemDetails.fold(0.0, (s, i) => s + (i.finalPrice));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _summaryRow("Without Tax", _formatCurrency(totalWithoutTax)),
        _summaryRow("CGST", _formatCurrency(totalCgst)),
        _summaryRow("SGST", _formatCurrency(totalSgst)),
        _summaryRow("IGST", _formatCurrency(totalIgst)),
        const Divider(),
        _summaryRow("Total Amount", _formatCurrency(totalFinal), bold: true),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double? v) => v?.toStringAsFixed(2) ?? "0.00";
  String _formatCurrency(double? v) => v?.toStringAsFixed(2) ?? "0.00";
}
