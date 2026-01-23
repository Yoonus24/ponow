// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:purchaseorders2/models/po_item.dart';
// import 'package:purchaseorders2/widgets/approved po/approved_po_logic.dart';
// import 'package:purchaseorders2/widgets/approved po/table_components.dart';

// class ApprovedPOTable extends StatelessWidget {
//   final ApprovedPOLogic logic;
//   final bool isOrdered;
//   final double rowHeight;
//   final int minVisibleRows;

//   const ApprovedPOTable({
//     super.key,
//     required this.logic,
//     required this.isOrdered,
//     required this.rowHeight,
//     required this.minVisibleRows,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final items = logic.po.items;

//     if (items.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(40),
//           child: Text(
//             isOrdered ? "No ordered items" : "No received items",
//             style: const TextStyle(color: Colors.grey, fontSize: 16),
//           ),
//         ),
//       );
//     }

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final double availableWidth = constraints.maxWidth;

//         return ValueListenableBuilder<Map<String, bool>>(
//           valueListenable: logic.sharedColumnVisibility,
//           builder: (context, visibility, _) {
//             final double totalColumnsWidth = logic.calculateTotalWidth(
//               logic.sharedColumns.value,
//               visibility,
//               isOrdered: isOrdered,
//             );

//             final double availableForDataColumns =
//                 availableWidth - logic.getColumnWidth('Item');

//             final bool needsHorizontalScroll =
//                 totalColumnsWidth > availableForDataColumns;

//             return SizedBox(
//               height:
//                   rowHeight *
//                   (items.length < minVisibleRows
//                       ? items.length + 1
//                       : minVisibleRows + 1),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildFixedItemColumn(items),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       controller: isOrdered
//                           ? logic.orderedHorizontalController
//                           : logic.receivedHorizontalController,
//                       scrollDirection: Axis.horizontal,
//                       physics: needsHorizontalScroll
//                           ? const AlwaysScrollableScrollPhysics()
//                           : const NeverScrollableScrollPhysics(),
//                       child: SizedBox(
//                         width: totalColumnsWidth,
//                         child: Column(
//                           children: [
//                             Container(
//                               height: 32,
//                               child: Row(
//                                 children: logic.sharedColumns.value
//                                     .where((column) {
//                                       if (column == 'Item') return false;
//                                       final isVisible =
//                                           visibility[column] ?? true;
//                                       if (!isVisible) return false;
//                                       if (isOrdered && column == 'Received')
//                                         return false;
//                                       if (!isOrdered && column == 'Total')
//                                         return false;
//                                       return true;
//                                     })
//                                     .map((column) {
//                                       return TableHeaderCell(
//                                         column,
//                                         width: logic.getColumnWidth(column),
//                                       );
//                                     })
//                                     .toList(),
//                               ),
//                             ),
//                             Expanded(
//                               child: SingleChildScrollView(
//                                 controller: isOrdered
//                                     ? logic.orderedRightVertical
//                                     : logic.receivedRightVertical,
//                                 physics: const AlwaysScrollableScrollPhysics(),
//                                 child: Column(
//                                   children: items.asMap().entries.map((entry) {
//                                     final index = entry.key;
//                                     final item = entry.value;

