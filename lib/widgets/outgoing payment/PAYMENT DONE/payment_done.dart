// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../../../models/outgoing.dart';
import '../../../providers/outgoing_payment_provider.dart';

class PaymentDonePage extends StatefulWidget {
  final String status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool showAllPaidStatuses;

  const PaymentDonePage({
    super.key,
    required this.status,
    this.fromDate,
    this.toDate,
    this.showAllPaidStatuses = false,
  });

  @override
  State<PaymentDonePage> createState() => _PaymentDonePageState();
}

class _PaymentDonePageState extends State<PaymentDonePage> {
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<List<Outgoing>> filteredPaymentsNotifier =
      ValueNotifier<List<Outgoing>>([]);
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> hasErrorNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> errorNotifier = ValueNotifier<String>("");
  final ValueNotifier<bool> loadingMoreNotifier = ValueNotifier(false);
  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();
  final Map<int, ValueNotifier<bool>> loadingPdfNotifiers = {};
  Timer? _debounceTimer;
  late final FocusNode _searchFocusNode;

  int _skip = 0;
  final int _limit = 50;
  bool _isLoading = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Column visibility and order management
  final ValueNotifier<List<String>> _columnOrderNotifier = ValueNotifier([]);
  final ValueNotifier<Map<String, bool>> _columnVisibilityNotifier =
      ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _initializeColumnSettings();
    _searchFocusNode = FocusNode();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });

    verticalScrollController.addListener(() {
      if (verticalScrollController.position.pixels >
          verticalScrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  void _initializeColumnSettings() {
    _columnOrderNotifier.value = [
      'No',
      'Status',
      'View',
      'PDF',
      'Vendor Name',
      'Invoice No',
      'Invoice Date',
      'Total Amount',
      'Amount Paid',
      'Payment Date',
      'Discount',
      'Payable Amount',
    ];

    _columnVisibilityNotifier.value = {
      'No': true,
      'Status': true,
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
  void didUpdateWidget(covariant PaymentDonePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromDate != widget.fromDate ||
        oldWidget.toDate != widget.toDate ||
        oldWidget.status != widget.status) {
      _fromDate = widget.fromDate;
      _toDate = widget.toDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadInitial();
        }
      });
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _filterPayments();
    });
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;

    loadingNotifier.value = true;
    hasErrorNotifier.value = false;
    errorNotifier.value = "";

    try {
      final provider = context.read<OutgoingPaymentProvider>();
      _skip = 0;

      await provider.fetchFilteredOutgoings(
        skip: _skip,
        limit: _limit,
        status: 'Fully Paid,Partially Paid',
        filterBy: 'paymentDate',
      );

      _skip += _limit;

      _filterPayments();

      loadingNotifier.value = false;
      hasErrorNotifier.value = false;
    } catch (e) {
      hasErrorNotifier.value = true;
      errorNotifier.value = "Failed to load payments: $e";
      loadingNotifier.value = false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _handleRefresh() async {
    _skip = 0;

    final provider = context.read<OutgoingPaymentProvider>();

    await provider.fetchFilteredOutgoings(
      skip: _skip,
      limit: _limit,
      status: 'Fully Paid,Partially Paid',
      filterBy: 'paymentDate',
    );

    _skip += _limit;

    _filterPayments();
  }

  Future<void> _loadMore() async {
    if (loadingMoreNotifier.value) return;

    loadingMoreNotifier.value = true;

    final provider = context.read<OutgoingPaymentProvider>();

    await provider.fetchFilteredOutgoings(
      skip: _skip,
      limit: _limit,
      status: 'Fully Paid,Partially Paid',
      filterBy: 'paymentDate',
    );

    _skip += _limit;

    _filterPayments();

    loadingMoreNotifier.value = false;
  }

  Future<void> _handlePdfClick(int index, Outgoing payment) async {
    if (!loadingPdfNotifiers.containsKey(index)) {
      loadingPdfNotifiers[index] = ValueNotifier(false);
    }

    loadingPdfNotifiers[index]!.value = true;

    try {
      final pdf = await OutgoingPdf().generateOutgoingPdf(payment.outgoingId);
      await Printing.layoutPdf(onLayout: (_) => pdf.readAsBytesSync());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("PDF generated")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("PDF error: $e")));
      }
    } finally {
      loadingPdfNotifiers[index]!.value = false;
    }
  }

  void _filterPayments() {
    final provider = context.read<OutgoingPaymentProvider>();
    final query = searchController.text.toLowerCase();

    print("----- FILTER START -----");
    print("FROM DATE: $_fromDate");
    print("TO DATE: $_toDate");

    final filtered = provider.payments.where((payment) {
      print("\nChecking Payment:");
      print("Invoice No: ${payment.invoiceNo}");
      print("Status: ${payment.status}");

      final status = payment.status?.toLowerCase();
      final matchesStatus =
          status == 'fully paid' || status == 'partially paid';

      print("Status Match: $matchesStatus");

      if (!matchesStatus) return false;

      // ✅ Date filter using paymentDate (FIXED)
      if (_fromDate != null && _toDate != null) {
        final paymentDate = payment.paymentDate?.toLocal();

        print("Original Payment Date: ${payment.paymentDate}");
        print("Converted Payment Date: $paymentDate");

        if (paymentDate == null) {
          print("❌ Skipped: paymentDate is null");
          return false;
        }

        final start = DateTime(
          _fromDate!.year,
          _fromDate!.month,
          _fromDate!.day,
        );

        final end = DateTime(
          _toDate!.year,
          _toDate!.month,
          _toDate!.day,
          23,
          59,
          59,
        );

        print("Start Date: $start");
        print("End Date: $end");

        if (paymentDate.isBefore(start) || paymentDate.isAfter(end)) {
          print("❌ Skipped: Outside date range");
          return false;
        } else {
          print("✅ Passed Date Filter");
        }
      }

      final vendorName = payment.vendorName?.toLowerCase() ?? '';
      final invoiceNo = payment.invoiceNo?.toLowerCase() ?? '';

      final searchMatch =
          vendorName.contains(query) || invoiceNo.contains(query);

      print("Search Match: $searchMatch");

      if (!searchMatch) {
        print("❌ Skipped: Search mismatch");
      } else {
        print("✅ Passed Search");
      }

      return searchMatch;
    }).toList();

    print("FINAL FILTERED COUNT: ${filtered.length}");
    print("----- FILTER END -----");

    filteredPaymentsNotifier.value = filtered;
  }

  @override
  void dispose() {
    searchController.dispose();
    filteredPaymentsNotifier.dispose();
    loadingNotifier.dispose();
    hasErrorNotifier.dispose();
    errorNotifier.dispose();
    loadingMoreNotifier.dispose();
    horizontalController.dispose();
    verticalScrollController.dispose();
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _columnOrderNotifier.dispose();
    _columnVisibilityNotifier.dispose();
    for (var notifier in loadingPdfNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'fully paid':
      case 'paid':
        return Colors.green;
      case 'partially paid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'fully paid':
      case 'paid':
        return 'Paid';
      case 'partially paid':
        return 'Partial';
      default:
        return status ?? 'N/A';
    }
  }

  String _formatCurrency(double? val) => val != null
      ? NumberFormat.currency(symbol: '', decimalDigits: 2).format(val)
      : '0.00';

  String _formatDate(DateTime? date) =>
      date != null ? DateFormat('dd-MM-yyyy').format(date) : 'N/A';

  // List<String> _vendorSuggestions(OutgoingPaymentProvider provider) {
  //   final allowed = ['fully paid', 'partially paid'];
  //   return provider.payments
  //       .where(
  //         (p) =>
  //             p.vendorName != null && allowed.contains(p.status?.toLowerCase()),
  //       )
  //       .map((p) => p.vendorName!)
  //       .toSet()
  //       .toList();
  // }

  void _openColumnFilter() {
    showDialog(
      context: context,
      builder: (context) => PaymentDoneColumnFilter(
        allColumns: _columnOrderNotifier.value,
        columnVisibility: _columnVisibilityNotifier.value,
        onApply: (newOrder, newVisibility) {
          _columnOrderNotifier.value = newOrder;
          _columnVisibilityNotifier.value = newVisibility;
        },
      ),
    );
  }

  // double _calculateTotalWidth(
  //   List<String> columnOrder,
  //   Map<String, bool> columnVisibility,
  // ) {
  //   double totalWidth = 70; // padding
  //   for (var column in columnOrder) {
  //     if (columnVisibility[column] == true) {
  //       switch (column) {
  //         case 'No':
  //           totalWidth += 50;
  //           break;
  //         case 'Status':
  //           totalWidth += 90;
  //           break;
  //         case 'View':
  //           totalWidth += 70;
  //           break;
  //         case 'PDF':
  //           totalWidth += 70;
  //           break;
  //         case 'Vendor Name':
  //           totalWidth += 200;
  //           break;
  //         case 'Invoice No':
  //           totalWidth += 120;
  //           break;
  //         case 'Invoice Date':
  //           totalWidth += 110;
  //           break;
  //         case 'Total Amount':
  //           totalWidth += 110;
  //           break;
  //         case 'Amount Paid':
  //           totalWidth += 110;
  //           break;
  //         case 'Payment Date':
  //           totalWidth += 120;
  //           break;
  //         case 'Discount':
  //           totalWidth += 130;
  //           break;
  //         case 'Payable Amount':
  //           totalWidth += 180;
  //           break;
  //       }
  //     }
  //   }
  //   return totalWidth;
  // }

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
          case 'Status':
            headers.add(_buildHeaderCell('Status', width: 90, center: true));
            break;
          case 'View':
            headers.add(_buildHeaderCell('View', width: 70, center: true));
            break;
          case 'PDF':
            headers.add(_buildHeaderCell('PDF', width: 70, center: true));
            break;
          case 'Vendor Name':
            headers.add(_buildHeaderCell('Vendor Name', width: 200));
            break;
          case 'Invoice No':
            headers.add(_buildHeaderCell('Invoice No', width: 120));
            break;
          case 'Invoice Date':
            headers.add(_buildHeaderCell('Invoice Date', width: 110));
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
            headers.add(_buildHeaderCell('Payment Date', width: 120));
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
          case 'Status':
            cells.add(_buildStatusCell(payment.status, 90));
            break;
          case 'View':
            cells.add(
              _buildIconCell(
                Icons.remove_red_eye,
                color: Colors.blueAccent,
                onPressed: () => showPaymentDetailsTable(context, payment),
                width: 70,
              ),
            );
            break;
          case 'PDF':
            cells.add(
              Container(
                width: 70,
                alignment: Alignment.center,
                child:
                    (loadingPdfNotifiers[index] ?? ValueNotifier(false)).value
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
                        onPressed: () => _handlePdfClick(index, payment),
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
              _buildCell(payment.vendorName ?? 'N/A', width: 200, center: true),
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
                width: 110,
                center: true,
              ),
            );
            break;
          case 'Total Amount':
            cells.add(
              _buildCell(
                _formatCurrency(payment.payableAmount),
                width: 110,
                center: true,
                isBold: true,
              ),
            );
            break;
          case 'Amount Paid':
            cells.add(
              _buildCell(
                _formatCurrency(payment.totalPaidAmount ?? 0),
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
                width: 120,
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
                _formatCurrency(payment.remainingPayableAmount ?? 0),
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

  Widget _buildHeaderCell(
    String text, {
    required double width,
    bool center = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
      ),
    );
  }

  Widget _buildCell(
    String text, {
    required double width,
    bool center = false,
    bool isBold = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
      ),
    );
  }

  Widget _buildStatusCell(String? status, double width) {
    final color = _getStatusColor(status);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconCell(
    IconData icon, {
    required Color color,
    required VoidCallback onPressed,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: IconButton(
          icon: Icon(icon, size: 20, color: color),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          iconSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OutgoingPaymentProvider>();
    final Color headerColor = const Color.fromARGB(255, 74, 122, 227);

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
            // Body section with loader overlay
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: hasErrorNotifier,
                builder: (context, hasError, _) {
                  if (hasError) {
                    return ValueListenableBuilder<String>(
                      valueListenable: errorNotifier,
                      builder: (context, errorMessage, _) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
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
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _loadInitial,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return ValueListenableBuilder<List<Outgoing>>(
                    valueListenable: filteredPaymentsNotifier,
                    builder: (context, filteredList, _) {
                      if (filteredList.isEmpty && !loadingNotifier.value) {
                        return RefreshIndicator(
                          onRefresh: _handleRefresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 300),
                              Center(
                                child: Text(
                                  "No payments found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Stack for table content + loader overlay
                      return Stack(
                        children: [
                          // Table content
                          RefreshIndicator(
                            onRefresh: _handleRefresh,
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: verticalScrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      controller: horizontalController,
                                      child: ValueListenableBuilder<List<String>>(
                                        valueListenable: _columnOrderNotifier,
                                        builder: (context, columnOrder, _) {
                                          return ValueListenableBuilder<
                                            Map<String, bool>
                                          >(
                                            valueListenable:
                                                _columnVisibilityNotifier,
                                            builder: (context, columnVisibility, _) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // HEADER
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 16,
                                                          right: 16,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      color: headerColor,
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  4,
                                                                ),
                                                            topRight:
                                                                Radius.circular(
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
                                                  ValueListenableBuilder<bool>(
                                                    valueListenable:
                                                        loadingMoreNotifier,
                                                    builder: (_, loadingMore, __) {
                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          ...List.generate(filteredList.length, (
                                                            index,
                                                          ) {
                                                            final payment =
                                                                filteredList[index];
                                                            final serialNo =
                                                                index + 1;

                                                            if (!loadingPdfNotifiers
                                                                .containsKey(
                                                                  index,
                                                                )) {
                                                              loadingPdfNotifiers[index] =
                                                                  ValueNotifier(
                                                                    false,
                                                                  );
                                                            }

                                                            return Container(
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                  ),
                                                              height: 60,
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white,
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
                                                                children: _buildDataRow(
                                                                  payment,
                                                                  serialNo,
                                                                  provider,
                                                                  index,
                                                                  columnOrder,
                                                                  columnVisibility,
                                                                ),
                                                              ),
                                                            );
                                                          }),
                                                          if (loadingMore)
                                                            const Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    16,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              ),
                                                            ),
                                                        ],
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Loader overlay (only when loading)
                          ValueListenableBuilder<bool>(
                            valueListenable: loadingNotifier,
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

  Widget _buildSearchBar() {
    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, child) {
        final suggestions = provider.payments
            .where(
              (p) =>
                  (p.status ?? '').toLowerCase() == 'fully paid' ||
                  (p.status ?? '').toLowerCase() == 'partially paid',
            )
            .map((p) => (p.vendorName ?? '').trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        return Row(
          children: [
            /// 🔍 VENDOR SEARCH
            Expanded(
              child: RawAutocomplete<String>(
                textEditingController: searchController,
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
                    setState(() {
                      _fromDate = picked.start;
                      _toDate = picked.end;
                    });
                    _loadInitial();
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
                              : "Select Date",
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_fromDate != null && _toDate != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                            });
                            _loadInitial();
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

  void showPaymentDetailsTable(BuildContext context, Outgoing payment) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                  _detailRowAligned("Vendor", payment.vendorName),
                  _detailRowAligned("Invoice No", payment.invoiceNo),
                  _detailRowAligned(
                    "Invoice Date",
                    _formatDate(payment.invoiceDate),
                  ),
                  _detailRowAligned(
                    "Total Amount",
                    _formatCurrency(payment.payableAmount),
                  ),
                  _detailRowAligned(
                    "Paid Amount",
                    _formatCurrency(payment.totalPaidAmount ?? 0),
                  ),
                  _detailRowAligned(
                    "Discount",
                    _formatCurrency(payment.discountDetails),
                  ),
                  _detailRowAligned(
                    "Payable Amount",
                    _formatCurrency(payment.remainingPayableAmount ?? 0),
                  ),
                  _detailRowAligned(
                    "Payment Date",
                    _formatDate(payment.paymentDate),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRowAligned(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ":",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              softWrap: true,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// PaymentDoneColumnFilter Widget
class PaymentDoneColumnFilter extends StatefulWidget {
  final List<String> allColumns;
  final Map<String, bool> columnVisibility;
  final Function(List<String>, Map<String, bool>) onApply;

  const PaymentDoneColumnFilter({
    super.key,
    required this.allColumns,
    required this.columnVisibility,
    required this.onApply,
  });

  @override
  State<PaymentDoneColumnFilter> createState() =>
      _PaymentDoneColumnFilterState();
}

class _PaymentDoneColumnFilterState extends State<PaymentDoneColumnFilter> {
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
