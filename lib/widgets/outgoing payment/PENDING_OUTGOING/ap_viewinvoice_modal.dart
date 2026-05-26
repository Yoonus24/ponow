//---------------dialog for inside outgoing for showing invoice details ------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap/ap.dart';
import 'package:purchaseorders2/widgets/column_filter.dart';

class APViewInvoiceModal extends StatefulWidget {
  final ApInvoice apinvoice;

  const APViewInvoiceModal({super.key, required this.apinvoice});

  @override
  State<APViewInvoiceModal> createState() => _APViewInvoiceModalState();
}

class _APViewInvoiceModalState extends State<APViewInvoiceModal> {
  late ValueNotifier<List<String>> columnOrderNotifier;
  late ValueNotifier<Map<String, bool>> columnVisibilityNotifier;
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _rightHorizontalController = ScrollController();

  late final Map<String, Widget Function(dynamic)> cellRenderers;

  @override
  void initState() {
    super.initState();

    cellRenderers = {
      'Item Name': (item) => Text(
        item.itemName ?? '',
        style: const TextStyle(fontSize: 14),
        maxLines: null,
        softWrap: true,
        overflow: TextOverflow.visible,
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
      'T.Qty': (item) => Text(
        '${item.quantity ?? 0}',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
      ),
      'Price': (item) => Text(
        item.unitPrice?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
      'Disc': (item) => Text(
        item.discountAmount?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
      'SGST': (item) => Text(
        item.sgst?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
      'CGST': (item) => Text(
        item.cgst?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
      'IGST': (item) => Text(
        item.igst?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
      'Total': (item) => Text(
        item.totalPrice?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
      'Final': (item) => Text(
        item.finalPrice?.toStringAsFixed(2) ?? '0.00',
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.right,
      ),
    };

    columnOrderNotifier = ValueNotifier<List<String>>([
      'S.No',
      'Item Name',
      'UOM',
      'Count',
      'Qty',
      'T.Qty',
      'Price',
      'Disc',
      'SGST',
      'CGST',
      'IGST',
      'Total',
      'Final',
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
    'S.No': 40,
    'Item Name': 150,
    'UOM': 70,
    'Count': 70,
    'Qty': 70,
    'T.Qty': 70,
    'Price': 100,
    'Disc': 80,
    'SGST': 80,
    'CGST': 80,
    'IGST': 80,
    'Total': 100,
    'Final': 100,
  };

  @override
  void dispose() {
    columnOrderNotifier.dispose();
    columnVisibilityNotifier.dispose();
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _rightHorizontalController.dispose();
    super.dispose();
  }

  double _calculateRowHeight(String text) {
    const double minHeight = 34;
    const int approxCharsPerLine = 11;

    final int lineCount = (text.length / approxCharsPerLine).ceil();

    final double calculatedHeight = (lineCount * 20).toDouble();

    return calculatedHeight < minHeight ? minHeight : calculatedHeight;
  }

  String _formatDate(String? date) {
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
    final dynamicRowHeight = _calculateRowHeight(item.itemName ?? '');

    return Container(
      height: dynamicRowHeight,

      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: rightColumns.map((column) {
          return Container(
            width: columnWidths[column] ?? 120,

            alignment: Alignment.center,

            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),

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

  @override
  Widget build(BuildContext context) {
    final items = widget.apinvoice.itemDetails ?? [];
    final double roundOff = widget.apinvoice.roundOffAdjustment ?? 0.0;
    final double finalTotal = widget.apinvoice.invoiceAmount ?? 0.0;
    final double totalDiscount = widget.apinvoice.discountDetails ?? 0.0;

    double totalSGST = 0.0;
    double totalCGST = 0.0;
    double totalIGST = 0.0;
    double totalTax = 0.0;

    for (var item in items) {
      totalSGST += item.sgst ?? 0;
      totalCGST += item.cgst ?? 0;
      totalIGST += item.igst ?? 0;
      totalTax += (item.sgst ?? 0) + (item.cgst ?? 0) + (item.igst ?? 0);
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
                        .where(
                          (column) => column != 'Item Name' && column != 'S.No',
                        )
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AP Invoice Details',
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
                          'Date: ${_formatDate(widget.apinvoice.invoiceDate)}',
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
                                          padding: const EdgeInsets.symmetric(
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
                                          final item = items[index];

                                          final dynamicRowHeight =
                                              _calculateRowHeight(
                                                item.itemName ?? '',
                                              );

                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,

                                            children: [
                                              Container(
                                                width: columnWidths['S.No'],

                                                height: dynamicRowHeight,

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
                                                  '${index + 1}',

                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    height: 0.9,
                                                  ),
                                                ),
                                              ),

                                              Container(
                                                width:
                                                    columnWidths['Item Name'],

                                                height: dynamicRowHeight,

                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 0,
                                                    ),

                                                alignment: Alignment.centerLeft,

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

                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 0.9,
                                                  ),

                                                  maxLines: null,

                                                  softWrap: true,

                                                  overflow:
                                                      TextOverflow.visible,
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
                                'Total SGST: ${totalSGST.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Total CGST: ${totalCGST.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (totalIGST > 0)
                                Text(
                                  'Total IGST: ${totalIGST.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              Text(
                                'Total Tax: ${totalTax.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (roundOff != 0)
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
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 40),
                                ),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(fontSize: 12),
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
