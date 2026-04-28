import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';

import '../../../models/outgoing.dart';
import '../../../providers/outgoing_payment_provider.dart';

class Ledger extends StatefulWidget {
  final String status;
  final DateTime? fromDate;
  final DateTime? toDate;

  const Ledger({super.key, required this.status, this.fromDate, this.toDate});

  @override
  State<Ledger> createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  Timer? _debounceTimer;

  // ValueNotifiers for all state management
  final ValueNotifier<List<Outgoing>> _filteredPaymentsNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _hasErrorNotifier = ValueNotifier(false);
  final ValueNotifier<String> _errorMessageNotifier = ValueNotifier('');
  final ValueNotifier<bool> _loadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<Map<int, bool>> _loadingPdfNotifier = ValueNotifier({});
  final ValueNotifier<List<String>> _columnOrderNotifier = ValueNotifier([]);
  final ValueNotifier<Map<String, bool>> _columnVisibilityNotifier =
      ValueNotifier({});
  final ValueNotifier<DateTime?> _fromDateNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> _toDateNotifier = ValueNotifier(null);

  // Pagination
  int _skip = 0;
  final int _limit = 50;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeColumnSettings();
    _setupScrollListener();
    _searchFocusNode = FocusNode();
    _fromDateNotifier.value = widget.fromDate;
    _toDateNotifier.value = widget.toDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initializeColumnSettings() {
    _columnOrderNotifier.value = [
      'PDF',
      'Payment Date',
      'Vendor Name',
      'Payment Method',
      'Reference No',
      'Invoice No',
      'Invoice Date',
      'Total Amount',
      'Paid Amount',
      'Remaining Amount',
      'Status',
    ];

    _columnVisibilityNotifier.value = {
      'PDF': true,
      'Payment Date': true,
      'Vendor Name': true,
      'Payment Method': true,
      'Reference No': true,
      'Invoice No': true,
      'Invoice Date': true,
      'Total Amount': true,
      'Paid Amount': true,
      'Remaining Amount': true,
      'Status': true,
    };
  }

  void _setupScrollListener() {
    _verticalScrollController.addListener(() {
      if (_verticalScrollController.position.pixels >=
          _verticalScrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _debounceTimer?.cancel();
    _filteredPaymentsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasErrorNotifier.dispose();
    _errorMessageNotifier.dispose();
    _loadingMoreNotifier.dispose();
    _loadingPdfNotifier.dispose();
    _columnOrderNotifier.dispose();
    _columnVisibilityNotifier.dispose();
    _fromDateNotifier.dispose();
    _toDateNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _filterPayments();
    });
  }

  @override
  void didUpdateWidget(covariant Ledger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.fromDate != widget.fromDate ||
        oldWidget.toDate != widget.toDate) {
      _fromDateNotifier.value = widget.fromDate;
      _toDateNotifier.value = widget.toDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final provider = Provider.of<OutgoingPaymentProvider>(
        context,
        listen: false,
      );

      _isLoadingNotifier.value = true;
      _hasErrorNotifier.value = false;
      _skip = 0;

      await provider.fetchAllOutgoings();

      _skip += _limit;
      if (!mounted) return;

      _filterPayments();
      _isLoadingNotifier.value = false;
    } catch (e) {
      if (!mounted) return;
      _isLoadingNotifier.value = false;
      _hasErrorNotifier.value = true;
      _errorMessageNotifier.value = 'Error loading data: $e';
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMoreNotifier.value) return;

    _loadingMoreNotifier.value = true;

    final provider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );

    await provider.fetchAllOutgoings(
      fromDate: _fromDateNotifier.value,
      toDate: _toDateNotifier.value,
    );

