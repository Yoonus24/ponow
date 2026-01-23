// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/widgets/column_filter.dart';
import '../../models/grn.dart';

class GRNViewModal extends StatefulWidget {
  final GRN grn;

  const GRNViewModal({super.key, required this.grn});

  @override
  State<GRNViewModal> createState() => _GRNViewModalState();
}

class _GRNViewModalState extends State<GRNViewModal> {
  final List<String> _allColumns = [
    // 'No',
    'Item Name',
    'Vendor',
    'Quantity',
    'Returned Qty',
    'Unit Price',
    'Return Date',
    'Returned By',
    'Return Quantity',
    'Reason',
  ];

  final ValueNotifier<List<String>> _visibleColumnsNotifier = ValueNotifier([]);
  final ValueNotifier<Map<String, bool>> _columnVisibilityNotifier =
      ValueNotifier({});

  final ScrollController _fixedColumnScroll = ScrollController();
  final ScrollController _scrollableColumnScroll = ScrollController();

  static const double _rowHeight = 60.0;

  @override
  void initState() {
    super.initState();

    _columnVisibilityNotifier.value = {for (final c in _allColumns) c: true};
    _visibleColumnsNotifier.value = List.from(_allColumns);

    _fixedColumnScroll.addListener(() {
      if (_scrollableColumnScroll.offset != _fixedColumnScroll.offset) {
        _scrollableColumnScroll.jumpTo(_fixedColumnScroll.offset);
      }
    });

    _scrollableColumnScroll.addListener(() {
      if (_fixedColumnScroll.offset != _scrollableColumnScroll.offset) {
        _fixedColumnScroll.jumpTo(_scrollableColumnScroll.offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _collectReturnEntries();
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650; // 🔥 RESPONSIVE SWITCH

    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 8),
          Expanded(child: _buildResponsiveTable(rows, isMobile)),
          const SizedBox(height: 10),
          _buildSummarySection(isMobile),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Close"),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

  //──────────────── HEADER ────────────────

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleText('GRN No: ${widget.grn.randomId}'),
                _titleText('Vendor: ${widget.grn.vendorName ?? "Unknown"}'),
                _normalText('Date: ${formatDate(widget.grn.grnDate)}'),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showColumnFilterDialog,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleText('GRN No: ${widget.grn.randomId}'),
                      _titleText(
                        'Vendor: ${widget.grn.vendorName ?? "Unknown"}',
                      ),
                      _normalText('Date: ${formatDate(widget.grn.grnDate)}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showColumnFilterDialog,
                ),
              ],
            ),
    );
  }