//                                     return Container(
//                                       height: rowHeight,
//                                       color: Colors.white,
//                                       child: Row(
//                                         children: logic.sharedColumns.value
//                                             .where((column) {
//                                               if (column == 'Item')
//                                                 return false;
//                                               final isVisible =
//                                                   visibility[column] ?? true;
//                                               if (!isVisible) return false;
//                                               if (isOrdered &&
//                                                   column == 'Received')
//                                                 return false;
//                                               if (!isOrdered &&
//                                                   column == 'Total')
//                                                 return false;
//                                               return true;
//                                             })
//                                             .map((column) {
//                                               return SizedBox(
//                                                 width: logic.getColumnWidth(
//                                                   column,
//                                                 ),
//                                                 child: isOrdered
//                                                     ? _buildOrderedItemCell(
//                                                         item,
//                                                         column,
//                                                         index.isEven,
//                                                       )
//                                                     : _buildReceivedItemCell(
//                                                         item,
//                                                         column,
//                                                         index.isEven,
//                                                       ),
//                                               );
//                                             })
//                                             .toList(),
//                                       ),
//                                     );
//                                   }).toList(),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // =========================================================
//   // ✅ FIXED ITEM NAME COLUMN (wrap + no cut)
//   // =========================================================
//   Widget _buildFixedItemColumn(List<Item> items) {
//     return Column(
//       children: [
//         SizedBox(
//           width: logic.getColumnWidth('Item'),
//           child: TableHeaderCell(
//             "Item Name",
//             width: logic.getColumnWidth('Item'),
//             alignment: Alignment.centerLeft,
//           ),
//         ),
//         Expanded(
//           child: SingleChildScrollView(
//             controller: isOrdered
//                 ? logic.orderedLeftVertical
//                 : logic.receivedLeftVertical,
//             physics: const AlwaysScrollableScrollPhysics(),
//             child: Column(
//               children: items.map((item) {
//                 return Container(
//                   height: rowHeight,
//                   color: Colors.white,
//                   child: Container(
//                     width: logic.getColumnWidth('Item'),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 6,
//                     ),
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       item.itemName ?? "",
//                       maxLines: null, // ✅ unlimited
//                       overflow: TextOverflow.visible, // ✅ no cut
//                       softWrap: true,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         height: 1,
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOrderedItemCell(Item item, String column, bool isEvenRow) {
//     // Skip received column in ordered table
//     if (column == 'Received') {
//       return Container(width: logic.getColumnWidth(column));
//     }

//     String displayText = '';

//     switch (column) {
//       case 'Count':
//       case 'Qty':
//       case 'Total':
//       case 'Price':
//       case 'BefTax':
//       case 'AfTax':
//       case 'Tax%':
//       case 'Total Price':
//       case 'Final':
//         displayText = logic.getOrderedItemValue(item, column);
//         return CustomTableCell(
//           text: displayText,
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//           alignment: Alignment.center,
//         );

//       case 'UOM':
//         displayText = item.uom ?? 'N/A';
//         return CustomTableCell(
//           text: displayText,
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//           alignment: Alignment.center,
//         );

//       case 'Expiry':
//         // ✅ SAFE: don’t use expiryDateValuesMap[item]!
//         final expiryController = logic.expiryDateControllersMap[item];

//         if (expiryController == null) {
//           return Container(width: logic.getColumnWidth(column));
//         }

//         return Container(
//           width: logic.getColumnWidth(column),
//           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: TextField(
//             controller: expiryController,
//             enabled: false,
//             readOnly: true,
//             decoration: InputDecoration(
//               hintText: "Auto-filled",
//               hintStyle: const TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey,
//                 fontStyle: FontStyle.italic,
//               ),
//               filled: true,
//               fillColor: Colors.grey.shade200,
//               border: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade400),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               disabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade400),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(
//                 vertical: 4,
//                 horizontal: 6,
//               ),
//             ),
//             style: const TextStyle(fontSize: 10, color: Colors.black54),
//           ),
//         );

//       default:
//         return CustomTableCell(
//           text: '',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//           alignment: Alignment.center,
//         );
//     }
//   }

//   Widget _buildReceivedItemCell(Item item, String column, bool isEvenRow) {
//     // Check if this column should be shown in received table
//     if (column == 'Total') {
//       return Container(width: logic.getColumnWidth(column));
//     }

//     // Get controllers with null safety
//     final controller = logic.receivedQtyControllers[item];
//     final befTaxController = logic.befTaxControllersMap[item];
//     final afTaxController = logic.afTaxControllersMap[item];
//     final expiryController = logic.expiryDateControllersMap[item];

//     switch (column) {
//       case 'Count':
//         return CustomTableCell(
//           text: item.count?.toStringAsFixed(2) ?? '0.00',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       case 'Qty':
//         return CustomTableCell(
//           text: item.eachQuantity?.toStringAsFixed(2) ?? '0.00',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       case 'UOM':
//         return CustomTableCell(
//           text: item.uom ?? 'N/A',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       case 'Received':
//         if (controller == null) {
//           return Container(width: logic.getColumnWidth(column));
//         }

//         return ValueListenableBuilder<Map<Item, String?>>(
//           valueListenable: logic.receivedQtyErrorsValue,
//           builder: (context, errorMap, _) {
//             final error = errorMap[item];
//             final hasError = (error ?? '').isNotEmpty;

//             return Container(
//               width: logic.getColumnWidth(column),
//               color: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               child: InkWell(
//                 onTap: () {
//                   // 🔥 CLEAR OLD ERROR BEFORE OPENING CALCULATOR
//                   final errors = Map<Item, String?>.from(
//                     logic.receivedQtyErrorsValue.value,
//                   );
//                   errors.remove(item);
//                   logic.receivedQtyErrorsValue.value = errors;

//                   logic.showNumericCalculator(
//                     controller: controller,
//                     varianceName: 'Enter Received Quantity',
//                     onValueSelected: () {
//                       logic.updateQtyWhenReceivedChanges(item);
//                       logic.calculateReceivedQuantity(item);
//                       logic.calculateReceivedSummary();
//                     },
//                   );
//                 },

//                 child: IgnorePointer(
//                   child: SizedBox(
//                     height: rowHeight - 2,
//                     child: TextField(
//                       key: ValueKey(hasError), // rebuild when error toggles
//                       controller: controller,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 12),
//                       decoration: InputDecoration(
//                         isDense: true,
//                         contentPadding: const EdgeInsets.only(
//                           bottom: 2,
//                           top: 2,
//                         ),
//                         enabledBorder: UnderlineInputBorder(
//                           borderSide: BorderSide(
//                             color: hasError ? Colors.red : Colors.grey,
//                             width: hasError ? 2 : 1,
//                           ),
//                         ),
//                         focusedBorder: UnderlineInputBorder(
//                           borderSide: BorderSide(
//                             color: hasError ? Colors.red : Colors.blue,
//                             width: hasError ? 2 : 1,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );

//       case 'Price':
//         return CustomTableCell(
//           text: item.newPrice?.toStringAsFixed(2) ?? '0.00',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       case 'BefTax':
//         if (befTaxController == null) {
//           return Container(width: logic.getColumnWidth(column));
//         }

//         // Add ValueListenableBuilder to listen for controller changes
//         return ValueListenableBuilder<TextEditingValue>(
//           valueListenable: befTaxController,
//           builder: (context, value, _) {
//             return Container(
//               width: logic.getColumnWidth(column),
//               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//               decoration: const BoxDecoration(color: Colors.white),
//               child: Text(
//                 // Show discount PERCENTAGE from item, not from controller
//                 item.befTaxDiscount?.toStringAsFixed(2) ?? '0.00',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 11, color: Colors.black),
//               ),
//             );
//           },
//         );

//       case 'AfTax':
//         if (afTaxController == null) {
//           return Container(width: logic.getColumnWidth(column));
//         }

//         // Add ValueListenableBuilder to listen for controller changes
//         return ValueListenableBuilder<TextEditingValue>(
//           valueListenable: afTaxController,
//           builder: (context, value, _) {
//             return Container(
//               width: logic.getColumnWidth(column),
//               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//               decoration: const BoxDecoration(color: Colors.white),
//               child: Text(
//                 // Show discount PERCENTAGE from item, not from controller
//                 item.afTaxDiscount?.toStringAsFixed(2) ?? '0.00',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 11, color: Colors.black),
//               ),
//             );
//           },
//         );

//       case 'Expiry':
//         if (expiryController == null) {
//           return Container(width: logic.getColumnWidth(column));
//         }

//         return ValueListenableBuilder<String?>(
//           valueListenable: logic.expiryDateErrorsMap[item]!,
//           builder: (context, error, _) {
//             return Container(
//               width: logic.getColumnWidth(column),
//               padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//               child: InkWell(
//                 onTap: () async {
//                   DateTime initialDate = DateTime.now();

//                   if ((item.expiryDate).isNotEmpty) {
//                     try {
//                       final parts = item.expiryDate.split('-');
//                       initialDate = DateTime(
//                         int.parse(parts[2]),
//                         int.parse(parts[1]),
//                         int.parse(parts[0]),
//                       );
//                     } catch (_) {}
//                   }

//                   final DateTime? picked = await showDatePicker(
//                     context: context,
//                     initialDate: initialDate,
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime(2101),
//                     builder: (context, child) {
//                       return Theme(
//                         data: Theme.of(context).copyWith(
//                           colorScheme: const ColorScheme.light(
//                             surface: Colors.white,
//                             primary: Colors.blueAccent,
//                             onPrimary: Colors.white,
//                             onSurface: Colors.black,
//                           ),
//                           dialogBackgroundColor: Colors.white,
//                           textButtonTheme: TextButtonThemeData(
//                             style: TextButton.styleFrom(
//                               foregroundColor: Colors.blueAccent,
//                             ),
//                           ),
//                         ),
//                         child: child!,
//                       );
//                     },
//                   );

//                   if (picked != null) {
//                     final formatted = DateFormat('dd-MM-yyyy').format(picked);
//                     item.expiryDate = formatted;
//                     expiryController.text = formatted;
//                     logic.expiryDateErrorsMap[item]!.value = null;
//                   } else {
//                     logic.expiryDateErrorsMap[item]!.value = "";
//                   }
//                 },
//                 child: SizedBox(
//                   height: 30,
//                   child: AbsorbPointer(
//                     child: TextField(
//                       controller: expiryController,
//                       readOnly: true,
//                       decoration: InputDecoration(
//                         hintText: "select date",
//                         hintStyle: const TextStyle(
//                           fontSize: 8,
//                           color: Colors.grey,
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(4),
//                           borderSide: BorderSide(
//                             color: error != null ? Colors.red : Colors.grey,
//                             width: error != null ? 1.4 : 1,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(4),
//                           borderSide: BorderSide(
//                             color: error != null
//                                 ? Colors.red
//                                 : Colors.blueAccent,
//                             width: error != null ? 1.4 : 1,
//                           ),
//                         ),
//                         isDense: true,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 6,
//                         ),
//                       ),
//                       style: const TextStyle(fontSize: 9),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );

//       case 'Tax%':
//         return CustomTableCell(
//           text: item.taxPercentage?.toStringAsFixed(2) ?? '0.00',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       case 'Total Price':
//         return CustomTableCell(
//           text: item.totalPrice?.toStringAsFixed(2) ?? '0.00',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       case 'Final':
//         return CustomTableCell(
//           text: item.finalPrice?.toStringAsFixed(2) ?? '0.00',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );

//       default:
//         return CustomTableCell(
//           text: '',
//           width: logic.getColumnWidth(column),
//           isEvenRow: isEvenRow,
//         );
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/po_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final items = logic.po.items;

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

            return SizedBox(
              height:
                  rowHeight *
                  (items.length < minVisibleRows
                      ? items.length + 1
                      : minVisibleRows + 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFixedItemColumn(items),
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
                            Container(
                              height: 32,
                              child: Row(
                                children: logic.sharedColumns.value
                                    .where((column) {
                                      if (column == 'Item') return false;
                                      final isVisible =
                                          visibility[column] ?? true;
                                      if (!isVisible) return false;
                                      if (isOrdered && column == 'Received')
                                        return false;
                                      if (!isOrdered && column == 'Total')
                                        return false;
                                      return true;
                                    })
                                    .map((column) {
                                      return TableHeaderCell(
                                        column,
                                        width: logic.getColumnWidth(column),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: isOrdered
                                    ? logic.orderedRightVertical
                                    : logic.receivedRightVertical,
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  children: items.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;

                                    return Container(
                                      height: rowHeight,
                                      color: Colors.white,
                                      child: Row(
                                        children: logic.sharedColumns.value
                                            .where((column) {
                                              if (column == 'Item')
                                                return false;
                                              final isVisible =
                                                  visibility[column] ?? true;
                                              if (!isVisible) return false;
                                              if (isOrdered &&
                                                  column == 'Received')
                                                return false;
                                              if (!isOrdered &&
                                                  column == 'Total')
                                                return false;
                                              return true;
                                            })
                                            .map((column) {
                                              return SizedBox(
                                                width: logic.getColumnWidth(
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
  }

  // =========================================================
  // ✅ FIXED ITEM NAME COLUMN (wrap + no cut)
  // =========================================================
  Widget _buildFixedItemColumn(List<Item> items) {
    return Column(
      children: [
        SizedBox(
          width: logic.getColumnWidth('Item'),
          child: TableHeaderCell(
            "Item Name",
            width: logic.getColumnWidth('Item'),
            alignment: Alignment.centerLeft,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: isOrdered
                ? logic.orderedLeftVertical
                : logic.receivedLeftVertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: items.map((item) {
                return Container(
                  height: rowHeight,
                  color: Colors.white,
                  child: Container(
                    width: logic.getColumnWidth('Item'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.itemName ?? "",
                      maxLines: null, // ✅ unlimited
                      overflow: TextOverflow.visible, // ✅ no cut
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
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
    // Skip received column in ordered table
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
        // ✅ SAFE: don’t use expiryDateValuesMap[item]!
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
    // Check if this column should be shown in received table
    if (column == 'Total') {
      return Container(width: logic.getColumnWidth(column));
    }

    // Get controllers with null safety
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

        return ValueListenableBuilder<Map<Item, String?>>(
          valueListenable: logic.receivedQtyErrorsValue,
          builder: (context, errorMap, _) {
            final error = errorMap[item];
            final hasError = (error ?? '').isNotEmpty;

            return Container(
              width: logic.getColumnWidth(column),
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  // 🔥 CLEAR OLD ERROR BEFORE OPENING CALCULATOR
                  final errors = Map<Item, String?>.from(
                    logic.receivedQtyErrorsValue.value,
                  );
                  errors.remove(item);
                  logic.receivedQtyErrorsValue.value = errors;

                  logic.showNumericCalculator(
                    controller: controller,
                    varianceName: 'Enter Received Quantity',
                    onValueSelected: () {
                      logic.updateQtyWhenReceivedChanges(item);
                    },
                  );
                },

                child: IgnorePointer(
                  child: SizedBox(
                    height: rowHeight - 2,
                    child: TextField(
                      key: ValueKey(hasError), // rebuild when error toggles
                      controller: controller,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
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
            );
          },
        );

      case 'Price':
        return CustomTableCell(
          text: item.newPrice?.toStringAsFixed(2) ?? '0.00',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'BefTax':
        if (befTaxController == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        // Add ValueListenableBuilder to listen for controller changes
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: befTaxController,
          builder: (context, value, _) {
            return Container(
              width: logic.getColumnWidth(column),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: const BoxDecoration(color: Colors.white),
              child: Text(
                // Show discount PERCENTAGE from item, not from controller
                item.befTaxDiscount?.toStringAsFixed(2) ?? '0.00',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black),
              ),
            );
          },
        );

      case 'AfTax':
        if (afTaxController == null) {
          return Container(width: logic.getColumnWidth(column));
        }

        // Add ValueListenableBuilder to listen for controller changes
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: afTaxController,
          builder: (context, value, _) {
            return Container(
              width: logic.getColumnWidth(column),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: const BoxDecoration(color: Colors.white),
              child: Text(
                // Show discount PERCENTAGE from item, not from controller
                item.afTaxDiscount?.toStringAsFixed(2) ?? '0.00',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black),
              ),
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
              width: logic.getColumnWidth(column),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: InkWell(
                onTap: () async {
                  DateTime initialDate = DateTime.now();

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
                    firstDate: DateTime.now(),
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
                          dialogBackgroundColor: Colors.white,
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                            ),
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
          text: item.totalPrice?.toStringAsFixed(2) ?? '0.00',
          width: logic.getColumnWidth(column),
          isEvenRow: isEvenRow,
        );

      case 'Final':
        return CustomTableCell(
          text: item.finalPrice?.toStringAsFixed(2) ?? '0.00',
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
