// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'package:purchaseorders2/widgets/approved po/approved_po_logic.dart';
import 'package:purchaseorders2/widgets/approved po/table_components.dart';

class ApprovedPOTable extends StatelessWidget {
  final ApprovedPOLogic logic;
  final bool isOrdered;
  final double rowHeight;
  final int minVisibleRows;

  const ApprovedPOTable({
    super.key,
    required this.logic,
    required this.isOrdered,
    required this.rowHeight,
    required this.minVisibleRows,
  });
  double _calculateRowHeight(String text) {
    const double minHeight = 38;
    const int approxCharsPerLine = 11;

    final int lineCount = (text.length / approxCharsPerLine).ceil();

    final double calculatedHeight = (lineCount * 15).toDouble();

    return calculatedHeight < minHeight ? minHeight : calculatedHeight;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: logic.isInvoiceDrivenMode,

      builder: (context, isInvoiceMode, _) {
        return ValueListenableBuilder<List<Item>>(
          valueListenable: logic.invoiceReceivedItems,

          builder: (context, invoiceItems, _) {
            final items = isOrdered
                ? logic.po.items
                : isInvoiceMode
                ? invoiceItems
                : logic.po.items;

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    isOrdered ? "No ordered items" : "No received items",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final double availableWidth = constraints.maxWidth;

                return ValueListenableBuilder<Map<String, bool>>(
                  valueListenable: logic.sharedColumnVisibility,

                  builder: (context, visibility, _) {
                    final double totalColumnsWidth = logic.calculateTotalWidth(
                      logic.sharedColumns.value,
                      visibility,
                      isOrdered: isOrdered,
                    );

                    final double availableForDataColumns =
                        availableWidth - logic.getColumnWidth('Item');

                    final bool needsHorizontalScroll =
                        totalColumnsWidth > availableForDataColumns;

                    double totalRowsHeight = 0;

                    for (final item in items) {
                      totalRowsHeight += _calculateRowHeight(
                        item.itemName ?? "",
                      );
                    }

                    final double tableHeight = totalRowsHeight + rowHeight;

                    final double maxTableHeight =
                        MediaQuery.of(context).size.height * 0.45;

                    return SizedBox(
                      height: tableHeight > maxTableHeight
                          ? maxTableHeight
                          : tableHeight,

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          /// FIXED ITEM COLUMN
                          _buildFixedItemColumn(items),

                          /// DATA COLUMNS
                          Expanded(
                            child: SingleChildScrollView(
                              controller: isOrdered
                                  ? logic.orderedHorizontalController
                                  : logic.receivedHorizontalController,

                              scrollDirection: Axis.horizontal,

                              physics: needsHorizontalScroll
                                  ? const AlwaysScrollableScrollPhysics()
                                  : const NeverScrollableScrollPhysics(),

                              child: SizedBox(
                                width: totalColumnsWidth,

                                child: Column(
                                  children: [
                                    /// HEADER
                                    SizedBox(
                                      height: 32,

                                      child: Row(
                                        children: logic.sharedColumns.value
                                            .where((column) {
                                              if (column == 'Item') {
                                                return false;
                                              }

                                              final isVisible =
                                                  visibility[column] ?? true;

                                              if (!isVisible) {
                                                return false;
                                              }

                                              if (isOrdered &&
                                                  column == 'Received') {
                                                return false;
                                              }

                                              if (!isOrdered &&
                                                  column == 'Total') {
                                                return false;
                                              }

                                              return true;
                                            })
                                            .map((column) {
                                              return TableHeaderCell(
                                                column,
                                                width: logic.getColumnWidth(
                                                  column,
                                                ),
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ),

                                    /// BODY
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: isOrdered
                                            ? logic.orderedRightVertical
                                            : logic.receivedRightVertical,

                                        physics:
                                            const AlwaysScrollableScrollPhysics(),

                                        child: Column(
                                          children: items.asMap().entries.map((
                                            entry,
                                          ) {
                                            final index = entry.key;

                                            final item = entry.value;

                                            final dynamicRowHeight =
                                                _calculateRowHeight(
                                                  item.itemName ?? "",
                                                );

                                            return Container(
                                              height: dynamicRowHeight,

                                              color: Colors.white,

                                              child: Row(
                                                children: logic
                                                    .sharedColumns
                                                    .value
                                                    .where((column) {
                                                      if (column == 'Item') {
                                                        return false;
                                                      }

                                                      final isVisible =
                                                          visibility[column] ??
                                                          true;

                                                      if (!isVisible) {
                                                        return false;
                                                      }

                                                      if (isOrdered &&
                                                          column ==
                                                              'Received') {
                                                        return false;
                                                      }

                                                      if (!isOrdered &&
                                                          column == 'Total') {
                                                        return false;
                                                      }

                                                      return true;
                                                    })
                                                    .map((column) {
                                                      return SizedBox(
                                                        width: logic
                                                            .getColumnWidth(
                                                              column,
                                                            ),

                                                        child: isOrdered
                                                            ? _buildOrderedItemCell(
                                                                item,
                                                                column,
                                                                index.isEven,
                                                              )
                                                            : _buildReceivedItemCell(
                                                                item,
                                                                column,
                                                                index.isEven,
                                                              ),
                                                      );
                                                    })
                                                    .toList(),
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
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFixedItemColumn(List<Item> items) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 40,

              child: TableHeaderCell(
                "S.No",
                width: 40,
                alignment: Alignment.center,
              ),
            ),

            SizedBox(
              width: logic.getColumnWidth('Item') - 40,

              child: TableHeaderCell(
                "Item Name",

                width: logic.getColumnWidth('Item') - 40,

                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: isOrdered
                ? logic.orderedLeftVertical
                : logic.receivedLeftVertical,

            physics: const AlwaysScrollableScrollPhysics(),

            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;

                final item = entry.value;

                final dynamicRowHeight = _calculateRowHeight(
                  item.itemName ?? "",
                );

                return Container(
                  height: dynamicRowHeight,

                  color: Colors.white,

                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,

                        child: Center(
                          child: Text(
                            "${index + 1}",

                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: logic.getColumnWidth('Item') - 40,

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 1,
                          ),

                          alignment: Alignment.centerLeft,

                          child: Text(
                            item.itemName ?? "",

                            maxLines: null,

                            overflow: TextOverflow.visible,

                            softWrap: true,

                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 0.9,
                            ),
                          ),
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
    );
  }

  Widget _buildOrderedItemCell(Item item, String column, bool isEvenRow) {
    if (column == 'Received') {
      return Container(width: logic.getColumnWidth(column));
    }

    String displayText = '';

    switch (column) {
      case 'Count':
      case 'Qty':
      case 'Total':
      case 'Price':
      case 'BefTax':
      case 'AfTax':
      case 'Tax%':
      case 'Total Price':
      case 'Final':
        displayText = logic.getOrderedItemValue(item, column);
        return CustomTableCell(
          text: displayText,
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
          alignment: Alignment.center,
        );

      case 'UOM':
        displayText = item.uom ?? 'N/A';
        return CustomTableCell(
          text: displayText,
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
          alignment: Alignment.center,
        );

      case 'Expiry':
        final expiryController = logic.expiryDateControllersMap[item];

        if (expiryController == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        return Container(
          width: logic.getColumnWidth(column),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: expiryController,
            enabled: false,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Auto-filled",
              hintStyle: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 6,
              ),
            ),
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        );

      default:
        return CustomTableCell(
          text: '',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
          alignment: Alignment.center,
        );
    }
  }

  Widget _buildReceivedItemCell(Item item, String column, bool isEvenRow) {
    if (column == 'Total') {
      return Container(width: logic.getColumnWidth(column));
    }
    final controller = logic.receivedQtyControllers[item];
    final befTaxController = logic.befTaxControllersMap[item];
    final afTaxController = logic.afTaxControllersMap[item];
    final expiryController = logic.expiryDateControllersMap[item];

    switch (column) {
      case 'Count':
        return CustomTableCell(
          text: item.count?.toStringAsFixed(2) ?? '0.00',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'Qty':
        return CustomTableCell(
          text: item.eachQuantity?.toStringAsFixed(2) ?? '0.00',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'UOM':
        return CustomTableCell(
          text: item.uom ?? 'N/A',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'Received':
        if (controller == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        return ValueListenableBuilder<Set<Item>>(
          valueListenable: logic.aiHighlightedItems,

          builder: (context, highlightedItems, _) {
            final isAIHighlighted = highlightedItems.contains(item);

            return ValueListenableBuilder<Map<Item, String?>>(
              valueListenable: logic.receivedQtyErrorsValue,

              builder: (context, errorMap, _) {
                final error = errorMap[item];

                final hasError = (error ?? '').isNotEmpty;

                return Container(
                  key: logic.receivedFieldKeys[item], // ✅ ADD THIS

                  width: logic.getColumnWidth(column),

                  color: Colors.white,

                  padding: const EdgeInsets.symmetric(horizontal: 4),

                  child: InkWell(
                    onTap: () {
                      final errors = Map<Item, String?>.from(
                        logic.receivedQtyErrorsValue.value,
                      );

                      errors.remove(item);

                      logic.receivedQtyErrorsValue.value = errors;

                      logic.showNumericCalculator(
                        controller: controller,

                        varianceName: 'Enter Received Quantity',

                        item: item,

                        onValueSelected: () async {
                          logic.updateQtyWhenReceivedChanges(item);

                          await logic.recalculateReceivedSummary();
                        },
                      );
                    },

                    child: IgnorePointer(
                      child: SizedBox(
                        height: rowHeight - 2,

                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),

                          curve: Curves.easeInOut,

                          decoration: BoxDecoration(
                            color: isAIHighlighted
                                ? const Color.fromARGB(
                                    255,
                                    255,
                                    251,
                                    2,
                                  ).withOpacity(0.35)
                                : Colors.white,

                            borderRadius: BorderRadius.circular(4),
                          ),

                          child: TextField(
                            key: ValueKey(hasError),

                            controller: controller,

                            textAlign: TextAlign.center,

                            style: const TextStyle(fontSize: 12),

                            decoration: InputDecoration(
                              filled: true,

                              fillColor: Colors.transparent,

                              isDense: true,

                              contentPadding: const EdgeInsets.only(
                                bottom: 2,
                                top: 2,
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: hasError ? Colors.red : Colors.grey,

                                  width: hasError ? 2 : 1,
                                ),
                              ),

                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: hasError ? Colors.red : Colors.blue,

                                  width: hasError ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );

      case 'Price':
        final priceController = logic.priceControllersMap[item];

        if (priceController == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        return ValueListenableBuilder<Set<Item>>(
          valueListenable: logic.aiHighlightedItems,
          builder: (context, highlightedItems, _) {
            final isAIHighlighted = highlightedItems.contains(item);

            return Container(
              width: logic.getColumnWidth(column),
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),

              child: InkWell(
                onTap: () {
                  logic.showNumericCalculator(
                    controller: priceController,
                    varianceName: 'Enter Price',
                    item: item,

                    onValueSelected: () {
                      final newPrice =
                          double.tryParse(priceController.text) ?? 0.0;

                      item.newPrice = newPrice;

                      logic.onPriceChanged(item, newPrice);
                    },
                  );
                },

                child: IgnorePointer(
                  child: SizedBox(
                    height: rowHeight - 2,

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,

                      decoration: BoxDecoration(
                        color: isAIHighlighted
                            ? const Color.fromARGB(
                                255,
                                255,
                                251,
                                2,
                              ).withOpacity(0.35)
                            : Colors.white,

                        borderRadius: BorderRadius.circular(4),
                      ),

                      child: TextField(
                        controller: priceController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),

                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,

                          isDense: true,

                          contentPadding: EdgeInsets.only(bottom: 2, top: 2),

                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),

                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case 'BefTax':
        final controller = logic.befTaxControllers[item];

        if (controller == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        return ValueListenableBuilder<Set<Item>>(
          valueListenable: logic.aiHighlightedItems,
          builder: (context, highlightedItems, _) {
            final isAIHighlighted = highlightedItems.contains(item);

            return ValueListenableBuilder<bool>(
              valueListenable: logic.isBefTaxDiscount,

              builder: (context, isBefTaxMode, _) {
                final isDisabled = !isBefTaxMode;

                return Opacity(
                  opacity: isDisabled ? 0.4 : 1,

                  child: IgnorePointer(
                    ignoring: isDisabled,

                    child: Container(
                      width: logic.getColumnWidth(column),

                      padding: const EdgeInsets.symmetric(horizontal: 4),

                      child: InkWell(
                        onTap: () {
                          logic.onDiscountChanged(isBefTax: true);

                          logic.showNumericCalculator(
                            controller: controller,

                            varianceName: 'Enter Before Tax Discount',

                            item: item,

                            onValueSelected: () {
                              final value =
                                  double.tryParse(controller.text) ?? 0.0;

                              item.befTaxDiscount = value;
                            },
                          );
                        },

                        child: IgnorePointer(
                          child: SizedBox(
                            height: rowHeight - 2,

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,

                              decoration: BoxDecoration(
                                color: isAIHighlighted
                                    ? const Color.fromARGB(
                                        255,
                                        255,
                                        251,
                                        2,
                                      ).withOpacity(0.35)
                                    : Colors.white,

                                borderRadius: BorderRadius.circular(4),
                              ),

                              child: TextField(
                                controller: controller,

                                textAlign: TextAlign.center,

                                style: const TextStyle(fontSize: 12),

                                decoration: const InputDecoration(
                                  filled: true,

                                  fillColor: Colors.transparent,

                                  isDense: true,

                                  contentPadding: EdgeInsets.only(
                                    bottom: 2,
                                    top: 2,
                                  ),

                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),

                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );

      case 'AfTax':
        final controller = logic.afTaxControllers[item];

        if (controller == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        return ValueListenableBuilder<Set<Item>>(
          valueListenable: logic.aiHighlightedItems,
          builder: (context, highlightedItems, _) {
            final isAIHighlighted = highlightedItems.contains(item);

            return ValueListenableBuilder<bool>(
              valueListenable: logic.isBefTaxDiscount,

              builder: (context, isBefTaxMode, _) {
                final isDisabled = isBefTaxMode;

                return Opacity(
                  opacity: isDisabled ? 0.4 : 1,

                  child: IgnorePointer(
                    ignoring: isDisabled,

                    child: Container(
                      width: logic.getColumnWidth(column),

                      padding: const EdgeInsets.symmetric(horizontal: 4),

                      child: InkWell(
                        onTap: () {
                          logic.onDiscountChanged(isBefTax: false);

                          logic.showNumericCalculator(
                            controller: controller,

                            varianceName: 'Enter After Tax Discount',

                            item: item,

                            onValueSelected: () {
                              final value =
                                  double.tryParse(controller.text) ?? 0.0;

                              item.afTaxDiscount = value;
                            },
                          );
                        },

                        child: IgnorePointer(
                          child: SizedBox(
                            height: rowHeight - 2,

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,

                              decoration: BoxDecoration(
                                color: isAIHighlighted
                                    ? const Color.fromARGB(
                                        255,
                                        255,
                                        251,
                                        2,
                                      ).withOpacity(0.35)
                                    : Colors.white,

                                borderRadius: BorderRadius.circular(4),
                              ),

                              child: TextField(
                                controller: controller,

                                textAlign: TextAlign.center,

                                style: const TextStyle(fontSize: 12),

                                decoration: const InputDecoration(
                                  filled: true,

                                  fillColor: Colors.transparent,

                                  isDense: true,

                                  contentPadding: EdgeInsets.only(
                                    bottom: 2,
                                    top: 2,
                                  ),

                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),

                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      case 'Expiry':
        if (expiryController == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        return ValueListenableBuilder<String?>(
          valueListenable: logic.expiryDateErrorsMap[item]!,

          builder: (context, error, _) {
            return Container(
              key: logic.expiryFieldKeys[item], // ✅ ADD THIS

              width: logic.getColumnWidth(column),

              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),

              child: InkWell(
                onTap: () async {
                  DateTime initialDate = ServerTimeService.now;

                  if ((item.expiryDate).isNotEmpty) {
                    try {
                      final parts = item.expiryDate.split('-');

                      initialDate = DateTime(
                        int.parse(parts[2]),
                        int.parse(parts[1]),
                        int.parse(parts[0]),
                      );
                    } catch (_) {}
                  }

                  final DateTime? picked = await showDatePicker(
                    context: context,

                    initialDate: initialDate,

                    firstDate: ServerTimeService.now,

                    lastDate: DateTime(2101),

                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            surface: Colors.white,
                            primary: Colors.blueAccent,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),

                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                            ),
                          ),

                          dialogTheme: DialogThemeData(
                            backgroundColor: Colors.white,
                          ),
                        ),

                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    final formatted = DateFormat('dd-MM-yyyy').format(picked);

                    item.expiryDate = formatted;

                    expiryController.text = formatted;

                    logic.expiryDateErrorsMap[item]!.value = null;
                  } else {
                    logic.expiryDateErrorsMap[item]!.value = "";
                  }
                },

                child: SizedBox(
                  height: 30,

                  child: AbsorbPointer(
                    child: TextField(
                      controller: expiryController,

                      readOnly: true,

                      decoration: InputDecoration(
                        hintText: "select date",

                        hintStyle: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),

                          borderSide: BorderSide(
                            color: error != null ? Colors.red : Colors.grey,

                            width: error != null ? 1.4 : 1,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),

                          borderSide: BorderSide(
                            color: error != null
                                ? Colors.red
                                : Colors.blueAccent,

                            width: error != null ? 1.4 : 1,
                          ),
                        ),

                        isDense: true,

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                      ),

                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case 'Tax%':
        return CustomTableCell(
          text: item.taxPercentage?.toStringAsFixed(2) ?? '0.00',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'Total Price':
        return CustomTableCell(
          text: (item.pendingTotalPrice ?? 0.0).toStringAsFixed(2),
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'Final':
        return CustomTableCell(
          text: (item.pendingFinalPrice ?? 0.0).toStringAsFixed(2),
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      default:
        return CustomTableCell(
          text: '',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );
    }
  }
}
