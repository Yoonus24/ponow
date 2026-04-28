import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/widgets/create%20po/import_csv_dialog.dart';
import 'table_components.dart';
import '../../models/discount_model.dart';
import 'FREIGHT/freight_dialog.dart';

class ItemsTable extends StatefulWidget {
  final PurchaseOrderNotifier? notifier;
  final VoidCallback onAddItem;
  final Function(BuildContext, int) onEditItem;
  final Function(Item) onRemoveItem;
  final double Function(dynamic, String) getItemProperty;
  final DiscountMode itemWiseDiscountMode;
  final Function(List items)? onImport;
  const ItemsTable({
    super.key,
    this.notifier,
    required this.onAddItem,
    required this.onEditItem,
    required this.onRemoveItem,
    required this.getItemProperty,
    required this.itemWiseDiscountMode,
    this.onImport,
  });

  @override
  State<ItemsTable> createState() => _ItemsTableState();
}

class _ItemsTableState extends State<ItemsTable> {
  static const double rowHeight = 48.0;
  static const int maxVisibleRows = 7;

  final ScrollController horizontalController = ScrollController();
  final ScrollController leftVertical = ScrollController();
  final ScrollController rightVertical = ScrollController();

  String _getBefTaxDiscountDisplay(Item item) {
    try {
      if (widget.itemWiseDiscountMode == DiscountMode.percentage) {
        final value = item.befTaxDiscount ?? 0.0;
        return "${value.toStringAsFixed(2)}%";
      } else {
        final amount = item.befTaxDiscountAmount ?? 0.0;
        return "₹${amount.toStringAsFixed(2)}";
      }
    } catch (e) {
      return "0.00";
    }
  }

  String _getAfTaxDiscountDisplay(Item item) {
    try {
      if (widget.itemWiseDiscountMode == DiscountMode.percentage) {
        final value = item.afTaxDiscount ?? 0.0;
        return "${value.toStringAsFixed(2)}%";
      } else {
        final amount = item.afTaxDiscountAmount ?? 0.0;
        return "₹${amount.toStringAsFixed(2)}";
      }
    } catch (e) {
      return "0.00";
    }
  }

  @override
  void initState() {
    super.initState();

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
    horizontalController.dispose();
    leftVertical.dispose();
    rightVertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseNotifier =
        widget.notifier ?? Provider.of<PurchaseOrderNotifier>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ✅ IMPORT
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ImportCSVDialog(
                        onSuccess: (items) {
                          if (widget.onImport != null) {
                            widget.onImport!(items);
                          }
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.upload_file,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Import",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ✅ ADD FREIGHT
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => FreightDialog(
                        onAdd: (freight) {
                          for (var f in freight) {
                            purchaseNotifier.addFreight(f);
                          }
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.local_shipping,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Add Freight",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ✅ ADD ITEM
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    "Add Item",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        if (purchaseNotifier.poItems.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                "No items added yet",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
        else
          Consumer<PurchaseOrderNotifier>(
            builder: (context, provider, _) {
              final items = purchaseNotifier.poItems;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final int visibleRows = items.length < maxVisibleRows
                      ? items.length
                      : maxVisibleRows;

                  final double tableHeight = rowHeight * (visibleRows + 1);

                  return SizedBox(
                    height: tableHeight,
                    child: Row( 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            // 🔹 HEADER
                            Container(
                              height: rowHeight,
                              width: 160, // 50 + 110
                              color: Colors.grey[200],
                              child: Row(
                                children: const [
                                  TableHeaderCell("No", flex: 50),
                                  TableHeaderCell("Item Name", flex: 110),
                                ],
                              ),
                            ),

                            // 🔹 BODY
                            Expanded(
                              child: SingleChildScrollView(
                                controller: leftVertical,
                                child: Column(
                                  children: items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;

                                    return Container(
                                      height: rowHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // 🔸 SERIAL NUMBER
                                          CustomTableCell(
                                            text: (index + 1).toString(),
                                            flex: 50,
                                          ),

                                          // 🔸 ITEM NAME
                                          MultiLineTableCell(
                                            text: item.itemName ?? "",
                                            flex: 110,
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

                        Expanded(
                          child: SingleChildScrollView(
                            controller: horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              children: [
                                Container(
                                  height: rowHeight,
                                  color: Colors.grey[200],
                                  child: Row(
                                    children: const [
                                      TableHeaderCell("Qty"),
                                      TableHeaderCell("Pkt Count"),
                                      TableHeaderCell("UOM"),
                                      TableHeaderCell("Each Qty"),
                                      TableHeaderCell("Existing"),
                                      TableHeaderCell("New"),
                                      TableHeaderCell("BefTax Disc"),
                                      TableHeaderCell("AfTax Disc"),
                                      TableHeaderCell("Tax %"),
                                      TableHeaderCell("Total Price"),
                                      TableHeaderCell("Actions", flex: 120),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: rightVertical,
                                    child: Column(
                                      children: items.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final item = entry.value;

                                        final quantity = item.quantity ?? 0.0;
                                        final count = item.count ?? 0.0;
                                        final uom = item.uom ?? '';
                                        final eachQuantity =
                                            item.eachQuantity ?? 0.0;
                                        final existingPrice =
                                            item.existingPrice ?? 0.0;
                                        final newPrice = item.newPrice ?? 0.0;
                                        final taxPercentage =
                                            item.taxPercentage ?? 0.0;
                                        final finalPrice =
                                            item.finalPrice ?? 0.0;

                                        final befTaxDisplay =
                                            _getBefTaxDiscountDisplay(item);
                                        final afTaxDisplay =
                                            _getAfTaxDiscountDisplay(item);

                                        return Container(
                                          height: rowHeight,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CustomTableCell(
                                                text: quantity.toStringAsFixed(
                                                  2,
                                                ),
                                              ),

                                              CustomTableCell(
                                                text: count.toStringAsFixed(2),
                                              ),

                                              CustomTableCell(text: uom),

                                              CustomTableCell(
                                                text: eachQuantity
                                                    .toStringAsFixed(2),
                                              ),

                                              CustomTableCell(
                                                text: existingPrice
                                                    .toStringAsFixed(2),
                                              ),

                                              CustomTableCell(
                                                text: newPrice.toStringAsFixed(
                                                  2,
                                                ),
                                              ),

                                              CustomTableCell(
                                                text: befTaxDisplay,
                                              ),

                                              CustomTableCell(
                                                text: afTaxDisplay,
                                              ),

                                              CustomTableCell(
                                                text: taxPercentage
                                                    .toStringAsFixed(2),
                                              ),

                                              CustomTableCell(
                                                text:
                                                    "₹${finalPrice.toStringAsFixed(2)}",
                                              ),

                                              // ACTIONS
                                              SizedBox(
                                                width: 120,
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        color:
                                                            Colors.blueAccent,
                                                      ),
                                                      onPressed: () =>
                                                          widget.onEditItem(
                                                            context,
                                                            index,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () => widget
                                                          .onRemoveItem(item),
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
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
