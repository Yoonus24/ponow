// ignore_for_file: invalid_use_of_visible_for_testing_member, use_build_context_synchronously, curly_braces_in_flow_control_structures, invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/widgets/numeric_calculator.dart';
import 'package:provider/provider.dart';
import '../../providers/po_model_provider.dart';
import '../../models/po.dart';
import '../../providers/po_provider.dart';
import '../column_filter.dart';

class POModal extends StatefulWidget {
  final PO po;
  final bool showApproveButton;
  final bool showRejectButton;

  const POModal({
    super.key,
    required this.po,
    this.showApproveButton = false,
    this.showRejectButton = false,
  });

  @override
  _POModalState createState() => _POModalState();
}

class _POModalState extends State<POModal> {
  late List<TextEditingController> countControllers;
  late List<TextEditingController> eachQuantityControllers;
  late List<TextEditingController> newPriceControllers;
  late List<TextEditingController> befTaxDiscountControllers;
  late List<TextEditingController> afTaxDiscountControllers;
  late ValueNotifier<List<String>> columnsNotifier;
  late ValueNotifier<Map<String, bool>> columnVisibilityNotifier;

  // ⭐ NEW: Scroll controllers for fixed + scrollable areas
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _rightHorizontalController = ScrollController();
  final ValueNotifier<bool> isSaving = ValueNotifier(false);
  final ValueNotifier<bool> isApproving = ValueNotifier(false);
  final ValueNotifier<bool> isRejecting = ValueNotifier(false);

  bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers from PO items
    countControllers = widget.po.items
        .map(
          (item) =>
              TextEditingController(text: item.pendingCount?.toString() ?? ''),
        )
        .toList();
    eachQuantityControllers = widget.po.items
        .map(
          (item) => TextEditingController(
            text: item.pendingQuantity?.toString() ?? '',
          ),
        )
        .toList();
    newPriceControllers = widget.po.items
        .map(
          (item) =>
              TextEditingController(text: item.newPrice?.toString() ?? ''),
        )
        .toList();
    befTaxDiscountControllers = widget.po.items
        .map(
          (item) => TextEditingController(
            text: item.pendingBefTaxDiscountAmount?.toString() ?? '',
          ),
        )
        .toList();
    afTaxDiscountControllers = widget.po.items
        .map(
          (item) => TextEditingController(
            text: item.pendingAfTaxDiscountAmount?.toString() ?? '',
          ),
        )
        .toList();

    columnsNotifier = ValueNotifier<List<String>>([
      'Item Name',
      'UOM',
      'Count',
      'Each Qty',
      'Total Qty',
      'New Price',
      'BeforeTaxDiscount',
      'AfterTaxDiscount',
      'Tax %',
      'Total Price',
      'Final Price',
      'Tax Amount',
      'sgst',
      'cgst',
      'igst',
    ]);

    columnVisibilityNotifier = ValueNotifier<Map<String, bool>>({
      'Item Name': true,
      'UOM': true,
      'Count': true,
      'Each Qty': true,
      'Total Qty': true,
      'New Price': true,
      'BeforeTaxDiscount': false,
      'AfterTaxDiscount': false,
      'Tax %': false,
      'Total Price': true,
      'Final Price': true,
      'Tax Amount': false,
      'sgst': false,
      'cgst': false,
      'igst': false,
    });

    // ⭐ Sync vertical scroll between left & right lists
    _leftVerticalController.addListener(() {
      if (_rightVerticalController.offset != _leftVerticalController.offset) {
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
      }
    });

