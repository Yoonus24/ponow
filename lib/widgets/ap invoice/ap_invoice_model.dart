// ignore_for_file: use_build_context_synchronously

//---------------dialog for inside outgoing for showing invoice details ------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/ap_item.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/widgets/column_filter.dart';
import '../../providers/ap_invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';

class APInvoiceModal extends StatefulWidget {
  final ApInvoice apinvoice;

  const APInvoiceModal({super.key, required this.apinvoice});

  @override
  State<APInvoiceModal> createState() => _APInvoiceModalState();
}

class _APInvoiceModalState extends State<APInvoiceModal> {
  late ValueNotifier<List<String>> columnOrderNotifier;
  late ValueNotifier<Map<String, bool>> columnVisibilityNotifier;
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _rightHorizontalController = ScrollController();
  final ValueNotifier<bool> _isReturning = ValueNotifier(false);

  final Map<String, Widget Function(dynamic)> cellRenderers = {
    'Item Name': (item) => Text(
      item.itemName ?? '',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
    ),

    'UOM': (item) => Text(
      item.uom ?? '',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
    ),

    'Received Qty': (item) => Text(
      '${item.eachQuantity ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Returned Qty': (item) => Text(
      '${item.returnedQuantity ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Pkt Count': (item) => Text(
      '${item.nos ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Qty': (item) => Text(
      '${item.quantity ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Stock Qty': (item) => Text(
      '${item.stockQuantity ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'BefTax': (item) => Text(
      '${item.befTaxDiscount ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'AfTax': (item) => Text(
      '${item.afTaxDiscount ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Tax %': (item) => Text(
      '${item.purchasetaxName ?? 0}',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Unit Price': (item) => Text(
      item.unitPrice != null ? item.unitPrice.toStringAsFixed(2) : '0.00',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Total Price': (item) => Text(
      item.totalPrice != null ? item.totalPrice.toStringAsFixed(2) : '0.00',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),

    'Final Price': (item) => Text(
      item.finalPrice != null ? item.finalPrice.toStringAsFixed(2) : '0.00',
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.right,
    ),
  };

  @override
  void initState() {
    super.initState();

    columnOrderNotifier = ValueNotifier<List<String>>([
      'S.No',
      'Item Name',
      'Received Qty',
      'UOM',
      'Returned Qty',
      'Pkt Count',
      'Qty',
      'Stock Qty',
      'BefTax',
      'AfTax',
      'Tax %',
      'Unit Price',
      'Total Price',
      'Final Price',
    ]);

    columnVisibilityNotifier = ValueNotifier<Map<String, bool>>({
      for (var col in columnOrderNotifier.value) col: true,
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

  final Map<String, double> columnWidths = {
    'S.No': 40,
    'Item Name': 130,
    'UOM': 70,
    'Pkt Count': 80,
    'Qty': 70,
    'Stock Qty': 80,
    'BefTax': 90,
    'AfTax': 90,
    'Tax': 80,
    'Unit Price': 100,
    'Total Price': 100,
    'Final Price': 100,
  };

  @override
  void dispose() {
    columnOrderNotifier.dispose();
    columnVisibilityNotifier.dispose();

    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _rightHorizontalController.dispose();
    _isReturning.dispose();

    super.dispose();
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

  bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.read<PermissionProvider>();
    final outgoingProvider = context.read<OutgoingPaymentProvider>();

    final hasOutgoing = outgoingProvider.allPayments.any(
      (o) => o.invoiceId == widget.apinvoice.invoiceId,
    );

    debugPrint('🧾 AP MODAL STATUS => "${widget.apinvoice.status}"');
    final items = widget.apinvoice.itemDetails ?? [];
    final double roundOff = widget.apinvoice.roundOffAdjustment ?? 0.0;

    final double finalTotal = (widget.apinvoice.invoiceAmount ?? 0.0);
    final double freightAmount = widget.apinvoice.totalFreightAmount ?? 0.0;

    final double freightTax = widget.apinvoice.totalFreightTaxAmount ?? 0.0;

    final double freightTotal = freightAmount + freightTax;

    final double totalDiscount = (widget.apinvoice.discountDetails ?? 0.0);

    final apStatus = (widget.apinvoice.status ?? '').toLowerCase().trim();
    final canReturn =
        apStatus.isNotEmpty &&
        !apStatus.contains('returned') &&
        permission.hasPermission('grns', '', 'edit') &&
        permission.hasEditAction('grns', 'return_grn');
    double totalSgst = 0.0, totalCgst = 0.0;
    for (var item in items) {
      totalSgst += (item.sgst ?? 0.0);
      totalCgst += (item.cgst ?? 0.0);
    }

    final landscape = isLandscape(context);

    // For portrait mode - use original layout (no changes)
    if (!landscape) {
      return _buildPortraitMode(
        context,
        items,
        finalTotal,
        freightTotal,
        totalDiscount,
        roundOff,
        totalSgst,
        totalCgst,
        canReturn,
      );
    }

    // For landscape mode - use responsive layout
    return _buildLandscapeMode(
      context,
      items,
      finalTotal,
      freightTotal,
      totalDiscount,
      roundOff,
      totalSgst,
      totalCgst,
      canReturn,
    );
  }

  // ORIGINAL PORTRAIT MODE - NO CHANGES
  Widget _buildPortraitMode(
    BuildContext context,
    List<ItemDetail> items,
    double finalTotal,
    double freightTotal,
    double totalDiscount,
    double roundOff,
    double totalSgst,
    double totalCgst,
    bool canReturn,
  ) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),

      child: SizedBox.expand(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: columnOrderNotifier,
                  builder: (context, columnOrder, _) {
                    return ValueListenableBuilder<Map<String, bool>>(
                      valueListenable: columnVisibilityNotifier,
                      builder: (context, columnVisibility, _) {
                        final visibleColumns = columnOrder
                            .where((col) => columnVisibility[col] == true)
                            .toList();

                        final rightColumns = visibleColumns
                            .where(
                              (column) =>
                                  column != 'Item Name' && column != 'S.No',
                            )
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Invoice Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.filter_list),
                                  tooltip: 'Filter Columns',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => ColumnFilterDialog(
                                        columns: columnOrderNotifier.value,
                                        columnVisibility:
                                            columnVisibilityNotifier.value,
                                        onApply: (newOrder, newVisibility) {
                                          columnOrderNotifier.value = newOrder;
                                          columnVisibilityNotifier.value =
                                              newVisibility;
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(thickness: 1),
                            const SizedBox(height: 4),

                            Text(
                              'Invoice No: ${widget.apinvoice.randomId ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Vendor: ${widget.apinvoice.vendorName ?? 'Unknown Vendor'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Date: ${formatDate(widget.apinvoice.invoiceDate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Total Amount: ${finalTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Expanded(
                              child: Row(
                                children: [
                                  /// LEFT SIDE (S.No + Item Name)
                                  SizedBox(
                                    width:
                                        columnWidths['S.No']! +
                                        columnWidths['Item Name']!,
                                    child: Column(
                                      children: [
                                        /// HEADER
                                        Row(
                                          children: [
                                            Container(
                                              width: columnWidths['S.No'],
                                              height: 40,
                                              alignment: Alignment.center,
                                              color: Colors.grey[200],
                                              child: const Text(
                                                "S.No",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: columnWidths['Item Name'],
                                              height: 40,
                                              alignment: Alignment.centerLeft,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              color: Colors.grey[200],
                                              child: const Text(
                                                "Item Name",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        /// BODY
                                        Expanded(
                                          child: ListView.builder(
                                            controller: _leftVerticalController,
                                            itemCount: items.length,
                                            itemBuilder: (context, index) {
                                              return Row(
                                                children: [
                                                  Container(
                                                    width: columnWidths['S.No'],
                                                    height: 45,
                                                    alignment: Alignment.center,
                                                    decoration:
                                                        const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color:
                                                                  Colors.grey,
                                                              width: 0.5,
                                                            ),
                                                          ),
                                                        ),
                                                    child: Text('${index + 1}'),
                                                  ),
                                                  Container(
                                                    width:
                                                        columnWidths['Item Name'],
                                                    height: 45,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    decoration:
                                                        const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color:
                                                                  Colors.grey,
                                                              width: 0.5,
                                                            ),
                                                          ),
                                                        ),
                                                    child: Text(
                                                      items[index].itemName ??
                                                          '',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// RIGHT SIDE (SCROLLABLE)
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: _rightHorizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: rightColumns.fold<double>(
                                          0.0,
                                          (sum, col) =>
                                              sum + (columnWidths[col] ?? 120),
                                        ),
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

                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total Discount Amount: ${totalDiscount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                  Text(
                                    'SGST: ${totalSgst.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'CGST: ${totalCgst.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Freight Charges: ${freightTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                  Text(
                                    'Round Off: ${roundOff.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Invoice Amount: ${finalTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: canReturn
                                          ? () async {
                                              final shouldReturn = await showDialog<bool>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (dialogContext) {
                                                  return AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    title: const Text(
                                                      "Confirm Return",
                                                    ),
                                                    content: const Text(
                                                      "Are you sure you want to return this GRN?",
                                                    ),
                                                    actions: [
                                                      ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              dialogContext,
                                                            ).pop(false),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .blueAccent,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          _isReturning.value =
                                                              true;
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(true);
                                                          try {
                                                            await context
                                                                .read<
                                                                  APInvoiceProvider
                                                                >()
                                                                .convertToGrnFromApReturned(
                                                                  widget
                                                                          .apinvoice
                                                                          .invoiceId ??
                                                                      '',
                                                                  context,
                                                                );
                                                            if (context
                                                                .mounted) {
                                                              Navigator.of(
                                                                context,
                                                              ).pop(true);
                                                            }
                                                          } catch (e) {
                                                            _isReturning.value =
                                                                false;
                                                            if (context
                                                                .mounted) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Return failed: $e',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .blueAccent,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        child: const Text(
                                                          "Confirm",
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canReturn
                                            ? Colors.blueAccent
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'Return to GRN',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            // Full-screen loader overlay
            ValueListenableBuilder<bool>(
              valueListenable: _isReturning,
              builder: (context, isLoading, _) {
                if (!isLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // LANDSCAPE MODE - FULLY RESPONSIVE
  Widget _buildLandscapeMode(
    BuildContext context,
    List<ItemDetail> items,
    double finalTotal,
    double freightTotal,
    double totalDiscount,
    double roundOff,
    double totalSgst,
    double totalCgst,
    bool canReturn,
  ) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            body: ValueListenableBuilder<List<String>>(
              valueListenable: columnOrderNotifier,
              builder: (context, columnOrder, _) {
                return ValueListenableBuilder<Map<String, bool>>(
                  valueListenable: columnVisibilityNotifier,
                  builder: (context, columnVisibility, _) {
                    final visibleColumns = columnOrder
                        .where((col) => columnVisibility[col] == true)
                        .toList();

                    final rightColumns = visibleColumns
                        .where(
                          (column) => column != 'Item Name' && column != 'S.No',
                        )
                        .toList();

                    final leftWidth =
                        (columnWidths['S.No'] ?? 40) +
                        (columnWidths['Item Name'] ?? 130);
                    final rightWidth = rightColumns.fold<double>(
                      0.0,
                      (sum, col) => sum + (columnWidths[col] ?? 120),
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header Section
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Invoice No: ${widget.apinvoice.randomId ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Vendor: ${widget.apinvoice.vendorName ?? 'Unknown Vendor'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Date: ${formatDate(widget.apinvoice.invoiceDate)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Total Amount: ${finalTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.filter_list,
                                          size: 20,
                                        ),
                                        tooltip: 'Filter Columns',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                ColumnFilterDialog(
                                                  columns:
                                                      columnOrderNotifier.value,
                                                  columnVisibility:
                                                      columnVisibilityNotifier
                                                          .value,
                                                  onApply:
                                                      (
                                                        newOrder,
                                                        newVisibility,
                                                      ) {
                                                        columnOrderNotifier
                                                                .value =
                                                            newOrder;
                                                        columnVisibilityNotifier
                                                                .value =
                                                            newVisibility;
                                                      },
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(thickness: 1),

                                // Table Section
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.55,
                                  child: Row(
                                    children: [
                                      // Fixed Left Column
                                      SizedBox(
                                        width: leftWidth,
                                        child: Column(
                                          children: [
                                            _buildLandscapeHeaderLeft(),
                                            Expanded(
                                              child: ListView.builder(
                                                controller:
                                                    _leftVerticalController,
                                                itemCount: items.length,
                                                itemBuilder: (context, index) {
                                                  return _buildLandscapeItemLeft(
                                                    items[index],
                                                    index,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Scrollable Right Columns
                                      Expanded(
                                        child: SingleChildScrollView(
                                          controller:
                                              _rightHorizontalController,
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: rightWidth,
                                            child: Column(
                                              children: [
                                                _buildLandscapeHeaderRow(
                                                  rightColumns,
                                                ),
                                                Expanded(
                                                  child: ListView.builder(
                                                    controller:
                                                        _rightVerticalController,
                                                    itemCount: items.length,
                                                    itemBuilder: (context, index) {
                                                      return _buildLandscapeItemRow(
                                                        items[index],
                                                        index,
                                                        rightColumns,
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

                                const SizedBox(height: 8),

                                // Totals Section
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total Discount Amount: ${totalDiscount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'SGST: ${totalSgst.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'CGST: ${totalCgst.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Freight Charges: ${freightTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Round Off: ${roundOff.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Divider(),
                                      Text(
                                        'Total Invoice Amount: ${finalTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Buttons Section
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Return Button
                                      if (canReturn)
                                        ElevatedButton(
                                          onPressed: () async {
                                            final shouldReturn = await showDialog<bool>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (dialogContext) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: const Text(
                                                    "Confirm Return",
                                                  ),
                                                  content: const Text(
                                                    "Are you sure you want to return this GRN?",
                                                  ),
                                                  actions: [
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(false),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .blueAccent,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      child: const Text(
                                                        "Cancel",
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        _isReturning.value =
                                                            true;
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(true);
                                                        try {
                                                          await context
                                                              .read<
                                                                APInvoiceProvider
                                                              >()
                                                              .convertToGrnFromApReturned(
                                                                widget
                                                                        .apinvoice
                                                                        .invoiceId ??
                                                                    '',
                                                                context,
                                                              );
                                                          if (context.mounted) {
                                                            Navigator.of(
                                                              context,
                                                            ).pop(true);
                                                          }
                                                        } catch (e) {
                                                          _isReturning.value =
                                                              false;
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Return failed: $e',
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .blueAccent,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      child: const Text(
                                                        "Confirm",
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Return to GRN',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      // Close Button
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Loader overlay
          ValueListenableBuilder<bool>(
            valueListenable: _isReturning,
            builder: (context, isLoading, _) {
              if (!isLoading) return const SizedBox.shrink();
              return Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeHeaderLeft() {
    return Row(
      children: [
        Container(
          width: columnWidths['S.No'] ?? 40,
          height: 40,
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: const Text(
            "S.No",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: columnWidths['Item Name'] ?? 130,
          height: 40,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: Colors.grey[200],
          child: const Text(
            "Item Name",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeItemLeft(ItemDetail item, int index) {
    return Row(
      children: [
        Container(
          width: columnWidths['S.No'] ?? 40,
          height: 45,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
        ),
        Container(
          width: columnWidths['Item Name'] ?? 130,
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Text(
            item.itemName ?? '',
            style: const TextStyle(fontSize: 11),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeHeaderRow(List<String> columns) {
    return Container(
      height: 40,
      color: Colors.grey[200],
      child: Row(
        children: columns.map((column) {
          return Container(
            width: columnWidths[column] ?? 120,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              column,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLandscapeItemRow(
    dynamic item,
    int index,
    List<String> rightColumns,
  ) {
    return Container(
      height: 45,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: rightColumns.map((column) {
          return Container(
            width: columnWidths[column] ?? 120,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildLandscapeCellContent(column, item, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLandscapeCellContent(String column, dynamic item, int index) {
    if (column == 'S.No') {
      return Text(
        '${index + 1}',
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
      );
    }

    final renderer = cellRenderers[column];
    if (renderer != null) {
      // Override font size for landscape
      if (renderer(item) is Text) {
        final textWidget = renderer(item) as Text;
        return Text(
          textWidget.data ?? '',
          style: const TextStyle(fontSize: 11),
          textAlign: textWidget.textAlign,
        );
      }
      return Align(alignment: Alignment.center, child: renderer(item));
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeaderRow(List<String> columns) {
    return Container(
      height: 40,
      color: Colors.grey[200],
      child: Row(
        children: columns.map((column) {
          return Container(
            width: columnWidths[column] ?? 120,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              column,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemRow(dynamic item, int index, List<String> rightColumns) {
    return Container(
      height: 45,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: rightColumns.map((column) {
          return Container(
            width: columnWidths[column] ?? 120,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCellContent(column, item, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCellContent(String column, dynamic item, int index) {
    if (column == 'S.No') {
      return Text(
        '${index + 1}',
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      );
    }

    final renderer = cellRenderers[column];
    if (renderer != null) {
      return Align(alignment: Alignment.center, child: renderer(item));
    }
    return const SizedBox.shrink();
  }
}

class ColumnManager {
  final List<String> columns;
  final Map<String, bool> columnVisibility;

  ColumnManager(this.columns, this.columnVisibility);
}
