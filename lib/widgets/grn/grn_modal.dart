// ignore_for_file: avoid_print, use_build_context_synchronously, unused_element, invalid_use_of_visible_for_testing_member, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/grnitem.dart';
import 'package:purchaseorders2/providers/grn_provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';
import '../../providers/ap_invoice_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class GRNModal extends StatefulWidget {
  final GRN grn;

  const GRNModal({super.key, required this.grn});

  @override
  _GRNModalState createState() => _GRNModalState();
}

class _GRNModalState extends State<GRNModal> {
  late GRN grn;

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
  final ValueNotifier<bool> isConverting = ValueNotifier(false);
  final Map<String, ValueNotifier<double>> befTaxDiscountNotifiers = {};
  final Map<String, ValueNotifier<double>> afTaxDiscountNotifiers = {};
  final ValueNotifier<double> commonDiscountNotifier = ValueNotifier(0.0);
  final ValueNotifier<Map<String, dynamic>> totalsNotifier = ValueNotifier({});
  final TextEditingController roundOffController = TextEditingController();
  final ValueNotifier<double> roundOffNotifier = ValueNotifier(0.0);
  final ValueNotifier<String?> roundOffErrorNotifier = ValueNotifier(null);
  final ValueNotifier<List<String>> visibleColumnsNotifier = ValueNotifier([
    'Item Name',
    'UOM',
    'Count',
    'Each Quantity',
    'Received Qty',
    'Returned Qty',
    'Total Quantity',
    'Price',
    'BefTax Discount',
    'AfTax Discount',
    'Expiry Date',
    'Total Price',
  ]);

