import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/widgets/ap%20invoice/ap_viewinvoice_modal.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/grn_details_screen.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/pending%20_outgoing_view_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/outgoing_payment_provider.dart';
import 'pending_outgoing_logic.dart';

class PendingOutgoing extends StatefulWidget {
  final String filterStatus;
  const PendingOutgoing({super.key, required this.filterStatus});

  @override
  State<PendingOutgoing> createState() => _PendingOutgoingState();
}

class _PendingOutgoingState extends State<PendingOutgoing> {
  late final PendingOutgoingLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = PendingOutgoingLogic();
    
    _logic.horizontalScrollController.addListener(_handleHorizontalScroll);
    _logic.verticalScrollController.addListener(_handleScroll);
    _logic.selectedRowsNotifier.value = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logic.loadInitialData(context);
    });
  }

  @override
  void dispose() {
    _logic.horizontalScrollController.removeListener(_handleHorizontalScroll);
    _logic.dispose();
    super.dispose();
  }

  void _handleHorizontalScroll() {
    if (_logic.overlayEntry != null) _logic.removeOverlay();
  }

  void _handleScroll() {
    if (_logic.isLoadingMoreNotifier.value) return;
    if (_logic.verticalScrollController.position.pixels >=
        _logic.verticalScrollController.position.maxScrollExtent - 150) {
      _logic.loadMore(context);
    }
  }

  // Header Cell Widget
  Widget _buildHeaderCell(String text, double width, {String? sortColumn}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ValueListenableBuilder<String>(
          valueListenable: _logic.sortColumnNotifier,
          builder: (context, currentSortColumn, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _logic.sortAscendingNotifier,
              builder: (context, isAscending, __) {
                final bool isActive = sortColumn != null && currentSortColumn == sortColumn;

                return GestureDetector(
                  onTap: sortColumn == null ? null : () {
                    if (_logic.sortColumnNotifier.value == sortColumn) {
                      _logic.sortAscendingNotifier.value = !_logic.sortAscendingNotifier.value;
                    } else {
                      _logic.sortColumnNotifier.value = sortColumn!;
                      _logic.sortAscendingNotifier.value = true;
                    }
                  },
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
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (sortColumn != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              isActive
                                  ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 12,
                              color: Colors.white,
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

  // Content Cell Widget
  Widget _buildContentCell(String text, double width, {Widget? child, TextStyle? textStyle}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Center(
          child: child ?? 
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

  // Vendor Filter Field
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
                valueListenable: _logic.selectedVendorNotifier,
                builder: (context, selectedVendor, _) {
                  return Autocomplete<String>(
                    displayStringForOption: (option) => option,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final options = [
                        'All Vendors',
                        ...provider.payments
                            .map((p) => p.vendorName ?? '')
                            .where((name) => name.isNotEmpty)
                            .toSet()
                            .toList(),
                      ];
                      if (textEditingValue.text.isEmpty) return options;
                      return options.where(
                        (vendor) => vendor.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Filter by Vendor',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 10, right: 6),
                            child: Icon(Icons.person, size: 18, color: Colors.black54),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          suffixIcon: controller.text.isNotEmpty && controller.text != 'All Vendors'
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    controller.clear();
                                    _logic.handleVendorSelected(null, context);
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(top: 6, bottom: 0, left: 5, right: 5),
                        ),
                        onTap: () {
                          if (controller.text == 'All Vendors') controller.clear();
                        },
                      );
                    },
                    onSelected: (selected) => _logic.handleVendorSelected(selected, context),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Text(option, style: const TextStyle(fontSize: 13)),
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

  // Invoice Search Field
  Widget _buildInvoiceSearchField(OutgoingPaymentProvider provider) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _logic.invoiceSearchController,
      builder: (context, value, _) {
        return SizedBox(
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _logic.invoiceSearchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by Invoice',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 6),
                  child: Icon(Icons.search, size: 18, color: Colors.black54),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _logic.invoiceSearchController.clear();
                          _logic.handleInvoiceSelected(null, context);
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 6, bottom: 0, left: 5, right: 5),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _logic.invoiceSearchController.text) {
                    _logic.handleInvoiceSelected(value, context);
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  // Multiple Payment Button
  Widget _buildMultiplePaymentButton(List<Outgoing> filteredPayments) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: _logic.selectedIndicesNotifier,
      builder: (context, selectedIndices, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.payments,
                size: 22,
                color: selectedIndices.length >= 2 ? Colors.blueAccent : Colors.grey,
              ),
              tooltip: selectedIndices.length >= 2
                  ? 'Process Selected Payments'
                  : 'Select 2 or more items to enable',
              onPressed: selectedIndices.length >= 2
                  ? () {
                      final selectedPayments = selectedIndices
                          .map((index) => filteredPayments[index])
                          .toList();
                      _logic.showPaymentDialog(context, selectedPayments, null, true);
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

  // Data Row
  Widget _buildDataRow(
    int index,
    Outgoing outgoing,
    Map<String, GRN> grnMap,
    Map<String, ApInvoice> apMap,
    List<double> columnWidths,
  ) {
    final GlobalKey cellKey = GlobalKey();
    final dueDays = _logic.calculateDueDays(outgoing);
    final grn = grnMap[outgoing.grnId];
    final ap = apMap[outgoing.invoiceId];
    final grnDisplay = grn?.randomId ?? outgoing.grnId ?? 'N/A';
    final apDisplay = ap?.randomId ?? outgoing.invoiceId ?? 'N/A';

    return Row(
      children: [
        _buildContentCell('${index + 1}', columnWidths[0]),
        
        _buildContentCell(
          '',
          columnWidths[1],
          child: ValueListenableBuilder<List<bool>>(
            valueListenable: _logic.selectedRowsNotifier,
            builder: (context, selectedRows, _) {
              if (selectedRows.isEmpty || index >= selectedRows.length) {
                return const Checkbox(value: false, onChanged: null);
              }
              final isSelected = selectedRows[index];
              return Checkbox(
                value: isSelected,
                activeColor: Colors.blue,
                checkColor: Colors.white,
                onChanged: (value) {
                  final newSelectedRows = List<bool>.from(selectedRows);
                  if (index < newSelectedRows.length) {
                    newSelectedRows[index] = value ?? false;
                    _logic.selectedRowsNotifier.value = newSelectedRows;

                    final newSelectedIndices = Set<int>.from(_logic.selectedIndicesNotifier.value);
                    if (value == true) newSelectedIndices.add(index);
                    else newSelectedIndices.remove(index);
                    _logic.selectedIndicesNotifier.value = newSelectedIndices;
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
            icon: const Icon(Icons.remove_red_eye, color: Colors.blue, size: 18),
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
            valueListenable: _logic.selectedIndicesNotifier,
            builder: (context, selectedIndices, _) {
              return IconButton(
                icon: Icon(
                  Icons.payment,
                  color: selectedIndices.length > 1 ? Colors.grey : Colors.blue,
                  size: 18,
                ),
                onPressed: selectedIndices.length > 1
                    ? null
                    : () => _logic.showPaymentDialog(context, [outgoing], index, false),
              );
            },
          ),
        ),

        _buildContentCell(
          '',
          columnWidths[4],
          child: _logic.loadingPdfMap[index] == true
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 18),
                  onPressed: () => _logic.handlePdfClick(context, index, outgoing),
                ),
        ),

        _buildContentCell(
          dueDays.toString(),
          columnWidths[5],
          textStyle: TextStyle(
            fontSize: 12,
            color: dueDays < 0 ? Colors.red : dueDays <= 3 ? Colors.orange : Colors.green,
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
            onTap: () => _logic.showGrnDetailsDialog(
              context, outgoing.grnId, grnMap.values.toList(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                grnDisplay,
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
            onTap: () => _logic.showApDetailsDialog(
              context, outgoing.invoiceId, apMap.values.toList(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                apDisplay,
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
          outgoing.totalPrice?.toStringAsFixed(2) ?? 'N/A',
          columnWidths[11],
        ),

        _buildContentCell(
          '',
          columnWidths[12],
          child: GestureDetector(
            onTap: () => _logic.showTaxTooltip(context, cellKey, outgoing, index),
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
                ),
                textAlign: TextAlign.center,
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

  Future<void> _onRefresh() async => _logic.loadData(context);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _logic.overlayEntry == null,
      onPopInvoked: (didPop) {
        if (_logic.overlayEntry != null) _logic.removeOverlay();
      },
      child: ScaffoldMessenger(
        key: _logic.scaffoldMessengerKey,
        child: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: _logic.refreshDataNotifier,
            builder: (context, refreshData, _) {
              return Consumer<OutgoingPaymentProvider>(
                builder: (context, provider, child) {
                  final List<Outgoing> filtered = provider.payments;
                  final Map<String, GRN> grnMap = {
                    for (var g in provider.grnList) if (g.grnId != null) g.grnId!: g,
                  };
                  final Map<String, ApInvoice> apMap = {
                    for (var a in provider.apInvoices) if (a.invoiceId != null) a.invoiceId!: a,
                  };

                  if (provider.isLoadingOutgoings && provider.payments.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!provider.isLoadingOutgoings && filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending outgoing',
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    );
                  }

                  final sortedPayments = _logic.sortPayments(filtered);

                  const columnWidths = <double>[
                    45, 50, 45, 50, 50, 150, 150, 85, 95, 85, 85, 95, 85, 85, 85, 95, 85, 150,
                  ];
                  final totalWidth = columnWidths.reduce((a, b) => a + b);

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    displacement: 60,
                    color: Colors.blueAccent,
                    child: Scrollbar(
                      controller: _logic.mainScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _logic.mainScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Payable Amount: ${sortedPayments.fold(0.0, (sum, p) => sum + (p.totalPayableAmount ?? 0.0)).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
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
                                            _buildMultiplePaymentButton(sortedPayments),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ValueListenableBuilder<Set<int>>(
                                                valueListenable: _logic.selectedIndicesNotifier,
                                                builder: (context, selectedIndices, _) {
                                                  if (selectedIndices.length > 1) {
                                                    final amount = selectedIndices.fold(
                                                      0.0,
                                                      (sum, index) => sum + (sortedPayments[index].totalPayableAmount ?? 0.0),
                                                    );
                                                    return Text(
                                                      'Selected Amount: ${amount.toStringAsFixed(2)}',
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
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
                                              Expanded(child: _buildVendorFilterField(provider)),
                                              const SizedBox(width: 8),
                                              Expanded(child: _buildInvoiceSearchField(provider)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _buildMultiplePaymentButton(sortedPayments),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ValueListenableBuilder<Set<int>>(
                                                  valueListenable: _logic.selectedIndicesNotifier,
                                                  builder: (context, selectedIndices, _) {
                                                    if (selectedIndices.length > 1) {
                                                      final amount = selectedIndices.fold(
                                                        0.0,
                                                        (sum, index) => sum + (sortedPayments[index].totalPayableAmount ?? 0.0),
                                                      );
                                                      return Text(
                                                        'Selected Amount: ${amount.toStringAsFixed(2)}',
                                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
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
                              valueListenable: _logic.selectedVendorNotifier,
                              builder: (context, selectedVendor, _) {
                                return ValueListenableBuilder<String?>(
                                  valueListenable: _logic.selectedInvoiceNotifier,
                                  builder: (context, selectedInvoice, _) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              Scrollbar(
                                                controller: _logic.horizontalScrollController,
                                                thumbVisibility: true,
                                                child: SingleChildScrollView(
                                                  controller: _logic.horizontalScrollController,
                                                  scrollDirection: Axis.horizontal,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        decoration: const BoxDecoration(color: Colors.blueAccent),
                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                        child: SizedBox(
                                                          width: totalWidth,
                                                          child: Row(
                                                            children: [
                                                              _buildHeaderCell('No', columnWidths[0]),
                                                              _buildHeaderCell('Select', columnWidths[1]),
                                                              _buildHeaderCell('View', columnWidths[2]),
                                                              _buildHeaderCell('Action', columnWidths[3]),
                                                              _buildHeaderCell('Pdf', columnWidths[4]),
                                                              _buildHeaderCell('Due Days', columnWidths[5], sortColumn: 'dueDays'),
                                                              _buildHeaderCell('Vendor Name', columnWidths[6]),
                                                              _buildHeaderCell('Invoice No', columnWidths[7]),
                                                              _buildHeaderCell('Invoice Date', columnWidths[8]),
                                                              _buildHeaderCell('GRN No', columnWidths[9]),
                                                              _buildHeaderCell('AP No', columnWidths[10]),
                                                              _buildHeaderCell('Total Amount', columnWidths[11]),
                                                              _buildHeaderCell('Tax', columnWidths[12]),
                                                              _buildHeaderCell('Discount', columnWidths[13]),
                                                              _buildHeaderCell('Total', columnWidths[14]),
                                                              _buildHeaderCell('Paid Amount', columnWidths[15]),
                                                              _buildHeaderCell('Remaining', columnWidths[16]),
                                                              _buildHeaderCell('Payment Terms', columnWidths[17], sortColumn: 'paymentTerms'),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 360,
                                                        child: ValueListenableBuilder<bool>(
                                                          valueListenable: _logic.isLoadingMoreNotifier,
                                                          builder: (context, isLoadingMore, _) {
                                                            return Scrollbar(
                                                              controller: _logic.verticalScrollController,
                                                              thumbVisibility: true,
                                                              child: SizedBox(
                                                                width: totalWidth,
                                                                child: ListView.builder(
                                                                  controller: _logic.verticalScrollController,
                                                                  itemCount: sortedPayments.length + (isLoadingMore ? 1 : 0),
                                                                  itemBuilder: (context, index) {
                                                                    if (index >= sortedPayments.length) {
                                                                      return Container(
                                                                        height: 70,
                                                                        alignment: Alignment.center,
                                                                        child: const CircularProgressIndicator(strokeWidth: 2),
                                                                      );
                                                                    }
                                                                    return _buildDataRow(
                                                                      index,
                                                                      sortedPayments[index],
                                                                      grnMap,
                                                                      apMap,
                                                                      columnWidths,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (provider.isTableLoading)
                                            Positioned.fill(
                                              child: Container(
                                                color: Colors.white.withOpacity(0.6),
                                                child: const Center(child: CircularProgressIndicator()),
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