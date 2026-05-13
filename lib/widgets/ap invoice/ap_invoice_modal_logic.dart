// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/ap_item.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/providers/ap_invoice_provider.dart';
import 'package:purchaseorders2/providers/outgoing_payment_provider.dart';
import 'package:provider/provider.dart';

class APInvoiceModalLogic extends ChangeNotifier {
  final ApInvoice apinvoice;
  late BuildContext _context;

  // Notifiers
  late ValueNotifier<List<String>> columnOrderNotifier;
  late ValueNotifier<Map<String, bool>> columnVisibilityNotifier;
  final ValueNotifier<bool> isReturning = ValueNotifier(false);

  // Scroll Controllers
  final ScrollController leftVerticalController = ScrollController();
  final ScrollController rightVerticalController = ScrollController();
  final ScrollController rightHorizontalController = ScrollController();

  // Column Widths
  final Map<String, double> columnWidths = {
    'S.No': 40,
    'Item Name': 150,
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

  APInvoiceModalLogic({required this.apinvoice}) {
    _initNotifiers();
    _setupScrollListeners();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void _initNotifiers() {
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
  }

  void _setupScrollListeners() {
    leftVerticalController.addListener(() {
      if (rightVerticalController.hasClients &&
          rightVerticalController.offset != leftVerticalController.offset) {
        rightVerticalController.jumpTo(leftVerticalController.offset);
      }
    });

    rightVerticalController.addListener(() {
      if (leftVerticalController.hasClients &&
          leftVerticalController.offset != rightVerticalController.offset) {
        leftVerticalController.jumpTo(rightVerticalController.offset);
      }
    });
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

  List<ItemDetail> getItems() {
    return apinvoice.itemDetails ?? [];
  }

  double getRoundOff() {
    return apinvoice.roundOffAdjustment ?? 0.0;
  }

  double getFinalTotal() {
    return apinvoice.invoiceAmount ?? 0.0;
  }

  double getFreightTotal() {
    final freightAmount = apinvoice.totalFreightAmount ?? 0.0;
    final freightTax = apinvoice.totalFreightTaxAmount ?? 0.0;
    return freightAmount + freightTax;
  }

  double getTotalDiscount() {
    return apinvoice.discountDetails ?? 0.0;
  }

  bool getCanReturn(BuildContext context) {
    final permission = context.read<PermissionProvider>();
    final apStatus = (apinvoice.status ?? '').toLowerCase().trim();
    return apStatus.isNotEmpty &&
        !apStatus.contains('returned') &&
        permission.hasPermission('grns', '', 'edit') &&
        permission.hasEditAction('grns', 'return_grn');
  }

  Map<String, double> getTaxTotals(List<ItemDetail> items) {
    double totalSgst = 0.0, totalCgst = 0.0;
    for (var item in items) {
      totalSgst += (item.sgst ?? 0.0);
      totalCgst += (item.cgst ?? 0.0);
    }
    return {'sgst': totalSgst, 'cgst': totalCgst};
  }

  bool hasOutgoingPayment(BuildContext context) {
    final outgoingProvider = context.read<OutgoingPaymentProvider>();
    return outgoingProvider.allPayments.any(
      (o) => o.invoiceId == apinvoice.invoiceId,
    );
  }

  Future<void> performReturn(BuildContext context) async {
    isReturning.value = true;
    try {
      await context.read<APInvoiceProvider>().convertToGrnFromApReturned(
        apinvoice.invoiceId ?? '',
        context,
      );
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      isReturning.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void updateColumnOrder(List<String> newOrder) {
    columnOrderNotifier.value = newOrder;
  }

  void updateColumnVisibility(Map<String, bool> newVisibility) {
    columnVisibilityNotifier.value = newVisibility;
  }

  List<String> getVisibleColumns() {
    return columnOrderNotifier.value
        .where((col) => columnVisibilityNotifier.value[col] == true)
        .toList();
  }

  List<String> getRightColumns() {
    final visibleColumns = getVisibleColumns();
    return visibleColumns
        .where((column) => column != 'Item Name' && column != 'S.No')
        .toList();
  }

  double getLeftWidth() {
    return (columnWidths['S.No'] ?? 40) + (columnWidths['Item Name'] ?? 130);
  }

  double getRightWidth(List<String> rightColumns) {
    return rightColumns.fold<double>(
      0.0,
      (sum, col) => sum + (columnWidths[col] ?? 120),
    );
  }

  String getInvoiceNo() {
    return apinvoice.randomId ?? 'N/A';
  }

  String getVendorName() {
    return apinvoice.vendorName ?? 'Unknown Vendor';
  }

  String getInvoiceDate() {
    return formatDate(apinvoice.invoiceDate);
  }

  @override
  void dispose() {
    columnOrderNotifier.dispose();
    columnVisibilityNotifier.dispose();
    leftVerticalController.dispose();
    rightVerticalController.dispose();
    rightHorizontalController.dispose();
    isReturning.dispose();
    super.dispose();
  }
}
