// ignore_for_file: dead_null_aware_expression, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/ap_viewinvoice_modal.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/grn_details_screen.dart';
import '../../providers/outgoing_payment_provider.dart';
import 'payment_dialogue.dart';

class PendingOutgoingLogic {
  // Scroll Controllers
  final ScrollController verticalScrollController = ScrollController();
  final ScrollController horizontalScrollController = ScrollController();
  final ScrollController mainScrollController = ScrollController();
  
  // Text Controllers
  final TextEditingController vendorController = TextEditingController();
  final TextEditingController invoiceSearchController = TextEditingController();
  
  // Value Notifiers
  final ValueNotifier<List<bool>> selectedRowsNotifier = ValueNotifier<List<bool>>([]);
  final ValueNotifier<Set<int>> selectedIndicesNotifier = ValueNotifier<Set<int>>({});
  final ValueNotifier<String?> selectedVendorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> selectedInvoiceNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String> sortColumnNotifier = ValueNotifier<String>('dueDays');
  final ValueNotifier<bool> sortAscendingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> refreshDataNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingMoreNotifier = ValueNotifier(false);
  
  // State
  final Map<int, bool> loadingPdfMap = {};
  OverlayEntry? overlayEntry;
  int? currentTooltipIndex;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Calculate Due Days
  int calculateDueDays(Outgoing outgoing) {
    if (outgoing.invoiceDate == null) return 0;
    final terms = outgoing.paymentTerms ?? '';
    final match = RegExp(r'\d+').firstMatch(terms);
    final int creditDays = match != null ? int.parse(match.group(0)!) : 0;
    final dueDate = outgoing.invoiceDate!.add(Duration(days: creditDays));
    final today = ServerTimeService.now;
    return dueDate.difference(today).inDays;
  }

  bool get isMultipleSelected => selectedIndicesNotifier.value.length > 1;

