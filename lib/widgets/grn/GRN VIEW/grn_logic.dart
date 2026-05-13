// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures, avoid_print, use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/grnitem.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';

class GRNLogic {
  final GRN grn;

  // Controllers
  final Map<String, TextEditingController> expiryDateControllers = {};
  final Map<String, TextEditingController> nosControllers = {};
  final Map<String, TextEditingController> eachQuantityControllers = {};
  final Map<String, TextEditingController> receivedQtyControllers = {};
  final Map<String, TextEditingController> returnedQtyControllers = {};
  final Map<String, TextEditingController> befTaxDiscountControllers = {};
  final Map<String, TextEditingController> afTaxDiscountControllers = {};
  final TextEditingController commonDiscountController =
      TextEditingController();

  // ValueNotifiers
  final ValueNotifier<bool> isConverting = ValueNotifier(false);
  final Map<String, ValueNotifier<double>> befTaxDiscountNotifiers = {};
  final Map<String, ValueNotifier<double>> afTaxDiscountNotifiers = {};
  final ValueNotifier<double> commonDiscountNotifier = ValueNotifier(0.0);
  final ValueNotifier<Map<String, dynamic>> totalsNotifier = ValueNotifier({});
  final TextEditingController roundOffController = TextEditingController();
  final ValueNotifier<double> roundOffNotifier = ValueNotifier(0.0);
  final ValueNotifier<String?> roundOffErrorNotifier = ValueNotifier(null);
  ValueNotifier<List<String>> visibleColumnsNotifier = ValueNotifier([
    'Item Name',
    'Pkt Count',
    'Each Quantity',
    'Received Qty',
    'Returned Qty',
    'Total Quantity',
    'UOM',
    'Unit Price',
    'BefTax Discount',
    'AfTax Discount',
    'Expiry Date',
    'Total Price',
    'Final Price',
  ]);

  final ValueNotifier<Map<String, bool>> columnVisibilityNotifier =
      ValueNotifier({
        'Item Name': true,
        'UOM': true,
        'Pkt Count': true,
        'Each Quantity': true,
        'Received Qty': true,
        'Returned Qty': true,
        'Total Quantity': true,
        'Unit Price': true,
        'BefTax Discount': true,
        'AfTax Discount': true,
        'Expiry Date': true,
        'Total Price': true,
        'Discount Amount': false,
        'Tax Amount': false,
        'Final Price': false,
        'sgst': false,
        'cgst': false,
        'igst': false,
      });

  final List<String> allColumns = [
    'Item Name',
    'Pkt Count',
    'Each Quantity',
    'Received Qty',
    'Returned Qty',
    'Total Quantity',
    'UOM',
    'Unit Price',
    'Tax Amount', // instead of Tax (%)
    'BefTax Discount',
    'AfTax Discount',
    'Expiry Date',
    'Total Price',
    'Final Price',
    'Discount Amount',
    'sgst',
    'cgst',
    'igst',
  ];

  final ScrollController headerScrollController = ScrollController();
  final ScrollController contentScrollController = ScrollController();
  final ScrollController leftVerticalController = ScrollController();
  final ScrollController rightVerticalController = ScrollController();

  static const double rowHeight = 52.0;
  static const double headerHeight = 42.0;

  GRNLogic(this.grn);

  void init() {
    _setupScrollControllers();
    _loadInitialData();
    _setupInitialNotifiers();
  }

  void _setupScrollControllers() {
    contentScrollController.addListener(() {
      if (headerScrollController.hasClients) {
        headerScrollController.jumpTo(contentScrollController.offset);
      }
    });

    leftVerticalController.addListener(() {
      if (rightVerticalController.hasClients &&
          rightVerticalController.offset != leftVerticalController.offset) {
        rightVerticalController.jumpTo(leftVerticalController.offset);
      }
    });

    rightVerticalController.addListener(() {
      if (leftVerticalController.hasClients &&
          leftVerticalController.offset != rightVerticalController.offset) {
        leftVerticalController.jumpTo(rightVerticalController.offset);
      }
    });
  }

  void _loadInitialData() {
    grn.roundOffAdjustment = 0.0;
    roundOffController.text = "";
    roundOffNotifier.value = 0.0;

    commonDiscountController.text = (grn.discountPrice ?? 0.0).toStringAsFixed(
      2,
    );

    commonDiscountNotifier.value = grn.discountPrice ?? 0.0;
  }

