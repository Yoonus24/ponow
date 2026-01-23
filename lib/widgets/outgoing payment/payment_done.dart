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
  // -------------------------------
  // Value Notifiers (Reactive State)
  // -------------------------------
  final TextEditingController searchController = TextEditingController();

  final ValueNotifier<List<Outgoing>> filteredPaymentsNotifier =
      ValueNotifier<List<Outgoing>>([]);

  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> errorNotifier = ValueNotifier<String>("");

  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  // -------------------------------
  // INIT
  // -------------------------------
  @override
  void initState() {
    super.initState();

    searchController.addListener(_filterPayments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // -------------------------------
  // LOAD DATA
  // -------------------------------
  Future<void> _loadData() async {
    loadingNotifier.value = true;
    errorNotifier.value = "";

    try {
      final provider = context.read<OutgoingPaymentProvider>();

      await provider.fetchFilteredOutgoings(
        status: 'Fully Paid',
        filterByAmount: false,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      _filterPayments();
      loadingNotifier.value = false;
    } catch (e) {
      errorNotifier.value = "Failed to load payments: $e";
      loadingNotifier.value = false;
    }
  }

  // -------------------------------
  // FILTER
  // -------------------------------
  void _filterPayments() {
    final provider = context.read<OutgoingPaymentProvider>();

    final query = searchController.text.toLowerCase();
    final filtered = provider.payments.where((payment) {
      // if (payment.status?.toLowerCase() == 'active') return false;

      final matchesStatus =
          payment.status?.toLowerCase() == 'fully paid' ||
          payment.status?.toLowerCase() == 'partially paid';

      if (!matchesStatus) return false;

      final vendorName = payment.vendorName?.toLowerCase() ?? '';
      final invoiceNo = payment.invoiceNo?.toLowerCase() ?? '';

      return vendorName.contains(query) || invoiceNo.contains(query);
    }).toList();

    filteredPaymentsNotifier.value = filtered;
  }

  // -------------------------------
  // DISPOSE
  // -------------------------------
  @override
  void dispose() {
    searchController.removeListener(_filterPayments);
    searchController.dispose();

    filteredPaymentsNotifier.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();

    verticalController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  // -------------------------------
  // SMALL HELPERS
  // -------------------------------
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

  // double calculatePaid(Outgoing p) {
  //   if (p.status?.toLowerCase() == 'fully paid') {
  //     return p.fullPaymentAmount ?? 0;
  //   } else if (p.status?.toLowerCase() == 'partially paid') {
  //     return p.partialAmount ?? 0;
  //   }
  //   return (p.partialAmount ?? 0) + (p.fullPaymentAmount ?? 0);
  // }

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

  // -------------------------------
  // MAIN UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final columnWidths = {
      'no': 35.0,
      'vendor': 200.0,
      'invoice': 100.0,
      'date': 110.0,
      'total': 110.0,
      'paid': 110.0,
      'balance': 110.0,
      'spacer': 10.0,
      'payment_date': 110.0,
      'status': 70.0,
      'view': 55.0,
      'pdf': 55.0,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header section in same row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Small black text
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
                          if (error.isNotEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    error,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ValueListenableBuilder<List<Outgoing>>(
                            valueListenable: filteredPaymentsNotifier,
                            builder: (_, payments, __) {
                              if (payments.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No payments found",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              }

                              return Scrollbar(
                                thumbVisibility: true,
                                controller: horizontalController,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: horizontalController,
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    controller: verticalController,
                                    child: SizedBox(
                                      height: 468,
                                      child: SingleChildScrollView(
                                        controller: verticalController,
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                const Color.fromARGB(
                                                  255,
                                                  74,
                                                  122,
                                                  227,
                                                ), // Blue accent
                                              ),
                                          headingTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          dataRowHeight: 60,
                                          headingRowHeight: 48,
                                          horizontalMargin: 16,
                                          columnSpacing: 0,
                                          columns: _buildColumns(columnWidths),
                                          rows: payments
                                              .asMap()
                                              .entries
                                              .map(
                                                (e) => _buildRow(
                                                  e.key,
                                                  e.value,
                                                  columnWidths,
                                                  context,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
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

  // -------------------------------
  // SEARCH BAR (Updated)
  // -------------------------------
  Widget _buildSearchBar() {
    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, __) {
        return RawAutocomplete<String>(
          textEditingController: searchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            final suggestions = _vendorSuggestions(provider);
            if (textEditingValue.text.isEmpty) return suggestions;
            return suggestions.where(
              (option) => option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search vendor name or invoice',
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              controller.clear();
                              _filterPayments();
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
                          searchController.text = option;
                          _filterPayments();
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------
  // DATATABLE COLUMNS
  // -------------------------------
  List<DataColumn> _buildColumns(Map widths) {
    return [
      DataColumn(label: _cell("NO", widths['no'], align: TextAlign.center)),
      DataColumn(
        label: _cell("STATUS", widths['status'], align: TextAlign.center),
      ),
      DataColumn(label: _cell("VIEW", widths['view'], align: TextAlign.center)),
      DataColumn(label: _cell("PDF", widths['pdf'], align: TextAlign.center)),
      DataColumn(
        label: _cell("VENDOR", widths['vendor'], align: TextAlign.center),
      ),
      DataColumn(
        label: _cell("INVOICE", widths['invoice'], align: TextAlign.center),
      ),
      DataColumn(label: _cell("DATE", widths['date'], align: TextAlign.center)),
      DataColumn(
        label: _cell("TOTAL", widths['total'], align: TextAlign.center),
      ),
      DataColumn(label: _cell("PAID", widths['paid'], align: TextAlign.center)),
      DataColumn(
        label: _cell("BALANCE", widths['balance'], align: TextAlign.center),
      ),
      DataColumn(label: _cell("", widths['spacer'], align: TextAlign.center)),
      DataColumn(
        label: _cell(
          "PAYMENT DATE",
          widths['payment_date'],
          align: TextAlign.center,
        ),
      ),
    ];
  }

  // -------------------------------
  // DATATABLE ROW
  // -------------------------------
  DataRow _buildRow(int index, Outgoing p, Map w, BuildContext context) {
    return DataRow(
      cells: [
        _data("${index + 1}", w['no'], TextAlign.center),
        _statusCell(p.status, w['status']),
        _viewCell(context, p, w['view']),
        _pdfCell(context, p, w['pdf']),
        _data(p.vendorName ?? 'N/A', w['vendor'], TextAlign.center),
        _data(p.invoiceNo ?? 'N/A', w['invoice'], TextAlign.center),
        _data(_formatDate(p.invoiceDate), w['date'], TextAlign.center),
        _data(_formatCurrency(p.payableAmount), w['total'], TextAlign.center),
        _data(
          _formatCurrency(p.totalPaidAmount ?? 0),
          w['paid'],
          TextAlign.center,
        ),
        _data(
          _formatCurrency(p.remainingPayableAmount),
          w['balance'],
          TextAlign.center,
        ),

        DataCell(Container(width: w['spacer'])),
        _data(_formatDate(p.paymentDate), w['payment_date'], TextAlign.center),
      ],
    );
  }

  // -------------------------------
  // CELLS
  // -------------------------------
  Widget _cell(String t, double w, {TextAlign align = TextAlign.center}) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        t,
        textAlign: align,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  DataCell _data(String t, double w, TextAlign align) {
    return DataCell(
      SizedBox(
        width: w,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            t,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
      ),
    );
  }

  // STATUS CELL
  DataCell _statusCell(String? s, double width) {
    final color = _getStatusColor(s);
    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              _getStatusText(s),
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

  // VIEW CELL
  DataCell _viewCell(BuildContext c, Outgoing p, double w) {
    return DataCell(
      SizedBox(
        width: w,
        child: Center(
          child: IconButton(
            icon: const Icon(
              Icons.remove_red_eye,
              size: 22,
              color: Colors.blueAccent,
            ),
            onPressed: () => showPaymentDetailsTable(c, p),
          ),
        ),
      ),
    );
  }

  // PDF CELL
  DataCell _pdfCell(BuildContext c, Outgoing p, double w) {
    return DataCell(
      SizedBox(
        width: w,
        child: Center(
          child: IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: () async {
              try {
                final pdf = await OutgoingPdf().generateOutgoingPdf(
                  p.outgoingId,
                );

                await Printing.layoutPdf(
                  onLayout: (_) => pdf.readAsBytesSync(),
                );

                ScaffoldMessenger.of(
                  c,
                ).showSnackBar(const SnackBar(content: Text("PDF generated")));
              } catch (e) {
                ScaffoldMessenger.of(
                  c,
                ).showSnackBar(SnackBar(content: Text("PDF error: $e")));
              }
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------
  // PAYMENT DETAILS POPUP
  // -------------------------------
  void showPaymentDetailsTable(BuildContext context, Outgoing payment) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // ✅ more curved edges
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // ✅ match curve
            ),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header: centered title + right close icon
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

                  // 🔹 Close button
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
          // LABEL
          SizedBox(
            width: 100, // 👈 fixed width = perfect alignment
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // COLON
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

          // VALUE (wraps automatically)
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
