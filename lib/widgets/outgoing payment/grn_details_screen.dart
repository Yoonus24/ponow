//------------------ dialog for inside outgoing for showing grn details ------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'dart:ui' as ui;

class GRNDetailsDialog extends StatefulWidget {
  final GRN grn;

  const GRNDetailsDialog({super.key, required this.grn});

  @override
  State<GRNDetailsDialog> createState() => _GRNDetailsDialogState();
}

class _GRNDetailsDialogState extends State<GRNDetailsDialog> {
  late ScrollController _leftVerticalController;
  late ScrollController _rightVerticalController;
  bool _syncing = false;

  final List<Map<String, dynamic>> rightColumns = [
    {"title": "UOM", "width": 60.0},
    {"title": "Count", "width": 65.0},
    {"title": "Qty", "width": 60.0},
    {"title": "Rcv Qty", "width": 70.0},
    {"title": "Price", "width": 80.0},
    {"title": "Total", "width": 90.0},
    {"title": "Tax", "width": 80.0},
    {"title": "Final", "width": 90.0},
    {"title": "Expiry", "width": 90.0},
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

  GRN get grn => widget.grn;

  @override
  Widget build(BuildContext context) {
    double itemTotal = 0.0;
    double totalTax = 0.0;

    for (final item in grn.itemDetails ?? []) {
      itemTotal += item.finalPrice ?? 0.0;
      totalTax += item.taxAmount ?? 0.0;
    }

    final double freightAmount = grn.totalFreightAmount ?? 0.0;
    final double freightTax = grn.totalFreightTaxAmount ?? 0.0;
    final double freightTotal = freightAmount + freightTax;
    final double discount = grn.totalDiscount ?? grn.discountPrice ?? 0.0;
    final double roundOff = grn.roundOffAdjustment ?? 0.0;
    final double finalTotal = itemTotal + freightTotal - discount + roundOff;

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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildSummary(
                  itemTotal: itemTotal,
                  discount: discount,
                  freightAmount: freightAmount,
                  freightTax: freightTax,
                  freightTotal: freightTotal,
                  roundOff: roundOff,
                  finalTotal: finalTotal,
                  totalTax: totalTax,
                ),
              ),

              const SizedBox(height: 20),

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

  double _rowHeight(String text) {
    const style = TextStyle(fontSize: 14);

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: null,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: 130);

    return painter.height < 43 ? 43 : painter.height + 12;
  }

  Widget _buildTableSection() {
    final items = grn.itemDetails ?? [];
    const headerHeight = 40.0;

    final rightWidth = rightColumns.fold<double>(
      0,
      (sum, c) => sum + (c['width'] as double),
    );

    if (items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return Row(
      children: [
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
                        color: Colors.white,
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
                            color: Colors.white,
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

  Widget _buildSummary({
    required double itemTotal,
    required double discount,
    required double freightAmount,
    required double freightTax,
    required double freightTotal,
    required double roundOff,
    required double finalTotal,
    required double totalTax,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _sum("Items Total:", _formatCurrency(itemTotal)),
        _sum("Discount:", _formatCurrency(discount)),
        _sum("Freight:", _formatCurrency(freightAmount)),
        _sum("Freight Tax:", _formatCurrency(freightTax)),
        _sum("Total Freight:", _formatCurrency(freightTotal)),
        _sum("Tax:", _formatCurrency(totalTax)),
        if (roundOff != 0) _sum("Round Off:", _formatCurrency(roundOff)),
        const Divider(),
        _sum(
          "Final Total:",
          _formatCurrency(finalTotal),
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
            width: 100,
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

  Widget _buildVerticalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("GRN No:", grn.randomId ?? "N/A"),
        _infoRow("Vendor:", grn.vendorName ?? "Unknown"),
        _infoRow("Date:", _formatDate(grn.grnDate)),
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
      case "Rcv Qty":
        return "${item.receivedQuantity ?? 0}";
      case "Price":
        return _formatCurrency(item.unitPrice);
      case "Total":
        return _formatCurrency(item.totalPrice);
      case "Tax":
        return _formatCurrency(item.taxAmount);
      case "Final":
        return _formatCurrency(item.finalPrice);
      case "Expiry":
        return _formatDate(item.expiryDate);
      default:
        return "";
    }
  }

  String _formatCurrency(double? value) {
    return "₹${(value ?? 0.0).toStringAsFixed(2)}";
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "N/A";
    try {
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.parse(date).toUtc().toLocal());
    } catch (_) {
      return date;
    }
  }
}
