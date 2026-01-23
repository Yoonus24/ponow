// ignore_for_file: unused_field, file_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:purchaseorders2/widgets/ap%20invoice/ap_viewinvoice_modal.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/grn_details_screen.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/payment_dialogue.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/pending%20_outgoing_view_dialog.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/outgoing_payment_provider.dart';

class PendingOutgoing extends StatefulWidget {
  final String filterStatus;

  const PendingOutgoing({super.key, required this.filterStatus});

  @override
  State<PendingOutgoing> createState() => _PendingOutgoingState();
}

class _PendingOutgoingState extends State<PendingOutgoing> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final ValueNotifier<List<bool>> _selectedRowsNotifier =
      ValueNotifier<List<bool>>([]);
  final ValueNotifier<Set<int>> _selectedIndicesNotifier =
      ValueNotifier<Set<int>>({});
  OverlayEntry? _overlayEntry;
  int? _currentTooltipIndex;
  late TextEditingController _vendorController;
  late TextEditingController _invoiceSearchController;
  final ValueNotifier<String?> _selectedVendorNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<String?> _selectedInvoiceNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<String> _sortColumnNotifier = ValueNotifier<String>(
    'dueDays',
  );
  final ValueNotifier<bool> _sortAscendingNotifier = ValueNotifier<bool>(true);
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final ValueNotifier<bool> _refreshDataNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> _filteredCountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController();
    _invoiceSearchController = TextEditingController();
    _selectedRowsNotifier.addListener(_updateSelection);
    _selectedIndicesNotifier.addListener(_updateSelection);
    _horizontalScrollController.addListener(_handleHorizontalScroll);

    // Initialize with empty list
    _selectedRowsNotifier.value = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_handleHorizontalScroll);
    _selectedRowsNotifier.dispose();
    _selectedIndicesNotifier.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _mainScrollController.dispose();
    _removeOverlay();
    _vendorController.dispose();
    _invoiceSearchController.dispose();
    _selectedVendorNotifier.dispose();
    _selectedInvoiceNotifier.dispose();
    _sortColumnNotifier.dispose();
    _sortAscendingNotifier.dispose();
    _refreshDataNotifier.dispose();
    _filteredCountNotifier.dispose();
    super.dispose();
  }

  void _handleHorizontalScroll() {
    if (_overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _updateSelection() {}

  bool get isMultipleSelected => _selectedIndicesNotifier.value.length > 1;

  Future<void> _loadInitialData() async {
    final provider = context.read<OutgoingPaymentProvider>();

    try {
      await provider.fetchFilteredOutgoings(
        status: 'Pending',
        filterBy: 'invoiceDate',
        limit: 100,
      );

      if (mounted) {
        _syncSelectedRows(provider.payments.length);
      }
    } catch (_) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to load pending payments')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final provider = Provider.of<OutgoingPaymentProvider>(
        context,
        listen: false,
      );

      debugPrint('🔍 Loading data with filters:');
      debugPrint('  - Vendor: ${_selectedVendorNotifier.value}');
      debugPrint('  - Invoice: ${_selectedInvoiceNotifier.value}');

      // FIX 1: Send null for "All Vendors" instead of empty string
      final String? vendorNameForApi =
          (_selectedVendorNotifier.value == null ||
              _selectedVendorNotifier.value!.isEmpty ||
              _selectedVendorNotifier.value == 'All Vendors')
          ? null
          : _selectedVendorNotifier.value!.trim();

      // FIX 2: Send null for "All Invoices"
      final String? invoiceNoForApi =
          (_selectedInvoiceNotifier.value == null ||
              _selectedInvoiceNotifier.value!.trim().isEmpty)
          ? null
          : _selectedInvoiceNotifier.value!.trim();

      debugPrint('🔍 API Parameters:');
      debugPrint(
        '  - vendorNameForApi: $vendorNameForApi (is null: ${vendorNameForApi == null})',
      );
      debugPrint(
        '  - invoiceNoForApi: $invoiceNoForApi (is null: ${invoiceNoForApi == null})',
      );

      await provider.fetchFilteredOutgoings(
        status: 'Pending',
        filterBy: 'invoiceDate',
        limit: 100,
        vendorName: vendorNameForApi,
        invoiceNo: invoiceNoForApi,
      );

      debugPrint('✅ Data loaded: ${provider.payments.length} payments');
      debugPrint(
        '✅ First few vendors: ${provider.payments.take(3).map((p) => p.vendorName).toList()}',
      );

      if (provider.error.isNotEmpty && mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Data load error: ${provider.error}')),
        );
      }
      _refreshDataNotifier.value = !_refreshDataNotifier.value;
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to load data')),
        );
      }
    }
  }

  double _calculatePaidAmount(Outgoing payment) {
    // ✅ ALWAYS TRUST BACKEND SUMMARY
    if (payment.totalPaidAmount != null) {
      return payment.totalPaidAmount!;
    }

    // 🔁 FALLBACK (safety only)
    return (payment.partialAmount ?? 0.0) + (payment.fullPaymentAmount ?? 0.0);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentTooltipIndex = null;
  }

  void _showTaxTooltip(
    BuildContext context,
    GlobalKey key,
    Outgoing payment,
    int index,
  ) {
    _removeOverlay();
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Listener(
        onPointerMove: (_) => _removeOverlay(),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
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

    _currentTooltipIndex = index;
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildTaxTooltipContent(Outgoing payment) {
    double sgst = 0.0;
    double cgst = 0.0;
    double igst = 0.0;

    if (payment.itemDetails != null) {
      for (final item in payment.itemDetails!) {
        sgst += item.sgst ?? 0.0;
        cgst += item.cgst ?? 0.0;
        igst += item.igst ?? 0.0;
      }
    }

    final totalTax = sgst + cgst + igst;

    Text _row(String label, double value, {bool bold = false}) {
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
        _row('SGST', sgst),
        _row('CGST', cgst),
        _row('IGST', igst),

        const SizedBox(height: 6),
        const Divider(color: Colors.white54, thickness: 1),
        const SizedBox(height: 4),

        _row('TOTAL TAX', totalTax, bold: true),
      ],
    );
  }

  Widget _buildHeaderCell(String text, double width, {String? sortColumn}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ValueListenableBuilder(
          valueListenable: _sortColumnNotifier,
          builder: (context, sortColumnValue, child) {
            return ValueListenableBuilder(
              valueListenable: _sortAscendingNotifier,
              builder: (context, sortAscendingValue, child) {
                return GestureDetector(
                  onTap: sortColumn != null
                      ? () {
                          if (sortColumnValue == sortColumn) {
                            _sortAscendingNotifier.value = !sortAscendingValue;
                          } else {
                            _sortColumnNotifier.value = sortColumn;
                            _sortAscendingNotifier.value = true;
                          }
                          _loadData();
                        }
                      : null,
                  child: Tooltip(
                    message: text,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        if (sortColumn != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              sortColumnValue == sortColumn &&
                                      !sortAscendingValue
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentCell(
    String text,
    double width, {
    Widget? child,
    TextStyle? textStyle,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Center(
          child:
              child ??
              Text(
                text,
                style: textStyle ?? const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    List<Outgoing> selectedPayments,
    int? singleIndex,
    bool isBulkPayment,
  ) async {
    double totalPayableAmount = 0.0;
    for (var payment in selectedPayments) {
      totalPayableAmount += payment.totalPayableAmount ?? 0.0;
    }

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return PaymentDialog(
          totalPayableAmount: totalPayableAmount,
          isBulkPayment: isBulkPayment,
          onPaymentConfirmed:
              (
                paymentType,
                amount,
                paymentMode,
                paymentMethod,
                transactionDetails,
              ) async {
                final provider = Provider.of<OutgoingPaymentProvider>(
                  context,
                  listen: false,
                );

                try {
                  if (isBulkPayment) {
                    final double perOutgoingAmount =
                        amount / selectedPayments.length;

                    final bulkPayments = selectedPayments.map((payment) {
                      String? transactionReference;

                      if (paymentMode == 'Bank') {
                        if (paymentMethod == 'neft') {
                          transactionReference = transactionDetails['neftNo'];
                        } else if (paymentMethod == 'rtgs') {
                          transactionReference = transactionDetails['rtgsNo'];
                        } else if (paymentMethod == 'imps') {
                          transactionReference = transactionDetails['impsNo'];
                        } else if (paymentMethod == 'upi') {
                          transactionReference = transactionDetails['upi'];
                        }
                      }

                      return BulkPayment(
                        outgoingId: payment.outgoingId ?? '',
                        paymentType: paymentType,
                        paymentMode: paymentMode,
                        paymentMethod: paymentMethod,

                        // ✅ SEND TOTAL AMOUNT, NOT SPLIT
                        partialAmount: paymentType == 'partial' ? amount : null,

                        fullPaymentAmount: paymentType == 'full'
                            ? payment.totalPayableAmount
                            : null,

                        bankName: paymentMode == 'Bank'
                            ? transactionDetails['bankName']
                            : null,

                        transactionReference: transactionReference,
                        cashVoucherNo: null,

                        pettyCashAmount:
                            paymentMode == 'Cash' &&
                                paymentMethod == 'petty_cash'
                            ? amount
                            : null,

                        hoCash:
                            paymentMode == 'Cash' && paymentMethod == 'ho_cash'
                            ? amount
                            : null,
                      );
                    }).toList();

                    await provider.processBulkPayments(
                      bulkPayments,
                      selectedPayments,
                    );
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
                      final newSelectedRows = List<bool>.from(
                        _selectedRowsNotifier.value,
                      );
                      newSelectedRows[singleIndex] = false;
                      _selectedRowsNotifier.value = newSelectedRows;

                      final newSelectedIndices = Set<int>.from(
                        _selectedIndicesNotifier.value,
                      );
                      newSelectedIndices.remove(singleIndex);
                      _selectedIndicesNotifier.value = newSelectedIndices;
                    } else {
                      final newSelectedRows = List<bool>.from(
                        _selectedRowsNotifier.value,
                      );
                      for (var index
                          in _selectedIndicesNotifier.value.toList()) {
                        newSelectedRows[index] = false;
                      }
                      _selectedRowsNotifier.value = newSelectedRows;
                      _selectedIndicesNotifier.value = {};
                    }

                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('Payment Confirmed')),
                    );
                    await _loadData();
                  }
                } catch (e) {
                  if (context.mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(content: Text('Payment Failed: $e')),
                    );
                  }
                }
              },
        );
      },
    );
  }

  void _showGrnDetailsDialog(
    BuildContext context,
    String? grnId,
    List<GRN> grnList,
  ) {
    if (grnId == null || grnList.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('not found')),
        );
      }
    } catch (e) {
      debugPrint('Error showing GRN details: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('not found')),
      );
    }
  }

  void _showApDetailsDialog(
    BuildContext context,
    String? invoiceId,
    List<ApInvoice> apInvoices,
  ) {
    if (invoiceId == null || apInvoices.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
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
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('AP Invoice details not found')),
        );
      }
    } catch (e) {
      debugPrint('Error showing AP Invoice details: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('AP Invoice details not found')),
      );
    }
  }

  String? _getGrnRandomId(String? grnId, List<GRN> grnList) {
    debugPrint(
      'Looking for GRN ID: $grnId in grnList: ${grnList.map((g) => g.grnId).toList()}',
    );
    if (grnId == null || grnList.isEmpty) {
      debugPrint('GRN ID is null or grnList is empty');
      return null;
    }
    try {
      final grn = grnList.firstWhere(
        (grn) => grn.grnId == grnId,
        orElse: () => GRN(grnId: '', grnVerifiedDate: '', itemDetails: []),
      );
      debugPrint('Found GRN: ${grn.grnId}, randomId: ${grn.randomId}');
      return grn.randomId;
    } catch (e) {
      debugPrint('GRN lookup failed for $grnId: $e');
      return null;
    }
  }

  String? _getApRandomId(String? invoiceId, List<ApInvoice> apInvoices) {
    debugPrint(
      'Looking for Invoice ID: $invoiceId in apInvoices: ${apInvoices.map((ap) => ap.invoiceId).toList()}',
    );
    if (invoiceId == null || apInvoices.isEmpty) {
      debugPrint('Invoice ID is null or apInvoices is empty');
      return null;
    }
    try {
      final apInvoice = apInvoices.firstWhere(
        (ap) => ap.invoiceId == invoiceId,
        orElse: () => ApInvoice(randomId: ''),
      );
      debugPrint(
        'Found AP Invoice: ${apInvoice.invoiceId}, randomId: ${apInvoice.randomId}',
      );
      return apInvoice.randomId;
    } catch (e) {
      debugPrint('AP Invoice lookup failed for $invoiceId: $e');
      return null;
    }
  }

  void _handleVendorSelected(String? value) {
    _selectedVendorNotifier.value = (value == null || value == 'All Vendors')
        ? null
        : value;

    _loadData();
  }

  void _handleInvoiceSelected(String? value) {
    _selectedInvoiceNotifier.value = (value == null || value == 'All Invoices')
        ? null
        : value;

    _loadData();
  }

  Widget _buildVendorFilterField(OutgoingPaymentProvider provider) {
    return SizedBox(
      width: 250,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: provider.isLoadingVendors
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ValueListenableBuilder<String?>(
                valueListenable: _selectedVendorNotifier,
                builder: (context, selectedVendor, _) {
                  return Autocomplete<String>(
                    displayStringForOption: (option) => option,

                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final options = ['All Vendors', ...provider.vendorNames];

                      if (textEditingValue.text.isEmpty) {
                        return options;
                      }

                      return options.where(
                        (vendor) => vendor.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },

                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          // Ensure selected vendor appears in the field
                          if (selectedVendor != null &&
                              selectedVendor.isNotEmpty &&
                              controller.text != selectedVendor) {
                            controller.text = selectedVendor;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          }

                          return TextField(
                            controller: controller,
                            focusNode: focusNode,

                            // 🔴 IMPORTANT: Removed textAlignVertical to allow top shift
                            style: const TextStyle(fontSize: 14),

                            decoration: InputDecoration(
                              hintText: 'Filter by Vendor',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),

                              // ✅ Icon centered with fixed size
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  right: 6,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),

                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),

                              // ✅ Clear button
                              suffixIcon:
                                  controller.text.isNotEmpty &&
                                      controller.text != 'All Vendors'
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        _handleVendorSelected(null);
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,

                              border: InputBorder.none,

                              // ✅ THIS moves the text slightly UP
                              contentPadding: const EdgeInsets.only(
                                top: 6, // text moves upward
                                bottom: 0,
                                left: 5,
                                right: 5,
                              ),
                            ),

                            onTap: () {
                              if (controller.text == 'All Vendors') {
                                controller.clear();
                              }
                            },
                          );
                        },

                    onSelected: (selected) {
                      // _selectedVendorNotifier.value = selected;
                      _handleVendorSelected(selected);
                    },

                    // ✅ Dropdown UI
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SizedBox(
                              width: 250,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);

                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        option,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildInvoiceSearchField(OutgoingPaymentProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double fieldWidth = constraints.maxWidth;

        return Container(
          height: 40,
          width: fieldWidth,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: provider.isLoadingInvoices
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ValueListenableBuilder<String?>(
                  valueListenable: _selectedInvoiceNotifier,
                  builder: (context, selectedInvoice, _) {
                    return Autocomplete<String>(
                      displayStringForOption: (option) => option,

                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final options = [
                          'All Invoices',
                          ...provider.invoiceNumbers,
                        ];

                        if (textEditingValue.text.isEmpty) {
                          return options;
                        }

                        return options.where(
                          (invoice) => invoice.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },

                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            // ✅ Ensure selected invoice appears in the field
                            if (selectedInvoice != null &&
                                selectedInvoice.isNotEmpty &&
                                controller.text != selectedInvoice) {
                              controller.text = selectedInvoice;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,

                                style: const TextStyle(fontSize: 14),

                                decoration: InputDecoration(
                                  hintText: 'Search by Invoice',
                                  hintStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),

                                  // ✅ ICON SAME AS VENDOR STYLE
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 6,
                                    ),
                                    child: const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                  ),

                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),

                                  // ✅ CLEAR BUTTON SAME STYLE
                                  suffixIcon:
                                      controller.text.isNotEmpty &&
                                          controller.text != 'All Invoices'
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            controller.clear();
                                            _handleInvoiceSelected(null);
                                            FocusScope.of(context).unfocus();
                                          },
                                        )
                                      : null,

                                  border: InputBorder.none,

                                  // ✅ SAME TEXT POSITION AS VENDOR FIELD
                                  contentPadding: const EdgeInsets.only(
                                    top: 6,
                                    bottom: 0,
                                    left: 5,
                                    right: 5,
                                  ),
                                ),

                                onTap: () {
                                  if (controller.text == 'All Invoices') {
                                    controller.clear();
                                  }
                                },
                              ),
                            );
                          },

                      onSelected: (selected) {
                        // _selectedInvoiceNotifier.value = selected;
                        _handleInvoiceSelected(selected);
                      },

                      // ✅ DROPDOWN UI MATCHES VENDOR FIELD
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth: fieldWidth,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);

                                  return InkWell(
                                    onTap: () {
                                      onSelected(option);
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        option,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildMultiplePaymentButton(List<Outgoing> filteredPayments) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: _selectedIndicesNotifier,
      builder: (context, selectedIndices, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.payments,
                size: 22,
                color: selectedIndices.length >= 2
                    ? Colors.blueAccent
                    : Colors.grey,
              ),
              tooltip: selectedIndices.length >= 2
                  ? 'Process Selected Payments'
                  : 'Select 2 or more items to enable',
              onPressed: selectedIndices.length >= 2
                  ? () {
                      final selectedPayments = selectedIndices
                          .map((index) => filteredPayments[index])
                          .toList();
                      _showPaymentDialog(context, selectedPayments, null, true);
                    }
                  : null,
            ),
            const SizedBox(width: 4),
            const Text('Multiple Pay', style: TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }

  Widget _buildDataRow(
    int index,
    Outgoing outgoing,
    List<GRN> grnList,
    List<ApInvoice> apInvoices,
    List<double> columnWidths,
  ) {
    // Safety check
    if (index < 0) {
      return Container(height: 60.0);
    }

    final GlobalKey cellKey = GlobalKey();

    return Row(
      children: [
        _buildContentCell('${index + 1}', columnWidths[0]),

        _buildContentCell(
          '',
          columnWidths[1],
          child: Builder(
            builder: (context) {
              final selectedRows = _selectedRowsNotifier.value;

              if (selectedRows.isEmpty || index >= selectedRows.length) {
                return const Checkbox(
                  value: false,
                  onChanged: null,
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                );
              }

              // Safe to access now
              final isSelected = selectedRows[index];

              return Checkbox(
                value: isSelected,
                activeColor: Colors.blue,
                checkColor: Colors.white,
                onChanged: (value) {
                  final newSelectedRows = List<bool>.from(selectedRows);

                  // Double-check bounds before modifying
                  if (index < newSelectedRows.length) {
                    newSelectedRows[index] = value ?? false;
                    _selectedRowsNotifier.value = newSelectedRows;

                    final newSelectedIndices = Set<int>.from(
                      _selectedIndicesNotifier.value,
                    );
                    if (value == true) {
                      newSelectedIndices.add(index);
                    } else {
                      newSelectedIndices.remove(index);
                    }
                    _selectedIndicesNotifier.value = newSelectedIndices;
                  }
                },
              );
            },
          ),
        ),

        _buildContentCell(
          '',
          columnWidths[2],
          child: IconButton(
            icon: const Icon(
              Icons.remove_red_eye,
              color: Colors.blue,
              size: 18,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => PendingOutgoingDialog(outgoing: outgoing),
              );
            },
          ),
        ),

        _buildContentCell(
          '',
          columnWidths[3],
          child: ValueListenableBuilder<Set<int>>(
            valueListenable: _selectedIndicesNotifier,
            builder: (context, selectedIndices, _) {
              return IconButton(
                icon: Icon(
                  Icons.payment,
                  color: selectedIndices.length > 1 ? Colors.grey : Colors.blue,
                  size: 18,
                ),
                onPressed: selectedIndices.length > 1
                    ? null
                    : () {
                        _showPaymentDialog(context, [outgoing], index, false);
                      },
              );
            },
          ),
        ),

        _buildContentCell(
          '',
          columnWidths[4],
          child: ValueListenableBuilder<Set<int>>(
            valueListenable: _selectedIndicesNotifier,
            builder: (context, selectedIndices, _) {
              return IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.blue,
                  size: 18,
                ),
                onPressed: () async {
                  try {
                    final poService = OutgoingPdf();
                    final pdfFile = await poService.generateOutgoingPdf(
                      outgoing.outgoingId,
                    );
                    await Printing.layoutPdf(
                      onLayout: (_) => pdfFile.readAsBytesSync(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF generated successfully')),
                    );
                  } catch (e) {
                    print("Error during download or upload pdf: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate PDF: $e')),
                    );
                  }
                },
              );
            },
          ),
        ),

        _buildContentCell(
          (outgoing.intimationDays?.toInt() ?? 0).toString(),
          columnWidths[5],
          textStyle: TextStyle(
            fontSize: 12,
            color: (outgoing.intimationDays?.toInt() ?? 0) < 5
                ? Colors.red
                : (outgoing.intimationDays?.toInt() ?? 0) < 10
                ? Colors.orange
                : Colors.green,
          ),
        ),

        _buildContentCell(outgoing.vendorName ?? 'N/A', columnWidths[6]),
        _buildContentCell(outgoing.invoiceNo ?? 'N/A', columnWidths[7]),
        _buildContentCell(
          outgoing.invoiceDate != null
              ? DateFormat('dd-MM-yyyy').format(outgoing.invoiceDate!)
              : 'N/A',
          columnWidths[8],
        ),

        _buildContentCell(
          '',
          columnWidths[9],
          child: GestureDetector(
            onTap: () =>
                _showGrnDetailsDialog(context, outgoing.grnId, grnList),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getGrnRandomId(outgoing.grnId, grnList) ??
                    outgoing.grnId ??
                    'N/A',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),

        _buildContentCell(
          '',
          columnWidths[10],
          child: GestureDetector(
            onTap: () =>
                _showApDetailsDialog(context, outgoing.invoiceId, apInvoices),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getApRandomId(outgoing.invoiceId, apInvoices) ??
                    outgoing.invoiceId ??
                    'N/A',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),

        _buildContentCell(
          outgoing.totalPrice != null
              ? outgoing.totalPrice!.toStringAsFixed(2)
              : 'N/A',
          columnWidths[11],
        ),

        _buildContentCell(
          '',
          columnWidths[12],
          child: GestureDetector(
            onTap: () => _showTaxTooltip(context, cellKey, outgoing, index),
            onLongPress: () =>
                _showTaxTooltip(context, cellKey, outgoing, index),
            child: Container(
              key: cellKey,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                outgoing.taxDetails?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),

        _buildContentCell(
          outgoing.discountDetails?.toStringAsFixed(2) ?? '0.00',
          columnWidths[13],
        ),

        _buildContentCell(
          outgoing.payableAmount?.toStringAsFixed(2) ?? 'N/A',
          columnWidths[14],
        ),

        _buildContentCell(
          (outgoing.totalPaidAmount ?? 0.0).toStringAsFixed(2),
          columnWidths[15],
        ),

        _buildContentCell(
          outgoing.totalPayableAmount?.toStringAsFixed(2) ?? 'N/A',
          columnWidths[16],
        ),

        _buildContentCell(outgoing.paymentTerms ?? 'N/A', columnWidths[17]),
      ],
    );
  }

  void _syncSelectedRows(int filteredCount) {
    final currentRows = _selectedRowsNotifier.value;
    if (currentRows.length != filteredCount) {
      _selectedRowsNotifier.value = List<bool>.filled(filteredCount, false);
      _selectedIndicesNotifier.value = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _overlayEntry == null,
      onPopInvoked: (didPop) {
        if (_overlayEntry != null) {
          _removeOverlay();
        }
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: _refreshDataNotifier,
            builder: (context, refreshData, _) {
              return Consumer<OutgoingPaymentProvider>(
                builder: (context, provider, child) {
                  // Show loading state
                  if (provider.isLoadingOutgoings) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Show error state
                  if (provider.error.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${provider.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final grnList = provider.grnList;
                  final apInvoices = provider.apInvoices;
                  final filtered =
                      provider.payments; // Already filtered by backend

                  debugPrint(
                    '🏗️ Building UI with ${filtered.length} filtered payments (from backend)',
                  );

                  // Show empty state
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No pending payments found.',
                            style: TextStyle(fontSize: 17, color: Colors.grey),
                          ),
                          if (provider.allPayments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Total payments in system: ${provider.allPayments.length}',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          IconButton(
                            onPressed: _loadData,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueAccent,
                              size: 22,
                            ),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    );
                  }

                  const columnWidths = <double>[
                    45,
                    50,
                    45,
                    50,
                    50,
                    150,
                    150,
                    85,
                    95,
                    85,
                    85,
                    95,
                    85,
                    85,
                    85,
                    95,
                    85,
                    120,
                  ];
                  final totalWidth = columnWidths.reduce((a, b) => a + b);

                  return Scrollbar(
                    controller: _mainScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _mainScrollController,
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PENDING OUTGOING',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Total Payable Amount: ${filtered.fold(0.0, (sum, p) => sum + (p.totalPayableAmount ?? 0.0)).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 600) {
                                      return Row(
                                        children: [
                                          _buildVendorFilterField(provider),
                                          const SizedBox(width: 8),
                                          _buildInvoiceSearchField(provider),
                                          const SizedBox(width: 8),
                                          _buildMultiplePaymentButton(filtered),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ValueListenableBuilder<Set<int>>(
                                              valueListenable:
                                                  _selectedIndicesNotifier,
                                              builder: (context, selectedIndices, _) {
                                                if (selectedIndices.length >
                                                    1) {
                                                  final amount = selectedIndices
                                                      .fold(
                                                        0.0,
                                                        (sum, index) =>
                                                            sum +
                                                            (filtered[index]
                                                                    .totalPayableAmount ??
                                                                0.0),
                                                      );
                                                  return Text(
                                                    'Selected Amount: ${amount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black,
                                                    ),
                                                  );
                                                }
                                                return const SizedBox();
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildVendorFilterField(
                                                provider,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildInvoiceSearchField(
                                                provider,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _buildMultiplePaymentButton(
                                              filtered,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ValueListenableBuilder<Set<int>>(
                                                valueListenable:
                                                    _selectedIndicesNotifier,
                                                builder: (context, selectedIndices, _) {
                                                  if (selectedIndices.length >
                                                      1) {
                                                    final amount =
                                                        selectedIndices.fold(
                                                          0.0,
                                                          (sum, index) =>
                                                              sum +
                                                              (filtered[index]
                                                                      .totalPayableAmount ??
                                                                  0.0),
                                                        );
                                                    return Text(
                                                      'Selected Amount: ${amount.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.black,
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          ValueListenableBuilder<String?>(
                            valueListenable: _selectedVendorNotifier,
                            builder: (context, selectedVendor, _) {
                              return ValueListenableBuilder<String?>(
                                valueListenable: _selectedInvoiceNotifier,
                                builder: (context, selectedInvoice, _) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      children: [
                                        Scrollbar(
                                          controller:
                                              _horizontalScrollController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller:
                                                _horizontalScrollController,
                                            scrollDirection: Axis.horizontal,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                Color.fromARGB(
                                                                  255,
                                                                  74,
                                                                  122,
                                                                  227,
                                                                ),
                                                                Color.fromARGB(
                                                                  255,
                                                                  100,
                                                                  140,
                                                                  240,
                                                                ),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  child: SizedBox(
                                                    width: totalWidth,
                                                    child: Row(
                                                      children: [
                                                        _buildHeaderCell(
                                                          'No',
                                                          columnWidths[0],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Select',
                                                          columnWidths[1],
                                                        ),
                                                        _buildHeaderCell(
                                                          'View',
                                                          columnWidths[2],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Action',
                                                          columnWidths[3],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Pdf',
                                                          columnWidths[4],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Due Days',
                                                          columnWidths[5],
                                                          sortColumn: 'dueDays',
                                                        ),
                                                        _buildHeaderCell(
                                                          'Vendor Name',
                                                          columnWidths[6],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Invoice No',
                                                          columnWidths[7],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Invoice Date',
                                                          columnWidths[8],
                                                        ),
                                                        _buildHeaderCell(
                                                          'GRN No',
                                                          columnWidths[9],
                                                        ),
                                                        _buildHeaderCell(
                                                          'AP No',
                                                          columnWidths[10],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Total Amount',
                                                          columnWidths[11],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Tax',
                                                          columnWidths[12],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Discount',
                                                          columnWidths[13],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Total',
                                                          columnWidths[14],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Paid Amount',
                                                          columnWidths[15],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Remaining',
                                                          columnWidths[16],
                                                        ),
                                                        _buildHeaderCell(
                                                          'Payment Terms',
                                                          columnWidths[17],
                                                          sortColumn:
                                                              'paymentTerms',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 360,
                                                  child: Scrollbar(
                                                    controller:
                                                        _verticalScrollController, // ✅ ADD THIS LINE
                                                    thumbVisibility: true,
                                                    child: SingleChildScrollView(
                                                      controller:
                                                          _verticalScrollController, // ✅ SAME CONTROLLER
                                                      child: SizedBox(
                                                        width: totalWidth,
                                                        child: Column(
                                                          children: [
                                                            for (
                                                              var index = 0;
                                                              index <
                                                                  filtered
                                                                      .length;
                                                              index++
                                                            )
                                                              ValueListenableBuilder<
                                                                List<bool>
                                                              >(
                                                                valueListenable:
                                                                    _selectedRowsNotifier,
                                                                builder:
                                                                    (
                                                                      context,
                                                                      selectedRows,
                                                                      _,
                                                                    ) {
                                                                      return Container(
                                                                        height:
                                                                            60.0,
                                                                        color:
                                                                            selectedRows.isNotEmpty &&
                                                                                index <
                                                                                    selectedRows.length &&
                                                                                selectedRows[index]
                                                                            ? Colors.blue.shade50
                                                                            : (index.isEven
                                                                                  ? Colors.white
                                                                                  : Colors.grey.shade50),
                                                                        child: _buildDataRow(
                                                                          index,
                                                                          filtered[index],
                                                                          grnList,
                                                                          apInvoices,
                                                                          columnWidths,
                                                                        ),
                                                                      );
                                                                    },
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
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
