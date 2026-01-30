import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:provider/provider.dart';
import 'table_components.dart';
import '../../models/discount_model.dart';

class ItemsTable extends StatefulWidget {
  final PurchaseOrderNotifier? notifier;
  final VoidCallback onAddItem;
  final Function(BuildContext, int) onEditItem;
  final Function(Item) onRemoveItem;
  final double Function(dynamic, String) getItemProperty;
  final DiscountMode itemWiseDiscountMode;

  const ItemsTable({
    super.key,
    this.notifier,
    required this.onAddItem,
    required this.onEditItem,
    required this.onRemoveItem,
    required this.getItemProperty,
    required this.itemWiseDiscountMode,
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

  // ✅ FIXED: Direct discount display methods
  String _getBefTaxDiscountDisplay(Item item) {
    try {
      // Debug print
      print('🔍 BEF DISPLAY for ${item.itemName}:');
      print('   Mode: ${widget.itemWiseDiscountMode}');
      print('   befTaxDiscount: ${item.befTaxDiscount}');
      print('   befTaxDiscountAmount: ${item.befTaxDiscountAmount}');

      if (widget.itemWiseDiscountMode == DiscountMode.percentage) {
        final value = item.befTaxDiscount ?? 0.0;
        return "${value.toStringAsFixed(2)}%";
      } else {
        final amount = item.befTaxDiscountAmount ?? 0.0;
        return "₹${amount.toStringAsFixed(2)}";
      }
    } catch (e) {
      print('⚠️ Error in bef discount display: $e');
      return "0.00";
    }
  }

  String _getAfTaxDiscountDisplay(Item item) {
    try {
      // Debug print
      print('🔍 AF DISPLAY for ${item.itemName}:');
      print('   Mode: ${widget.itemWiseDiscountMode}');
      print('   afTaxDiscount: ${item.afTaxDiscount}');
      print('   afTaxDiscountAmount: ${item.afTaxDiscountAmount}');

      if (widget.itemWiseDiscountMode == DiscountMode.percentage) {
        final value = item.afTaxDiscount ?? 0.0;
        return "${value.toStringAsFixed(2)}%";
      } else {
        final amount = item.afTaxDiscountAmount ?? 0.0;
        return "₹${amount.toStringAsFixed(2)}";
      }
    } catch (e) {
      print('⚠️ Error in af discount display: $e');
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

    // ✅ DEBUG: Print items when table builds
    print(
      '📋 ItemsTable building with ${purchaseNotifier.poItems.length} items',
    );
    for (var i = 0; i < purchaseNotifier.poItems.length; i++) {
      var item = purchaseNotifier.poItems[i];
      print('   Item $i: ${item.itemName}');
      print('     quantity: ${item.quantity}');
      print('     count: ${item.count}');
      print('     eachQuantity: ${item.eachQuantity}');
      print('     existingPrice: ${item.existingPrice}');
      print('     newPrice: ${item.newPrice}');
      print('     uom: ${item.uom}');
      print('     befTaxDiscount: ${item.befTaxDiscount}');
      print('     befTaxDiscountAmount: ${item.befTaxDiscountAmount}');
      print('     afTaxDiscount: ${item.afTaxDiscount}');
      print('     afTaxDiscountAmount: ${item.afTaxDiscountAmount}');
      print('     taxPercentage: ${item.taxPercentage}');
      print('     finalPrice: ${item.finalPrice}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Items",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 35,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    "Add item",
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

                  return Container(
                    height: tableHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              height: rowHeight,
                              width: 130,
                              color: Colors.grey[200],
                              child: const TableHeaderCell(
                                "Item Name",
                                flex: 130,
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: leftVertical,
                                child: Column(
                                  children: items.map((item) {
                                    return Container(
                                      height: rowHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                      child: MultiLineTableCell(
                                        text: item.itemName ?? "",
                                        flex: 130,
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
                                      TableHeaderCell("Count"),
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

                                        // ✅ FIXED: Direct property access
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

                                        // ✅ FIXED: Use direct display methods
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
                                              // QTY - FIXED ✅
                                              CustomTableCell(
                                                text: quantity.toStringAsFixed(
                                                  2,
                                                ),
                                              ),

                                              // COUNT - FIXED ✅
                                              CustomTableCell(
                                                text: count.toStringAsFixed(2),
                                              ),

                                              // UOM - FIXED ✅
                                              CustomTableCell(text: uom),

                                              // EACH QUANTITY - FIXED ✅
                                              CustomTableCell(
                                                text: eachQuantity
                                                    .toStringAsFixed(2),
                                              ),

                                              // EXISTING PRICE - FIXED ✅
                                              CustomTableCell(
                                                text: existingPrice
                                                    .toStringAsFixed(2),
                                              ),

                                              // NEW PRICE - FIXED ✅
                                              CustomTableCell(
                                                text: newPrice.toStringAsFixed(
                                                  2,
                                                ),
                                              ),

                                              // BEF TAX DISCOUNT - FIXED ✅
                                              CustomTableCell(
                                                text: befTaxDisplay,
                                              ),

                                              // AF TAX DISCOUNT - FIXED ✅
                                              CustomTableCell(
                                                text: afTaxDisplay,
                                              ),

                                              // TAX % - FIXED ✅
                                              CustomTableCell(
                                                text: taxPercentage
                                                    .toStringAsFixed(2),
                                              ),

                                              // TOTAL PRICE - FIXED ✅
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