  final ValueNotifier<Map<String, bool>> columnVisibilityNotifier =
      ValueNotifier({
        'Item Name': true,
        'UOM': true,
        'Count': true,
        'Each Quantity': true,
        'Received Qty': true,
        'Returned Qty': true,
        'Total Quantity': true,
        'Price': true,
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
    'UOM',
    'Count',
    'Each Quantity',
    'Received Qty',
    'Returned Qty',
    'Total Quantity',
    'Price',
    'BefTax Discount',
    'AfTax Discount',
    'Discount Amount',
    'Tax Amount',
    'Expiry Date',
    'Total Price',
    'Final Price',
    'sgst',
    'cgst',
    'igst',
  ];

  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();

  static const double _rowHeight = 52.0;
  static const double _headerHeight = 42.0;

  @override
  void initState() {
    super.initState();

    grn = widget.grn;

    _contentScrollController.addListener(() {
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(_contentScrollController.offset);
      }
    });

    final double backendRound = grn.grnRoundOffAmount ?? 0.0;

    grn.roundOffAdjustment = backendRound;
    roundOffController.text = backendRound.toStringAsFixed(2);
    roundOffNotifier.value = backendRound;
    commonDiscountController.text = (grn.discountPrice ?? 0.0).toStringAsFixed(
      2,
    );
    commonDiscountNotifier.value = grn.discountPrice ?? 0.0;

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

  @override
  void dispose() {
    for (var controller in expiryDateControllers.values) {
      controller.dispose();
    }
    for (var controller in nosControllers.values) {
      controller.dispose();
    }
    for (var controller in eachQuantityControllers.values) {
      controller.dispose();
    }
    for (var controller in receivedQtyControllers.values) {
      controller.dispose();
    }
    for (var controller in returnedQtyControllers.values) {
      controller.dispose();
    }
    for (var controller in befTaxDiscountControllers.values) {
      controller.dispose();
    }
    for (var controller in afTaxDiscountControllers.values) {
      controller.dispose();
    }
    commonDiscountController.dispose();
    visibleColumnsNotifier.dispose();
    columnVisibilityNotifier.dispose();

    for (var notifier in befTaxDiscountNotifiers.values) {
      notifier.dispose();
    }
    for (var notifier in afTaxDiscountNotifiers.values) {
      notifier.dispose();
    }

    commonDiscountNotifier.dispose();
    totalsNotifier.dispose();
    _headerScrollController.dispose();
    _contentScrollController.dispose();
    roundOffController.dispose();
    roundOffNotifier.dispose();
    roundOffErrorNotifier.dispose();
    isConverting.dispose();

    super.dispose();
  }

  void _safeUpdateController(TextEditingController? controller, String value) {
    if (controller != null && controller.text != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.text = value;
      });
    }
  }

  bool _validateRoundOff(double value) {
    if (value < -2 || value > 2) {
      roundOffErrorNotifier.value = 'Round off must be between -2.00 and +2.00';
      return false;
    }
    roundOffErrorNotifier.value = null;
    return true;
  }

  void _updateItemQuantities(ItemDetail item, String itemId) {
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

  void _recalculateItemTotals(ItemDetail item) {
    item.totalPrice = (item.receivedQuantity ?? 0) * (item.unitPrice ?? 0);
  }

  Map<String, double> _recalculateGRNTotal() {
    double itemTotal = 0.0;
    double totalSGST = 0.0;
    double totalCGST = 0.0;
    double totalIGST = 0.0;
    double totalDiscount = 0.0;

    final double overallDiscount = grn.discountPrice ?? 0.0;
    final int itemCount = grn.itemDetails?.length ?? 0;

    final double discountPerItem = itemCount > 0
        ? overallDiscount / itemCount
        : 0.0;

    for (final item in grn.itemDetails ?? []) {
      final double base = item.totalPrice ?? 0.0;

      double discount =
          (item.befTaxDiscountAmount ?? 0.0) +
          (item.afTaxDiscountAmount ?? 0.0);

      if (discount == 0 && overallDiscount > 0) {
        discount = discountPerItem;
      }

      final double tax = item.taxAmount ?? 0.0;

      final double finalItem = base - discount + tax;

      itemTotal += finalItem;
      totalDiscount += discount;

      totalSGST += item.sgst ?? 0.0;
      totalCGST += item.cgst ?? 0.0;
      totalIGST += item.igst ?? 0.0;
    }

    final double freight =
        (grn.totalFreightAmount ?? 0.0) + (grn.totalFreightTaxAmount ?? 0.0);

    final double roundOff = grn.roundOffAdjustment ?? 0.0;

    final double finalTotal = itemTotal + freight + roundOff;

    totalDiscount = totalDiscount.roundToDouble();

    return {
      'totalItemsAmount': itemTotal,
      'freightAmount': freight,
      'roundOff': roundOff,
      'totalReceivedAmount': finalTotal,
      'totalDiscount': totalDiscount,
      'totalSGST': totalSGST,
      'totalCGST': totalCGST,
      'totalIGST': totalIGST,
    };
  }

  void _updateTotalsWithRoundOff() {
    final totals = _recalculateGRNTotal();
    totalsNotifier.value = totals;
  }

  void _openRoundOffCalculator() {
    showNumericCalculator(
      context: context,
      controller: roundOffController,
      varianceName: 'Manual Round Off',
      onValueSelected: () {
        final doubleVal = double.tryParse(roundOffController.text) ?? 0.0;

        if (!_validateRoundOff(doubleVal)) return;

        grn.roundOffAdjustment = doubleVal;
        roundOffNotifier.value = doubleVal;
        totalsNotifier.value = _recalculateGRNTotal();
      },
    );
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

  void _showConfirmationDialog(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    final totals = _recalculateGRNTotal();
    final double roundOff =
        (totals['roundOff'] ?? 0.0) + (totals['autoRound'] ?? 0.0);
    if (!_validateRoundOff(roundOff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Round off must be between -2.00 and +2.00'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Action'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),

                if (roundOff != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Round Off Adjustment:'),
                      Text('₹ ${roundOff.toStringAsFixed(2)}'),
                    ],
                  ),

                const SizedBox(height: 12),

                _buildSummaryRow(
                  "Total Received Amount",
                  (grn.grnAmount ?? 0.0).toStringAsFixed(2),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showColumnFilterDialog(BuildContext context) {
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

  Future<void> _convertGrnToPo(BuildContext context) async {
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueAccent, // text color
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent, // button bg
              foregroundColor: Colors.white, // text color
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

    print("🟡 User confirmation: $confirm");

    if (confirm != true) {
      print("❌ Revert cancelled by user");
      return;
    }

    try {
      print("🚀 Calling cancelGRN API...");

      final success = await context.read<GRNProvider>().cancelGRN(
        grn.grnId ?? '',
      );

      print("📦 API response: $success");

      if (!context.mounted) return;

      if (success) {
        print("✅ GRN reverted successfully");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("GRN moved back to PO successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } else {
        print("❌ API returned false");
        throw Exception("Failed");
      }
    } catch (e) {
      print("🔥 ERROR during revert: $e");

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _convertToAP(BuildContext context) async {
    if (isConverting.value) return;

    final shouldConvert = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Convert to AP",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to convert this GRN to AP + Outgoing?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Convert"),
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

      /// ✅🔥 IMPORTANT FIX: SEND FULL TAX DATA + TAX %
      final itemUpdates =
          grn.itemDetails?.map((item) {
            final taxAmount = item.taxAmount ?? 0.0;
            final sgst = item.sgst ?? 0.0;
            final cgst = item.cgst ?? 0.0;
            final igst = item.igst ?? 0.0;
            final totalPrice = item.totalPrice ?? 0.0;

            /// fallback safety
            final finalPrice = item.finalPrice ?? (totalPrice + taxAmount);

            print("🧾 SENDING ITEM:");
            print("itemId => ${item.itemId}");
            print("taxAmount => $taxAmount");
            print("sgst => $sgst");
            print("cgst => $cgst");
            print("finalPrice => $finalPrice");
            print("tax % => ${item.purchasetaxName}");

            return ItemDetail(
              itemId: item.itemId,

              // discounts
              befTaxDiscount: item.befTaxDiscount ?? 0.0,
              afTaxDiscount: item.afTaxDiscount ?? 0.0,

              // expiry
              expiryDate: item.expiryDate,

              purchasetaxName: item.taxPercentage ?? 0.0,

              /// tax values
              taxAmount: taxAmount,
              sgst: sgst,
              cgst: cgst,
              igst: igst,

              /// price
              totalPrice: totalPrice,
              finalPrice: finalPrice,
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
            status: "Outgoing Posted",
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
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      isConverting.value = false;
    }
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    TextEditingController? controller,
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2.0 : 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          controller != null
              ? SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controller,
                    readOnly: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: compact ? 4 : 8,
                      ),
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
        ],
      ),
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

  double _getColumnWidth(String column) {
    switch (column) {
      case 'Item Name':
        return 140;
      case 'UOM':
        return 70;
      case 'Expiry Date':
        return 130;
      case 'Count':
      case 'Each Quantity':
      case 'Received Qty':
      case 'Returned Qty':
      case 'Total Quantity':
      case 'Price':
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

  Alignment _getColumnAlignment(String column) {
    switch (column) {
      case 'Count':
      case 'Each Quantity':
      case 'Received Qty':
      case 'Returned Qty':
      case 'Total Quantity':
      case 'Price':
      case 'BefTax Discount':
      case 'AfTax Discount':
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }

  double _calculateTotalRightColumnsWidth(List<String> rightColumns) {
    double totalWidth = 0.0;
    for (var column in rightColumns) {
      totalWidth += _getColumnWidth(column);
    }
    return totalWidth;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'PO No: ${grn.poRandomID ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                softWrap: true,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '→',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'GRN No: ${grn.randomId ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Vendor: ${grn.vendorName ?? 'Unknown Vendor'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          softWrap: true,
                        ),

                        const SizedBox(height: 6),

                        ValueListenableBuilder<Map<String, dynamic>>(
                          valueListenable: totalsNotifier,
                          builder: (context, totals, _) {
                            final double totalReceivedAmount =
                                grn.grnAmount ?? 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Received Amount: ${totalReceivedAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'GRN Date: ${formatDate(grn.grnDate)}',
                                style: const TextStyle(fontSize: 16),
                                softWrap: true,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () => _showColumnFilterDialog(context),
                              tooltip: 'Filter columns',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8.0),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxTableWidth = constraints.maxWidth;
                    final maxTableHeight = constraints.maxHeight;

                    return ValueListenableBuilder<List<String>>(
                      valueListenable: visibleColumnsNotifier,
                      builder: (context, visibleColumns, _) {
                        final bool itemNameVisible = visibleColumns.contains(
                          'Item Name',
                        );
                        final List<String> rightColumns = visibleColumns
                            .where((c) => c != 'Item Name')
                            .toList();

                        final double totalRightColumnsWidth =
                            _calculateTotalRightColumnsWidth(rightColumns);
                        final double itemNameWidth = _getColumnWidth(
                          'Item Name',
                        );

                        return SizedBox(
                          width: maxTableWidth,
                          height: maxTableHeight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: maxTableWidth,
                                height: _headerHeight,
                                color: Colors.grey[200],
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (itemNameVisible)
                                      Container(
                                        height: _headerHeight,
                                        width: itemNameWidth,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Item Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        controller: _headerScrollController,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        child: Container(
                                          height: _headerHeight,
                                          width: totalRightColumnsWidth,
                                          child: Row(
                                            children: rightColumns.map((
                                              column,
                                            ) {
                                              final width = _getColumnWidth(
                                                column,
                                              );
                                              return Container(
                                                height: _headerHeight,
                                                width: width,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Align(
                                                  alignment:
                                                      _getColumnAlignment(
                                                        column,
                                                      ),
                                                  child: Text(
                                                    column,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 4),

                              // ---------- BODY ----------
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // LEFT FIXED COLUMN
                                      if (itemNameVisible)
                                        Container(
                                          width: itemNameWidth,
                                          child: Column(
                                            children: (grn.itemDetails ?? [])
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                                  final item = entry.value;
                                                  return Container(
                                                    height: _rowHeight,
                                                    width: itemNameWidth,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Align(
                                                      alignment:
                                                          _getColumnAlignment(
                                                            'Item Name',
                                                          ),
                                                      child: Text(
                                                        item.itemName ?? '',
                                                        maxLines: 2,
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                          ),
                                        ),

                                      // RIGHT SCROLLABLE
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          controller: _contentScrollController,
                                          child: Container(
                                            width: totalRightColumnsWidth,
                                            child: Column(
                                              children: (grn.itemDetails ?? []).asMap().entries.map((
                                                entry,
                                              ) {
                                                final index = entry.key;
                                                final item = entry.value;
                                                final itemId =
                                                    item.itemId ??
                                                    'item_$index';

                                                return Container(
                                                  height: _rowHeight,
                                                  width: totalRightColumnsWidth,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: rightColumns.map((
                                                      column,
                                                    ) {
                                                      final colWidth =
                                                          _getColumnWidth(
                                                            column,
                                                          );
                                                      return Container(
                                                        height: _rowHeight,
                                                        width: colWidth,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                            ),
                                                        child: Align(
                                                          alignment:
                                                              _getColumnAlignment(
                                                                column,
                                                              ),
                                                          child:
                                                              _buildCellContent(
                                                                item,
                                                                column,
                                                                itemId,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
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
              ),

              const SizedBox(height: 8),

              ValueListenableBuilder<Map<String, dynamic>>(
                valueListenable: totalsNotifier,
                builder: (context, totals, _) {
                  final double totalItemsAmount =
                      totals['totalItemsAmount'] ?? 0.0;
                  final double discount = totals['totalDiscount'] ?? 0.0;
                  final double manualRound = totals['roundOff'] ?? 0.0;
                  final double autoRound = totals['autoRound'] ?? 0.0;
                  final double roundOff = manualRound;
                  final double totalReceivedAmount =
                      totals['totalReceivedAmount'] ?? 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Items Total:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              totalItemsAmount.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildSummaryRow(
                        "Discount Amount",
                        '${discount.toStringAsFixed(2)}',
                        compact: true,
                      ),

                      _buildSummaryRow(
                        "Freight Charges",
                        totals['freightAmount']?.toStringAsFixed(2) ?? '0.00',
                        compact: true,
                      ),

                      if (manualRound != 0)
                        _buildSummaryRow(
                          "Round Off Adjustment",
                          '${manualRound > 0 ? '+' : ''}${manualRound.toStringAsFixed(2)}',
                          compact: true,
                        ),

                      _buildSummaryRow(
                        "Total SGST",
                        totals['totalSGST']?.toStringAsFixed(2) ?? '0.00',
                        compact: true,
                      ),
                      _buildSummaryRow(
                        "Total CGST",
                        totals['totalCGST']?.toStringAsFixed(2) ?? '0.00',
                        compact: true,
                      ),
                      _buildSummaryRow(
                        "Total IGST",
                        totals['totalIGST']?.toStringAsFixed(2) ?? '0.00',
                        compact: true,
                      ),

                      ValueListenableBuilder<String?>(
                        valueListenable: roundOffErrorNotifier,
                        builder: (context, error, _) {
                          final bool hasError = error != null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Round Off:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: _openRoundOffCalculator,
                                      child: Container(
                                        width: 100,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: hasError
                                                ? Colors.red
                                                : Colors.grey,
                                            width: hasError ? 2 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            manualRound.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: hasError
                                                  ? Colors.red
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      const Divider(color: Colors.grey, height: 1),
                      const SizedBox(height: 4),

                      _buildSummaryRow(
                        "Final Total Amount",
                        (grn.grnAmount ?? 0.0).toStringAsFixed(2),
                        compact: true,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _convertGrnToPo(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Revert to PO",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    ValueListenableBuilder<bool>(
                      valueListenable: isConverting,
                      builder: (_, converting, __) {
                        return GestureDetector(
                          onTap: converting
                              ? null
                              : () => _convertToAP(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: converting
                                  ? Colors.blueAccent.withOpacity(0.7)
                                  : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: converting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Convert to AP",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(ItemDetail item, String column, String itemId) {
    switch (column) {
      case 'UOM':
        return Text(
          item.uom ?? '',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'Count':
        return Text(
          '${item.nos ?? 0}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'Each Quantity':
        return Text(
          '${item.eachQuantity ?? 0}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'Received Qty':
        return Text(
          item.receivedQuantity?.toStringAsFixed(2) ?? '0.00',
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'Returned Qty':
        return Text(
          item.returnedQuantity?.toStringAsFixed(2) ?? '0.00',
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'Total Quantity':
        return Text(
          (item.quantity ?? 0).toStringAsFixed(2),
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'Price':
        return Text(
          '${item.unitPrice ?? 0}',
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'BefTax Discount':
        return ValueListenableBuilder<double>(
          valueListenable:
              befTaxDiscountNotifiers[itemId] ?? ValueNotifier(0.0),
          builder: (context, value, child) {
            return Center(
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        );
      case 'AfTax Discount':
        return ValueListenableBuilder<double>(
          valueListenable: afTaxDiscountNotifiers[itemId] ?? ValueNotifier(0.0),
          builder: (context, value, child) {
            return Center(
              child: Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        );

      case 'Discount Amount':
        return Text(
          '${item.discountAmount ?? 0}',
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'Tax Amount':
        return Text(
          '${item.taxAmount ?? 0}',
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'Expiry Date':
        return Text(
          expiryDateControllers[itemId]?.text ?? '',
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );

      case 'Total Price':
        return Text(
          (item.totalPrice ?? 0).toStringAsFixed(2),
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'Final Price':
        return Text(
          (item.finalPrice ?? 0).toStringAsFixed(2),
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'sgst':
        return Text(
          '${item.sgst ?? 0}',
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'cgst':
        return Text(
          '${item.cgst ?? 0}',
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      case 'igst':
        return Text(
          '${item.igst ?? 0}',
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );

      default:
        return Text(
          '',
          style: const TextStyle(fontSize: 13),
          textAlign: _getColumnAlignment(column) == Alignment.center
              ? TextAlign.center
              : TextAlign.left,
        );
    }
  }
}

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
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final manager = _columnNotifier.value;
            widget.onApply(manager.columns, manager.columnVisibility);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
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

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[300],
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final double width;

  const _DataCell({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
