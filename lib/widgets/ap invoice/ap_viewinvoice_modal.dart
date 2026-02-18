import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'dart:ui' as ui;

class APViewInvoiceModal extends StatefulWidget {
  final ApInvoice apinvoice;

  const APViewInvoiceModal({super.key, required this.apinvoice});

  @override
  State<APViewInvoiceModal> createState() => _APViewInvoiceModalState();
}

class _APViewInvoiceModalState extends State<APViewInvoiceModal> {
  late ScrollController _leftVerticalController;
  late ScrollController _rightVerticalController;
  bool _syncing = false;

  final List<Map<String, dynamic>> rightColumns = [
    {"title": "UOM", "width": 60.0},
    {"title": "Count", "width": 65.0},
    {"title": "Qty", "width": 60.0},
    {"title": "T.Qty", "width": 60.0},
    {"title": "Price", "width": 80.0},
    {"title": "Disc", "width": 80.0},
    {"title": "Tax", "width": 80.0},
    {"title": "Total", "width": 90.0},
    {"title": "Final", "width": 90.0},
  ];

  @override
  void initState() {
    super.initState();
    _leftVerticalController = ScrollController();
    _rightVerticalController = ScrollController();

    _leftVerticalController.addListener(() {
      if (_syncing || !_rightVerticalController.hasClients) return;
      _syncing = true;
      _rightVerticalController.jumpTo(_leftVerticalController.position.pixels);
      _syncing = false;
    });

    _rightVerticalController.addListener(() {
      if (_syncing || !_leftVerticalController.hasClients) return;
      _syncing = true;
      _leftVerticalController.jumpTo(_rightVerticalController.position.pixels);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    super.dispose();
  }

  ApInvoice get apinvoice => widget.apinvoice;

  @override
  Widget build(BuildContext context) {
    final totalAmount = apinvoice.invoiceAmount ?? 0.0;
    double totalTax = 0.0;
    double totalSgst = 0.0;
    double totalCgst = 0.0;

    for (var item in apinvoice.itemDetails ?? []) {
      totalTax += (item.sgst ?? 0) + (item.cgst ?? 0) + (item.igst ?? 0);
      totalSgst += item.sgst ?? 0;
      totalCgst += item.cgst ?? 0;
    }

    final totalDiscount = (apinvoice.discountDetails ?? 0.0);
    // .roundToDouble();

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildVerticalInfo(),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildTableSection(),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ ORIGINAL SUMMARY RESTORED
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildSummary(
                  totalAmount: totalAmount,
                  totalTax: totalTax,
                  totalDiscount: totalDiscount,
                  totalSgst: totalSgst,
                  totalCgst: totalCgst,
                ),
              ),

              const SizedBox(height: 20),

              // ✅ ORIGINAL CLOSE BUTTON RESTORED
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ROW HEIGHT CALCULATOR =================
  double _rowHeight(String text) {
    const style = TextStyle(fontSize: 14);

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: null,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: 130);

    return painter.height < 43 ? 43 : painter.height + 12;
  }

  // ================= TABLE =================
  Widget _buildTableSection() {
    final items = apinvoice.itemDetails ?? [];
    const headerHeight = 40.0;

    final rightWidth = rightColumns.fold<double>(
      0,
      (sum, c) => sum + (c['width'] as double),
    );

    return Row(
      children: [
        // LEFT FIXED COLUMN
        SizedBox(
          width: 130,
          child: Column(
            children: [
              Container(
                height: headerHeight,
                color: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Item",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _leftVerticalController,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final h = _rowHeight(item.itemName ?? "");

                    return Container(
                      height: h,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.white : Colors.grey.shade100,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.itemName ?? "",
                        style: const TextStyle(fontSize: 13),
                        softWrap: true,
                        maxLines: null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // RIGHT SCROLLABLE SIDE
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: rightWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    color: Colors.grey.shade300,
                    child: Row(
                      children: rightColumns.map((c) {
                        return Container(
                          width: c['width'],
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.centerRight,
                          child: Text(
                            c['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _rightVerticalController,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final h = _rowHeight(item.itemName ?? "");

                        return Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? Colors.white
                                : Colors.grey.shade50,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: rightColumns.map((c) {
                              return Container(
                                width: c['width'],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _getColValue(c['title'], item),
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.right,
                                  softWrap: true,
                                  maxLines: null,
                                ),
                              );
                            }).toList(),
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
    );
  }

  // ================= SUMMARY (ORIGINAL) =================
  Widget _buildSummary({
    required double totalAmount,
    required double totalTax,
    required double totalDiscount,
    required double totalSgst,
    required double totalCgst,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _sum("Total:", _formatCurrency(totalAmount)),
        _sum("Disc:", _formatCurrency(totalDiscount)),
        _sum("Tax:", _formatCurrency(totalTax)),
        _sum("SGST:", _formatCurrency(totalSgst)),
        _sum("CGST:", _formatCurrency(totalCgst)),
        const Divider(),
        _sum(
          "Amount:",
          _formatCurrency(totalAmount),
          bold: true,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _sum(String title, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Widget _buildVerticalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Invoice:", apinvoice.randomId ?? "N/A"),
        _infoRow("Vendor:", apinvoice.vendorName ?? "Unknown"),
        _infoRow("Date:", _formatDate(apinvoice.invoiceDate)),
      ],
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getColValue(String col, dynamic item) {
    switch (col) {
      case "UOM":
        return item.uom ?? "";
      case "Count":
        return "${item.nos ?? 0}";
      case "Qty":
        return "${item.eachQuantity ?? 0}";
      case "T.Qty":
        return "${item.quantity ?? 0}";
      case "Price":
        return item.unitPrice?.toStringAsFixed(2) ?? "0.00";
      case "Disc":
        return item.discountAmount?.toStringAsFixed(2) ?? "0.00";
      case "Tax":
        return ((item.sgst ?? 0) + (item.cgst ?? 0) + (item.igst ?? 0))
            .toStringAsFixed(2);
      case "Total":
        return item.totalPrice?.toStringAsFixed(2) ?? "0.00";
      case "Final":
        return item.finalPrice?.toStringAsFixed(2) ?? "0.00";
      default:
        return "";
    }
  }

  String _formatCurrency(double value) => "₹${value.toStringAsFixed(2)}";

  String _formatDate(String? date) {
    if (date == null) return "N/A";
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}
