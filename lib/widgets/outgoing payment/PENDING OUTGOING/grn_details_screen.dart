//------------------ dialog for inside outgoing for showing grn details ------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/widgets/column_filter.dart';

class GRNDetailsDialog extends StatefulWidget {
  final GRN grn;

  const GRNDetailsDialog({super.key, required this.grn});

  @override
  State<GRNDetailsDialog> createState() => _GRNDetailsDialogState();
}

class _GRNDetailsDialogState extends State<GRNDetailsDialog> {
  late ValueNotifier<List<String>> columnOrderNotifier;
  late ValueNotifier<Map<String, bool>> columnVisibilityNotifier;
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _rightHorizontalController = ScrollController();

  late final Map<String, Widget Function(dynamic)> cellRenderers;

  @override
  void initState() {
    super.initState();

    // Initialize cellRenderers here after the instance is ready
    cellRenderers = {
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
      'Rcv Qty': (item) => Text(
        '${item.receivedQuantity ?? 0}',
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
      'Tax': (item) => Text(
        item.taxAmount?.toStringAsFixed(2) ?? '0.00',
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
      'Expiry Date': (item) => Text(
        _formatDate(item.expiryDate),
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
      ),
    };

    columnOrderNotifier = ValueNotifier<List<String>>([
      'S.No',
      'Item Name',
      'UOM',
      'Count',
      'Qty',
      'Rcv Qty',
      'Unit Price',
      'Total Price',
      'Tax',
      'Final Price',
      'Expiry Date',
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
    'Item Name': 130,
    'UOM': 70,
    'Count': 70,
    'Qty': 70,
    'Rcv Qty': 80,
    'Unit Price': 100,
    'Total Price': 100,
    'Tax': 80,
    'Final Price': 100,
    'Expiry Date': 105,
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

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'No Date';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatCurrency(double? value) {
    if (value == null) return '0.00';
    return value.toStringAsFixed(2);
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

  @override
  Widget build(BuildContext context) {
    final items = widget.grn.itemDetails ?? [];
    final double roundOff = widget.grn.roundOffAdjustment ?? 0.0;
    final double finalTotal = widget.grn.grnAmount ?? 0.0;
    final double freightAmount = widget.grn.totalFreightAmount ?? 0.0;
    final double freightTax = widget.grn.totalFreightTaxAmount ?? 0.0;
    final double freightTotal = freightAmount + freightTax;
    final double totalDiscount =
        widget.grn.totalDiscount ?? widget.grn.discountPrice ?? 0.0;

    double totalTax = 0.0;
    for (var item in items) {
      totalTax += (item.taxAmount ?? 0.0);
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
                              'GRN Details',
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
                          'GRN No: ${widget.grn.randomId ?? 'N/A'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Vendor: ${widget.grn.vendorName ?? 'Unknown Vendor'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Date: ${_formatDate(widget.grn.grnDate)}',
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
                                          return Row(
                                            children: [
                                              Container(
                                                width: columnWidths['S.No'],
                                                height: 45,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey,
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
                                                  items[index].itemName ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                'Total Tax: ${totalTax.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Freight Charges: ${freightAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Freight Tax: ${freightTax.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Total Freight: ${freightTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Round Off: ${roundOff.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total GRN Amount: ${finalTotal.toStringAsFixed(2)}',
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
                                    horizontal: 16, // 👈 controls width
                                    vertical: 8,
                                  ),
                                  minimumSize: Size(
                                    0,
                                    40,
                                  ), // 👈 removes default full width
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
