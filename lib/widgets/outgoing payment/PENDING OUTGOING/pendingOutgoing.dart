// ignore_for_file: unnecessary_to_list_in_spreads, unnecessary_brace_in_string_interps, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/OutgoingColumnFilter.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/PENDING%20OUTGOING/pending%20_outgoing_view_dialog.dart';
import 'package:provider/provider.dart';
import '../../../providers/outgoing_payment_provider.dart';
import 'pending_outgoing_logic.dart';

class PendingOutgoing extends StatefulWidget {
  final String filterStatus;
  const PendingOutgoing({super.key, required this.filterStatus});

  @override
  State<PendingOutgoing> createState() => _PendingOutgoingState();
}

class _PendingOutgoingState extends State<PendingOutgoing> {
  late final PendingOutgoingLogic _logic;

  // Column filter state variables
  late ValueNotifier<List<String>> _visibleColumnsNotifier;
  late ValueNotifier<Map<String, bool>> _columnVisibilityNotifier;

  // Selected amount state with setState
  double _selectedAmount = 0.0;
  int _selectedCount = 0;
  bool _isSorting = false;
  // Define all available columns
  final List<String> _allColumns = const [
    'S.No',
    'Select',
    'PO No',
    'GRN No',
    'AP No',
    'Outgoing No',
    'Vendor Name',
    'Type',
    'Invoice No',
    'Invoice Date',
    'Total Amount',
    'Tax',
    'Discount',
    'Total',
    'Paid Amount',
    'Remaining',
    'Due Days',
    'Payment Terms',
    'Action',
    'View',
    'PDF',
  ];
  // Column widths mapping
  final Map<String, double> _columnWidths = const {
    'S.No': 45,
    'Select': 50,
    'PO No': 120,
    'Outgoing No': 120,
    'Type': 100,
    'View': 45,
    'Action': 50,
    'PDF': 50,
    'Due Days': 150,
    'Vendor Name': 150,
    'Invoice No': 85,
    'Invoice Date': 110,
    'GRN No': 85,
    'AP No': 85,
    'Total Amount': 95,
    'Tax': 85,
    'Discount': 85,
    'Total': 85,
    'Paid Amount': 95,
    'Remaining': 85,
    'Payment Terms': 100,
  };