  void _setupInitialNotifiers() {
    if (grn.itemDetails != null) {
      for (var item in grn.itemDetails!) {
        String itemId = item.itemId ?? 'item_${grn.itemDetails!.indexOf(item)}';

        expiryDateControllers[itemId] = TextEditingController(
          text: _formatExpiryDate(item.expiryDate),
        );

        nosControllers[itemId] = TextEditingController(
          text: item.nos?.toString() ?? '0',
        );

        eachQuantityControllers[itemId] = TextEditingController(
          text: item.eachQuantity?.toString() ?? '0',
        );

        receivedQtyControllers[itemId] = TextEditingController(
          text: item.receivedQuantity?.toString() ?? '0',
        );

        returnedQtyControllers[itemId] = TextEditingController(
          text: item.returnedQuantity?.toString() ?? '0',
        );

        befTaxDiscountControllers[itemId] = TextEditingController(
          text: item.befTaxDiscount?.toString() ?? '0',
        );

        afTaxDiscountControllers[itemId] = TextEditingController(
          text: item.afTaxDiscount?.toString() ?? '0',
        );

        befTaxDiscountNotifiers[itemId] = ValueNotifier(
          item.befTaxDiscount ?? 0.0,
        );
        afTaxDiscountNotifiers[itemId] = ValueNotifier(
          item.afTaxDiscount ?? 0.0,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      totalsNotifier.value = _recalculateGRNTotal();
    });
  }

  String _formatExpiryDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'No Date';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  void _safeUpdateController(TextEditingController? controller, String value) {
    if (controller != null && controller.text != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.text = value;
      });
    }
  }

  bool validateRoundOff(double value) {
    if (value < -2 || value > 2) {
      roundOffErrorNotifier.value = 'Round off must be between -2.00 and +2.00';
      return false;
    }
    roundOffErrorNotifier.value = null;
    return true;
  }

  void updateItemQuantities(ItemDetail item, String itemId) {
    double receivedQty = item.receivedQuantity ?? 0;
    if (receivedQty > 0) {
      item.nos = 1;
      item.eachQuantity = receivedQty;
    } else {
      item.nos = 0;
      item.eachQuantity = 0;
    }
    _safeUpdateController(nosControllers[itemId], item.nos.toString());
    _safeUpdateController(
      eachQuantityControllers[itemId],
      item.eachQuantity.toString(),
    );
  }

  void recalculateItemTotals(ItemDetail item) {
    item.totalPrice = (item.receivedQuantity ?? 0) * (item.unitPrice ?? 0);
  }

  Map<String, double> _recalculateGRNTotal() {
    double itemTotal = 0.0;
    double totalSGST = 0.0;
    double totalCGST = 0.0;
    double totalIGST = 0.0;

    // ✅ Use backend values only
    for (final item in grn.itemDetails ?? []) {
      final double finalItem = item.finalPrice ?? 0.0;

      itemTotal += finalItem;

      totalSGST += item.sgst ?? 0.0;
      totalCGST += item.cgst ?? 0.0;
      totalIGST += item.igst ?? 0.0;
    }

    // 🔥 FIX: use GRN level totalDiscount instead of item.discountAmount
    double totalDiscount = grn.totalDiscount ?? 0.0;

    // ✅ Freight
    final double freight =
        (grn.totalFreightAmount ?? 0.0) + (grn.totalFreightTaxAmount ?? 0.0);

    // ❌ DO NOT APPLY ROUND OFF AGAIN
    // final double roundOff = grn.roundOffAdjustment ?? 0.0;

    // ✅ FINAL TOTAL (BEST SOURCE)
    final double finalTotal = grn.grnAmount ?? (itemTotal + freight);

    // ✅ update model (optional)
    grn.grnAmount = finalTotal;

    return {
      'totalItemsAmount': itemTotal,
      'freightAmount': freight,
      'roundOff': grn.roundOffAdjustment ?? 0.0,
      'totalReceivedAmount': finalTotal,
      'totalDiscount': totalDiscount,
      'totalSGST': totalSGST,
      'totalCGST': totalCGST,
      'totalIGST': totalIGST,
    };
  }

  void updateTotalsWithRoundOff() {
    final totals = _recalculateGRNTotal();
    totalsNotifier.value = totals;
  }

  void openRoundOffCalculator(BuildContext context) {
    showNumericCalculator(
      context: context,
      controller: roundOffController,
      varianceName: 'Manual Round Off',
      onValueSelected: () {
        final doubleVal = double.tryParse(roundOffController.text) ?? 0.0;
        if (!validateRoundOff(doubleVal)) return;
        grn.roundOffAdjustment = doubleVal;
        roundOffNotifier.value = doubleVal;
        // Update totals immediately
        updateTotalsWithRoundOff();
      },
    );
  }

  void showNumericCalculator({
    required BuildContext context,
    TextEditingController? controller,
    String? varianceName,
    VoidCallback? onValueSelected,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NumericCalculator(
          varianceName: varianceName ?? 'Enter Value',
          initialValue: controller != null
              ? double.tryParse(controller.text) ?? 0.0
              : 0.0,
          onValueSelected: (double value) {
            if (controller != null) {
              controller.text = value.toStringAsFixed(2);
            }
            onValueSelected?.call();
          },
          controller: controller,
        );
      },
    );
  }

  void showColumnFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.blueAccent,
          highlightColor: Colors.blueAccent.withOpacity(0.2),
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: Colors.blueAccent),
        ),
        child: ColumnFilterDialog(
          columns: allColumns,
          columnVisibility: columnVisibilityNotifier.value,
          onApply: (updatedColumns, updatedVisibility) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              visibleColumnsNotifier.value = updatedColumns
                  .where((col) => updatedVisibility[col] ?? false)
                  .toList();
              columnVisibilityNotifier.value = updatedVisibility;
            });
          },
        ),
      ),
    );
  }

  Future<void> convertGrnToPo(BuildContext context) async {
    if (isConverting.value) return;

    print("🔁 Revert to PO clicked");
    print("GRN ID: ${grn.grnId}");
    print("GRN No: ${grn.randomId}");

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Convert GRN to PO",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: const Text(
          "Are you sure you want to cancel this GRN and move it back to PO?",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 2,
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isConverting.value = true;
      final success = await context.read<GRNProvider>().cancelGRN(
        grn.grnId ?? '',
      );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("GRN moved back to PO successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      isConverting.value = false;
    }
  }

  Future<void> convertToAP(BuildContext context) async {
    if (isConverting.value) return;

    final shouldConvert = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Convert to AP",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: const Text(
          "Are you sure you want to convert this GRN to AP + Outgoing?",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 2,
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldConvert != true || !context.mounted) return;

    try {
      isConverting.value = true;

      final totals = _recalculateGRNTotal();
      double finalRound = (totals['roundOff'] ?? 0.0);
      finalRound = double.parse(finalRound.toStringAsFixed(2));
      if (finalRound > 2.0) finalRound = 2.0;
      if (finalRound < -2.0) finalRound = -2.0;

      final itemUpdates =
          grn.itemDetails?.map((item) {
            return ItemDetail(
              itemId: item.itemId,
              befTaxDiscount: item.befTaxDiscount ?? 0.0,
              afTaxDiscount: item.afTaxDiscount ?? 0.0,
              expiryDate: item.expiryDate,
              taxPercentage: item.taxPercentage ?? 0.0,
              taxAmount: item.taxAmount ?? 0.0,
              sgst: item.sgst ?? 0.0,
              cgst: item.cgst ?? 0.0,
              igst: item.igst ?? 0.0,
              totalPrice: item.totalPrice ?? 0.0,
              finalPrice:
                  item.finalPrice ??
                  ((item.totalPrice ?? 0.0) + (item.taxAmount ?? 0.0)),
            );
          }).toList() ??
          [];

      if (itemUpdates.isEmpty) {
        throw Exception("No items to convert");
      }

      final result = await context
          .read<GRNProvider>()
          .convertGrnToApAndOutgoing(
            grnId: grn.grnId ?? '',
            discountPrice: grn.discountPrice ?? 0.0,
            roundOffAdjustment: finalRound,
            itemUpdates: itemUpdates,
          );

      if (result['success'] == true && context.mounted) {
        Navigator.of(context).pop();
        Future.microtask(() {
          context.read<APInvoiceProvider>().fetchAPInvoices(
            status: "Pending Payment",
            skip: 0,
            limit: 50,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GRN converted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Conversion failed');
      }
    } catch (e) {
      print("❌ ERROR => $e");
      if (e is DioException) {
        print("❌ STATUS CODE => ${e.response?.statusCode}");
        print("❌ RESPONSE DATA => ${e.response?.data}");
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      isConverting.value = false;
    }
  }

  double getColumnWidth(String column) {
    switch (column) {
      case 'Item Name':
        return 170;
      case 'UOM':
        return 70;
      case 'Expiry Date':
        return 130;
      case 'Pkt Count':
      case 'Each Quantity':
      case 'Received Qty':
      case 'Returned Qty':
      case 'Total Quantity':
      case 'Unit Price':
      case 'BefTax Discount':
      case 'AfTax Discount':
      case 'Discount Amount':
      case 'Tax Amount':
      case 'Total Price':
      case 'Final Price':
      case 'sgst':
      case 'cgst':
      case 'igst':
        return 90;
      default:
        return 110;
    }
  }

  Alignment getColumnAlignment(String column) {
    switch (column) {
      case 'Pkt Count':
      case 'Each Quantity':
      case 'Received Qty':
      case 'Returned Qty':
      case 'Total Quantity':
      case 'Unit Price':
      case 'BefTax Discount':
      case 'AfTax Discount':
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }

  double calculateTotalRightColumnsWidth(List<String> rightColumns) {
    double totalWidth = 0.0;
    for (var column in rightColumns) {
      totalWidth += getColumnWidth(column);
    }
    return totalWidth;
  }

  bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;
  }

  List<ItemDetail> getFilteredItems() {
    return (grn.itemDetails ?? [])
        .where((item) => (item.receivedQuantity ?? 0) > 0)
        .toList();
  }

  void dispose() {
    for (var controller in expiryDateControllers.values) controller.dispose();
    for (var controller in nosControllers.values) controller.dispose();
    for (var controller in eachQuantityControllers.values) controller.dispose();
    for (var controller in receivedQtyControllers.values) controller.dispose();
    for (var controller in returnedQtyControllers.values) controller.dispose();
    for (var controller in befTaxDiscountControllers.values)
      controller.dispose();
    for (var controller in afTaxDiscountControllers.values)
      controller.dispose();
    commonDiscountController.dispose();
    roundOffController.dispose();

    for (var notifier in befTaxDiscountNotifiers.values) notifier.dispose();
    for (var notifier in afTaxDiscountNotifiers.values) notifier.dispose();

    commonDiscountNotifier.dispose();
    totalsNotifier.dispose();
    roundOffNotifier.dispose();
    roundOffErrorNotifier.dispose();
    isConverting.dispose();
    visibleColumnsNotifier.dispose();
    columnVisibilityNotifier.dispose();

    headerScrollController.dispose();
    contentScrollController.dispose();
    leftVerticalController.dispose();
    rightVerticalController.dispose();
  }
}

// ColumnFilterDialog class remains the same
class ColumnFilterDialog extends StatefulWidget {
  final List<String> columns;
  final Map<String, bool> columnVisibility;
  final Function(List<String>, Map<String, bool>) onApply;

  const ColumnFilterDialog({
    super.key,
    required this.columns,
    required this.columnVisibility,
    required this.onApply,
  });

  @override
  _ColumnFilterDialogState createState() => _ColumnFilterDialogState();
}

class _ColumnFilterDialogState extends State<ColumnFilterDialog> {
  late ValueNotifier<ColumnManager> _columnNotifier;

  @override
  void initState() {
    super.initState();
    final columnVisibility = Map<String, bool>.from(widget.columnVisibility);
    for (var column in widget.columns) {
      columnVisibility.putIfAbsent(column, () => true);
    }
    _columnNotifier = ValueNotifier(
      ColumnManager(List.from(widget.columns), columnVisibility),
    );
  }

  @override
  void dispose() {
    _columnNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Filter Columns'),
      content: SizedBox(
        width: double.maxFinite,
        child: ValueListenableBuilder<ColumnManager>(
          valueListenable: _columnNotifier,
          builder: (context, manager, _) {
            return ReorderableListView(
              shrinkWrap: true,
              onReorder: (int oldIndex, int newIndex) {
                final newManager = ColumnManager(
                  List.from(manager.columns),
                  Map.from(manager.columnVisibility),
                );
                if (newIndex > oldIndex) newIndex -= 1;
                final item = newManager.columns.removeAt(oldIndex);
                newManager.columns.insert(newIndex, item);
                _columnNotifier.value = newManager;
              },
              children: [
                for (int index = 0; index < manager.columns.length; index++)
                  ListTile(
                    key: ValueKey(manager.columns[index]),
                    title: Text(manager.columns[index]),
                    trailing: Checkbox(
                      value:
                          manager.columnVisibility[manager.columns[index]] ??
                          true,
                      onChanged: (bool? value) {
                        final newManager = ColumnManager(
                          List.from(manager.columns),
                          Map.from(manager.columnVisibility),
                        );
                        newManager.columnVisibility[newManager.columns[index]] =
                            value ?? true;
                        _columnNotifier.value = newManager;
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          onPressed: () {
            final manager = _columnNotifier.value;
            widget.onApply(manager.columns, manager.columnVisibility);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class ColumnManager {
  final List<String> columns;
  final Map<String, bool> columnVisibility;
  ColumnManager(this.columns, this.columnVisibility);
}
