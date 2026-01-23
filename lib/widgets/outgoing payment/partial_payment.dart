import 'dart:async';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/outgoing.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/outgoing_payment_provider.dart';
import 'package:intl/intl.dart';

class PartialPaymentPage extends StatefulWidget {
  final String status;

  const PartialPaymentPage({super.key, required this.status});

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

  @override
  void initState() {
    super.initState();

    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filteredPaymentsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasErrorNotifier.dispose();
    _errorMessageNotifier.dispose();
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final provider = Provider.of<OutgoingPaymentProvider>(
        context,
        listen: false,
      );
      await provider.fetchFilteredOutgoings(
        status: 'Partially Paid',
        filterBy: 'invoiceDate',
        limit: 200,
      );

      if (!mounted) return;

      _filteredPaymentsNotifier.value = provider.payments
          .where((p) => p.status == 'Partially Paid')
          .toList();
      _isLoadingNotifier.value = false;
      _hasErrorNotifier.value = provider.error.isNotEmpty;
      _errorMessageNotifier.value = provider.error;
    } catch (e) {
      if (!mounted) return;
      _isLoadingNotifier.value = false;
      _hasErrorNotifier.value = true;
      _errorMessageNotifier.value = 'Error loading data: $e';
    }
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

  Future<void> _generateAndViewPdf(Outgoing payment) async {
    try {
      final poService = OutgoingPdf();
      final pdfFile = await poService.generateOutgoingPdf(payment.outgoingId);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final Color headerColor = Colors.blueAccent;

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<bool>(
              valueListenable: _hasErrorNotifier,
              builder: (context, hasError, _) {
                if (hasError) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _errorMessageNotifier,
                    builder: (context, errorMessage, _) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $errorMessage',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return ValueListenableBuilder<List<Outgoing>>(
                  valueListenable: _filteredPaymentsNotifier,
                  builder: (context, filteredList, _) {
                    if (filteredList.isEmpty) {
                      return const Center(
                        child: Text(
                          'No partial payments found.',
                          style: TextStyle(fontSize: 17, color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Header Section: Title + Search in same row
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              // Small black text
                              Text(
                                'Partial Payment',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),

                              Expanded(flex: 2, child: _buildSearchBar()),
                            ],
                          ),
                        ),

                        // Table
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: DataTable(
                                headingRowHeight: 48,
                                dataRowHeight: 56,
                                headingRowColor: WidgetStatePropertyAll(
                                  headerColor,
                                ),
                                columnSpacing: 16,
                                dividerThickness: 1,
                                columns: [
                                  DataColumn(
                                    label: _headerText('No', center: true),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: _headerText('View', center: true),
                                  ),
                                  DataColumn(
                                    label: _headerText('PDF', center: true),
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Vendor Name',
                                      center: true,
                                    ),
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Invoice No',
                                      center: true,
                                    ),
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Invoice Date',
                                      center: true,
                                    ),
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Total Amount',
                                      center: true,
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Amount Paid',
                                      center: true,
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Payment Date',
                                      center: true,
                                    ),
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Discount',
                                      center: true,
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: _headerText(
                                      'Payable Amount',
                                      center: true,
                                    ),
                                    numeric: true,
                                  ),
                                ],
                                rows: filteredList.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final payment = entry.value;

                                  return DataRow(
                                    color: WidgetStatePropertyAll(
                                      entry.key.isEven
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                    cells: [
                                      DataCell(
                                        Center(
                                          child: Text(
                                            '$index',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.remove_red_eye,
                                              size: 22,
                                              color: Colors.black87,
                                            ),
                                            tooltip: 'View Details',
                                            onPressed: () =>
                                                showPaymentDetailsDialog(
                                                  context,
                                                  payment,
                                                ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.redAccent,
                                              size: 22,
                                            ),
                                            tooltip: 'View PDF',
                                            onPressed: () =>
                                                _generateAndViewPdf(payment),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            payment.vendorName ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            payment.invoiceNo ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            _formatDate(payment.invoiceDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            _formatCurrency(
                                              payment.payableAmount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            _formatCurrency(
                                              payment.totalPaidAmount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),

                                      DataCell(
                                        Center(
                                          child: Text(
                                            _formatDate(payment.paymentDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            _formatCurrency(
                                              payment.discountDetails,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            _formatCurrency(
                                              payment.totalPayableAmount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _headerText(String text, {bool center = true}) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 12,
      ),
      textAlign: center ? TextAlign.center : null,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSearchBar() {
    final provider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );
    final suggestions = provider.payments
        .where((p) => (p.status ?? '').toLowerCase() == 'partially paid')
        .map((p) => (p.vendorName ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    return RawAutocomplete<String>(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return suggestions;
        return suggestions.where(
          (option) => option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search vendor or invoice',
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      _onSearchChanged();
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
              horizontal: 14,
              vertical: 12,
            ),
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 48),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => _onSearchChanged(),
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
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
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
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    onTap: () {
                      onSelected(option);
                      _searchController.text = option;
                      _onSearchChanged();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void showPaymentDetailsDialog(BuildContext context, Outgoing payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white, // ✅ force white
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
                // 🔹 Header: centered title + right close
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
                  '${payment.taxDetails?.toStringAsFixed(2) ?? '0.00'}',
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
                      backgroundColor: Colors.blue,
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