  Widget _titleText(String text) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );

  Widget _normalText(String text) =>
      Text(text, style: const TextStyle(fontSize: 16));

  //──────────────── TABLE BUILDER (RESPONSIVE) ────────────────

  Widget _buildResponsiveTable(List<Map<String, dynamic>> rows, bool isMobile) {
    return ValueListenableBuilder(
      valueListenable: _visibleColumnsNotifier,
      builder: (context, visibleCols, _) {
        return ValueListenableBuilder(
          valueListenable: _columnVisibilityNotifier,
          builder: (context, visibility, _) {
            // visible columns
            List<String> finalCols = visibleCols
                .where((c) => visibility[c] ?? true)
                .toList();

            // ALWAYS FIXED
            List<String> fixedCols = [
              'Item Name',
            ].where((c) => finalCols.contains(c)).toList();

            List<String> scrollCols = finalCols
                .where((c) => !fixedCols.contains(c))
                .toList();

            // Dynamic widths based on device
            double fixedWidth = fixedCols.fold(
              0,
              (s, c) => s + _getColumnWidthTablet(c),
            );

            double scrollWidth = scrollCols.fold(
              0,
              (s, c) =>
                  s +
                  (isMobile
                      ? _getColumnWidthMobile(c)
                      : _getColumnWidthTablet(c)),
            );

            return Row(
              children: [
                //──────── LEFT FIXED COLUMN
                Container(
                  width: fixedWidth,
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildHeaderRowTablet(fixedCols),
                      Expanded(
                        child: ListView.builder(
                          controller: _fixedColumnScroll,
                          itemExtent: _rowHeight,
                          itemCount: rows.length,
                          itemBuilder: (_, index) {
                            return _buildBodyRowTablet(rows[index], fixedCols);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                //──────── RIGHT SCROLLABLE SECTION
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: scrollWidth,
                      child: Column(
                        children: [
                          isMobile
                              ? _buildHeaderRowMobile(scrollCols)
                              : _buildHeaderRowTablet(scrollCols),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollableColumnScroll,
                              itemExtent: _rowHeight,
                              itemCount: rows.length,
                              itemBuilder: (_, index) {
                                return isMobile
                                    ? _buildBodyRowMobile(
                                        rows[index],
                                        scrollCols,
                                      )
                                    : _buildBodyRowTablet(
                                        rows[index],
                                        scrollCols,
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
            );
          },
        );
      },
    );
  }

  //──────────────── MOBILE TABLE (FULL HORIZONTAL SCROLL) ────────────────

  Widget _buildMobileTable(List<Map<String, dynamic>> rows) {
    return ValueListenableBuilder(
      valueListenable: _visibleColumnsNotifier,
      builder: (_, visibleCols, __) {
        return ValueListenableBuilder(
          valueListenable: _columnVisibilityNotifier,
          builder: (_, visibility, __) {
            final finalCols = visibleCols
                .where((c) => visibility[c] ?? true)
                .toList();

            final double totalWidth = finalCols.fold(
              0,
              (s, c) => s + _getColumnWidthMobile(c),
            );

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: Column(
                  children: [
                    _buildHeaderRowMobile(finalCols),
                    Expanded(
                      child: ListView.builder(
                        itemExtent: _rowHeight,
                        itemCount: rows.length,
                        itemBuilder: (_, i) =>
                            _buildBodyRowMobile(rows[i], finalCols),
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
  }

  Widget _buildHeaderRowMobile(List<String> cols) {
    return Container(
      height: 40,
      color: Colors.grey[300],
      child: Row(
        children: cols
            .map(
              (c) => SizedBox(
                width: _getColumnWidthMobile(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    c,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBodyRowMobile(Map<String, dynamic> r, List<String> cols) {
    return Row(
      children: cols
          .map(
            (c) => SizedBox(
              width: _getColumnWidthMobile(c),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _getCellValue(c, r),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  double _getColumnWidthMobile(String col) {
    switch (col) {
      // case 'No':
      //   return 40;
      case 'Item Name':
        return 90;
      case 'Vendor':
        return 160;
      case 'Reason':
        return 150;
      default:
        return 110;
    }
  }

  //──────────────── TABLET / LARGE SCREEN TABLE (YOUR ORIGINAL FIXED LAYOUT) ────────────────

  Widget _buildTabletTable(List<Map<String, dynamic>> rows) {
    return ValueListenableBuilder(
      valueListenable: _visibleColumnsNotifier,
      builder: (_, visibleCols, __) {
        return ValueListenableBuilder(
          valueListenable: _columnVisibilityNotifier,
          builder: (_, visibility, __) {
            List<String> finalCols = visibleCols
                .where((c) => visibility[c] ?? true)
                .toList();

            List<String> fixedCols = [
              'No',
              'Item Name',
            ].where((c) => finalCols.contains(c)).toList();

            List<String> scrollCols = finalCols
                .where((c) => !fixedCols.contains(c))
                .toList();

            double fixedWidth = fixedCols.fold(
              0,
              (s, c) => s + _getColumnWidthTablet(c),
            );
            double scrollWidth = scrollCols.fold(
              0,
              (s, c) => s + _getColumnWidthTablet(c),
            );

            return Row(
              children: [
                Container(
                  width: fixedWidth,
                  child: Column(
                    children: [
                      _buildHeaderRowTablet(fixedCols),
                      Expanded(
                        child: ListView.builder(
                          controller: _fixedColumnScroll,
                          itemExtent: _rowHeight,
                          itemCount: rows.length,
                          itemBuilder: (_, i) =>
                              _buildBodyRowTablet(rows[i], fixedCols),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: scrollWidth,
                      child: Column(
                        children: [
                          _buildHeaderRowTablet(scrollCols),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollableColumnScroll,
                              itemExtent: _rowHeight,
                              itemCount: rows.length,
                              itemBuilder: (_, i) =>
                                  _buildBodyRowTablet(rows[i], scrollCols),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderRowTablet(List<String> cols) {
    return Container(
      height: 40,
      color: Colors.grey[300],
      child: Row(
        children: cols.map((c) {
          return Row(
            children: [
              SizedBox(
                width: _getColumnWidthTablet(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    c,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 🔥 Add spacing right after Vendor column
              if (c == 'Vendor') const SizedBox(width: 10),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBodyRowTablet(Map<String, dynamic> r, List<String> cols) {
    return Row(
      children: cols.map((c) {
        return Row(
          children: [
            SizedBox(
              width: _getColumnWidthTablet(c),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  _getCellValue(c, r),
                  maxLines: c == 'Vendor' ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 🔥 Add spacing ONLY between Vendor → Quantity
            if (c == 'Vendor') const SizedBox(width: 10),
          ],
        );
      }).toList(),
    );
  }

  double _getColumnWidthTablet(String col) {
    switch (col) {
      case 'Vendor':
        return 200;
      case 'Reason':
        return 280;
      case 'Item Name':
        return 110;
      default:
        return 120;
    }
  }

  //──────────────── SUMMARY ────────────────

  Widget _buildSummarySection(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 6),
          isMobile
              ? Column(
                  children: [
                    buildSummaryRow(
                      'Total Discount:',
                      widget.grn.totalDiscount,
                    ),
                    buildSummaryRow('SGST:', calculateTotalSGST(widget.grn)),
                    buildSummaryRow('CGST:', calculateTotalCGST(widget.grn)),
                    buildSummaryRow(
                      'Final Returned Amt:',
                      widget.grn.totalReturnedAmount,
                    ),
                  ],
                )
              : Column(
                  children: [
                    buildSummaryRow(
                      'Total Discount:',
                      widget.grn.totalDiscount,
                    ),
                    buildSummaryRow('SGST:', calculateTotalSGST(widget.grn)),
                    buildSummaryRow('CGST:', calculateTotalCGST(widget.grn)),
                    buildSummaryRow(
                      'Final Returned Amt:',
                      widget.grn.totalReturnedAmount,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  //──────────────── DATA PARSER ────────────────

  List<Map<String, dynamic>> _collectReturnEntries() {
    final list = <Map<String, dynamic>>[];
    // int index = 0;

    for (final item in widget.grn.itemDetails ?? []) {
      for (final h in item.returnHistory ?? []) {
        list.add({
          "itemName": item.itemName ?? "",
          "vendor": widget.grn.vendorName ?? "",
          "quantity": item.totalQuantity ?? 0,
          "returnedQuantity": item.returnedQuantity ?? 0,
          "unitPrice": item.unitPrice?.toStringAsFixed(2) ?? "0.00",
          "returnDate": h['date'] ?? "",
          "returnedBy": h['by'] ?? "",
          "returnQuantity": h['totalUnits']?.toString() ?? "0",
          "reason": h['reason'] ?? "",
        });
      }
    }

    return list;
  }

  String _getCellValue(String col, Map<String, dynamic> r) {
    switch (col) {
      // case 'No':
      //   return '${r["index"]}';
      case 'Item Name':
        return r["itemName"];
      case 'Vendor':
        return r["vendor"];
      case 'Quantity':
        return '${r["quantity"]}';
      case 'Returned Qty':
        return '${r["returnedQuantity"]}';
      case 'Unit Price':
        return r["unitPrice"];
      case 'Return Date':
        return formatDate(r["returnDate"]);
      case 'Returned By':
        return r["returnedBy"];
      case 'Return Quantity':
        return r["returnQuantity"];
      case 'Reason':
        return r["reason"];
      default:
        return "";
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final d = DateTime.parse(dateStr);
      return DateFormat("dd-MM-yyyy hh:mm a").format(d);
    } catch (_) {
      return dateStr;
    }
  }

  Widget buildSummaryRow(String label, dynamic val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(val != null ? val.toStringAsFixed(2) : "0.00"),
        ],
      ),
    );
  }

  double calculateTotalSGST(GRN grn) {
    return grn.itemDetails?.fold<double>(0, (s, it) => s + (it.sgst ?? 0.0)) ??
        0.0;
  }

  double calculateTotalCGST(GRN grn) {
    return grn.itemDetails?.fold<double>(0, (s, it) => s + (it.cgst ?? 0.0)) ??
        0.0;
  }

  void _showColumnFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => ColumnFilterDialog(
        columns: _visibleColumnsNotifier.value,
        columnVisibility: _columnVisibilityNotifier.value,
        onApply: (order, visibility) {
          _visibleColumnsNotifier.value = List.from(order);
          _columnVisibilityNotifier.value = Map.from(visibility);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fixedColumnScroll.dispose();
    _scrollableColumnScroll.dispose();
    _visibleColumnsNotifier.dispose();
    _columnVisibilityNotifier.dispose();
    super.dispose();
  }
}
