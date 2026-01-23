import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:purchaseorders2/widgets/po page/po_model.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/po.dart';
import '../../providers/po_provider.dart';
import '../../screens/create_po_page.dart';
import '../../notifier/purchasenotifier.dart';

class POWidget extends StatefulWidget {
  final PO po;
  final bool isSelected;
  final VoidCallback? onStatusChanged;

  const POWidget({
    super.key,
    required this.po,
    required this.isSelected,
    this.onStatusChanged,
  });

  @override
  State<POWidget> createState() => _POWidgetState();
}

class _POWidgetState extends State<POWidget> {
  bool _isHeaderScrolling = false;
  bool _isBodyScrolling = false;

  late ScrollController _headerHorizontal;
  late ScrollController _bodyHorizontal;

  @override
  void initState() {
    super.initState();
    _headerHorizontal = ScrollController();
    _bodyHorizontal = ScrollController();

    _bodyHorizontal.addListener(() {
      if (_isBodyScrolling) return;
      _isHeaderScrolling = true;
      if (_headerHorizontal.hasClients) {
        _headerHorizontal.jumpTo(_bodyHorizontal.position.pixels);
      }
      _isHeaderScrolling = false;
    });

    _headerHorizontal.addListener(() {
      if (_isHeaderScrolling) return;
      _isBodyScrolling = true;
      if (_bodyHorizontal.hasClients) {
        _bodyHorizontal.jumpTo(_headerHorizontal.position.pixels);
      }
      _isBodyScrolling = false;
    });
  }

  @override
  void dispose() {
    _headerHorizontal.dispose();
    _bodyHorizontal.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    return Colors.blueAccent;
  }

  Color _getHeaderColor(String? orderDate) {
    return Colors.blueAccent;
  }

  String _getFormattedDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      DateTime date;
      try {
        date = DateTime.parse(dateString);
      } catch (_) {
        final clean = dateString.split('.')[0].split('+')[0];
        date = DateTime.parse(clean);
      }
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<POProvider>(
      builder: (context, poProvider, child) {
        final updatedPO = poProvider.poList.firstWhere(
          (p) => p.purchaseOrderId == widget.po.purchaseOrderId,
          orElse: () => widget.po,
        );

        return Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isSelected
                  ? [const Color(0xFFE6F0FA), const Color(0xFFD6EAF8)]
                  : [const Color(0xFFF8F9FA), const Color(0xFFECEFF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(255, 74, 122, 227),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
            border: widget.isSelected
                ? Border.all(color: const Color(0xFF87CEEB), width: 2)
                : Border.all(color: Colors.transparent),
          ),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getHeaderColor(updatedPO.orderDate),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(updatedPO.poStatus),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            updatedPO.poStatus?.toUpperCase() ?? "N/A",
                            style: GoogleFonts.quicksand(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _editPO(context, updatedPO),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PO No: ${updatedPO.randomId}",
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getFormattedDate(updatedPO.orderDate),
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Vendor: ${updatedPO.vendorName}",
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Total: ${(updatedPO.pendingOrderAmount ?? updatedPO.totalOrderAmount ?? 0.0).toStringAsFixed(2)}",
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildPOItemsTable(updatedPO)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _openApproveModal(context, updatedPO),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Approve"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _openRejectModal(context, updatedPO),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 191, 74, 74),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Reject"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPOItemsTable(PO updatedPO) {
    const double rowHeight = 48;
    const double headerHeight = 48;
    const double itemNameWidth = 120;

    final List<double> widths = [80, 80, 80, 80, 120, 120, 120, 120, 120, 120];

    final rightTotalWidth = widths.fold<double>(0, (sum, w) => sum + w);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: itemNameWidth,
              height: headerHeight,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[300],
              child: const Text(
                "Item Name",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: rightTotalWidth,
                  height: headerHeight,
                  child: Row(
                    children: [
                      _headerCell("Qty", widths[0]),
                      _headerCell("Count", widths[1]),
                      _headerCell("UOM", widths[2]),
                      _headerCell("Total", widths[3]),
                      _headerCell("Existing", widths[4]),
                      _headerCell("New", widths[5]),
                      _headerCell("Discount", widths[6]),
                      _headerCell("Tax", widths[8]),
                      _headerCell("Total Price", widths[9]),
                      _headerCell("Final Price", widths[9]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: updatedPO.items.map((item) {
                    return Container(
                      width: itemNameWidth,
                      height: rowHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[200],
                      child: Text(
                        item.itemName ?? "",
                        maxLines: 2,

                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _bodyHorizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: rightTotalWidth,
                      child: Column(
                        children: updatedPO.items.map((item) {
                          return SizedBox(
                            height: rowHeight,
                            child: Row(
                              children: [
                                _dataCell("${item.pendingQuantity}", widths[0]),
                                _dataCell("${item.pendingCount}", widths[1]),
                                _dataCell(item.uom ?? "", widths[2]),
                                _dataCell(
                                  "${item.pendingTotalQuantity}",
                                  widths[3],
                                ),
                                _dataCell(
                                  item.existingPrice?.toStringAsFixed(2) ??
                                      "0.00",
                                  widths[4],
                                ),
                                _dataCell(
                                  item.newPrice?.toStringAsFixed(2) ?? "0.00",
                                  widths[5],
                                ),
                                _dataCell(
                                  item.pendingDiscountAmount?.toStringAsFixed(
                                        2,
                                      ) ??
                                      "0.00",
                                  widths[6],
                                ),
                                _dataCell(
                                  item.pendingTaxAmount?.toStringAsFixed(2) ??
                                      "0.00",
                                  widths[7],
                                ),

                                _dataCell(
                                  item.pendingTotalPrice?.toStringAsFixed(2) ??
                                      "0.00",
                                  widths[9],
                                ),
                                _dataCell(
                                  item.pendingFinalPrice?.toStringAsFixed(2) ??
                                      "0.00",
                                  widths[9],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      color: Colors.grey[300],
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _dataCell(String text, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      color: Colors.grey[200],
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
    );
  }

  void _openApproveModal(BuildContext context, PO updatedPO) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => POModal(
        po: updatedPO,
        key: UniqueKey(),
        showApproveButton: true,
        showRejectButton: false,
      ),
    );
  }

  void _openRejectModal(BuildContext context, PO updatedPO) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => POModal(
        po: updatedPO,
        key: UniqueKey(),
        showApproveButton: false,
        showRejectButton: true,
      ),
    );
  }

  void _editPO(BuildContext context, PO po) {
    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
    notifier.setEditingPO(po);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => PurchaseOrderDialog(
        key: UniqueKey(),
        editingPO: po,
        templateProvider: context.read<TemplateProvider>(),
      ),
    ).then((result) async {
      if (!mounted) return; // ✅ VERY IMPORTANT

      // Clear editing PO safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.setEditingPO(null);
        }
      });

      if (result == true) {
        // ✅ Refresh PO list safely
        final poProvider = Provider.of<POProvider>(context, listen: false);
        await poProvider.fetchPOs();

        if (!mounted) return;

        if (widget.onStatusChanged != null) {
          widget.onStatusChanged!();
        }

        // ✅ Show success message safely
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Purchase Order updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