    _filterPayments();
    _loadingMoreNotifier.value = false;
  }

  void _filterPayments() {
    if (!mounted) return;

    final provider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );

    final query = _searchController.text.toLowerCase();
    final fromDate = _fromDateNotifier.value;
    final toDate = _toDateNotifier.value;

    _filteredPaymentsNotifier.value = provider.payments.where((payment) {
      // ✅ DATE FILTER USING INVOICE DATE
      if (fromDate != null && toDate != null) {
        final invoiceDate = payment.invoiceDate?.toLocal();
        if (invoiceDate == null) return false;

        final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
        final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

        if (invoiceDate.isBefore(start) || invoiceDate.isAfter(end)) {
          return false;
        }
      }

      // ✅ SEARCH FILTER
      if (query.isNotEmpty) {
        final vendorName = payment.vendorName?.toLowerCase() ?? '';
        final invoiceNo = payment.invoiceNo?.toLowerCase() ?? '';
        final neftNo = payment.neftNo?.toLowerCase() ?? '';
        final paymentMethod = payment.paymentMethod?.toLowerCase() ?? '';

        return vendorName.contains(query) ||
            invoiceNo.contains(query) ||
            neftNo.contains(query) ||
            paymentMethod.contains(query);
      }

      return true;
    }).toList();
  }

  String _formatDate(DateTime? date) =>
      date != null ? DateFormat('dd-MM-yyyy').format(date) : 'N/A';

  String _formatCurrency(double? amount) => amount != null
      ? NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)
      : '0.00';

  double _calculateRemainingAmount(Outgoing p) {
    final totalPayable = p.totalPayableAmount ?? 0;
    final paidAmount = p.totalPaidAmount ?? p.paidAmount ?? 0;
    return (totalPayable - paidAmount).clamp(0, double.infinity);
  }

  double _calculatePaidAmount(Outgoing payment) {
    return payment.totalPaidAmount ?? payment.paidAmount ?? 0.0;
  }

  double _calculateTotalAmount(Outgoing payment) {
    return payment.totalPayableAmount ?? payment.payableAmount ?? 0;
  }

  Future<void> _generatePdf(int index, Outgoing payment) async {
    final currentMap = Map<int, bool>.from(_loadingPdfNotifier.value);
    currentMap[index] = true;
    _loadingPdfNotifier.value = currentMap;

    try {
      final pdfService = OutgoingPdf();
      final pdfFile = await pdfService.generateOutgoingPdf(payment.outgoingId);

      await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      final updatedMap = Map<int, bool>.from(_loadingPdfNotifier.value);
      updatedMap.remove(index);
      _loadingPdfNotifier.value = updatedMap;
    }
  }

  void _openColumnFilter() {
    showDialog(
      context: context,
      builder: (context) => LedgerColumnFilter(
        allColumns: _columnOrderNotifier.value,
        columnVisibility: _columnVisibilityNotifier.value,
        onApply: (newOrder, newVisibility) {
          _columnOrderNotifier.value = newOrder;
          _columnVisibilityNotifier.value = newVisibility;
        },
      ),
    );
  }

  void _clearDateFilter() {
    _fromDateNotifier.value = null;
    _toDateNotifier.value = null;
    _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: ServerTimeService.now,
      initialDateRange:
          _fromDateNotifier.value != null && _toDateNotifier.value != null
          ? DateTimeRange(
              start: _fromDateNotifier.value!,
              end: _toDateNotifier.value!,
            )
          : null,
    );

    if (picked != null) {
      _fromDateNotifier.value = picked.start;
      _toDateNotifier.value = picked.end;
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with search bar, date filter, and column filter icon
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildSearchBar(),
            ),
            // Body section
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, child) {
        final suggestions = provider.payments
            .map((p) => (p.vendorName ?? '').trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        return Row(
          children: [
            /// Search with AutoComplete
            Expanded(
              flex: 2,
              child: RawAutocomplete<String>(
                textEditingController: _searchController,
                focusNode: _searchFocusNode,
                optionsBuilder: (text) {
                  if (text.text.isEmpty) return suggestions;
                  return suggestions.where(
                    (option) =>
                        option.toLowerCase().contains(text.text.toLowerCase()),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search vendor, invoice, reference...',
                          suffix: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: controller,
                            builder: (context, value, _) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  _onSearchChanged();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    left: 4,
                                  ),
                                  child: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.blueAccent,
                              width: 1.2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => _onSearchChanged(),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 250,
                          minWidth: 250,
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: options.map((e) {
                            return InkWell(
                              onTap: () {
                                onSelected(e);
                                FocusScope.of(context).unfocus();
                                _onSearchChanged();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            /// Date Filter
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: _selectDateRange,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _fromDateNotifier,
                          builder: (context, fromDate, _) {
                            return ValueListenableBuilder(
                              valueListenable: _toDateNotifier,
                              builder: (context, toDate, _) {
                                return Text(
                                  fromDate != null && toDate != null
                                      ? "${DateFormat('dd-MM-yyyy').format(fromDate)} - ${DateFormat('dd-MM-yyyy').format(toDate)}"
                                      : "Select Date",
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: _fromDateNotifier,
                        builder: (context, fromDate, _) {
                          return ValueListenableBuilder(
                            valueListenable: _toDateNotifier,
                            builder: (context, toDate, _) {
                              if (fromDate != null && toDate != null) {
                                return GestureDetector(
                                  onTap: _clearDateFilter,
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            /// Column Filter Button
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: IconButton(
                onPressed: _openColumnFilter,
                icon: const Icon(
                  Icons.view_column,
                  size: 20,
                  color: Colors.blueAccent,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder(
      valueListenable: _hasErrorNotifier,
      builder: (context, hasError, _) {
        if (hasError) {
          return _buildErrorWidget();
        }
        return _buildMainContent();
      },
    );
  }

  Widget _buildErrorWidget() {
    return ValueListenableBuilder(
      valueListenable: _errorMessageNotifier,
      builder: (context, errorMessage, _) {
        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
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
                      errorMessage.isNotEmpty
                          ? errorMessage
                          : "Something went wrong. Please try again.",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loadData,
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
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return ValueListenableBuilder(
      valueListenable: _filteredPaymentsNotifier,
      builder: (context, filteredList, _) {
        if (filteredList.isEmpty && !_isLoadingNotifier.value) {
          return _buildEmptyWidget();
        }
        return Stack(
          children: [_buildTableContent(filteredList), _buildLoadingOverlay()],
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 300),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ledger entries found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or date filter',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(List<Outgoing> filteredList) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: ValueListenableBuilder(
          valueListenable: _columnOrderNotifier,
          builder: (context, columnOrder, _) {
            return ValueListenableBuilder(
              valueListenable: _columnVisibilityNotifier,
              builder: (context, columnVisibility, _) {
                return SizedBox(
                  width: _calculateTotalWidth(columnOrder, columnVisibility),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(columnOrder, columnVisibility),
                      Expanded(
                        child: _buildRows(
                          filteredList,
                          columnOrder,
                          columnVisibility,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(children: _buildHeaderRow(columnOrder, columnVisibility)),
    );
  }

  Widget _buildRows(
    List<Outgoing> filteredList,
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'No ledger entries found.',
          style: TextStyle(fontSize: 17, color: Colors.grey),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: _loadingPdfNotifier,
      builder: (context, loadingMap, _) {
        return ValueListenableBuilder(
          valueListenable: _loadingMoreNotifier,
          builder: (context, loadingMore, _) {
            return ListView.builder(
              controller: _verticalScrollController,
              itemCount: filteredList.length + (loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= filteredList.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final payment = filteredList[index];
                final isLoadingPdf = loadingMap[index] == true;
                return _buildRow(
                  payment,
                  index,
                  isLoadingPdf,
                  columnOrder,
                  columnVisibility,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRow(
    Outgoing payment,
    int index,
    bool isLoadingPdf,
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          left: BorderSide(color: Colors.grey.shade300, width: 0.5),
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: _buildDataRow(
          payment,
          index,
          isLoadingPdf,
          columnOrder,
          columnVisibility,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return ValueListenableBuilder(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (!isLoading) return const SizedBox.shrink();
        return Container(
          color: Colors.black.withOpacity(0.3),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  double _calculateTotalWidth(
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    double totalWidth = 70;
    for (var column in columnOrder) {
      if (columnVisibility[column] == true) {
        switch (column) {
          case 'PDF':
            totalWidth += 70;
            break;
          case 'Payment Date':
            totalWidth += 110;
            break;
          case 'Vendor Name':
            totalWidth += 180;
            break;
          case 'Payment Method':
            totalWidth += 120;
            break;
          case 'Reference No':
            totalWidth += 130;
            break;
          case 'Invoice No':
            totalWidth += 120;
            break;
          case 'Invoice Date':
            totalWidth += 110;
            break;
          case 'Total Amount':
            totalWidth += 130;
            break;
          case 'Paid Amount':
            totalWidth += 130;
            break;
          case 'Remaining Amount':
            totalWidth += 140;
            break;
          case 'Status':
            totalWidth += 110;
            break;
        }
      }
    }
    return totalWidth;
  }

  List<Widget> _buildHeaderRow(
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    List<Widget> headers = [];

    for (var column in columnOrder) {
      if (columnVisibility[column] == true) {
        switch (column) {
          case 'PDF':
            headers.add(_buildHeaderCell('PDF', width: 70, center: true));
            break;
          case 'Payment Date':
            headers.add(_buildHeaderCell('Payment Date', width: 110));
            break;
          case 'Vendor Name':
            headers.add(_buildHeaderCell('Vendor Name', width: 180));
            break;
          case 'Payment Method':
            headers.add(_buildHeaderCell('Payment Method', width: 120));
            break;
          case 'Reference No':
            headers.add(_buildHeaderCell('Reference No', width: 130));
            break;
          case 'Invoice No':
            headers.add(_buildHeaderCell('Invoice No', width: 120));
            break;
          case 'Invoice Date':
            headers.add(_buildHeaderCell('Invoice Date', width: 110));
            break;
          case 'Total Amount':
            headers.add(
              _buildHeaderCell('Total Amount', width: 130, center: true),
            );
            break;
          case 'Paid Amount':
            headers.add(
              _buildHeaderCell('Paid Amount', width: 130, center: true),
            );
            break;
          case 'Remaining Amount':
            headers.add(
              _buildHeaderCell('Remaining Amount', width: 140, center: true),
            );
            break;
          case 'Status':
            headers.add(_buildHeaderCell('Status', width: 110, center: true));
            break;
        }
      }
    }
    return headers;
  }

  List<Widget> _buildDataRow(
    Outgoing payment,
    int index,
    bool isLoadingPdf,
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    List<Widget> cells = [];

    for (var column in columnOrder) {
      if (columnVisibility[column] == true) {
        switch (column) {
          case 'PDF':
            cells.add(
              Container(
                width: 70,
                alignment: Alignment.center,
                child: isLoadingPdf
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _generatePdf(index, payment),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
              ),
            );
            break;
          case 'Payment Date':
            cells.add(_buildCell(_formatDate(payment.paymentDate), width: 110));
            break;
          case 'Vendor Name':
            cells.add(_buildCell(payment.vendorName ?? 'N/A', width: 180));
            break;
          case 'Payment Method':
            cells.add(_buildCell(payment.paymentMethod ?? 'N/A', width: 120));
            break;
          case 'Reference No':
            cells.add(_buildCell(payment.neftNo ?? '-', width: 130));
            break;
          case 'Invoice No':
            cells.add(_buildCell(payment.invoiceNo ?? 'N/A', width: 120));
            break;
          case 'Invoice Date':
            cells.add(_buildCell(_formatDate(payment.invoiceDate), width: 110));
            break;
          case 'Total Amount':
            cells.add(
              _buildCell(
                _formatCurrency(_calculateTotalAmount(payment)),
                width: 130,
                center: true,
                isBold: true,
              ),
            );
            break;
          case 'Paid Amount':
            cells.add(
              _buildCell(
                _formatCurrency(_calculatePaidAmount(payment)),
                width: 130,
                center: true,
                isBold: true,
              ),
            );
            break;
          case 'Remaining Amount':
            cells.add(
              _buildCell(
                payment.status == 'Partially Paid'
                    ? _formatCurrency(_calculateRemainingAmount(payment))
                    : '0.00',
                width: 140,
                center: true,
                isBold: true,
              ),
            );
            break;
          case 'Status':
            cells.add(_buildStatusCell(payment.status ?? 'N/A', width: 110));
            break;
        }
      }
    }
    return cells;
  }

  Widget _buildHeaderCell(
    String text, {
    required double width,
    bool center = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCell(
    String text, {
    required double width,
    bool center = false,
    bool isBold = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildStatusCell(String status, {required double width}) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'paid':
      case 'fully paid':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'partially paid':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// LedgerColumnFilter Widget
class LedgerColumnFilter extends StatefulWidget {
  final List<String> allColumns;
  final Map<String, bool> columnVisibility;
  final Function(List<String>, Map<String, bool>) onApply;

  const LedgerColumnFilter({
    super.key,
    required this.allColumns,
    required this.columnVisibility,
    required this.onApply,
  });

  @override
  State<LedgerColumnFilter> createState() => _LedgerColumnFilterState();
}

class _LedgerColumnFilterState extends State<LedgerColumnFilter> {
  late ValueNotifier<LedgerColumnManager> _columnNotifier;

  @override
  void initState() {
    super.initState();
    final columnVisibility = Map<String, bool>.from(widget.columnVisibility);
    for (var column in widget.allColumns) {
      columnVisibility.putIfAbsent(column, () => true);
    }
    _columnNotifier = ValueNotifier(
      LedgerColumnManager(List.from(widget.allColumns), columnVisibility),
    );
  }

  @override
  void dispose() {
    _columnNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isSmallScreen ? screenWidth - 32 : 450,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Column Filter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag to reorder columns',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final newManager = LedgerColumnManager(
                          List.from(_columnNotifier.value.columns),
                          Map.from(_columnNotifier.value.columnVisibility),
                        );
                        for (var col in newManager.columns) {
                          newManager.columnVisibility[col] = true;
                        }
                        _columnNotifier.value = newManager;
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Show All',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<LedgerColumnManager>(
                valueListenable: _columnNotifier,
                builder: (context, manager, _) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    buildDefaultDragHandles: false,
                    onReorder: (int oldIndex, int newIndex) {
                      final newManager = LedgerColumnManager(
                        List.from(manager.columns),
                        Map.from(manager.columnVisibility),
                      );
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = newManager.columns.removeAt(oldIndex);
                      newManager.columns.insert(newIndex, item);
                      _columnNotifier.value = newManager;
                    },
                    itemCount: manager.columns.length,
                    itemBuilder: (context, index) {
                      final column = manager.columns[index];
                      final isVisible =
                          manager.columnVisibility[column] ?? true;
                      return Container(
                        key: ValueKey(column),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            column,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isVisible
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isVisible ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          trailing: Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: isVisible,
                              activeColor: Colors.blueAccent,
                              checkColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade400),
                              onChanged: (bool? value) {
                                final newManager = LedgerColumnManager(
                                  List.from(manager.columns),
                                  Map.from(manager.columnVisibility),
                                );
                                newManager.columnVisibility[column] =
                                    value ?? true;
                                _columnNotifier.value = newManager;
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final manager = _columnNotifier.value;
                      widget.onApply(manager.columns, manager.columnVisibility);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LedgerColumnManager {
  final List<String> columns;
  final Map<String, bool> columnVisibility;
  LedgerColumnManager(this.columns, this.columnVisibility);
}