  // Overlay Management
  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
    currentTooltipIndex = null;
  }

  // Sync Selected Rows
  void syncSelectedRows(int filteredCount) {
    final currentRows = selectedRowsNotifier.value;
    if (currentRows.length != filteredCount) {
      selectedRowsNotifier.value = List<bool>.filled(filteredCount, false);
      selectedIndicesNotifier.value = {};
    }
  }

  // Load More Data
  Future<void> loadMore(BuildContext context) async {
    if (isLoadingMoreNotifier.value) return;
    isLoadingMoreNotifier.value = true;

    final provider = context.read<OutgoingPaymentProvider>();
    final start = DateTime.now();

    await provider.fetchFilteredOutgoings(
      status: 'Pending',
      filterByAmount: true,
      skip: provider.payments.length,
      limit: 100,
    );

    final diff = DateTime.now().difference(start);
    if (diff.inMilliseconds < 400) {
      await Future.delayed(Duration(milliseconds: 400 - diff.inMilliseconds));
    }
    isLoadingMoreNotifier.value = false;
  }

  // Load Initial Data
  Future<void> loadInitialData(BuildContext context) async {
    final provider = context.read<OutgoingPaymentProvider>();
    try {
      await provider.fetchFilteredOutgoings(
        status: 'Pending',
        filterBy: 'invoiceDate',
        limit: 50,
      );
      if (context.mounted) {
        syncSelectedRows(provider.payments.length);
      }
    } catch (_) {
      if (context.mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to load pending payments')),
        );
      }
    }
  }

  // Load Data with Filters
  Future<void> loadData(BuildContext context) async {
    try {
      final provider = Provider.of<OutgoingPaymentProvider>(context, listen: false);
      
      final String? vendorNameForApi = 
          (selectedVendorNotifier.value == null ||
           selectedVendorNotifier.value!.isEmpty ||
           selectedVendorNotifier.value == 'All Vendors')
          ? null : selectedVendorNotifier.value!.trim();

      final String? invoiceNoForApi =
          (selectedInvoiceNotifier.value == null ||
           selectedInvoiceNotifier.value!.trim().isEmpty)
          ? null : selectedInvoiceNotifier.value!.trim();

      await provider.fetchFilteredOutgoings(
        status: 'Pending',
        filterBy: 'invoiceDate',
        limit: 100,
        vendorName: vendorNameForApi,
        invoiceNo: invoiceNoForApi,
        isTableRefresh: true,
      );

      refreshDataNotifier.value = !refreshDataNotifier.value;
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
    }
  }

  // Handle PDF Click
  Future<void> handlePdfClick(BuildContext context, int index, Outgoing outgoing) async {
    loadingPdfMap[index] = true;
    // Trigger rebuild
    refreshDataNotifier.value = !refreshDataNotifier.value;

    try {
      final service = OutgoingPdf();
      final pdfFile = await service.generateOutgoingPdf(outgoing.outgoingId);
      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());
      
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('PDF generated successfully')),
      );
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      loadingPdfMap[index] = false;
      refreshDataNotifier.value = !refreshDataNotifier.value;
    }
  }

  // Show Tax Tooltip
  void showTaxTooltip(BuildContext context, GlobalKey key, Outgoing payment, int index) {
    removeOverlay();
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    overlayEntry = OverlayEntry(
      builder: (context) => Listener(
        onPointerMove: (_) => removeOverlay(),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: removeOverlay,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: position.dx - (200 - size.width) / 2,
              top: position.dy + size.height + 4,
              width: 150,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildTaxTooltipContent(payment),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    currentTooltipIndex = index;
    Overlay.of(context).insert(overlayEntry!);
  }

  // Tax Tooltip Content
  Widget _buildTaxTooltipContent(Outgoing payment) {
    double sgst = 0.0, cgst = 0.0, igst = 0.0;

    if (payment.itemDetails != null) {
      for (final item in payment.itemDetails!) {
        sgst += item.sgst ?? 0.0;
        cgst += item.cgst ?? 0.0;
        igst += item.igst ?? 0.0;
      }
    }

    final totalTax = sgst + cgst + igst;

    Widget row(String label, double value, {bool bold = false}) {
      return Text(
        '$label : ${value.toStringAsFixed(2)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row('SGST', sgst),
        row('CGST', cgst),
        row('IGST', igst),
        const SizedBox(height: 6),
        const Divider(color: Colors.white54, thickness: 1),
        const SizedBox(height: 4),
        row('TOTAL TAX', totalTax, bold: true),
      ],
    );
  }

  // Show Payment Dialog
  Future<void> showPaymentDialog(
    BuildContext context,
    List<Outgoing> selectedPayments,
    int? singleIndex,
    bool isBulkPayment,
  ) async {
    double totalPayableAmount = selectedPayments.fold(0.0, 
        (sum, p) => sum + (p.totalPayableAmount ?? 0.0));

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return PaymentDialog(
          totalPayableAmount: totalPayableAmount,
          isBulkPayment: isBulkPayment,
          onPaymentConfirmed: (
            paymentType,
            amount,
            paymentMode,
            paymentMethod,
            transactionDetails,
          ) async {
            final provider = Provider.of<OutgoingPaymentProvider>(context, listen: false);

            try {
              if (isBulkPayment) {
                final bulkPayments = selectedPayments.map((payment) {
                  String? transactionReference;
                  if (paymentMode == 'Bank') {
                    if (paymentMethod == 'neft') transactionReference = transactionDetails['neftNo'];
                    else if (paymentMethod == 'rtgs') transactionReference = transactionDetails['rtgsNo'];
                    else if (paymentMethod == 'imps') transactionReference = transactionDetails['impsNo'];
                    else if (paymentMethod == 'upi') transactionReference = transactionDetails['upi'];
                  }

                  return BulkPayment(
                    outgoingId: payment.outgoingId ?? '',
                    paymentType: paymentType,
                    paymentMode: paymentMode,
                    paymentMethod: paymentMethod,
                    partialAmount: paymentType == 'partial' ? amount : null,
                    fullPaymentAmount: paymentType == 'full' ? payment.totalPayableAmount : null,
                    bankName: paymentMode == 'Bank' ? transactionDetails['bankName'] : null,
                    transactionReference: transactionReference,
                    cashVoucherNo: null,
                    pettyCashAmount: paymentMode == 'Cash' && paymentMethod == 'petty_cash' ? amount : null,
                    hoCash: paymentMode == 'Cash' && paymentMethod == 'ho_cash' ? amount : null,
                  );
                }).toList();

                await provider.processBulkPayments(bulkPayments, selectedPayments);
              } else {
                for (var payment in selectedPayments) {
                  await provider.processPayment(
                    outgoingId: payment.outgoingId ?? '',
                    paymentType: paymentType,
                    amount: amount / selectedPayments.length,
                    paymentMode: paymentMode,
                    paymentMethod: paymentMethod,
                    transactionDetails: transactionDetails,
                  );
                }
              }

              if (context.mounted) {
                if (singleIndex != null) {
                  final newSelectedRows = List<bool>.from(selectedRowsNotifier.value);
                  newSelectedRows[singleIndex] = false;
                  selectedRowsNotifier.value = newSelectedRows;

                  final newSelectedIndices = Set<int>.from(selectedIndicesNotifier.value);
                  newSelectedIndices.remove(singleIndex);
                  selectedIndicesNotifier.value = newSelectedIndices;
                } else {
                  final newSelectedRows = List<bool>.from(selectedRowsNotifier.value);
                  for (var index in selectedIndicesNotifier.value.toList()) {
                    newSelectedRows[index] = false;
                  }
                  selectedRowsNotifier.value = newSelectedRows;
                  selectedIndicesNotifier.value = {};
                }

                scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Payment Confirmed')),
                );

                final provider = Provider.of<OutgoingPaymentProvider>(context, listen: false);
                await provider.fetchApInvoices();
                await provider.fetchFilteredOutgoings(
                  status: 'Pending',
                  filterBy: 'invoiceDate',
                  limit: 100,
                  isTableRefresh: true,
                );
                refreshDataNotifier.value = !refreshDataNotifier.value;
              }
            } catch (e) {
              if (context.mounted) {
                scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Payment Failed: $e')),
                );
              }
            }
          },
        );
      },
    );
  }

  // Show GRN Details
  void showGrnDetailsDialog(
    BuildContext context,
    String? grnId,
    List<GRN> grnList,
  ) {
    if (grnId == null || grnList.isEmpty) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('GRN details not found')),
      );
      return;
    }

    try {
      final grn = grnList.firstWhere(
        (g) => g.grnId == grnId,
        orElse: () => GRN(grnId: '', grnVerifiedDate: '', itemDetails: []),
      );

      if (grn.grnId != null && grn.grnId!.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => GRNDetailsDialog(grn: grn),
        );
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('GRN details not found')),
        );
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('GRN details not found')),
      );
    }
  }

  // Show AP Details
  void showApDetailsDialog(
    BuildContext context,
    String? invoiceId,
    List<ApInvoice> apInvoices,
  ) {
    if (invoiceId == null || apInvoices.isEmpty) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('AP Invoice details not found')),
      );
      return;
    }

    try {
      final apInvoice = apInvoices.firstWhere(
        (ap) => ap.invoiceId == invoiceId,
        orElse: () => ApInvoice(randomId: ''),
      );

      if (apInvoice.invoiceId != null && apInvoice.invoiceId!.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => APViewInvoiceModal(apinvoice: apInvoice),
        );
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('AP Invoice details not found')),
        );
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('AP Invoice details not found')),
      );
    }
  }

  // Handle Vendor Selection
  void handleVendorSelected(String? value, BuildContext context) {
    selectedVendorNotifier.value = (value == null || value == 'All Vendors') ? null : value;
    loadData(context);
  }

  // Handle Invoice Selection
  void handleInvoiceSelected(String? value, BuildContext context) {
    selectedInvoiceNotifier.value = (value == null || value.trim().isEmpty) ? null : value;
    loadData(context);
  }

  // Sort Payments
  List<Outgoing> sortPayments(List<Outgoing> payments) {
    final String sortColumn = sortColumnNotifier.value;
    final bool ascending = sortAscendingNotifier.value;
    
    payments.sort((a, b) {
      int result = 0;
      switch (sortColumn) {
        case 'dueDays':
          result = (a.intimationDays ?? 0).compareTo(b.intimationDays ?? 0);
          break;
        case 'paymentTerms':
          result = (a.paymentTerms ?? '').compareTo(b.paymentTerms ?? '');
          break;
        case 'invoiceDate':
          result = (a.invoiceDate ?? DateTime(1970)).compareTo(b.invoiceDate ?? DateTime(1970));
          break;
      }
      return ascending ? result : -result;
    });
    return payments;
  }

  // Dispose
  void dispose() {
    verticalScrollController.dispose();
    horizontalScrollController.dispose();
    mainScrollController.dispose();
    vendorController.dispose();
    invoiceSearchController.dispose();
    selectedRowsNotifier.dispose();
    selectedIndicesNotifier.dispose();
    selectedVendorNotifier.dispose();
    selectedInvoiceNotifier.dispose();
    sortColumnNotifier.dispose();
    sortAscendingNotifier.dispose();
    refreshDataNotifier.dispose();
    isLoadingMoreNotifier.dispose();
    removeOverlay();
  }
}