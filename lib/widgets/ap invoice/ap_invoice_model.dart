// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
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
    'Count': (item) => Text(
      '${item.nos ?? 0}',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    ),
    'Qty': (item) => Text(
      '${item.eachQuantity ?? 0}',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    ),
    'Stock Qty': (item) => Text(
      '${item.stockQuantity ?? 0}',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    ),
    'BefTax': (item) => Text(
      '${item.befTaxDiscount ?? 0}',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    ),
    'AfTax': (item) => Text(
      '${item.afTaxDiscount ?? 0}',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    ),
    'Tax': (item) => Text(
      '${item.taxAmount ?? 0}',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    ),
    'Unit Price': (item) => Text(
      item.unitPrice?.toStringAsFixed(2) ?? '0.00',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.visible,
      softWrap: false,
      textAlign: TextAlign.right,
    ),
    'Total Price': (item) => Text(
      item.totalPrice != null ? item.totalPrice!.toStringAsFixed(2) : '0.00',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.visible,
      softWrap: false,
      textAlign: TextAlign.right,
    ),
    'Final Price': (item) => Text(
      item.finalPrice?.toStringAsFixed(2) ?? '0.00',
      style: const TextStyle(fontSize: 14),
      overflow: TextOverflow.visible,
      softWrap: false,
      textAlign: TextAlign.right,
    ),
  };

  @override
  void initState() {
    super.initState();

    columnOrderNotifier = ValueNotifier<List<String>>([
      'Item Name',
      'UOM',
      'Count',
      'Qty',
      'Stock Qty',
      'BefTax',
      'AfTax',
      'Tax',
      'Unit Price',
      'Total Price',
      'Final Price',
    ]);

    columnVisibilityNotifier = ValueNotifier<Map<String, bool>>({
      for (var col in columnOrderNotifier.value) col: true,
    });

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

  final Map<String, double> columnWidths = {
    'Item Name': 130,
    'UOM': 70,
    'Count': 70,
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
            child: _buildCellContent(column, item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCellContent(String column, dynamic item) {
    final renderer = cellRenderers[column];
    if (renderer != null) {
      return Align(alignment: Alignment.center, child: renderer(item));
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final outgoingProvider = context.read<OutgoingPaymentProvider>();

    final hasOutgoing = outgoingProvider.allPayments.any(
      (o) => o.invoiceId == widget.apinvoice.invoiceId, 
    );

    debugPrint('🧾 AP MODAL STATUS => "${widget.apinvoice.status}"');
    final items = widget.apinvoice.itemDetails ?? [];
    final double roundOff = widget.apinvoice.roundOffAdjustment ?? 0.0;

    final double finalTotal = (widget.apinvoice.invoiceAmount ?? 0.0);

    final double totalDiscount = (widget.apinvoice.discountDetails ?? 0.0);

    final apStatus = (widget.apinvoice.status ?? '').toLowerCase().trim();
    final canReturn = apStatus.isNotEmpty && !apStatus.contains('returned');

    double totalSgst = 0.0, totalCgst = 0.0;
    for (var item in items) {
      totalSgst += (item.sgst ?? 0.0);
      totalCgst += (item.cgst ?? 0.0);
    }

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox.expand(
        child: SafeArea(
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
                        .where((column) => column != 'Item Name')
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
                              SizedBox(
                                width: columnWidths['Item Name'],
                                child: Column(
                                  children: [
                                    Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      color: Colors.grey[200],
                                      child: const Text(
                                        "Item Name",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child: ListView.builder(
                                        controller: _leftVerticalController,
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            height: 45,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              items[index].itemName ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
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
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(
                                    context,
                                  ).copyWith(scrollbars: false),
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
                            if (canReturn)
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final shouldReturn = await showDialog<bool>(
                                        context: context,
                                        barrierDismissible:
                                            false, 
                                        builder: (context) {
                                          return ValueListenableBuilder<bool>(
                                            valueListenable: _isReturning,
                                            builder: (context, returning, _) {
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
                                                    onPressed: returning
                                                        ? null
                                                        : () => Navigator.of(
                                                            context,
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
                                                    onPressed: returning
                                                        ? null
                                                        : () async {
                                                            _isReturning.value =
                                                                true;

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
                                                              _isReturning
                                                                      .value =
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
                                                              Colors.blueAccent,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                    child: returning
                                                        ? const SizedBox(
                                                            height: 18,
                                                            width: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          )
                                                        : const Text("Confirm"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );

                                      if (shouldReturn == true &&
                                          context.mounted) {
                                        await context
                                            .read<APInvoiceProvider>()
                                            .convertToGrnFromApReturned(
                                              widget.apinvoice.invoiceId ?? '',
                                              context,
                                            );

                                        _isReturning.value = false;
                                        if (context.mounted) {
                                          Navigator.of(context).pop(true);
                                        }
                                      }
                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _isReturning,
                                      builder: (context, returning, _) {
                                        return returning
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Return to GRN',
                                                style: TextStyle(fontSize: 12),
                                              );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                            if (canReturn) const SizedBox(width: 10),

                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
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
      ),
    );
  }
}

class ColumnManager {
  final List<String> columns;
  final Map<String, bool> columnVisibility;

  ColumnManager(this.columns, this.columnVisibility);
}
