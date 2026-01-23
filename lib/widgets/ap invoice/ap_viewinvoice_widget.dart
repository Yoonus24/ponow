import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/widgets/ap invoice/ap_viewinvoice_modal.dart';

class APViewInvoiceWidget extends StatefulWidget {
  final ApInvoice apinvoice;

  const APViewInvoiceWidget({super.key, required this.apinvoice});

  @override
  State<APViewInvoiceWidget> createState() => _APViewInvoiceWidgetState();
}

class _APViewInvoiceWidgetState extends State<APViewInvoiceWidget> {
  late ScrollController _leftController;
  late ScrollController _rightController;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    _leftController = ScrollController();
    _rightController = ScrollController();

    // SYNC CONTROLLERS
    _leftController.addListener(() {
      if (_syncing) return;
      _syncing = true;
      if (_rightController.hasClients) {
        _rightController.jumpTo(_leftController.offset);
      }
      _syncing = false;
    });

    _rightController.addListener(() {
      if (_syncing) return;
      _syncing = true;
      if (_leftController.hasClients) {
        _leftController.jumpTo(_rightController.offset);
      }
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  ApInvoice get apinvoice => widget.apinvoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [_buildInvoiceCard(context), _buildItemDetailsTable()],
      ),
    );
  }

  // ============================================
  // TOP BLUE CARD
  // ============================================
  Widget _buildInvoiceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Invoice No: ${apinvoice.randomId ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                onPressed: () => _showInvoiceModal(context),
              ),
            ],
          ),
          Text(
            'Vendor: ${apinvoice.vendorName ?? 'N/A'}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Amount: ${apinvoice.invoiceAmount?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Date: ${_formatDate(apinvoice.invoiceDate)}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MAIN TABLE WITH SCROLL SYNC
  // ============================================
  Widget _buildItemDetailsTable() {
    final items = apinvoice.itemDetails ?? [];

    final List<Map<String, dynamic>> rightColumns = [
      {"title": "UOM", "width": 80.0},
      {"title": "Qty", "width": 80.0},
      {"title": "Unit Price", "width": 100.0},
      {"title": "Stock Qty", "width": 100.0},
      {"title": "BefTax", "width": 100.0},
      {"title": "AfTax", "width": 100.0},
      {"title": "Tax Amt", "width": 100.0},
      {"title": "Total Price", "width": 110.0},
      {"title": "Final Price", "width": 110.0},
    ];

    final double rightWidth = rightColumns.fold(
      0.0,
      (sum, col) => sum + col["width"],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 170),
      child: Row(
        children: [
          // ===========================================
          // LEFT FIXED COLUMN
          // ===========================================
          SizedBox(
            width: 150,
            child: Column(
              children: [
                // HEADER
                Container(
                  height: 40,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.grey.shade300,
                  child: const Text(
                    "Item Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                // BODY (SYNCED)
                Expanded(
                  child: ListView.builder(
                    controller: _leftController,
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Container(
                        height: 40, // FIXED ROW HEIGHT
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          item.itemName ?? "N/A",
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ===========================================
          // RIGHT SCROLLABLE COLUMNS
          // ===========================================
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: rightWidth,
                child: Column(
                  children: [
                    // HEADER ROW
                    Container(
                      height: 40,
                      width: rightWidth,
                      color: Colors.grey.shade300,
                      child: Row(
                        children: rightColumns.map((col) {
                          return Container(
                            width: col["width"],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              col["title"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // BODY (SYNCED)
                    Expanded(
                      child: ListView.builder(
                        controller: _rightController,
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return Container(
                            height: 40, // FIXED ROW HEIGHT
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: rightColumns.map((col) {
                                return Container(
                                  width: col["width"],
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    _getCellValue(col["title"], item),
                                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  // ============================================
  // CELL VALUE HANDLER
  // ============================================
  String _getCellValue(String col, dynamic item) {
    switch (col) {
      case "UOM":
        return item.uom ?? "N/A";
      case "Qty":
        return "${item.quantity ?? 0}";
      case "Unit Price":
        return item.unitPrice?.toStringAsFixed(2) ?? "0.00";
      case "Stock Qty":
        return item.stockQuantity?.toStringAsFixed(2) ?? "0.00";
      case "BefTax":
        return item.befTaxDiscount?.toStringAsFixed(2) ?? "0.00";
      case "AfTax":
        return item.afTaxDiscount?.toStringAsFixed(2) ?? "0.00";
      case "Tax Amt":
        return item.taxAmount?.toStringAsFixed(2) ?? "0.00";
      case "Total Price":
        return item.totalPrice?.toStringAsFixed(2) ?? "0.00";
      case "Final Price":
        return item.finalPrice?.toStringAsFixed(2) ?? "0.00";
      default:
        return "";
    }
  }

  void _showInvoiceModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => APViewInvoiceModal(apinvoice: apinvoice),
    );
  }
}

// =======================
// DATE FORMAT
// =======================
String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd-MM-yyyy').format(date);
  } catch (e) {
    return 'Invalid Date';
  }
}
