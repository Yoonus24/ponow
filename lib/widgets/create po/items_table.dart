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
  static const double minRowHeight = 48.0;
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

  double _calculateRowHeight(String text) {
    const int approxCharsPerLine = 11;

    final int lineCount = (text.length / approxCharsPerLine).ceil();

    final double calculatedHeight = (lineCount * 20).toDouble();

    return calculatedHeight < minRowHeight ? minRowHeight : calculatedHeight;
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
          const Center(
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

                  double totalRowsHeight = 0;

                  for (final item in items) {
                    totalRowsHeight += _calculateRowHeight(item.itemName ?? "");
                  }

                  final double tableHeight = totalRowsHeight + rowHeight;

                  return Container(
                    height: tableHeight > 500 ? 500 : tableHeight,

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // ================= LEFT SIDE =================
                        Column(
                          children: [
                            Container(
                              height: rowHeight,
                              width: 160,
                              color: Colors.grey[200],

                              child: Row(
                                children: const [
                                  TableHeaderCell("No", flex: 50),

                                  TableHeaderCell("Item Name", flex: 110),
                                ],
                              ),
                            ),

                            Expanded(
                              child: SingleChildScrollView(
                                controller: leftVertical,

                                child: Column(
                                  children: items.asMap().entries.map((entry) {
                                    final index = entry.key;

                                    final item = entry.value;

                                    final rowDynamicHeight =
                                        _calculateRowHeight(
                                          item.itemName ?? "",
                                        );

                                    return Container(
                                      height: rowDynamicHeight,

                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),

                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                        children: [
                                          CustomTableCell(
                                            text: (index + 1).toString(),

                                            flex: 50,
                                          ),

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

                        // ================= RIGHT SIDE =================
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

                                        final rowDynamicHeight =
                                            _calculateRowHeight(
                                              item.itemName ?? "",
                                            );

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
                                          height: rowDynamicHeight,

                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),

                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,

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

                                              SizedBox(
                                                width: 120,

                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,

                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,

                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
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
                                                      icon: const Icon(
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
