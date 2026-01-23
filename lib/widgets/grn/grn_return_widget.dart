import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/widgets/grn/view_grn_modal.dart';

class GRNReturnWidget extends StatefulWidget {
  final GRN grn;

  const GRNReturnWidget({super.key, required this.grn});

  @override
  State<GRNReturnWidget> createState() => _GRNReturnWidgetState();
}

class _GRNReturnWidgetState extends State<GRNReturnWidget> {
  @override
  Widget build(BuildContext context) {
    // Create a list of all return entries
    final allReturnEntries = <Map<String, dynamic>>[];
    int returnIndex = 0;

    for (final item in widget.grn.itemDetails ?? []) {
      if (item.returnHistory != null) {
        for (final returnEntry in item.returnHistory!) {
          final date = returnEntry is Map
              ? returnEntry['date']?.toString()
              : returnEntry.date?.toString();
          final by = returnEntry is Map
              ? returnEntry['by']?.toString()
              : returnEntry.by?.toString();
          final totalUnits = returnEntry is Map
              ? returnEntry['totalUnits']?.toString()
              : returnEntry.totalUnits?.toString();
          final reason = returnEntry is Map
              ? returnEntry['reason']?.toString()
              : returnEntry.reason?.toString();
          final status = returnEntry is Map
              ? returnEntry['status']?.toString()
              : returnEntry.status?.toString();

          if (date != null) {
            allReturnEntries.add({
              'index': ++returnIndex,
              'itemName': item.itemName ?? 'Unknown Item',
              'grnNo': widget.grn.randomId ?? '-',
              'poNo': widget.grn.poRandomID ?? '-',
              'vendor': widget.grn.vendorName ?? '-',
              'returnDate': date,
              'quantity': totalUnits ?? '0',
              'reason': reason ?? '',
              'returnedBy': by ?? '',
              'status': status ?? '',
              'totalPrice':
                  item.returnedTotalPrice?.toStringAsFixed(2) ?? '0.00',
            });
          }
        }
      }
    }

    // Row height: 10px top padding + 10px bottom padding + ~20px text/border + 3px bottom margin
    const double rowHeight = 43.0;
    const int maxVisibleRows = 5;
    const double maxTableHeight = rowHeight * maxVisibleRows;

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRN No: ${widget.grn.randomId ?? '-'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => GRNViewModal(grn: widget.grn),
                    );
                  },
                ),
              ],
            ),
          ),
          // Data section with single horizontal scroll for header and body
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Estimate header height: 8px top + 8px bottom + ~20px text/border
                  const double headerHeight = 36.0;
                  // Use available height minus header height, capped at maxTableHeight
                  final availableHeight = constraints.maxHeight - headerHeight;
                  final dataSectionHeight = availableHeight < maxTableHeight
                      ? availableHeight
                      : maxTableHeight;

                  return Column(
                    children: [
                      // Header row with bottom border
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 1),
                          ),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 50,
                              child: Text(
                                'No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'GRN No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'PO No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Vendor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Return Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Return Qty',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Total Price',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Data rows with constrained height and vertical scroll
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: dataSectionHeight,
                        ),
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < allReturnEntries.length;
                                  i++
                                )
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 3.0),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      color: i % 2 == 0
                                          ? Colors.white
                                          : Colors.grey[50],
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            '${allReturnEntries[i]['index']}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            allReturnEntries[i]['grnNo'] ?? '-',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            allReturnEntries[i]['poNo'] ?? '-',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            allReturnEntries[i]['vendor'] ??
                                                '-',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            DateFormat('dd-MM-yyyy').format(
                                              DateTime.tryParse(
                                                    allReturnEntries[i]['returnDate'] ??
                                                        '',
                                                  ) ??
                                                  DateTime.now(),
                                            ),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            allReturnEntries[i]['quantity'] ??
                                                '0',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            allReturnEntries[i]['quantity'] ??
                                                '0',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            allReturnEntries[i]['totalPrice'] ??
                                                '0.00',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
