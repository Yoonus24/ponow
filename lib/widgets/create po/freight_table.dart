import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'table_components.dart';
import 'freight_dialog.dart';

class FreightTable extends StatefulWidget {
  const FreightTable({super.key});

  @override
  State<FreightTable> createState() => _FreightTableState();
}

class _FreightTableState extends State<FreightTable> {
  static const double rowHeight = 48;

  final ScrollController leftVertical = ScrollController();
  final ScrollController rightVertical = ScrollController();
  final ScrollController horizontal = ScrollController();

  @override
  void initState() {
    super.initState();

    // sync vertical scrolling
    leftVertical.addListener(() {
      if (rightVertical.offset != leftVertical.offset) {
        rightVertical.jumpTo(leftVertical.offset);
      }
    });

    rightVertical.addListener(() {
      if (leftVertical.offset != rightVertical.offset) {
        leftVertical.jumpTo(rightVertical.offset);
      }
    });
  }

  @override
  void dispose() {
    leftVertical.dispose();
    rightVertical.dispose();
    horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PurchaseOrderNotifier>();
    final freights = notifier.freights;

    if (freights.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Freight",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 6),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          height: rowHeight * (freights.length + 1),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),

          child: Row(
            children: [
              // ✅ FIXED NAME COLUMN
              Column(
                children: [
                  Container(
                    height: rowHeight,
                    width: 130,
                    color: Colors.grey[200],
                    child: const TableHeaderCell("Name", flex: 130),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: leftVertical,
                      child: Column(
                        children: freights.map((f) {
                          return Container(
                            height: rowHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: MultiLineTableCell(text: f.name, flex: 130),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ SCROLLABLE PART
              Expanded(
                child: SingleChildScrollView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      Container(
                        height: rowHeight,
                        color: Colors.grey[200],
                        child: const Row(
                          children: [
                            TableHeaderCell("Amount"),
                            TableHeaderCell("Tax"),
                            TableHeaderCell("Total"),
                            TableHeaderCell("Actions", flex: 120),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: rightVertical,
                          child: Column(
                            children: freights.asMap().entries.map((entry) {
                              final index = entry.key;
                              final f = entry.value;

                              return Container(
                                height: rowHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CustomTableCell(
                                      text: "₹${f.amount.toStringAsFixed(2)}",
                                    ),
                                    CustomTableCell(
                                      text:
                                          "₹${f.taxAmount.toStringAsFixed(2)}",
                                    ),
                                    CustomTableCell(
                                      text: "₹${f.total.toStringAsFixed(2)}",
                                    ),

                                    SizedBox(
                                      width: 120,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blueAccent,
                                            ),
                                            onPressed: () async {
                                              await showDialog(
                                                context: context,
                                                builder: (_) => FreightDialog(
                                                  editingFreight: f,
                                                  onAdd: (updated) async {
                                                    await notifier
                                                        .updateFreightAt(
                                                          index,
                                                          updated,
                                                        );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              notifier.removeFreightAt(index);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