  @override
  void initState() {
    super.initState();
    _logic = PendingOutgoingLogic();
    _logic.sortColumnNotifier.addListener(_refreshSorting);
    _logic.sortAscendingNotifier.addListener(_refreshSorting);
    _logic.horizontalScrollController.addListener(_handleHorizontalScroll);
    _logic.verticalScrollController.addListener(_handleScroll);
    _logic.selectedRowsNotifier.value = [];

    // Listen to selected indices changes and update state
    _logic.selectedIndicesNotifier.addListener(_updateSelectedAmount);

    // Initialize column visibility (default all visible)
    _visibleColumnsNotifier = ValueNotifier(List.from(_allColumns));
    _columnVisibilityNotifier = ValueNotifier(
      Map.fromEntries(_allColumns.map((col) => MapEntry(col, true))),
    );

    // Load saved preferences from shared preferences if needed
    _loadColumnPreferences();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logic.loadInitialData(context);
    });
  }

  void _updateSelectedAmount() {
    final selectedIndices = _logic.selectedIndicesNotifier.value;
    final provider = context.read<OutgoingPaymentProvider>();
    final filtered = provider.payments;
    final sortedPayments = _logic.sortPayments(filtered);

    double total = 0.0;
    for (int index in selectedIndices) {
      if (index < sortedPayments.length) {
        total += sortedPayments[index].totalPayableAmount ?? 0.0;
      }
    }

    setState(() {
      _selectedAmount = total;
      _selectedCount = selectedIndices.length;
    });
  }

  void _loadColumnPreferences() {
    // You can load from SharedPreferences here
    // For now, keeping all columns visible
  }

  void _refreshSorting() async {
    if (!mounted) return;

    setState(() {
      _isSorting = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isSorting = false;
    });
  }

  void _saveColumnPreferences(
    List<String> columns,
    Map<String, bool> visibility,
  ) {
    // Save to SharedPreferences if needed
  }

  void _showColumnFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => OutgoingColumnFilter(
        allColumns: _allColumns,
        columnVisibility: _columnVisibilityNotifier.value,
        onApply: (updatedColumns, updatedVisibility) {
          setState(() {
            _visibleColumnsNotifier.value = updatedColumns
                .where((col) => updatedVisibility[col] ?? false)
                .toList();
            _columnVisibilityNotifier.value = updatedVisibility;
            _saveColumnPreferences(updatedColumns, updatedVisibility);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _logic.horizontalScrollController.removeListener(_handleHorizontalScroll);

    _logic.selectedIndicesNotifier.removeListener(_updateSelectedAmount);

    _logic.sortColumnNotifier.removeListener(_refreshSorting);
    _logic.sortAscendingNotifier.removeListener(_refreshSorting);

    _logic.dispose();

    _visibleColumnsNotifier.dispose();
    _columnVisibilityNotifier.dispose();

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
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ValueListenableBuilder<String>(
          valueListenable: _logic.sortColumnNotifier,
          builder: (context, currentSortColumn, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _logic.sortAscendingNotifier,
              builder: (context, isAscending, __) {
                final bool isActive =
                    sortColumn != null && currentSortColumn == sortColumn;

                return GestureDetector(
                  onTap: (text == 'Select' || sortColumn == null)
                      ? null
                      : () {
                          if (_logic.sortColumnNotifier.value == sortColumn) {
                            _logic.sortAscendingNotifier.value =
                                !_logic.sortAscendingNotifier.value;
                          } else {
                            _logic.sortColumnNotifier.value = sortColumn;
                            _logic.sortAscendingNotifier.value = true;
                          }
                        },
                  child: Tooltip(
                    message: text,
                    child: text == 'Select'
                        ? ValueListenableBuilder<List<bool>>(
                            valueListenable: _logic.selectedRowsNotifier,
                            builder: (context, selectedRows, _) {
                              final allSelected =
                                  selectedRows.isNotEmpty &&
                                  selectedRows.every((e) => e == true);

                              return Checkbox(
                                value: allSelected,
                                activeColor: Colors.white,
                                checkColor: Colors.blue,
                                onChanged: (value) {
                                  final provider = context
                                      .read<OutgoingPaymentProvider>();
                                  final count = provider.payments.length;
                                  final newList = List<bool>.filled(
                                    count,
                                    value ?? false,
                                  );
                                  _logic.selectedRowsNotifier.value = newList;

                                  if (value == true) {
                                    _logic.selectedIndicesNotifier.value =
                                        Set.from(
                                          List.generate(count, (i) => i),
                                        );
                                  } else {
                                    _logic.selectedIndicesNotifier.value = {};
                                  }
                                },
                              );
                            },
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (sortColumn != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Icon(
                                    isActive
                                        ? (isAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward)
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

  // Vendor Filter Field (Without Icon, Same shape as Column Filter)
  Widget _buildVendorFilterField(OutgoingPaymentProvider provider) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
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
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
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
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              suffixIcon:
                                  controller.text.isNotEmpty &&
                                      controller.text != 'All Vendors'
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        _logic.handleVendorSelected(
                                          null,
                                          context,
                                        );
                                        FocusScope.of(context).unfocus();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onTap: () {
                              if (controller.text == 'All Vendors') {
                                controller.clear();
                              }
                            },
                          );
                        },
                    onSelected: (selected) =>
                        _logic.handleVendorSelected(selected, context),
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

  // Invoice Search Field (Without Icon, Same shape as Column Filter)
  Widget _buildInvoiceSearchField(OutgoingPaymentProvider provider) {
    return Expanded(
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _logic.invoiceSearchController,
        builder: (context, value, _) {
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _logic.invoiceSearchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by Invoice',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _logic.invoiceSearchController.text) {
                    _logic.handleInvoiceSelected(value, context);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildColumnFilterButton() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: _showColumnFilterDialog,
        icon: const Icon(Icons.view_column, size: 20, color: Colors.blueAccent),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildMultiplePaymentButton(List<Outgoing> filteredPayments) {
    final permission = context.read<PermissionProvider>();

    final canPay = permission.hasPermission('outgoingpayment', '', 'edit');

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
                color: (!canPay || selectedIndices.length < 2)
                    ? Colors.grey
                    : Colors.blueAccent,
              ),
              tooltip: !canPay
                  ? 'No permission'
                  : selectedIndices.length >= 2
                  ? 'Process Selected Payments'
                  : 'Select 2 or more items to enable',
              onPressed: (!canPay || selectedIndices.length < 2)
                  ? null
                  : () {
                      final selectedPayments = selectedIndices
                          .map((index) => filteredPayments[index])
                          .toList();

                      _logic.showPaymentDialog(
                        context,
                        selectedPayments,
                        null,
                        true,
                      );
                    },
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
    Map<String, GRN> grnMap,
    Map<String, ApInvoice> apMap,
    List<String> visibleColumns,
  ) {
    final GlobalKey cellKey = GlobalKey();
    final dueDays = _logic.calculateDueDays(outgoing);
    final grn = grnMap[outgoing.grnId];
    final ap = apMap[outgoing.invoiceId];
    final bool isGrnLoading = outgoing.grnId != null && grn == null;
    final bool isApLoading = outgoing.invoiceId != null && ap == null;

    return Row(
      children: visibleColumns.map((column) {
        final width = _columnWidths[column] ?? 100;
        return _buildDynamicCell(
          column: column,
          index: index,
          outgoing: outgoing,
          grn: grn,
          ap: ap,
          isGrnLoading: isGrnLoading,
          isApLoading: isApLoading,
          dueDays: dueDays,
          cellKey: cellKey,
          width: width,
        );
      }).toList(),
    );
  }

  Widget _buildDynamicCell({
    required String column,
    required int index,
    required Outgoing outgoing,
    required GRN? grn,
    required ApInvoice? ap,
    required bool isGrnLoading,
    required bool isApLoading,
    required int dueDays,
    required GlobalKey cellKey,
    required double width,
  }) {
    switch (column) {
      case 'S.No':
        return _buildContentCell('${index + 1}', width);

      case 'Select':
        return _buildContentCell(
          '',
          width,
          child: ValueListenableBuilder<List<bool>>(
            valueListenable: _logic.selectedRowsNotifier,
            builder: (context, selectedRows, _) {
              if (selectedRows.isEmpty || index >= selectedRows.length) {
                return const Checkbox(value: false, onChanged: null);
              }
              return Checkbox(
                value: selectedRows[index],
                activeColor: Colors.blue,
                checkColor: Colors.white,
                onChanged: (value) {
                  final newSelectedRows = List<bool>.from(selectedRows);
                  if (index < newSelectedRows.length) {
                    newSelectedRows[index] = value ?? false;
                    _logic.selectedRowsNotifier.value = newSelectedRows;

                    final newSelectedIndices = Set<int>.from(
                      _logic.selectedIndicesNotifier.value,
                    );
                    if (value == true) {
                      newSelectedIndices.add(index);
                    } else {
                      newSelectedIndices.remove(index);
                    }
                    _logic.selectedIndicesNotifier.value = newSelectedIndices;
                    _updateSelectedAmount();
                  }
                },
              );
            },
          ),
        );

      case 'View':
        return _buildContentCell(
          '',
          width,
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
        );

      case 'Action':
        return _buildContentCell(
          '',
          width,
          child: ValueListenableBuilder<Set<int>>(
            valueListenable: _logic.selectedIndicesNotifier,
            builder: (context, selectedIndices, _) {
              final isMultiSelect = selectedIndices.length > 1;
              final isVerified =
                  ap != null &&
                  ap.verifiedBy != null &&
                  ap.verifiedBy!.isNotEmpty;

              final GlobalKey iconKey = GlobalKey();

              return IconButton(
                key: iconKey,
                icon: Icon(
                  Icons.payment,
                  color: isMultiSelect
                      ? Colors.grey
                      : isVerified
                      ? Colors.blue
                      : Colors.grey,
                  size: 18,
                ),
                onPressed: isMultiSelect
                    ? null
                    : () {
                        if (!isVerified) {
                          _logic.showPaymentTooltip(context, iconKey);
                          return;
                        }

                        _logic.showPaymentDialog(
                          context,
                          [outgoing],
                          index,
                          false,
                        );
                      },
              );
            },
          ),
        );
      case 'PDF':
        return _buildContentCell(
          '',
          width,
          child: _logic.loadingPdfMap[index] == true
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.blue,
                    size: 18,
                  ),
                  onPressed: () =>
                      _logic.handlePdfClick(context, index, outgoing),
                ),
        );

      case 'Due Days':
        return _buildContentCell(
          dueDays.toString(),
          width,
          textStyle: TextStyle(
            fontSize: 12,
            color: dueDays < 0
                ? Colors.red
                : dueDays <= 3
                ? Colors.orange
                : Colors.green,
          ),
        );

      case 'Vendor Name':
        return _buildContentCell(outgoing.vendorName ?? 'N/A', width);

      case 'Invoice No':
        return _buildContentCell(outgoing.invoiceNo ?? 'N/A', width);

      case 'Invoice Date':
        return _buildContentCell(
          outgoing.invoiceDate != null
              ? DateFormat('dd-MM-yyyy').format(outgoing.invoiceDate!)
              : 'N/A',
          width,
        );

      case 'GRN No':
        return _buildContentCell(
          '',
          width,
          child: GestureDetector(
            onTap: () => _logic.showGrnDetailsDialog(
              context,
              outgoing.grnId,
              grn != null ? [grn] : [],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isGrnLoading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      grn?.randomId ?? '-',
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
        );

      case 'AP No':
        return _buildContentCell(
          '',
          width,
          child: GestureDetector(
            onTap: () => _logic.showApDetailsDialog(
              context,
              outgoing.invoiceId,
              ap != null ? [ap] : [],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isApLoading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      ap?.randomId ?? '-',
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
        );

      case 'Total Amount':
        return _buildContentCell(
          outgoing.totalPrice?.toStringAsFixed(2) ?? 'N/A',
          width,
        );

      case 'Tax':
        return _buildContentCell(
          '',
          width,
          child: GestureDetector(
            onTap: () =>
                _logic.showTaxTooltip(context, cellKey, outgoing, index),
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
        );

      case 'Discount':
        return _buildContentCell(
          outgoing.discountDetails?.toStringAsFixed(2) ?? '0.00',
          width,
        );

      case 'Total':
        return _buildContentCell(
          outgoing.payableAmount?.toStringAsFixed(2) ?? 'N/A',
          width,
        );

      case 'Paid Amount':
        return _buildContentCell(
          (outgoing.totalPaidAmount ?? 0.0).toStringAsFixed(2),
          width,
        );

      case 'Remaining':
        return _buildContentCell(
          outgoing.totalPayableAmount?.toStringAsFixed(2) ?? 'N/A',
          width,
        );

      case 'Payment Terms':
        return _buildContentCell(outgoing.paymentTerms ?? 'N/A', width);

      case 'PO No':
        return _buildContentCell(
          outgoing.poRandomId ?? outgoing.purchaseOrderId ?? 'N/A',
          width,
        );
      case 'Outgoing No':
        return _buildContentCell(outgoing.randomId ?? 'N/A', width);
      case 'Type':
        return _buildContentCell(outgoing.invoiceType ?? 'N/A', width);

      default:
        return _buildContentCell('', width);
    }
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
                  if (provider.error.isNotEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                provider.error,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () async {
                                  await provider.fetchFilteredOutgoings(
                                    status: 'Pending',
                                    filterBy: 'invoiceDate',
                                    limit: 100,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final List<Outgoing> filtered = provider.payments;
                  final Map<String, GRN> grnMap = {
                    for (var g in provider.grnList)
                      if (g.grnId != null) g.grnId!: g,
                  };
                  final Map<String, ApInvoice> apMap = {
                    for (var a in provider.apInvoices)
                      if (a.invoiceId != null) a.invoiceId!: a,
                  };

                  if (provider.isLoadingOutgoings &&
                      provider.payments.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // if (!provider.isLoadingOutgoings && filtered.isEmpty) {
                  //   return const Center(
                  //     child: Text(
                  //       'No pending outgoing',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         color: Colors.grey,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   );
                  // }

                  final sortedPayments = _logic.sortPayments(filtered);
                  final totalWidth = _visibleColumnsNotifier.value.fold<double>(
                    0,
                    (sum, col) => sum + (_columnWidths[col] ?? 100),
                  );

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
                                  const Row(
                                    children: [
                                      Text(
                                        'PENDING OUTGOING',
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Payable Amount: ₹${sortedPayments.fold(0.0, (sum, p) => sum + (p.totalPayableAmount ?? 0.0)).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildVendorFilterField(provider),
                                      const SizedBox(width: 8),
                                      _buildInvoiceSearchField(provider),
                                      const SizedBox(width: 8),
                                      _buildColumnFilterButton(),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      _buildMultiplePaymentButton(
                                        sortedPayments,
                                      ),
                                      const Spacer(),
                                      if (_selectedCount > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Selected (${_selectedCount}) : ₹${_selectedAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            ValueListenableBuilder<List<String>>(
                              valueListenable: _visibleColumnsNotifier,
                              builder: (context, visibleColumns, _) {
                                return ValueListenableBuilder<String?>(
                                  valueListenable:
                                      _logic.selectedVendorNotifier,
                                  builder: (context, selectedVendor, _) {
                                    return ValueListenableBuilder<String?>(
                                      valueListenable:
                                          _logic.selectedInvoiceNotifier,
                                      builder: (context, selectedInvoice, _) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Stack(
                                            children: [
                                              Column(
                                                children: [
                                                  Scrollbar(
                                                    controller: _logic
                                                        .horizontalScrollController,
                                                    thumbVisibility: true,
                                                    child: SingleChildScrollView(
                                                      controller: _logic
                                                          .horizontalScrollController,
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color: Colors
                                                                      .blueAccent,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 16,
                                                                ),
                                                            child: SizedBox(
                                                              width: totalWidth,
                                                              child: Row(
                                                                children: visibleColumns.map((
                                                                  column,
                                                                ) {
                                                                  final sortKey =
                                                                      _getSortKeyForColumn(
                                                                        column,
                                                                      );
                                                                  return _buildHeaderCell(
                                                                    column,
                                                                    _columnWidths[column] ??
                                                                        100,
                                                                    sortColumn:
                                                                        sortKey,
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 360,
                                                            child: ValueListenableBuilder<bool>(
                                                              valueListenable:
                                                                  _logic
                                                                      .isLoadingMoreNotifier,
                                                              builder:
                                                                  (
                                                                    context,
                                                                    isLoadingMore,
                                                                    _,
                                                                  ) {
                                                                    // EMPTY TABLE STATE
                                                                    if (sortedPayments
                                                                        .isEmpty) {
                                                                      return SizedBox(
                                                                        width:
                                                                            totalWidth,
                                                                        height:
                                                                            250,
                                                                        child: const Center(
                                                                          child: Text(
                                                                            'No matching records found',
                                                                            style: TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.grey,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }

                                                                    return Scrollbar(
                                                                      controller:
                                                                          _logic
                                                                              .verticalScrollController,
                                                                      thumbVisibility:
                                                                          true,
                                                                      child: SizedBox(
                                                                        width:
                                                                            totalWidth,
                                                                        child: ListView.builder(
                                                                          controller:
                                                                              _logic.verticalScrollController,
                                                                          itemCount:
                                                                              sortedPayments.length +
                                                                              (isLoadingMore
                                                                                  ? 1
                                                                                  : 0),
                                                                          itemBuilder:
                                                                              (
                                                                                context,
                                                                                index,
                                                                              ) {
                                                                                if (index >=
                                                                                    sortedPayments.length) {
                                                                                  return Container(
                                                                                    height: 70,
                                                                                    alignment: Alignment.center,
                                                                                    child: const CircularProgressIndicator(
                                                                                      strokeWidth: 2,
                                                                                    ),
                                                                                  );
                                                                                }

                                                                                return _buildDataRow(
                                                                                  index,
                                                                                  sortedPayments[index],
                                                                                  grnMap,
                                                                                  apMap,
                                                                                  visibleColumns,
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
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                                ),
                                              if (_isSorting)
                                                Positioned.fill(
                                                  child: Container(
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
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

  String? _getSortKeyForColumn(String column) {
    switch (column) {
      case 'Due Days':
        return 'dueDays';
      case 'Payment Terms':
        return 'paymentTerms';
      case 'Invoice Date':
        return 'invoiceDate';
      default:
        return null;
    }
  }
}
