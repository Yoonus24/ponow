// ignore_for_file: invalid_use_of_visible_for_testing_member, use_build_context_synchronously, curly_braces_in_flow_control_structures, invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
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

  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _rightHorizontalController = ScrollController();
  final ValueNotifier<bool> isSaving = ValueNotifier(false);
  final ValueNotifier<bool> isApproving = ValueNotifier(false);
  final ValueNotifier<bool> isRejecting = ValueNotifier(false);
  bool _initialized = false;

  bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  @override
  void initState() {
    super.initState();

    countControllers = widget.po.items
        .map(
          (item) =>
              TextEditingController(text: (item.pendingCount ?? 0).toString()),
        )
        .toList();

    eachQuantityControllers = widget.po.items
        .map(
          (item) => TextEditingController(
            text: (item.pendingQuantity ?? 0).toString(),
          ),
        )
        .toList();

    newPriceControllers = widget.po.items
        .map(
          (item) => TextEditingController(
            text: (item.newPrice ?? 0).toStringAsFixed(2),
          ),
        )
        .toList();

    befTaxDiscountControllers = [];
    afTaxDiscountControllers = [];

    for (final item in widget.po.items) {
      final double totalDiscount = item.pendingDiscountAmount ?? 0.0;
      final double totalPrice = item.pendingTotalPrice ?? 0.0;

      double befAmount = 0.0;
      double afAmount = 0.0;

      if (totalDiscount > 0 && totalPrice > 0) {
        afAmount = totalDiscount;
      }

      item.pendingBefTaxDiscountAmount = befAmount;
      item.pendingAfTaxDiscountAmount = afAmount;

      befTaxDiscountControllers.add(
        TextEditingController(text: befAmount.toStringAsFixed(2)),
      );

      afTaxDiscountControllers.add(
        TextEditingController(text: afAmount.toStringAsFixed(2)),
      );
    }

    initializeTaxFromBackend();

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

    _leftVerticalController.addListener(() {
      if (_rightVerticalController.hasClients &&
          _rightVerticalController.offset != _leftVerticalController.offset) {
        _rightVerticalController.jumpTo(_leftVerticalController.offset);
      }
    });

    _rightVerticalController.addListener(() {
      if (_leftVerticalController.hasClients &&
          _leftVerticalController.offset != _rightVerticalController.offset) {
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

    final pendingCount = double.tryParse(countControllers[index].text) ?? 0.0;

    final eachQuantity =
        double.tryParse(eachQuantityControllers[index].text) ?? 0.0;

    final unitPrice = double.tryParse(newPriceControllers[index].text) ?? 0.0;

    final befTaxDiscountPercent =
        double.tryParse(befTaxDiscountControllers[index].text) ?? 0.0;

    final afTaxDiscountPercent =
        double.tryParse(afTaxDiscountControllers[index].text) ?? 0.0;

    final taxPercentage = item.taxPercentage ?? 0.0;

    final totalQuantity = pendingCount * eachQuantity;
    final totalPrice = totalQuantity * unitPrice;

    final befTaxDiscountAmount = (totalPrice * befTaxDiscountPercent) / 100;

    final priceAfterBefDiscount = totalPrice - befTaxDiscountAmount;

    final taxAmount = (priceAfterBefDiscount * taxPercentage) / 100;

    final afTaxDiscountAmount =
        (priceAfterBefDiscount + taxAmount) * (afTaxDiscountPercent / 100);

    final finalPrice = priceAfterBefDiscount + taxAmount - afTaxDiscountAmount;

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (taxAmount > 0) {
      if (item.taxType == "cgst_sgst") {
        cgst = taxAmount / 2;
        sgst = taxAmount / 2;
      } else {
        igst = taxAmount;
      }
    }

    item.pendingCount = pendingCount;
    item.pendingQuantity = eachQuantity;
    item.pendingTotalQuantity = totalQuantity;

    item.newPrice = unitPrice;
    item.pendingTotalPrice = totalPrice;

    item.pendingBefTaxDiscountAmount = befTaxDiscountAmount;
    item.pendingAfTaxDiscountAmount = afTaxDiscountAmount;

    if (befTaxDiscountPercent > 0 || afTaxDiscountPercent > 0) {
      item.pendingDiscountAmount = befTaxDiscountAmount + afTaxDiscountAmount;
    }

    item.pendingTaxAmount = taxAmount;
    item.pendingFinalPrice = finalPrice;

    item.pendingCgst = cgst;
    item.pendingSgst = sgst;
    item.pendingIgst = igst;

    befTaxDiscountControllers[index].text = befTaxDiscountAmount
        .toStringAsFixed(2);

    afTaxDiscountControllers[index].text = afTaxDiscountAmount.toStringAsFixed(
      2,
    );

    newPriceControllers[index].text = unitPrice.toStringAsFixed(2);

    widget.po.pendingDiscountAmount = widget.po.items.fold<double>(
      0.0,
      (sum, i) => sum + (i.pendingDiscountAmount ?? 0.0),
    );

    widget.po.pendingTaxAmount = widget.po.items.fold<double>(
      0.0,
      (sum, i) => sum + (i.pendingTaxAmount ?? 0.0),
    );

    widget.po.pendingOrderAmount = widget.po.items.fold<double>(
      0.0,
      (sum, i) => sum + (i.pendingFinalPrice ?? 0.0),
    );

    poModalProvider.notifyListeners();
  }

  void initializeTaxFromBackend() {
    for (final item in widget.po.items) {
      final tax = item.pendingTaxAmount ?? 0.0;

      if (tax > 0) {
        if (item.taxType == "cgst_sgst") {
          item.pendingCgst = tax / 2;
          item.pendingSgst = tax / 2;
          item.pendingIgst = 0.0;
        } else {
          item.pendingIgst = tax;
          item.pendingCgst = 0.0;
          item.pendingSgst = 0.0;
        }
      }
    }
  }

  double getTotalDiscountAmount() {
    return widget.po.items.fold<double>(
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
    final itemsTotal = widget.po.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.pendingFinalPrice ?? 0.0),
    );

    final freight = widget.po.totalFreightAmount ?? 0.0;

    final freightTax = widget.po.totalFreightTaxAmount ?? 0.0;

    final roundOff = widget.po.roundOffAdjustment ?? 0.0;

    final total = itemsTotal + freight + freightTax + roundOff;

    return total;
  }

  double getTotalOrderAmount() {
    return widget.po.items.fold<double>(
          0.0,
          (sum, item) => sum + (item.pendingFinalPrice ?? 0.0),
        ) +
        (widget.po.roundOffAdjustment ?? 0.0);
  }

  double getTotalTaxAmount() {
    return widget.po.items.fold<double>(
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
      height: 55,
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
    final provider = context.watch<POModalProvider>();

    switch (column) {
      case 'Item Name':
        return Text(
          item.itemName ?? '',
          textAlign: TextAlign.left,
          maxLines: 4,
          softWrap: true,
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
        return TextFormField(
          controller: countControllers[index],
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Count',
            errorText: provider.countErrors[index],
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            isDense: true,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: countControllers[index],
              varianceName: 'Enter Count',
              onValueSelected: () async {
                final provider = context.read<POModalProvider>();

                provider.updateItemRaw(
                  index,
                  count: double.tryParse(countControllers[index].text),
                );

                await provider.calculateAndUpdateItem(index);
              },
            );
          },
        );

      case 'Each Qty':
        return TextFormField(
          controller: eachQuantityControllers[index],
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Qty',
            errorText: provider.quantityErrors[index],
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            isDense: true,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: eachQuantityControllers[index],
              varianceName: 'Enter Quantity',
              onValueSelected: () async {
                final provider = context.read<POModalProvider>();

                final value =
                    double.tryParse(eachQuantityControllers[index].text) ?? 0;

                provider.updateItemRaw(index, eachQty: value);

                await provider.calculateAndUpdateItem(index);
              },
            );
          },
        );

      case 'Total Qty':
        return Text(
          item.pendingTotalQuantity?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'New Price':
        return TextFormField(
          controller: newPriceControllers[index],
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Price',
            errorText: provider.priceErrors[index],
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            isDense: true,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
          onTap: () {
            showNumericCalculator(
              context: context,
              controller: newPriceControllers[index],
              varianceName: 'Enter Price',
              onValueSelected: () async {
                final provider = context.read<POModalProvider>();

                final value =
                    double.tryParse(newPriceControllers[index].text) ?? 0;

                provider.updateItemRaw(index, newPrice: value);

                await provider.calculateAndUpdateItem(index);
              },
            );
          },
        );

      case 'BeforeTaxDiscount':
        return TextField(
          controller: befTaxDiscountControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Before Tax %',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        );

      case 'AfterTaxDiscount':
        return TextField(
          controller: afTaxDiscountControllers[index],
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'After Tax %',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        );

      case 'Tax %':
        return Text(
          item.taxPercentage?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'Tax Amount':
        return Text(
          item.pendingTaxAmount?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'Total Price':
        return Text(
          item.pendingTotalPrice?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'Final Price':
        return Text(
          item.pendingFinalPrice?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'sgst':
        return Text(
          item.pendingSgst?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'cgst':
        return Text(
          item.pendingCgst?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      case 'igst':
        return Text(
          item.pendingIgst?.toStringAsFixed(2) ?? '0.00',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        );

      default:
        return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<PermissionProvider>();

    bool canEdit = permission.hasPermission(
      "yenerp",
      "purchaseorders_pending",
      "edit",
    );

    bool canApprove = permission.hasPermission(
      "yenerp",
      "purchaseorders_pending",
      "approve",
    );
    bool canReject = permission.hasPermission(
      "yenerp",
      "purchaseorders_pending",
      "reject",
    );
    final items = widget.po.items
        .where((item) => (item.pendingTotalQuantity ?? 0) > 0)
        .toList();
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ValueListenableBuilder<List<String>>(
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
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 33,
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          color: Colors.grey[200],
                                          child: const Row(
                                            children: const [
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  "S.No",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  "Item Name",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            controller: _leftVerticalController,
                                            itemCount: items.length,
                                            itemBuilder: (context, index) {
                                              final item = items[index];
                                              return SizedBox(
                                                height: 55,
                                                child: Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 6,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Colors.grey,
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 30,
                                                        child: Text(
                                                          "${index + 1}",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          item.itemName ?? '',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: _rightHorizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: (rightColumns.length * 110.0)
                                            .clamp(300.0, 1500),
                                        child: Column(
                                          children: [
                                            _buildHeaderRow(rightColumns),
                                            Expanded(
                                              child: ListView.builder(
                                                controller:
                                                    _rightVerticalController,
                                                itemCount: items.length,
                                                itemBuilder: (context, index) {
                                                  return _buildItemRow(
                                                    items[index],
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

                                Text(
                                  "Freight Amount: ${(po.totalFreightAmount ?? 0.0).toStringAsFixed(2)}",
                                ),

                                Text(
                                  "Freight Tax: ${(po.totalFreightTaxAmount ?? 0.0).toStringAsFixed(2)}",
                                ),

                                Text(
                                  "Round Off: ${(po.roundOffAdjustment ?? 0.0).toStringAsFixed(2)}",
                                ),

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

                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Close'),
                                ),

                                const SizedBox(width: 12),

                                ElevatedButton(
                                  onPressed: (!canEdit || isSaving.value)
                                      ? null
                                      : () async {
                                          try {
                                            isSaving.value = true;

                                            await poModalProvider.saveChanges(
                                              context,
                                            );

                                            final poProvider = context
                                                .read<POProvider>();
                                            await poProvider
                                                .fetchPendingPOsFromBackend(
                                                  clearExisting: true,
                                                );

                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          } catch (e) {
                                            debugPrint("Save failed: $e");
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

                                if (widget.showApproveButton) ...[
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (!canApprove) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              "You do not have permission to approve this order",
                                            ),
                                            backgroundColor: Colors.red,

                                            behavior: SnackBarBehavior
                                                .floating, // 🔥 IMPORTANT

                                            margin: const EdgeInsets.only(
                                              bottom:
                                                  80, // 👈 adjust height (increase/decrease)
                                              left: 16,
                                              right: 16,
                                            ),

                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),

                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (isApproving.value) return;

                                      final errorMessage = context
                                          .read<POModalProvider>()
                                          .validateItems();

                                      if (errorMessage != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(errorMessage)),
                                        );
                                        return;
                                      }

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

                                        final poProvider = context
                                            .read<POProvider>();

                                        if (poModalProvider.hasChanges) {
                                          await poModalProvider
                                              .saveChangesDirect();
                                        }

                                        await poProvider.approvePo(
                                          widget.po.purchaseOrderId,
                                        );

                                        poProvider.removeApprovedPO(
                                          widget.po.purchaseOrderId,
                                        );

                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      } finally {
                                        isApproving.value = false;
                                      }
                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canApprove
                                          ? Colors.blueAccent
                                          : Colors.grey, // 👈 grey look
                                      foregroundColor: Colors.white,
                                    ),

                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: isApproving,
                                      builder: (_, saving, __) {
                                        return saving
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
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

                                if (widget.showRejectButton) ...[
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: isRejecting.value
                                        ? null
                                        : () async {
                                            if (!canReject) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    "You do not have permission to reject this order",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.only(
                                                    bottom: 80,
                                                    left: 16,
                                                    right: 16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

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

                                              await poProvider.rejectPo(
                                                widget.po.purchaseOrderId,
                                              );

                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            } finally {
                                              isRejecting.value = false;
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canReject
                                          ? Colors.redAccent
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: isRejecting,
                                      builder: (_, saving, __) {
                                        return saving
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
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
      ),
    );
  }
}
