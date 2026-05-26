import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/grn/grnitem.dart';
import 'package:purchaseorders2/models/grn/grn.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:provider/provider.dart';
import 'grn_logic.dart';

class GRNModal extends StatefulWidget {
  final GRN grn;

  const GRNModal({super.key, required this.grn});

  @override
  _GRNModalState createState() => _GRNModalState();
}

class _GRNModalState extends State<GRNModal> {
  late GRNLogic logic;

  @override
  void initState() {
    super.initState();
    logic = GRNLogic(widget.grn);
    logic.init();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  double _calculateRowHeight(String text) {
    const double minHeight = 38;
    const int approxCharsPerLine = 11;

    final int lineCount = (text.length / approxCharsPerLine).ceil();

    final double calculatedHeight = (lineCount * 15).toDouble();

    return calculatedHeight < minHeight ? minHeight : calculatedHeight;
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<PermissionProvider>();
    final canConvert = permission.hasEditAction("grns", "convert_to_ap");
    final canRevert = permission.hasEditAction("grns", "revert_to_po");
    final canReturn = permission.hasEditAction("grns", "return_grn");
    final size = MediaQuery.of(context).size;
    final landscape = logic.isLandscape(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: landscape
                ? _buildLandscapeMode(
                    context,
                    canConvert,
                    canRevert,
                    canReturn,
                    size,
                  )
                : _buildPortraitMode(
                    context,
                    canConvert,
                    canRevert,
                    canReturn,
                    size,
                  ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return ValueListenableBuilder<bool>(
      valueListenable: logic.isConverting,
      builder: (context, converting, child) {
        if (!converting) return const SizedBox.shrink();
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitMode(
    BuildContext context,
    bool canConvert,
    bool canRevert,
    bool canReturn,
    Size size,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 8.0),
          Expanded(child: _buildTableSection()),
          const SizedBox(height: 8),
          _buildTotalsSection(),
          const SizedBox(height: 12),
          _buildButtonsSection(context, canRevert, canConvert),
        ],
      ),
    );
  }

  Widget _buildLandscapeMode(
    BuildContext context,
    bool canConvert,
    bool canRevert,
    bool canReturn,
    Size size,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLandscapeHeader(),
                  _buildLandscapeTableSection(),
                  _buildLandscapeTotalsSection(),
                  _buildLandscapeButtonsSection(context, canRevert, canConvert),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
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
                      'PO No: ${logic.grn.poRandomID ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                      'GRN No: ${logic.grn.randomId ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Vendor: ${logic.grn.vendorName ?? 'Unknown Vendor'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<Map<String, dynamic>>(
                valueListenable: logic.totalsNotifier,
                builder: (context, totals, _) {
                  return Text(
                    'Total Received Amount: ${(logic.grn.grnAmount ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'GRN Date: ${logic.formatDate(logic.grn.grnDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => logic.showColumnFilterDialog(context),
                    tooltip: 'Filter columns',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
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
                        'PO No: ${logic.grn.poRandomID ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '→',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'GRN No: ${logic.grn.randomId ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Vendor: ${logic.grn.vendorName ?? 'Unknown Vendor'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<Map<String, dynamic>>(
                  valueListenable: logic.totalsNotifier,
                  builder: (context, totals, _) {
                    return Text(
                      'Total Received Amount: ${(logic.grn.grnAmount ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'GRN Date: ${logic.formatDate(logic.grn.grnDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: () => logic.showColumnFilterDialog(context),
                      tooltip: 'Filter columns',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<List<String>>(
          valueListenable: logic.visibleColumnsNotifier,
          builder: (context, visibleColumns, _) {
            final itemNameVisible = visibleColumns.contains('Item Name');
            final rightColumns = visibleColumns
                .where((c) => c != 'Item Name')
                .toList();
            final totalRightColumnsWidth = logic
                .calculateTotalRightColumnsWidth(rightColumns);
            final itemNameWidth = logic.getColumnWidth('Item Name');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(
                  itemNameVisible,
                  rightColumns,
                  itemNameWidth,
                  totalRightColumnsWidth,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _buildTableBody(
                    itemNameVisible,
                    rightColumns,
                    itemNameWidth,
                    totalRightColumnsWidth,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTableHeader(
    bool itemNameVisible,
    List<String> rightColumns,
    double itemNameWidth,
    double totalRightColumnsWidth,
  ) {
    return Container(
      height: GRNLogic.headerHeight,
      color: Colors.grey[200],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemNameVisible)
            SizedBox(
              height: GRNLogic.headerHeight,
              width: itemNameWidth,
              child: Row(
                children: [
                  const SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        "S.No",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Item Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: logic.headerScrollController,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: GRNLogic.headerHeight,
                width: totalRightColumnsWidth,
                child: Row(
                  children: rightColumns.map((column) {
                    return SizedBox(
                      width: logic.getColumnWidth(column),
                      height: GRNLogic.headerHeight,
                      child: Align(
                        alignment: logic.getColumnAlignment(column),
                        child: Text(
                          column,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildTableBody(
    bool itemNameVisible,
    List<String> rightColumns,
    double itemNameWidth,
    double totalRightColumnsWidth,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemNameVisible) _buildItemNameColumn(itemNameWidth),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: logic.contentScrollController,
              child: _buildRightColumns(rightColumns, totalRightColumnsWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemNameColumn(double itemNameWidth) {
    return SizedBox(
      width: itemNameWidth,

      child: Column(
        children: (logic.grn.itemDetails ?? []).asMap().entries.map((entry) {
          final index = entry.key;

          final item = entry.value;

          final dynamicRowHeight = _calculateRowHeight(item.itemName ?? '');

          return Container(
            height: dynamicRowHeight,

            padding: const EdgeInsets.symmetric(horizontal: 8),

            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),

            child: Align(
              alignment: Alignment.centerLeft,

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  SizedBox(
                    width: 35,

                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),

                      child: Text(
                        "${index + 1}",

                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),

                      child: Text(
                        item.itemName ?? '',

                        maxLines: null,

                        overflow: TextOverflow.visible,

                        softWrap: true,

                        style: const TextStyle(fontSize: 13, height: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRightColumns(
    List<String> rightColumns,
    double totalRightColumnsWidth,
  ) {
    return SizedBox(
      width: totalRightColumnsWidth,

      child: Column(
        children: (logic.grn.itemDetails ?? []).asMap().entries.map((entry) {
          final index = entry.key;

          final item = entry.value;

          final itemId = item.itemId ?? 'item_$index';

          final dynamicRowHeight = _calculateRowHeight(item.itemName ?? '');

          return Container(
            height: dynamicRowHeight,

            padding: const EdgeInsets.symmetric(vertical: 1),

            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),

            child: Row(
              children: rightColumns.map((column) {
                return SizedBox(
                  width: logic.getColumnWidth(column),

                  child: _buildCellContent(item, column, itemId),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLandscapeTableSection() {
    final items = logic.getFilteredItems();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ValueListenableBuilder<List<String>>(
          valueListenable: logic.visibleColumnsNotifier,
          builder: (context, visibleColumns, _) {
            final itemNameVisible = visibleColumns.contains('Item Name');
            final rightColumns = visibleColumns
                .where((c) => c != 'Item Name')
                .toList();
            final itemNameWidth = logic.getColumnWidth('Item Name');

            return Row(
              children: [
                if (itemNameVisible)
                  _buildLandscapeItemNameColumn(items, itemNameWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: logic.rightVerticalController,
                    scrollDirection: Axis.horizontal,
                    child: _buildLandscapeRightColumns(items, rightColumns),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLandscapeItemNameColumn(
    List<ItemDetail> items,
    double itemNameWidth,
  ) {
    return SizedBox(
      width: itemNameWidth,
      child: Column(
        children: [
          Container(
            height: GRNLogic.headerHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 6),
            color: Colors.grey[200],
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Text(
                    "S.No",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    "Item Name",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: logic.leftVerticalController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  height: GRNLogic.rowHeight,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.itemName ?? '',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(fontSize: 12),
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
    );
  }

  Widget _buildLandscapeRightColumns(
    List<ItemDetail> items,
    List<String> rightColumns,
  ) {
    return SizedBox(
      width: (rightColumns.length * 90.0).clamp(300.0, 1500),
      child: Column(
        children: [
          _buildLandscapeHeaderRow(rightColumns),
          Expanded(
            child: ListView.builder(
              controller: logic.rightVerticalController,
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
    );
  }

  Widget _buildLandscapeHeaderRow(List<String> columns) {
    return Container(
      height: GRNLogic.headerHeight,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            child: Center(
              child: Text(
                column,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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

  Widget _buildLandscapeItemRow(
    ItemDetail item,
    int index,
    List<String> columns,
  ) {
    final itemId = item.itemId ?? 'item_$index';

    return SizedBox(
      height: GRNLogic.rowHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: columns.map((column) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildCellContent(item, column, itemId),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCellContent(ItemDetail item, String column, String itemId) {
    switch (column) {
      case 'UOM':
        return Text(
          item.uom ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Pkt Count':
        return Text(
          '${item.nos ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Each Quantity':
        return Text(
          '${item.eachQuantity ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Received Qty':
        return Text(
          (item.receivedQuantity ?? 0).toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Returned Qty':
        return Text(
          (item.returnedQuantity ?? 0).toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Total Quantity':
        return Text(
          (item.quantity ?? 0).toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Unit Price':
        return Text(
          '${item.unitPrice ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'BefTax Discount':
        return ValueListenableBuilder<double>(
          valueListenable:
              logic.befTaxDiscountNotifiers[itemId] ?? ValueNotifier(0.0),
          builder: (context, value, child) => Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        );
      case 'AfTax Discount':
        return ValueListenableBuilder<double>(
          valueListenable:
              logic.afTaxDiscountNotifiers[itemId] ?? ValueNotifier(0.0),
          builder: (context, value, child) => Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        );
      case 'Discount Amount':
        return Text(
          '${item.discountAmount ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Tax Amount':
        return Text(
          '${item.taxAmount ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Expiry Date':
        return Text(
          logic.expiryDateControllers[itemId]?.text ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Total Price':
        return Text(
          (item.totalPrice ?? 0).toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'Final Price':
        return Text(
          (item.finalPrice ?? 0).toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'sgst':
        return Text(
          '${item.sgst ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'cgst':
        return Text(
          '${item.cgst ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      case 'igst':
        return Text(
          '${item.igst ?? 0}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        );
      default:
        return const Text('');
    }
  }

  Widget _buildTotalsSection() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: logic.totalsNotifier,
      builder: (context, totals, _) {
        final totalItemsAmount = totals['totalItemsAmount'] ?? 0.0;
        final discount = totals['totalDiscount'] ?? 0.0;
        final manualRound = totals['roundOff'] ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildSummaryRow(
              'Items Total:',
              totalItemsAmount.toStringAsFixed(2),
            ),
            _buildSummaryRow(
              'Discount Amount:',
              discount.toStringAsFixed(2),
              compact: true,
            ),
            _buildSummaryRow(
              'Freight Charges:',
              totals['freightAmount']?.toStringAsFixed(2) ?? '0.00',
              compact: true,
            ),
            if (manualRound != 0)
              _buildSummaryRow(
                'Round Off Adjustment:',
                '${manualRound > 0 ? '+' : ''}${manualRound.toStringAsFixed(2)}',
                compact: true,
              ),
            _buildSummaryRow(
              'Total SGST:',
              totals['totalSGST']?.toStringAsFixed(2) ?? '0.00',
              compact: true,
            ),
            _buildSummaryRow(
              'Total CGST:',
              totals['totalCGST']?.toStringAsFixed(2) ?? '0.00',
              compact: true,
            ),
            _buildSummaryRow(
              'Total IGST:',
              totals['totalIGST']?.toStringAsFixed(2) ?? '0.00',
              compact: true,
            ),
            _buildRoundOffRow(manualRound),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Final Total Amount:',
              (logic.grn.grnAmount ?? 0.0).toStringAsFixed(2),
              compact: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLandscapeTotalsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Divider(),
          ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: logic.totalsNotifier,
            builder: (context, totals, _) {
              final totalItemsAmount = totals['totalItemsAmount'] ?? 0.0;
              final discount = totals['totalDiscount'] ?? 0.0;
              final manualRound = totals['roundOff'] ?? 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Items Total: ${totalItemsAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Discount Amount: ${discount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Freight Charges: ${totals['freightAmount']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (manualRound != 0)
                    Text(
                      "Round Off Adjustment: ${manualRound > 0 ? '+' : ''}${manualRound.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  Text(
                    "Total SGST: ${totals['totalSGST']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Total CGST: ${totals['totalCGST']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Total IGST: ${totals['totalIGST']?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  _buildRoundOffRow(manualRound, compact: true),
                  const Divider(),
                  Text(
                    "Final Total Amount: ${(logic.grn.grnAmount ?? 0.0).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundOffRow(double manualRound, {bool compact = false}) {
    return ValueListenableBuilder<String?>(
      valueListenable: logic.roundOffErrorNotifier,
      builder: (context, error, _) {
        final hasError = error != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 4.0 : 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'AP Round Off:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => logic.openRoundOffCalculator(context),
                    child: Container(
                      width: compact ? 80 : 100,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: compact ? 2 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: hasError ? Colors.red : Colors.grey,
                          width: hasError ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          manualRound.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: hasError ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError && !compact)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool compact = false}) {
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
          Text(
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

  Widget _buildButtonsSection(
    BuildContext context,
    bool canRevert,
    bool canConvert,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: canRevert ? () => logic.convertGrnToPo(context) : null,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: canRevert ? Colors.orange : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Revert to PO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: ValueListenableBuilder<bool>(
              valueListenable: logic.isConverting,
              builder: (_, converting, __) {
                return GestureDetector(
                  onTap: (canConvert && !converting)
                      ? () => logic.convertToAP(context)
                      : null,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: canConvert
                          ? (converting
                                ? Colors.blueAccent.withOpacity(0.7)
                                : Colors.blueAccent)
                          : Colors.grey,
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
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeButtonsSection(
    BuildContext context,
    bool canRevert,
    bool canConvert,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Close', style: TextStyle(fontSize: 13)),
          ),
          if (canRevert) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: logic.isConverting.value
                  ? null
                  : () => logic.convertGrnToPo(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: logic.isConverting,
                builder: (_, converting, __) {
                  return converting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Revert to PO',
                          style: TextStyle(fontSize: 13),
                        );
                },
              ),
            ),
          ],
          if (canConvert) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: logic.isConverting.value
                  ? null
                  : () => logic.convertToAP(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: logic.isConverting,
                builder: (_, converting, __) {
                  return converting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Convert to AP',
                          style: TextStyle(fontSize: 13),
                        );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
