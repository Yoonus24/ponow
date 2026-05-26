import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/ap/ap.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'ap_invoice_model.dart';
// import 'package:purchaseorders2/models/globals.dart' as globals;

class APInvoiceWidget extends StatefulWidget {
  final ApInvoice apinvoice;

  const APInvoiceWidget({super.key, required this.apinvoice});

  @override
  State<APInvoiceWidget> createState() => _APInvoiceWidgetState();
}

class _APInvoiceWidgetState extends State<APInvoiceWidget> {
  late ScrollController _leftController;
  late ScrollController _rightController;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    _leftController = ScrollController();
    _rightController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<APInvoiceProvider>();
    final apinvoice = widget.apinvoice;
    // globals.apInvoiceRandomId = apinvoice.randomId ?? "";

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(apinvoice, provider),
          Expanded(child: _buildTable(apinvoice)),
        ],
      ),
    );
  }

  String getDisplayStatus(ApInvoice ap) {
    final status = (ap.status ?? "").toLowerCase();

    switch (status) {
      case "pending":
        return "Pending";

      case "pending payment":
        return "Pending Payment";

      case "verified":
        return "Verified";

      case "partially paid":
        return "Partially Paid";

      case "fully paid":
        return "Fully Paid";

      case "returned":
        return "Returned";

      default:
        return ap.status ?? "Unknown";
    }
  }

  Color getStatusColor(ApInvoice ap) {
    return Colors.blueAccent.shade100;
  }

  Widget _buildHeader(ApInvoice apinvoice, APInvoiceProvider provider) {
    String statusText = getDisplayStatus(apinvoice);
    final double headerAmount = (apinvoice.invoiceAmount ?? 0.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Invoice No
              Expanded(
                child: Text(
                  "Invoice No: ${apinvoice.randomId}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor(apinvoice),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vendor
              Expanded(
                child: Text(
                  "Vendor: ${apinvoice.vendorName ?? "N/A"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => APInvoiceModal(apinvoice: apinvoice),
                      );

                      if (!mounted) return;

                      if (result == true) {
                        await context.read<APInvoiceProvider>().fetchAPInvoices(
                          status: null,
                          skip: 0,
                          limit: 50,
                        );
                      }
                    },
                  ),
                  provider.isPdfLoading(apinvoice.invoiceId!)
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            context.read<APInvoiceProvider>().generatePdf(
                              apinvoice,
                              context,
                            );
                          },
                        ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  "Amount: ${headerAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  "Date: ${_formatDate(apinvoice.apinvoiceDate)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(ApInvoice apinvoice) {
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

    final double rightWidth = rightColumns.fold<double>(
      0.0,
      (sum, col) => sum + (col["width"] as double),
    );

    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Column(
            children: [
              Container(
                height: 40,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
                child: const Text(
                  "Item Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _leftController,
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    return Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(items[index].itemName ?? ""),
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
                    height: 40,
                    color: Colors.grey.shade300,
                    child: Row(
                      children: rightColumns.map((col) {
                        return Container(
                          width: col["width"] as double,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            col["title"] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      controller: _rightController,
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];

                        return SizedBox(
                          height: 40,
                          child: Row(
                            children: rightColumns.map((col) {
                              return Container(
                                width: col["width"] as double,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _getValue(col["title"] as String, item),
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
    );
  }

  String _getValue(String col, dynamic item) {
    switch (col) {
      case "UOM":
        return item.uom ?? "";
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
        return (item.finalPrice ?? 0.0).roundToDouble().toStringAsFixed(2);

      default:
        return "";
    }
  }

  String _formatDate(String? d) {
    if (d == null) return "N/A";
    try {
      return DateFormat("dd-MM-yyyy").format(DateTime.parse(d));
    } catch (_) {
      return "Invalid";
    }
  }
}
