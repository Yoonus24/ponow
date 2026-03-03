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

  bool _isLoading = false;

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
    } finally {
      _isLoading = false;
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
    final Color headerColor = Colors.blueAccent;
    final isSmallScreen = MediaQuery.of(context).size.width < 1000;

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
                        // Header with search bar
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Partial Payment',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(flex: 2, child: _buildSearchBar()),
                            ],
                          ),
                        ),

                        // FIXED: Horizontally scrollable table to fix overflow
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Table Header
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: headerColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHeaderCell(
                                        'No',
                                        width: 50,
                                        center: true,
                                      ),
                                      _buildHeaderCell(
                                        'View',
                                        width: 70,
                                        center: true,
                                      ),
                                      _buildHeaderCell(
                                        'PDF',
                                        width: 70,
                                        center: true,
                                      ),
                                      _buildHeaderCell(
                                        'Vendor Name',
                                        width: 150,
                                      ),
                                      _buildHeaderCell(
                                        'Invoice No',
                                        width: 120,
                                      ),
                                      _buildHeaderCell(
                                        'Invoice Date',
                                        width: 100,
                                      ),
                                      _buildHeaderCell(
                                        'Total Amount',
                                        width: 110,
                                        center: true,
                                      ),
                                      _buildHeaderCell(
                                        'Amount Paid',
                                        width: 110,
                                        center: true,
                                      ),
                                      _buildHeaderCell(
                                        'Payment Date',
                                        width: 100,
                                      ),
                                      _buildHeaderCell(
                                        'Discount',
                                        width: 90,
                                        center: true,
                                      ),
                                      _buildHeaderCell(
                                        'Payable Amount',
                                        width: 120,
                                        center: true,
                                      ),
                                    ],
                                  ),
                                ),
                                // Table Rows
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    children: filteredList.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final payment = entry.value;
                                      final serialNo = index + 1;

                                      return Container(
                                        height: 56,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                            left: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                            right: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // No - Serial Number
                                            _buildCell(
                                              '$serialNo',
                                              width: 50,
                                              center: true,
                                            ),

                                            // View Button
                                            _buildIconCell(
                                              Icons.remove_red_eye,
                                              color: Colors.black87,
                                              onPressed: () =>
                                                  showPaymentDetailsDialog(
                                                    context,
                                                    payment,
                                                  ),
                                              width: 70,
                                            ),

                                            // PDF Button
                                            _buildIconCell(
                                              Icons.picture_as_pdf,
                                              color: Colors.redAccent,
                                              onPressed: () =>
                                                  _generateAndViewPdf(payment),
                                              width: 70,
                                            ),

                                            // Vendor Name
                                            _buildCell(
                                              payment.vendorName ?? 'N/A',
                                              width: 150,
                                              center: true,
                                            ),

                                            // Invoice No
                                            _buildCell(
                                              payment.invoiceNo ?? 'N/A',
                                              width: 120,
                                              center: true,
                                            ),

                                            // Invoice Date
                                            _buildCell(
                                              _formatDate(payment.invoiceDate),
                                              width: 100,
                                              center: true,
                                            ),

                                            // Total Amount
                                            _buildCell(
                                              _formatCurrency(
                                                payment.totalPayableAmount,
                                              ),
                                              width: 110,
                                              center: true,
                                              isBold: true,
                                            ),

                                            // Amount Paid
                                            _buildCell(
                                              _formatCurrency(
                                                payment.totalPaidAmount,
                                              ),
                                              width: 110,
                                              center: true,
                                              isBold: true,
                                            ),

                                            // Payment Date
                                            _buildCell(
                                              _formatDate(payment.paymentDate),
                                              width: 100,
                                              center: true,
                                            ),

                                            // Discount
                                            _buildCell(
                                              _formatCurrency(
                                                payment.discountDetails,
                                              ),
                                              width: 90,
                                              center: true,
                                              isBold: true,
                                            ),

                                            // Payable Amount
                                            _buildCell(
                                              _formatCurrency(
                                                payment.payableAmount,
                                              ),
                                              width: 120,
                                              center: true,
                                              isBold: true,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
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
    // FIXED: Use consumer to avoid unnecessary rebuilds
    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, child) {
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
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 300,
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
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
