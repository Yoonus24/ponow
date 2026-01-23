// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/pdfs/grn_pdf.dart';
import 'package:purchaseorders2/widgets/grn/debit_note_viewdialog.dart';
import 'package:purchaseorders2/widgets/grn/grn_return_dialog.dart';
import 'package:printing/printing.dart';
import 'grn_modal.dart';
import 'package:purchaseorders2/models/globals.dart' as globals;

class GRNWidget extends StatefulWidget {
  final GRN grn;

  const GRNWidget({super.key, required this.grn});

  @override
  State<GRNWidget> createState() => _GRNWidgetState();
}

class _GRNWidgetState extends State<GRNWidget> {
  bool _isHeaderScrolling = false;
  bool _isBodyScrolling = false;

  late ScrollController _headerHorizontal;
  late ScrollController _bodyHorizontal;

  @override
  void initState() {
    super.initState();

    _headerHorizontal = ScrollController();
    _bodyHorizontal = ScrollController();

    _bodyHorizontal.addListener(() {
      if (_isBodyScrolling) return;
      _isHeaderScrolling = true;
      if (_headerHorizontal.hasClients) {
        _headerHorizontal.jumpTo(_bodyHorizontal.position.pixels);
      }
      _isHeaderScrolling = false;
    });

    _headerHorizontal.addListener(() {
      if (_isHeaderScrolling) return;
      _isBodyScrolling = true;
      if (_bodyHorizontal.hasClients) {
        _bodyHorizontal.jumpTo(_headerHorizontal.position.pixels);
      }
      _isBodyScrolling = false;
    });
  }

  @override
  void dispose() {
    _headerHorizontal.dispose();
    _bodyHorizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grn = widget.grn;
    globals.grnRandomId = grn.randomId ?? "";

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRN No: ${grn.randomId ?? ""}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Vendor: ${grn.vendorName ?? ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          icon: const Icon(
                            Icons.assignment_return,
                            color: Colors.white,
                            size: 25,
                          ),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => GRNReturn(grn: grn),
                          ),
                        ),
                        const Text(
                          'Return',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          icon: Icon(
                            Icons.account_balance,
                            color: grn.hasDebitCreditNotes == true
                                ? Colors.white
                                : Colors.grey,
                            size: 25,
                          ),

                          onPressed: grn.hasDebitCreditNotes == true
                              ? () {
                                  final note = DebitCreditNote.fromGRN(grn);
                                  showDialog(
                                    context: context,
                                    builder: (context) => DebitNoteViewDialog(
                                      grn: note,
                                      grns: grn,
                                    ),
                                  );
                                }
                              : null,
                        ),
                        Text(
                          'Debit',
                          style: TextStyle(
                            color: grn.hasDebitCreditNotes == true
                                ? Colors
                                      .white // text enabled
                                : Colors.grey, // text disabled
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 25,
                          ),
                          onPressed: () async {
                            try {
                              final service = GRNPDF();
                              final pdfFile = await service.generateGrnPdf(
                                grn.grnId ?? '',
                              );
                              await Printing.layoutPdf(
                                onLayout: (_) => pdfFile.readAsBytesSync(),
                              );
                            } catch (e) {}
                          },
                        ),
                        const Text(
                          'PDF',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          icon: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 25,
                          ),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => GRNModal(grn: grn),
                          ),
                        ),
                        const Text(
                          'View',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 3),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.white,
                child: _buildGrnItemsTable(grn),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrnItemsTable(GRN grn) {
    final items = grn.itemDetails ?? [];

    const double leftWidth = 130;

    final List<Map<String, dynamic>> rightColumns = [
      {"title": "UOM", "width": 80.0},
      {"title": "Req Qty", "width": 80.0},
      {"title": "Price", "width": 100.0},
      {"title": "Disc Amt", "width": 100.0},
      {"title": "Tax Amt", "width": 100.0},
      {"title": "Rec Qty", "width": 100.0},
      {"title": "Total", "width": 110.0},
      {"title": "Final", "width": 110.0},
    ];

    final double totalRightWidth = rightColumns.fold<double>(
      0.0,
      (sum, col) => sum + (col["width"] as double),
    );

    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          child: Column(
            children: [
              // HEADER
              Container(
                height: 40,
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.centerLeft,
                color: Colors.grey.shade300,
                child: const Text(
                  "Item Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _headerHorizontal,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    return Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(items[i].itemName ?? "", maxLines: 2),
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
              width: totalRightWidth,
              child: Column(
                children: [
                  // ---------------- HEADER ----------------
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

                  // ---------------- BODY ----------------
                  Expanded(
                    child: ListView.builder(
                      controller: _bodyHorizontal,
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return SizedBox(
                          height: 40,
                          child: Row(
                            children: rightColumns.map((col) {
                              final double w = col["width"] as double;
                              final String t = col["title"] as String;

                              return Container(
                                width: w,
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
                                  _getRightValue(t, item),
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

  // ======================= RIGHT COLUMN VALUE HANDLER =======================
  String _getRightValue(String col, dynamic item) {
    switch (col) {
      case "UOM":
        return item.uom ?? "";
      case "Req Qty":
        return "${item.quantity ?? 0}";
      case "Price":
        return item.unitPrice?.toStringAsFixed(2) ?? "0.00";
      case "Disc Amt":
        return item.discountAmount?.toStringAsFixed(2) ?? "0.00";
      case "Tax Amt":
        return item.taxAmount?.toStringAsFixed(2) ?? "0.00";
      case "Rec Qty":
        return "${item.receivedQuantity ?? 0}";
      case "Total":
        return item.totalPrice?.toStringAsFixed(2) ?? "0.00";
      case "Final":
        return item.finalPrice?.toStringAsFixed(2) ?? "0.00";
      default:
        return "";
    }
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      height: 40,
      alignment: Alignment.center,
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _dataCell(String text, double width, {bool right = false}) {
    return Container(
      width: width,
      height: 40,
      alignment: right ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.center,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
