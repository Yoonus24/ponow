// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';
import '../../providers/ap_invoice_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:purchaseorders2/screens/outgoing_payment_page.dart';

class APInvoiceModal extends StatefulWidget {
  final ApInvoice apinvoice;

  const APInvoiceModal({super.key, required this.apinvoice});

  @override
  State<APInvoiceModal> createState() => _APInvoiceModalState();
}

class _APInvoiceModalState extends State<APInvoiceModal> {
  late ValueNotifier<List<String>> columnOrderNotifier;
  late ValueNotifier<Map<String, bool>> columnVisibilityNotifier;

  // Scroll controllers for fixed + scrollable areas
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _rightHorizontalController = ScrollController();

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

    // Sync vertical scroll between left & right lists
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

  // Custom width for each column
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
    debugPrint('🧾 AP MODAL STATUS => "${widget.apinvoice.status}"');
    final items = widget.apinvoice.itemDetails ?? [];
    final double roundOff = widget.apinvoice.roundOffAdjustment ?? 0.0;

    // 🔥 summary values – rounded
    final double finalTotal = (widget.apinvoice.invoiceAmount ?? 0.0);
        // .roundToDouble();

    final double totalDiscount = (widget.apinvoice.discountDetails ?? 0.0);
        // .roundToDouble();

    final apStatus = (widget.apinvoice.status ?? '').toLowerCase().trim();
    final canReturn = apStatus.isNotEmpty && !apStatus.contains('returned');

    // Calculate total SGST and CGST from itemDetails
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

                    // Right side columns (exclude Item Name – fixed on left)
                    final rightColumns = visibleColumns
                        .where((column) => column != 'Item Name')
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP STATIC HEADER (title + filter)
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
                                  builder: (_) => ColumnFilterDialog(
                                    columns: columnOrder,
                                    columnVisibility: columnVisibility,
                                    onApply: (newOrder, newVisibility) async {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            columnOrderNotifier.value =
                                                newOrder;
                                            columnVisibilityNotifier.value =
                                                newVisibility;
                                          });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const Divider(thickness: 1),
                        const SizedBox(height: 4),

                        // STATIC INVOICE INFO
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

                        // MIDDLE AREA: TABLE (ONLY THIS SCROLLS VERTICALLY)
                        Expanded(
                          child: Row(
                            children: [
                              // LEFT: FIXED ITEM NAME COLUMN
                              SizedBox(
                                width: columnWidths['Item Name'],
                                child: Column(
                                  children: [
                                    // FIXED HEADER
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

                                    // FIXED BODY
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

                              // RIGHT: OTHER COLUMNS (H + V SCROLL)
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
                                          // STATIC TABLE HEADER INSIDE TABLE AREA
                                          _buildHeaderRow(rightColumns),
                                          // SCROLLABLE BODY
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

                        // STATIC DISCOUNT / SUMMARY SECTION
                        // STATIC DISCOUNT / SUMMARY SECTION
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

                        // STATIC BOTTOM BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ✅ RETURN GRN — SHOWN FOR ANY "returned" STATUS
                            if (canReturn)
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final shouldReturn = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.white,
                                          title: const Text("Confirm Return"),
                                          content: const Text(
                                            "Are you sure you want to return this GRN?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text("Confirm"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldReturn == true &&
                                          context.mounted) {
                                        await context
                                            .read<APInvoiceProvider>()
                                            .convertToGrnFromApReturned(
                                              widget.apinvoice.invoiceId ?? '',
                                              context,
                                            );

                                        // ✅ THIS IS THE IMPORTANT LINE
                                        if (context.mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(true); // closes APInvoiceModal
                                        }
                                      }
                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text(
                                      'Return to GRN',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),

                            if (canReturn) const SizedBox(width: 10),

                            // ✅ CLOSE — ALWAYS
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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
