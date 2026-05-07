// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/ap_item.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:purchaseorders2/widgets/column_filter.dart';
import 'ap_invoice_modal_logic.dart';

class APInvoiceModal extends StatefulWidget {
  final ApInvoice apinvoice;

  const APInvoiceModal({super.key, required this.apinvoice});

  @override
  State<APInvoiceModal> createState() => _APInvoiceModalState();
}

class _APInvoiceModalState extends State<APInvoiceModal> {
  late APInvoiceModalLogic logic;
  final ValueNotifier<bool> isVerifying = ValueNotifier(false);
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
    logic = APInvoiceModalLogic(apinvoice: widget.apinvoice);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logic.setContext(context);
    logic.hasOutgoingPayment(context);

    debugPrint('🧾 AP MODAL STATUS => "${widget.apinvoice.status}"');
    final items = logic.getItems();
    final roundOff = logic.getRoundOff();
    final finalTotal = logic.getFinalTotal();
    final freightTotal = logic.getFreightTotal();
    final totalDiscount = logic.getTotalDiscount();
    final canReturn = logic.getCanReturn(context);
    final taxTotals = logic.getTaxTotals(items);
    final totalSgst = taxTotals['sgst']!;
    final totalCgst = taxTotals['cgst']!;
    final landscape = logic.isLandscape(context);

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
                  valueListenable: logic.columnOrderNotifier,
                  builder: (context, columnOrder, _) {
                    return ValueListenableBuilder<Map<String, bool>>(
                      valueListenable: logic.columnVisibilityNotifier,
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
                                        columns:
                                            logic.columnOrderNotifier.value,
                                        columnVisibility: logic
                                            .columnVisibilityNotifier
                                            .value,
                                        onApply: (newOrder, newVisibility) {
                                          logic.updateColumnOrder(newOrder);
                                          logic.updateColumnVisibility(
                                            newVisibility,
                                          );
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
                              'Invoice No: ${logic.getInvoiceNo()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Vendor: ${logic.getVendorName()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Date: ${logic.getInvoiceDate()}',
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
                                  SizedBox(
                                    width:
                                        logic.columnWidths['S.No']! +
                                        logic.columnWidths['Item Name']!,
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: logic.columnWidths['S.No'],
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
                                              width: logic
                                                  .columnWidths['Item Name'],
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
                                        Expanded(
                                          child: ListView.builder(
                                            controller:
                                                logic.leftVerticalController,
                                            itemCount: items.length,
                                            itemBuilder: (context, index) {
                                              return Row(
                                                children: [
                                                  Container(
                                                    width: logic
                                                        .columnWidths['S.No'],
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
                                                    width: logic
                                                        .columnWidths['Item Name'],
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
                                                    child: Tooltip(
                                                      message:
                                                          items[index]
                                                              .itemName ??
                                                          '',
                                                      waitDuration:
                                                          const Duration(
                                                            milliseconds: 500,
                                                          ),
                                                      child: Text(
                                                        items[index].itemName ??
                                                            '',
                                                      ),
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
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller:
                                          logic.rightHorizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: logic.getRightWidth(
                                          rightColumns,
                                        ),
                                        child: Column(
                                          children: [
                                            _buildHeaderRow(rightColumns),
                                            Expanded(
                                              child: ListView.builder(
                                                controller: logic
                                                    .rightVerticalController,
                                                itemCount: items.length,
                                                itemBuilder: (context, index) =>
                                                    _buildItemRow(
                                                      items[index],
                                                      index,
                                                      rightColumns,
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
                                                builder: (dialogContext) => AlertDialog(
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
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(true);
                                                        await logic
                                                            .performReturn(
                                                              context,
                                                            );
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
                                                ),
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed:
                                          (widget.apinvoice.verifiedBy !=
                                                  null &&
                                              widget
                                                  .apinvoice
                                                  .verifiedBy!
                                                  .isNotEmpty)
                                          ? null
                                          : () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) => AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: const Text(
                                                    "Confirm Verify",
                                                  ),
                                                  content: const Text(
                                                    "Are you sure you want to verify this AP Invoice?",
                                                  ),
                                                  actions: [
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
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
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .blueAccent,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                      child: const Text(
                                                        "Verify",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                isVerifying.value =
                                                    true; 

                                                final success = await context
                                                    .read<APInvoiceProvider>()
                                                    .verifyAPInvoice(
                                                      widget
                                                          .apinvoice
                                                          .invoiceId!,
                                                    );

                                                isVerifying.value =
                                                    false; 

                                                if (success &&
                                                    context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "AP Invoice Verified",
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );

                                                  Navigator.pop(context, true);
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blueAccent, 
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("Verify"),
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
           ValueListenableBuilder<bool>(
  valueListenable: logic.isReturning,
  builder: (context, isReturning, _) {
    return ValueListenableBuilder<bool>(
      valueListenable: isVerifying,
      builder: (context, isVerifyingNow, _) {
        if (!isReturning && !isVerifyingNow) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.black.withOpacity(0.3),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
          ),
        );
      },
    );
  },
),
          ],
        ),
      ),
    );
  }

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
              valueListenable: logic.columnOrderNotifier,
              builder: (context, columnOrder, _) {
                return ValueListenableBuilder<Map<String, bool>>(
                  valueListenable: logic.columnVisibilityNotifier,
                  builder: (context, columnVisibility, _) {
                    final visibleColumns = columnOrder
                        .where((col) => columnVisibility[col] == true)
                        .toList();
                    final rightColumns = visibleColumns
                        .where(
                          (column) => column != 'Item Name' && column != 'S.No',
                        )
                        .toList();
                    final rightWidth = logic.getRightWidth(rightColumns);

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
                                            'Invoice No: ${logic.getInvoiceNo()}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Vendor: ${logic.getVendorName()}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Date: ${logic.getInvoiceDate()}',
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
                                                  columns: logic
                                                      .columnOrderNotifier
                                                      .value,
                                                  columnVisibility: logic
                                                      .columnVisibilityNotifier
                                                      .value,
                                                  onApply:
                                                      (
                                                        newOrder,
                                                        newVisibility,
                                                      ) {
                                                        logic.updateColumnOrder(
                                                          newOrder,
                                                        );
                                                        logic
                                                            .updateColumnVisibility(
                                                              newVisibility,
                                                            );
                                                      },
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(thickness: 1),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.55,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: logic.getLeftWidth(),
                                        child: Column(
                                          children: [
                                            _buildLandscapeHeaderLeft(),
                                            Expanded(
                                              child: ListView.builder(
                                                controller: logic
                                                    .leftVerticalController,
                                                itemCount: items.length,
                                                itemBuilder: (context, index) =>
                                                    _buildLandscapeItemLeft(
                                                      items[index],
                                                      index,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          controller:
                                              logic.rightHorizontalController,
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
                                                    controller: logic
                                                        .rightVerticalController,
                                                    itemCount: items.length,
                                                    itemBuilder:
                                                        (context, index) =>
                                                            _buildLandscapeItemRow(
                                                              items[index],
                                                              index,
                                                              rightColumns,
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
                                ),
                                const SizedBox(height: 8),
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
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (canReturn)
                                        ElevatedButton(
                                          onPressed: () async {
                                            final shouldReturn = await showDialog<bool>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (dialogContext) => AlertDialog(
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
                                                              Colors.blueAccent,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(true);
                                                      await logic.performReturn(
                                                        context,
                                                      );
                                                    },
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blueAccent,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: const Text(
                                                      "Confirm",
                                                    ),
                                                  ),
                                                ],
                                              ),
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
          ValueListenableBuilder<bool>(
            valueListenable: logic.isReturning,
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
          width: logic.columnWidths['S.No'] ?? 40,
          height: 40,
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: const Text(
            "S.No",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: logic.columnWidths['Item Name'] ?? 130,
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
          width: logic.columnWidths['S.No'] ?? 40,
          height: 45,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
        ),
        Container(
          width: logic.columnWidths['Item Name'] ?? 130,
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Tooltip(
            message: item.itemName ?? '',
            waitDuration: const Duration(milliseconds: 500),
            child: Text(
              item.itemName ?? '',
              style: const TextStyle(fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
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
            width: logic.columnWidths[column] ?? 120,
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
            width: logic.columnWidths[column] ?? 120,
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
            width: logic.columnWidths[column] ?? 120,
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
            width: logic.columnWidths[column] ?? 120,
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
