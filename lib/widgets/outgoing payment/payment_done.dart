// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../models/outgoing.dart';
import '../../providers/outgoing_payment_provider.dart';

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
  final ValueNotifier<String> errorNotifier = ValueNotifier<String>("");
  final ValueNotifier<bool> loadingMoreNotifier = ValueNotifier(false);
  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();
  final Map<int, ValueNotifier<bool>> loadingPdfNotifiers = {};

  int _skip = 0;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterPayments);
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

  @override
  void didUpdateWidget(covariant PaymentDonePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromDate != widget.fromDate ||
        oldWidget.toDate != widget.toDate) {
      _loadInitial();
    }
  }

  Future<void> _loadInitial() async {
    loadingNotifier.value = true;
    errorNotifier.value = "";

    try {
      final provider = context.read<OutgoingPaymentProvider>();
      _skip = 0;

      await provider.fetchFilteredOutgoings(
        skip: _skip,
        limit: _limit,
        status: 'Fully Paid,Partially Paid',
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );
      _skip += _limit;

      _filterPayments();
      loadingNotifier.value = false;
    } catch (e) {
      errorNotifier.value = "Failed to load payments: $e";
      loadingNotifier.value = false;
    }
  }

  Future<void> _handleRefresh() async {
    _skip = 0;
    final provider = context.read<OutgoingPaymentProvider>();

    await provider.fetchFilteredOutgoings(
      skip: _skip,
      limit: _limit,
      status: 'Fully Paid,Partially Paid',
      fromDate: widget.fromDate,
      toDate: widget.toDate,
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
      fromDate: widget.fromDate,
      toDate: widget.toDate,
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

    final filtered = provider.payments.where((payment) {
      final status = payment.status?.toLowerCase();
      final matchesStatus =
          status == 'fully paid' || status == 'partially paid';
      if (!matchesStatus) return false;
      final vendorName = payment.vendorName?.toLowerCase() ?? '';
      final invoiceNo = payment.invoiceNo?.toLowerCase() ?? '';
      return vendorName.contains(query) || invoiceNo.contains(query);
    }).toList();

    filteredPaymentsNotifier.value = filtered;
  }

  @override
  void dispose() {
    searchController.removeListener(_filterPayments);
    searchController.dispose();
    filteredPaymentsNotifier.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();
    loadingMoreNotifier.dispose();
    horizontalController.dispose();
    verticalScrollController.dispose();
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

  List<String> _vendorSuggestions(OutgoingPaymentProvider provider) {
    final allowed = ['fully paid', 'partially paid'];
    return provider.payments
        .where(
          (p) =>
              p.vendorName != null && allowed.contains(p.status?.toLowerCase()),
        )
        .map((p) => p.vendorName!)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final columnWidths = {
      'no': 50.0,
      'status': 90.0,
      'view': 60.0,
      'pdf': 60.0,
      'vendor': 200.0,
      'invoice': 100.0,
      'date': 110.0,
      'total': 110.0,
      'paid': 110.0,
      'balance': 110.0,
      'payment_date': 120.0,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Payment Done',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(child: _buildSearchBar()),
                ],
              ),
            ),
            Expanded(
              child: Consumer<OutgoingPaymentProvider>(
                builder: (_, provider, __) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: loadingNotifier,
                    builder: (_, loading, __) {
                      if (loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return ValueListenableBuilder<String>(
                        valueListenable: errorNotifier,
                        builder: (_, error, __) {
                          final providerError = provider.error;

                          if (error.isNotEmpty || providerError.isNotEmpty) {
                            final message = error.isNotEmpty
                                ? error
                                : providerError;
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
                                        message,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
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
                                ),
                              ],
                            );
                          }

                          return ValueListenableBuilder<List<Outgoing>>(
                            valueListenable: filteredPaymentsNotifier,
                            builder: (_, payments, __) {
                              if (payments.isEmpty) {
                                return RefreshIndicator(
                                  onRefresh: _handleRefresh,
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
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

                              return RefreshIndicator(
                                onRefresh: _handleRefresh,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      controller: verticalScrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                        ),
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          controller: horizontalController,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            controller: horizontalController,
                                            child: SizedBox(
                                              width: 1140,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height: 48,
                                                    color: const Color.fromARGB(
                                                      255,
                                                      74,
                                                      122,
                                                      227,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        _buildHeaderCell(
                                                          'NO',
                                                          columnWidths['no']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'STATUS',
                                                          columnWidths['status']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'VIEW',
                                                          columnWidths['view']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'PDF',
                                                          columnWidths['pdf']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'VENDOR',
                                                          columnWidths['vendor']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'INVOICE',
                                                          columnWidths['invoice']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'DATE',
                                                          columnWidths['date']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'TOTAL',
                                                          columnWidths['total']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'PAID',
                                                          columnWidths['paid']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'BALANCE',
                                                          columnWidths['balance']!,
                                                        ),
                                                        _buildHeaderCell(
                                                          'PAYMENT DATE',
                                                          columnWidths['payment_date']!,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  ValueListenableBuilder<bool>(
                                                    valueListenable:
                                                        loadingMoreNotifier,
                                                    builder: (_, loadingMore, __) {
                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          ListView.builder(
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            shrinkWrap: true,
                                                            itemCount:
                                                                payments.length,
                                                            itemBuilder: (context, index) {
                                                              final payment =
                                                                  payments[index];
                                                              final isEven =
                                                                  index % 2 ==
                                                                  0;

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
                                                                height: 60,
                                                                decoration: BoxDecoration(
                                                                  color: isEven
                                                                      ? Colors
                                                                            .white
                                                                      : Colors
                                                                            .grey
                                                                            .shade50,
                                                                  border: Border(
                                                                    left: BorderSide(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade300,
                                                                    ),
                                                                    right: BorderSide(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade300,
                                                                    ),
                                                                    bottom: BorderSide(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade300,
                                                                    ),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    _buildDataCell(
                                                                      '${index + 1}',
                                                                      columnWidths['no']!,
                                                                      align: TextAlign
                                                                          .center,
                                                                    ),
                                                                    _buildStatusCell(
                                                                      payment
                                                                          .status,
                                                                      columnWidths['status']!,
                                                                    ),
                                                                    _buildViewCell(
                                                                      context,
                                                                      payment,
                                                                      columnWidths['view']!,
                                                                    ),
                                                                    _buildPdfCell(
                                                                      payment,
                                                                      columnWidths['pdf']!,
                                                                      index,
                                                                    ),
                                                                    _buildDataCell(
                                                                      payment.vendorName ??
                                                                          'N/A',
                                                                      columnWidths['vendor']!,
                                                                    ),
                                                                    _buildDataCell(
                                                                      payment.invoiceNo ??
                                                                          'N/A',
                                                                      columnWidths['invoice']!,
                                                                    ),
                                                                    _buildDataCell(
                                                                      _formatDate(
                                                                        payment
                                                                            .invoiceDate,
                                                                      ),
                                                                      columnWidths['date']!,
                                                                    ),
                                                                    _buildDataCell(
                                                                      _formatCurrency(
                                                                        payment
                                                                            .payableAmount,
                                                                      ),
                                                                      columnWidths['total']!,
                                                                      isBold:
                                                                          true,
                                                                    ),
                                                                    _buildDataCell(
                                                                      _formatCurrency(
                                                                        payment.totalPaidAmount ??
                                                                            0,
                                                                      ),
                                                                      columnWidths['paid']!,
                                                                      isBold:
                                                                          true,
                                                                    ),
                                                                    _buildDataCell(
                                                                      _formatCurrency(
                                                                        (payment.payableAmount ??
                                                                                0) -
                                                                            (payment.totalPaidAmount ??
                                                                                0),
                                                                      ),
                                                                      columnWidths['balance']!,
                                                                      isBold:
                                                                          true,
                                                                    ),
                                                                    _buildDataCell(
                                                                      _formatDate(
                                                                        payment
                                                                            .paymentDate,
                                                                      ),
                                                                      columnWidths['payment_date']!,
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
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
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildHeaderCell(
    String text,
    double width, {
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: _getAlignment(align),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(
    String text,
    double width, {
    TextAlign align = TextAlign.center,
    bool isBold = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: _getAlignment(align),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          color: Colors.black,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusCell(String? status, double width) {
    final color = _getStatusColor(status);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.center,
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
    );
  }

  Widget _buildViewCell(BuildContext context, Outgoing payment, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(
          Icons.remove_red_eye,
          size: 22,
          color: Colors.blueAccent,
        ),
        onPressed: () => showPaymentDetailsTable(context, payment),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        iconSize: 22,
      ),
    );
  }

  Widget _buildPdfCell(Outgoing payment, double width, int index) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.center,
      child: ValueListenableBuilder<bool>(
        valueListenable: loadingPdfNotifiers[index]!,
        builder: (_, isLoading, __) {
          return isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () => _handlePdfClick(index, payment),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                );
        },
      ),
    );
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.center:
      default:
        return Alignment.center;
    }
  }

  Widget _buildSearchBar() {
    final focusNode = FocusNode();

    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, __) {
        return GestureDetector(
          onTap: () {
            // When tapping outside, unfocus and hide keyboard
            focusNode.unfocus();
            FocusScope.of(context).unfocus();
          },
          child: RawAutocomplete<String>(
            textEditingController: searchController,
            focusNode: focusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              final suggestions = _vendorSuggestions(provider);
              if (textEditingValue.text.isEmpty) return suggestions;
              return suggestions.where(
                (option) => option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            onSelected: (String selection) {
              searchController.text = selection;
              _filterPayments();

              // Hide keyboard after selection
              focusNode.unfocus();
              FocusScope.of(context).unfocus();
            },
            fieldViewBuilder:
                (context, controller, fieldFocusNode, onFieldSubmitted) {
                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      return TextField(
                        controller: controller,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search vendor name or invoice',
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    controller.clear();
                                    _filterPayments();
                                    // Keep focus on text field after clearing
                                    fieldFocusNode.requestFocus();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxHeight: 40),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (_) => _filterPayments(),
                      );
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 350,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          tileColor: Colors.white,
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
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
                    "Balance",
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
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              softWrap: true,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
