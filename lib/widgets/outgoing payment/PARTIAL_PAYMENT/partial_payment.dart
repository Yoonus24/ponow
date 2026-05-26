import 'dart:async';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/outgoing/outgoing.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../../../providers/outgoing_payment_provider.dart';
import 'package:intl/intl.dart';

class PartialPaymentPage extends StatefulWidget {
  final String status;
  final DateTime? fromDate;
  final DateTime? toDate;
  const PartialPaymentPage({
    super.key,
    required this.status,
    this.fromDate,
    this.toDate,
  });

  @override
  State<PartialPaymentPage> createState() => _PartialPaymentPageState();
}

class _PartialPaymentPageState extends State<PartialPaymentPage> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<Outgoing>> _filteredPaymentsNotifier =
      ValueNotifier<List<Outgoing>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _hasErrorNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _errorMessageNotifier = ValueNotifier<String>('');
  Timer? _debounceTimer;
  late final FocusNode _searchFocusNode;
  int _skip = 0;
  final int _limit = 50;
  final ValueNotifier<bool> _loadingMoreNotifier = ValueNotifier(false);
  final ScrollController _verticalScrollController = ScrollController();
  bool _isLoading = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Column visibility and order management using ValueNotifier
  final ValueNotifier<List<String>> _columnOrderNotifier = ValueNotifier([]);
  final ValueNotifier<Map<String, bool>> _columnVisibilityNotifier =
      ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _initializeColumnSettings();
    _verticalScrollController.addListener(() {
      if (_verticalScrollController.position.pixels >
          _verticalScrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
    _searchFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initializeColumnSettings() {
    _columnOrderNotifier.value = [
      'No',
      'Vendor Name',
      'Invoice No',
      'Invoice Date',
      'Total Amount',
      'Amount Paid',
      'Payment Date',
      'Discount',
      'Payable Amount',
      'View',
      'PDF',
    ];

    _columnVisibilityNotifier.value = {
      'No': true,
      'View': true,
      'PDF': true,
      'Vendor Name': true,
      'Invoice No': true,
      'Invoice Date': true,
      'Total Amount': true,
      'Amount Paid': true,
      'Payment Date': true,
      'Discount': true,
      'Payable Amount': true,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filteredPaymentsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasErrorNotifier.dispose();
    _errorMessageNotifier.dispose();
    _columnOrderNotifier.dispose();
    _columnVisibilityNotifier.dispose();
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _verticalScrollController.dispose();
    _loadingMoreNotifier.dispose();
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
  void didUpdateWidget(covariant PartialPaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
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

      _skip = 0;

      await provider.fetchFilteredOutgoings(
        status: 'Partially Paid',
        filterBy: 'paymentDate',
        skip: _skip,
        limit: _limit,
      );

      _skip += _limit;
      if (!mounted) return;

      _filteredPaymentsNotifier.value = provider.payments
          .where((p) => p.status == 'Partially Paid')
          .where((p) {
            if (_fromDate == null || _toDate == null) return true;

            final paymentDate = p.paymentDate;
            if (paymentDate == null) return false;

            return paymentDate.isAfter(
                  _fromDate!.subtract(const Duration(days: 1)),
                ) &&
                paymentDate.isBefore(_toDate!.add(const Duration(days: 1)));
          })
          .toList();

      _isLoadingNotifier.value = false;
      _hasErrorNotifier.value = provider.error.isNotEmpty;
      _errorMessageNotifier.value = provider.error;
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

    await provider.fetchFilteredOutgoings(
      status: 'Partially Paid',
      filterBy: 'paymentDate',
      skip: _skip,
      limit: _limit,
    );

    _skip += _limit;

    final query = _searchController.text.toLowerCase();

    _filteredPaymentsNotifier.value = provider.payments
        .where((p) => p.status == 'Partially Paid')
        .where((p) {
          if (_fromDate == null || _toDate == null) return true;

          final paymentDate = p.paymentDate;
          if (paymentDate == null) return false;

          return paymentDate.isAfter(
                _fromDate!.subtract(const Duration(days: 1)),
              ) &&
              paymentDate.isBefore(_toDate!.add(const Duration(days: 1)));
        })
        .where((payment) {
          final vendor = payment.vendorName?.toLowerCase() ?? '';
          final invoice = payment.invoiceNo?.toLowerCase() ?? '';
          return vendor.contains(query) || invoice.contains(query);
        })
        .toList();

    _loadingMoreNotifier.value = false;
  }

  void _filterPayments() {
    if (!mounted) return;
    final provider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text.toLowerCase();

    _filteredPaymentsNotifier.value = provider.payments
        .where((payment) => payment.status == 'Partially Paid')
        .where((payment) {
          final vendor = payment.vendorName?.toLowerCase() ?? '';
          final invoice = payment.invoiceNo?.toLowerCase() ?? '';
          return vendor.contains(query) || invoice.contains(query);
        })
        .toList();
  }

  String _formatDate(DateTime? date) =>
      date != null ? DateFormat('dd-MM-yyyy').format(date) : 'N/A';

  String _formatCurrency(double? amount) => amount != null
      ? NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)
      : '0.00';

  void _openColumnFilter() {
    showDialog(
      context: context,
      builder: (context) => OutgoingColumnFilter(
        allColumns: _columnOrderNotifier.value,
        columnVisibility: _columnVisibilityNotifier.value,
        onApply: (newOrder, newVisibility) {
          _columnOrderNotifier.value = newOrder;
          _columnVisibilityNotifier.value = newVisibility;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OutgoingPaymentProvider>();
    final Color headerColor = Colors.blueAccent;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with search bar, date filter, and column filter icon (ALWAYS VISIBLE)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildSearchBar(),
            ),

            // Body section with loader overlay
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _hasErrorNotifier,
                builder: (context, hasError, _) {
                  if (hasError) {
                    return ValueListenableBuilder<String>(
                      valueListenable: _errorMessageNotifier,
                      builder: (context, errorMessage, _) {
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
                        );
                      },
                    );
                  }

                  return ValueListenableBuilder<List<Outgoing>>(
                    valueListenable: _filteredPaymentsNotifier,
                    builder: (context, filteredList, _) {
                      if (filteredList.isEmpty && !_isLoadingNotifier.value) {
                        return const Center(
                          child: Text(
                            'No partial payments found.',
                            style: TextStyle(fontSize: 17, color: Colors.grey),
                          ),
                        );
                      }

                      // Stack for table content + loader overlay
                      return Stack(
                        children: [
                          // Table content
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ValueListenableBuilder<List<String>>(
                              valueListenable: _columnOrderNotifier,
                              builder: (context, columnOrder, _) {
                                return ValueListenableBuilder<
                                  Map<String, bool>
                                >(
                                  valueListenable: _columnVisibilityNotifier,
                                  builder: (context, columnVisibility, _) {
                                    return SizedBox(
                                      width: _calculateTotalWidth(
                                        columnOrder,
                                        columnVisibility,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // HEADER
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 16,
                                              right: 16,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: headerColor,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(4),
                                                    topRight: Radius.circular(
                                                      4,
                                                    ),
                                                  ),
                                            ),
                                            child: Row(
                                              children: _buildHeaderRow(
                                                columnOrder,
                                                columnVisibility,
                                              ),
                                            ),
                                          ),

                                          // ROW LIST
                                          Expanded(
                                            child: filteredList.isEmpty
                                                ? const Center(
                                                    child: Text(
                                                      'No partial payments found.',
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                : ValueListenableBuilder<bool>(
                                                    valueListenable:
                                                        _loadingMoreNotifier,
                                                    builder: (_, loadingMore, __) {
                                                      return ListView.builder(
                                                        controller:
                                                            _verticalScrollController,
                                                        itemCount:
                                                            filteredList
                                                                .length +
                                                            (loadingMore
                                                                ? 1
                                                                : 0),
                                                        itemBuilder: (context, index) {
                                                          if (index >=
                                                              filteredList
                                                                  .length) {
                                                            return const Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    16,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              ),
                                                            );
                                                          }

                                                          final payment =
                                                              filteredList[index];
                                                          final serialNo =
                                                              index + 1;

                                                          return Container(
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16,
                                                                ),
                                                            height: 56,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              border: Border(
                                                                bottom: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  width: 0.5,
                                                                ),
                                                                left: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  width: 0.5,
                                                                ),
                                                                right: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  width: 0.5,
                                                                ),
                                                              ),
                                                            ),
                                                            child: Row(
                                                              children:
                                                                  _buildDataRow(
                                                                    payment,
                                                                    serialNo,
                                                                    provider,
                                                                    index,
                                                                    columnOrder,
                                                                    columnVisibility,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
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

                          // Loader overlay (only when loading)
                          ValueListenableBuilder<bool>(
                            valueListenable: _isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              if (!isLoading) return const SizedBox.shrink();
                              return Container(
                                color: Colors.black.withOpacity(0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalWidth(
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    double totalWidth = 70; // padding
    for (var column in columnOrder) {
      if (columnVisibility[column] == true) {
        switch (column) {
          case 'No':
            totalWidth += 50;
            break;
          case 'View':
            totalWidth += 70;
            break;
          case 'PDF':
            totalWidth += 70;
            break;
          case 'Vendor Name':
            totalWidth += 150;
            break;
          case 'Invoice No':
            totalWidth += 120;
            break;
          case 'Invoice Date':
            totalWidth += 100;
            break;
          case 'Total Amount':
            totalWidth += 110;
            break;
          case 'Amount Paid':
            totalWidth += 110;
            break;
          case 'Payment Date':
            totalWidth += 100;
            break;
          case 'Discount':
            totalWidth += 130; // was 110
            break;

          case 'Payable Amount':
            totalWidth += 180; // was 140
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
          case 'No':
            headers.add(_buildHeaderCell('No', width: 50, center: true));
            break;

          case 'View':
            headers.add(_buildHeaderCell('View', width: 70, center: true));
            break;

          case 'PDF':
            headers.add(_buildHeaderCell('PDF', width: 70, center: true));
            break;

          case 'Vendor Name':
            headers.add(_buildHeaderCell('Vendor Name', width: 150));
            break;

          case 'Invoice No':
            headers.add(_buildHeaderCell('Invoice No', width: 120));
            break;

          case 'Invoice Date':
            headers.add(_buildHeaderCell('Invoice Date', width: 100));
            break;

          case 'Total Amount':
            headers.add(
              _buildHeaderCell('Total Amount', width: 110, center: true),
            );
            break;

          case 'Amount Paid':
            headers.add(
              _buildHeaderCell('Amount Paid', width: 110, center: true),
            );
            break;

          case 'Payment Date':
            headers.add(_buildHeaderCell('Payment Date', width: 100));
            break;

          case 'Discount':
            headers.add(_buildHeaderCell('Discount', width: 130, center: true));
            break;

          case 'Payable Amount':
            headers.add(
              _buildHeaderCell('Payable Amount', width: 180, center: true),
            );
            break;
        }
      }
    }

    return headers;
  }

  List<Widget> _buildDataRow(
    Outgoing payment,
    int serialNo,
    OutgoingPaymentProvider provider,
    int index,
    List<String> columnOrder,
    Map<String, bool> columnVisibility,
  ) {
    List<Widget> cells = [];

    for (var column in columnOrder) {
      if (columnVisibility[column] == true) {
        switch (column) {
          case 'No':
            cells.add(_buildCell('$serialNo', width: 50, center: true));
            break;
          case 'View':
            cells.add(
              _buildIconCell(
                Icons.remove_red_eye,
                color: Colors.black87,
                onPressed: () => showPaymentDetailsDialog(context, payment),
                width: 70,
              ),
            );
            break;
          case 'PDF':
            cells.add(
              Container(
                width: 70,
                alignment: Alignment.center,
                child: provider.isPdfLoading(index)
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
                        onPressed: () {
                          context.read<OutgoingPaymentProvider>().generatePdf(
                            index,
                            payment,
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
              ),
            );
            break;
          case 'Vendor Name':
            cells.add(
              _buildCell(payment.vendorName ?? 'N/A', width: 150, center: true),
            );
            break;
          case 'Invoice No':
            cells.add(
              _buildCell(payment.invoiceNo ?? 'N/A', width: 120, center: true),
            );
            break;
          case 'Invoice Date':
            cells.add(
              _buildCell(
                _formatDate(payment.invoiceDate),
                width: 100,
                center: true,
              ),
            );
            break;
          case 'Total Amount':
            cells.add(
              _buildCell(
                _formatCurrency(payment.totalPayableAmount),
                width: 110,
                center: true,
                isBold: true,
              ),
            );
            break;
          case 'Amount Paid':
            cells.add(
              _buildCell(
                _formatCurrency(payment.totalPaidAmount),
                width: 110,
                center: true,
                isBold: true,
              ),
            );
            break;
          case 'Payment Date':
            cells.add(
              _buildCell(
                _formatDate(payment.paymentDate),
                width: 100,
                center: true,
              ),
            );
            break;
          case 'Discount':
            cells.add(
              _buildCell(
                _formatCurrency(payment.discountDetails),
                width: 130,
                center: true,
                isBold: true,
              ),
            );
            break;

          case 'Payable Amount':
            cells.add(
              _buildCell(
                _formatCurrency(payment.payableAmount),
                width: 180,
                center: true,
                isBold: true,
              ),
            );
            break;
        }
      }
    }

    return cells;
  }

  // Header cell builder
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

  // Data cell builder
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
          fontSize: 13,
          color: Colors.black,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // Icon cell builder
  Widget _buildIconCell(
    IconData icon, {
    required Color color,
    required VoidCallback onPressed,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        iconSize: 20,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, child) {
        final suggestions = provider.payments
            .where((p) => (p.status ?? '').toLowerCase() == 'partially paid')
            .map((p) => (p.vendorName ?? '').trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        return Row(
          children: [
            /// 🔍 VENDOR SEARCH
            Expanded(
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
                          hintText: 'Search vendor or invoice',

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
                              color: Colors.grey,
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
                      child: SizedBox(
                        width: 250,
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
                                  vertical: 8,
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

            /// 📅 DATE FILTER
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: ServerTimeService.now,
                  );

                  if (picked != null) {
                    _fromDate = picked.start;
                    _toDate = picked.end;
                    _loadData();
                  }
                },
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
                      Expanded(
                        child: Text(
                          _fromDate != null && _toDate != null
                              ? "${DateFormat('dd-MM').format(_fromDate!)} - ${DateFormat('dd-MM').format(_toDate!)}"
                              : "Select Date ",
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_fromDate != null && _toDate != null)
                        GestureDetector(
                          onTap: () {
                            _fromDate = null;
                            _toDate = null;
                            _loadData();
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            /// 🎯 COLUMN FILTER
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

  void showPaymentDetailsDialog(BuildContext context, Outgoing payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(
                        child: Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                _buildDetailRow('Vendor', payment.vendorName ?? 'N/A'),
                _buildDetailRow('Invoice No', payment.invoiceNo ?? 'N/A'),
                _buildDetailRow(
                  'Invoice Date',
                  _formatDate(payment.invoiceDate),
                ),
                _buildDetailRow(
                  'Total Amount',
                  _formatCurrency(payment.totalPayableAmount),
                ),
                _buildDetailRow(
                  'Paid',
                  _formatCurrency(payment.totalPaidAmount),
                ),
                _buildDetailRow(
                  'Payment Date',
                  _formatDate(payment.paymentDate),
                ),
                _buildDetailRow(
                  'Tax',
                  payment.taxDetails?.toStringAsFixed(2) ?? '0.00',
                ),
                _buildDetailRow(
                  'Discount',
                  _formatCurrency(payment.discountDetails),
                ),
                _buildDetailRow(
                  'Remaining',
                  _formatCurrency(payment.payableAmount),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Text(
            ' : ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// OutgoingColumnFilter Widget
class OutgoingColumnFilter extends StatefulWidget {
  final List<String> allColumns;
  final Map<String, bool> columnVisibility;
  final Function(List<String>, Map<String, bool>) onApply;

  const OutgoingColumnFilter({
    super.key,
    required this.allColumns,
    required this.columnVisibility,
    required this.onApply,
  });

  @override
  State<OutgoingColumnFilter> createState() => _OutgoingColumnFilterState();
}

class _OutgoingColumnFilterState extends State<OutgoingColumnFilter> {
  late ValueNotifier<ColumnManager> _columnNotifier;

  @override
  void initState() {
    super.initState();
    final columnVisibility = Map<String, bool>.from(widget.columnVisibility);
    for (var column in widget.allColumns) {
      columnVisibility.putIfAbsent(column, () => true);
    }
    _columnNotifier = ValueNotifier(
      ColumnManager(List.from(widget.allColumns), columnVisibility),
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt,
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
            // Sub header with drag info
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
                        final newManager = ColumnManager(
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
            // Column list
            Expanded(
              child: ValueListenableBuilder<ColumnManager>(
                valueListenable: _columnNotifier,
                builder: (context, manager, _) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    buildDefaultDragHandles: false,
                    onReorder: (int oldIndex, int newIndex) {
                      final newManager = ColumnManager(
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
                                final newManager = ColumnManager(
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
            // Action Buttons
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

class ColumnManager {
  final List<String> columns;
  final Map<String, bool> columnVisibility;
  ColumnManager(this.columns, this.columnVisibility);
}