    _rightVerticalController.addListener(() {
      if (_leftVerticalController.offset != _rightVerticalController.offset) {
        _leftVerticalController.jumpTo(_rightVerticalController.offset);
      }
    });
  }

  @override
  void dispose() {
    [
          countControllers,
          eachQuantityControllers,
          newPriceControllers,
          befTaxDiscountControllers,
          afTaxDiscountControllers,
        ]
        .expand((list) => list)
        .toList()
        .forEach((controller) => controller.dispose());

    columnsNotifier.dispose();
    columnVisibilityNotifier.dispose();

    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _rightHorizontalController.dispose();
    isSaving.dispose();
    isApproving.dispose();
    isRejecting.dispose();

    super.dispose();
  }

  void updateCalculations(int index, BuildContext context) {
    final poModalProvider = Provider.of<POModalProvider>(
      context,
      listen: false,
    );
    final item = widget.po.items[index];

    final pendingCount = double.tryParse(countControllers[index].text) ?? 0;
    final eachQuantity =
        double.tryParse(eachQuantityControllers[index].text) ?? 0;
    final unitPrice = double.tryParse(newPriceControllers[index].text) ?? 0;
    final beftaxDiscountPercentage =
        double.tryParse(befTaxDiscountControllers[index].text) ?? 0;
    final aftaxDiscountPercentage =
        double.tryParse(afTaxDiscountControllers[index].text) ?? 0;
    final taxPercentage = item.taxPercentage ?? 0;

    final totalQuantity = pendingCount * eachQuantity;
    final totalPrice = totalQuantity * unitPrice;
    final discountAmount = (totalPrice * beftaxDiscountPercentage) / 100;
    final beftaxamount = totalPrice - discountAmount;
    final taxAmount = (beftaxamount * taxPercentage) / 100;
    final afterTaxDiscountAmount =
        (beftaxamount + taxAmount) * (aftaxDiscountPercentage / 100);
    final finalPrice = beftaxamount + taxAmount - afterTaxDiscountAmount;

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (taxAmount > 0) {
      cgst = taxAmount / 2;
      sgst = taxAmount / 2;
      igst = 0.0;
    }

    newPriceControllers[index].text = unitPrice.toStringAsFixed(2);
    befTaxDiscountControllers[index].text = beftaxDiscountPercentage
        .toStringAsFixed(2);
    afTaxDiscountControllers[index].text = aftaxDiscountPercentage
        .toStringAsFixed(2);

    // update model
    item.itemId = item.itemId;
    item.pendingCount = pendingCount;
    item.pendingQuantity = eachQuantity;
    item.pendingTotalQuantity = totalQuantity;
    item.newPrice = unitPrice;
    item.pendingDiscountAmount = discountAmount;
    item.pendingBefTaxDiscountAmount = beftaxDiscountPercentage;
    item.pendingAfTaxDiscountAmount = aftaxDiscountPercentage;
    item.pendingTaxAmount = taxAmount;
    item.pendingTotalPrice = totalPrice;
    item.pendingFinalPrice = finalPrice;

    item.pendingCgst = cgst;
    item.pendingSgst = sgst;
    item.pendingIgst = igst;

    widget.po.pendingDiscountAmount = getTotalDiscountAmount();
    widget.po.pendingTaxAmount = getTotalTaxAmount();
    widget.po.pendingOrderAmount = getTotalOrderAmount();

    poModalProvider.notifyListeners();
  }

  double getTotalDiscountAmount() {
    return widget.po.items.fold(
      0.0,
      (sum, item) => sum + (item.pendingDiscountAmount ?? 0.0),
    );
  }

  double getTotalSGST() {
    return widget.po.items.fold(
      0.0,
      (sum, item) => sum + (item.pendingTaxAmount ?? 0.0) / 2,
    );
  }

  double getTotalCGST() {
    return widget.po.items.fold(
      0.0,
      (sum, item) => sum + (item.pendingTaxAmount ?? 0.0) / 2,
    );
  }

  double getFinalTotalWithRoundOff() {
    final itemsTotal = widget.po.items.fold(
      0.0,
      (sum, item) => sum + (item.pendingFinalPrice ?? 0.0),
    );

    final roundOff = widget.po.roundOffAdjustment ?? 0.0;

    return itemsTotal + roundOff;
  }

  double getTotalOrderAmount() {
    // Use the PO's pendingOrderAmount if available, otherwise calculate it
    return widget.po.pendingOrderAmount ??
        widget.po.items.fold(
              0.0,
              (sum, item) => sum + (item.pendingFinalPrice ?? 0.0),
            ) +
            (widget.po.roundOffAdjustment ?? 0.0);
  }

  double getTotalTaxAmount() {
    return widget.po.items.fold(
      0.0,
      (sum, item) => sum + (item.pendingTaxAmount ?? 0.0),
    );
  }

  void _applyColumnFilter(
    List<String> updatedColumns,
    Map<String, bool> updatedVisibility,
  ) {
    columnsNotifier.value = List<String>.from(updatedColumns);
    columnVisibilityNotifier.value = Map<String, bool>.from(updatedVisibility);
  }

  void showNumericCalculator({
    required BuildContext context,
    required TextEditingController controller,
    required String varianceName,
    required VoidCallback onValueSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => Align(
        alignment: isTablet(context)
            ? Alignment.centerRight
            : Alignment.bottomCenter,
        child: Padding(
          padding: isTablet(context)
              ? const EdgeInsets.only(right: 16.0)
              : const EdgeInsets.only(bottom: 16.0),
          child: Material(
            color: Colors.transparent,
            child: NumericCalculator(
              varianceName: varianceName,
              controller: controller,
              initialValue: 0.0,
              onValueSelected: (value) {
                controller.text = value.toStringAsFixed(2);
                onValueSelected();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required bool isApprove,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            // CANCEL BUTTON
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // APPROVE / REJECT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove
                    ? Colors.blueAccent
                    : Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(isApprove ? "Approve" : "Reject"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow(List<String> visibleColumns) {
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Row(
        children: visibleColumns.map((column) {
          return Expanded(
            child: Center(
              child: Text(
                column,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemRow(
    Item item,
    int index,
    List<String> visibleColumns,
    BuildContext context,
  ) {
    return SizedBox(
      height: 45,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: visibleColumns.map((column) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: _buildCellContent(column, item, index, context),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCellContent(
    String column,
    Item item,
    int index,
    BuildContext context,
  ) {
    switch (column) {
      case 'Item Name':
        return Text(
          item.itemName ?? '',
          textAlign: TextAlign.left,

          maxLines: 2, // Changed from 1 to 2
          softWrap: true, // Changed from false to true
          style: const TextStyle(fontSize: 12),
        );

      case 'UOM':
        return Text(
          item.uom ?? '',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'Count':
        return TextField(
          controller: countControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Count',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 8.0,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: countControllers[index],
              varianceName: 'Enter Count',
              onValueSelected: () async {
                final provider = Provider.of<POModalProvider>(
                  context,
                  listen: false,
                );

                // First update raw values
                provider.updateItemRaw(
                  index,
                  count: double.tryParse(countControllers[index].text),
                );

                // Then ask backend to calculate
                await provider.calculateAndUpdateItem(index);
              },
            );
          },
          textAlign: TextAlign.center,
        );
      case 'Each Qty':
        return TextField(
          controller: eachQuantityControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Qty',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 8.0,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: eachQuantityControllers[index],
              varianceName: 'Enter Quantity',
              onValueSelected: () async {
                final provider = Provider.of<POModalProvider>(
                  context,
                  listen: false,
                );

                final value =
                    double.tryParse(eachQuantityControllers[index].text) ?? 0;

                provider.updateItemRaw(index, eachQty: value);

                await provider.calculateAndUpdateItem(index);
              },
            );
          },

          textAlign: TextAlign.center,
        );
      case 'Total Qty':
        return Text(
          item.pendingTotalQuantity?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'New Price':
        return TextField(
          controller: newPriceControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Price',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 8.0,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: newPriceControllers[index],
              varianceName: 'Enter Price',
              onValueSelected: () async {
                final provider = Provider.of<POModalProvider>(
                  context,
                  listen: false,
                );

                final value =
                    double.tryParse(newPriceControllers[index].text) ?? 0;

                // ✅ CORRECT: update newPrice
                provider.updateItemRaw(index, newPrice: value);

                await provider.calculateAndUpdateItem(index);
              },
            );
          },
          textAlign: TextAlign.center,
        );

      case 'BeforeTaxDiscount':
        return TextField(
          controller: befTaxDiscountControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Before Tax %',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 8.0,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: befTaxDiscountControllers[index],
              varianceName: 'Enter Before Tax Discount %',
              onValueSelected: () async {
                final provider = Provider.of<POModalProvider>(
                  context,
                  listen: false,
                );

                // First update raw values
                provider.updateItemRaw(
                  index,
                  count: double.tryParse(countControllers[index].text),
                );

                // Then ask backend to calculate
                await provider.calculateAndUpdateItem(index);
              },
            );
          },
          textAlign: TextAlign.center,
        );
      case 'AfterTaxDiscount':
        return TextField(
          controller: afTaxDiscountControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'After Tax %',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 8.0,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: afTaxDiscountControllers[index],
              varianceName: 'Enter After Tax Discount %',
              onValueSelected: () async {
                final provider = Provider.of<POModalProvider>(
                  context,
                  listen: false,
                );

                // First update raw values
                provider.updateItemRaw(
                  index,
                  count: double.tryParse(countControllers[index].text),
                );

                // Then ask backend to calculate
                await provider.calculateAndUpdateItem(index);
              },
            );
          },
          textAlign: TextAlign.center,
        );
      case 'Tax %':
        return Text(
          item.taxPercentage?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'Tax Amount':
        return Text(
          item.pendingTaxAmount?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'Total Price':
        return Text(
          item.pendingTotalPrice?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'Final Price':
        return Text(
          item.pendingFinalPrice?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'sgst':
        return Text(
          item.pendingSgst?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'cgst':
        return Text(
          item.pendingCgst?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      case 'igst':
        return Text(
          item.pendingIgst?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 12),
        );
      default:
        return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.po.items;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // ✅ REMOVE CURVE
      ),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: columnsNotifier,
        builder: (context, columns, _) {
          return ValueListenableBuilder<Map<String, bool>>(
            valueListenable: columnVisibilityNotifier,
            builder: (context, columnVisibility, _) {
              final visibleColumns = columns
                  .where((column) => columnVisibility[column] ?? false)
                  .toList();

              final rightColumns = visibleColumns
                  .where((column) => column != 'Item Name')
                  .toList();

              return ChangeNotifierProvider(
                create: (_) => POModalProvider(widget.po),
                child: Consumer<POModalProvider>(
                  builder: (context, poModalProvider, _) {
                    final po = poModalProvider.po;

                    return Column(
                      children: [
                        // ✅ HEADER (STATIC) - TOP SECTION
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PO No: ${po.randomId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Vendor: ${po.vendorName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.filter_list, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ColumnFilterDialog(
                                      columns: columns,
                                      columnVisibility: columnVisibility,
                                      onApply: _applyColumnFilter,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // ✅ TABLE SECTION WITH FIXED HEIGHT THAT SCROLLS
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                // LEFT FIXED COLUMN (Item Names)
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    children: [
                                      // FIXED HEADER
                                      Container(
                                        height: 33,
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 6),
                                        color: Colors.grey[200],
                                        child: const Text(
                                          "Item Name",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // SCROLLABLE ITEM NAMES
                                      Expanded(
                                        child: ListView.builder(
                                          controller: _leftVerticalController,
                                          itemCount: po.items.length,
                                          itemBuilder: (context, index) {
                                            final item = po.items[index];
                                            return SizedBox(
                                              height: 45,
                                              child: Container(
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.only(
                                                  left: 6,
                                                ),
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  item.itemName ?? '',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // RIGHT SCROLLABLE COLUMNS
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _rightHorizontalController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: (rightColumns.length * 110.0)
                                          .clamp(300.0, 1500),
                                      child: Column(
                                        children: [
                                          // FIXED HEADER ROW
                                          _buildHeaderRow(rightColumns),
                                          // SCROLLABLE CONTENT
                                          Expanded(
                                            child: ListView.builder(
                                              controller:
                                                  _rightVerticalController,
                                              itemCount: po.items.length,
                                              itemBuilder: (context, index) {
                                                return _buildItemRow(
                                                  po.items[index],
                                                  index,
                                                  rightColumns,
                                                  context,
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
                            ),
                          ),
                        ),

                        // ✅ BOTTOM STATIC SUMMARY SECTION (WITH ROUND OFF)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Divider(),

                              Text(
                                "Discount Amount: ${po.items.fold(0.0, (s, i) => s + (i.pendingDiscountAmount ?? 0)).toStringAsFixed(2)}",
                              ),

                              Text(
                                "SGST: ${po.items.fold(0.0, (s, i) => s + (i.pendingSgst ?? 0)).toStringAsFixed(2)}",
                              ),

                              Text(
                                "CGST: ${po.items.fold(0.0, (s, i) => s + (i.pendingCgst ?? 0)).toStringAsFixed(2)}",
                              ),

                              // ✅ SHOW ROUND OFF
                              Text(
                                "Round Off: ${(po.roundOffAdjustment ?? 0.0).toStringAsFixed(2)}",
                              ),

                              // ✅ FINAL TOTAL WITH ROUND OFF
                              Text(
                                "Total Order Amount: ${getFinalTotalWithRoundOff().toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ BOTTOM STATIC BUTTONS SECTION
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // CLOSE BUTTON
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Close'),
                              ),

                              const SizedBox(width: 12),

                              // SAVE BUTTON
                              ElevatedButton(
                                onPressed: isSaving.value
                                    ? null
                                    : () async {
                                        try {
                                          isSaving.value = true;

                                          await poModalProvider.saveChanges(
                                            context,
                                          );

                                          Provider.of<POProvider>(
                                            context,
                                            listen: false,
                                          ).fetchPOs(); // 🔄 background refresh

                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        } finally {
                                          isSaving.value = false;
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: isSaving,
                                  builder: (_, saving, __) {
                                    return saving
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Save',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                  },
                                ),
                              ),

                              // ⭐⭐⭐ APPROVE BUTTON (ONLY IF ENABLED)
                              if (widget.showApproveButton) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: isApproving.value
                                      ? null
                                      : () async {
                                          final confirm = await showConfirmDialog(
                                            context: context,
                                            title: "Approve PO?",
                                            message:
                                                "Are you sure you want to approve this purchase order?",
                                            isApprove: true,
                                          );

                                          if (confirm != true) return;

                                          try {
                                            isApproving.value = true;

                                            final poProvider =
                                                Provider.of<POProvider>(
                                                  context,
                                                  listen: false,
                                                );

                                            await poProvider.approvePo(
                                              widget.po.purchaseOrderId,
                                              'Approved',
                                              widget.po,
                                            );

                                            poProvider.fetchPOs();

                                            if (context.mounted)
                                              Navigator.of(context).pop();
                                          } finally {
                                            isApproving.value = false;
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: isApproving,
                                    builder: (_, saving, __) {
                                      return saving
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Approve',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                    },
                                  ),
                                ),
                              ],

                              // ⭐⭐⭐ REJECT BUTTON (ONLY IF ENABLED)
                              if (widget.showRejectButton) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: isRejecting.value
                                      ? null
                                      : () async {
                                          final confirm = await showConfirmDialog(
                                            context: context,
                                            title: "Reject PO?",
                                            message:
                                                "Are you sure you want to reject this purchase order?",
                                            isApprove: false,
                                          );

                                          if (confirm != true) return;

                                          try {
                                            isRejecting.value = true;

                                            final poProvider =
                                                Provider.of<POProvider>(
                                                  context,
                                                  listen: false,
                                                );

                                            await poProvider.approvePo(
                                              widget.po.purchaseOrderId,
                                              'Rejected',
                                              widget.po,
                                            );

                                            poProvider.fetchPOs();

                                            if (context.mounted)
                                              Navigator.of(context).pop();
                                          } finally {
                                            isRejecting.value = false;
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: isRejecting,
                                    builder: (_, saving, __) {
                                      return saving
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Reject',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
