// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/outgoing.dart';
import '../../providers/outgoing_payment_provider.dart';

class Ledger extends StatefulWidget {
  final String status;
  final DateTime? fromDate;
  final DateTime? toDate;

  const Ledger({super.key, required this.status, this.fromDate, this.toDate});

  @override
  State<Ledger> createState() => _LedgerState();
}

class _LedgerState extends State<Ledger> {
  // 🔍 Search
  final TextEditingController _vendorSearchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  final ValueNotifier<String?> _selectedVendorNotifier = ValueNotifier(null);

  // 🎯 Focus + Overlay
  final FocusNode _vendorFocusNode = FocusNode();
  final LayerLink _vendorLayerLink = LayerLink();
  OverlayEntry? _vendorOverlay;

  @override
  void initState() {
    super.initState();

    _vendorSearchController.addListener(() {
      _searchQueryNotifier.value = _vendorSearchController.text.toLowerCase();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _vendorOverlay?.remove();
    _vendorSearchController.dispose();
    _searchQueryNotifier.dispose();
    _selectedVendorNotifier.dispose();
    _vendorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );

    await provider.fetchFilteredOutgoings(
      status: null,
      filterByAmount: false,
      fromDate: widget.fromDate,
      toDate: widget.toDate,
      filterBy: 'invoiceDate',
    );
  }

  // 🔽 Overlay dropdown (same UX as PO VendorAutocomplete)
  void _showVendorOverlay(List<String> vendors) {
    _vendorOverlay?.remove();

    final query = _vendorSearchController.text.toLowerCase();
    final filtered = vendors
        .where((v) => v.toLowerCase().contains(query))
        .toList();

    _vendorOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 230,
        child: CompositedTransformFollower(
          link: _vendorLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            color: Colors.white, // ✅ dropdown background white
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // ✅ extra safety
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300, // subtle border
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final vendor = filtered[index];
                  return ListTile(
                    dense: true,
                    title: Text(vendor),
                    onTap: () {
                      _selectedVendorNotifier.value = vendor;
                      _vendorSearchController.text = vendor;
                      _vendorOverlay?.remove();
                      _vendorOverlay = null;
                      _vendorFocusNode.requestFocus(); // 🔥 keep keyboard
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_vendorOverlay!);
  }

  List<Outgoing> _filterPayments(
    List<Outgoing> payments,
    String query,
    String? selectedVendor,
  ) {
    return payments.where((payment) {
      final matchesSearch =
          query.isEmpty ||
          (payment.vendorName?.toLowerCase().contains(query) == true ||
              payment.invoiceNo?.toLowerCase().contains(query) == true);

      final matchesVendor =
          selectedVendor == null || payment.vendorName == selectedVendor;

      return matchesSearch && matchesVendor;
    }).toList();
  }

  double _calculatePaidAmount(Outgoing payment) {
    return payment.totalPaidAmount ?? payment.paidAmount ?? 0.0;
  }

  Future<void> _generatePdf(Outgoing payment) async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<OutgoingPaymentProvider>(
      builder: (context, provider, _) {
        final availableVendors =
            provider.payments
                .map((e) => e.vendorName ?? '')
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _vendorOverlay?.remove();
            _vendorOverlay = null;
          },
          child: ValueListenableBuilder<String>(
            valueListenable: _searchQueryNotifier,
            builder: (_, searchQuery, __) {
              return ValueListenableBuilder<String?>(
                valueListenable: _selectedVendorNotifier,
                builder: (_, selectedVendor, __) {
                  final filteredPayments = _filterPayments(
                    provider.payments,
                    searchQuery,
                    selectedVendor,
                  );

                  return Column(
                    children: [
                      // 🔹 Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'LEDGER',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),

                            // 🔍 Vendor Search (PO-style)
                            SizedBox(
                              width: 230,
                              child: CompositedTransformTarget(
                                link: _vendorLayerLink,
                                child: TextField(
                                  controller: _vendorSearchController,
                                  focusNode: _vendorFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Search Vendor',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    suffixIcon:
                                        _vendorSearchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _vendorSearchController.clear();
                                              _selectedVendorNotifier.value =
                                                  null;
                                              _searchQueryNotifier.value = '';
                                              _showVendorOverlay(
                                                availableVendors,
                                              );
                                              _vendorFocusNode.requestFocus();
                                            },
                                          )
                                        : const Icon(Icons.arrow_drop_down),
                                  ),
                                  onTap: () =>
                                      _showVendorOverlay(availableVendors),
                                  onChanged: (_) =>
                                      _showVendorOverlay(availableVendors),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Table
                      Expanded(
                        child: provider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredPayments.isEmpty
                            ? const Center(
                                child: Text('No matching records found'),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowHeight: 56,
                                    dataRowHeight: 60,
                                    headingRowColor:
                                        const WidgetStatePropertyAll(
                                          Colors.blueAccent,
                                        ),
                                    columns: const [
                                      DataColumn(label: _Header('PDF')),
                                      DataColumn(
                                        label: _Header('Payment Date'),
                                      ),
                                      DataColumn(label: _Header('Vendor Name')),
                                      DataColumn(label: _Header('Payment')),
                                      DataColumn(label: _Header('Reference')),
                                      DataColumn(
                                        label: _Header('Invoice Date'),
                                      ),
                                      DataColumn(
                                        numeric: true,
                                        label: _Header('Account Payable'),
                                      ),
                                      DataColumn(
                                        numeric: true,
                                        label: _Header('Paid Amount'),
                                      ),
                                      DataColumn(
                                        numeric: true,
                                        label: _Header('Remaining'),
                                      ),
                                    ],
                                    rows: filteredPayments.map((payment) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _generatePdf(payment),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              payment.paymentDate != null
                                                  ? DateFormat(
                                                      'dd-MM-yyyy',
                                                    ).format(
                                                      payment.paymentDate!,
                                                    )
                                                  : 'N/A',
                                            ),
                                          ),
                                          DataCell(
                                            Text(payment.vendorName ?? 'N/A'),
                                          ),
                                          DataCell(
                                            Text(
                                              payment.paymentMethod ?? 'N/A',
                                            ),
                                          ),
                                          DataCell(Text(payment.neftNo ?? '-')),
                                          DataCell(
                                            Text(
                                              payment.invoiceDate != null
                                                  ? DateFormat(
                                                      'dd-MM-yyyy',
                                                    ).format(
                                                      payment.invoiceDate!,
                                                    )
                                                  : 'N/A',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              (payment.payableAmount ??
                                                      payment
                                                          .totalPayableAmount ??
                                                      0)
                                                  .toStringAsFixed(2),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _calculatePaidAmount(
                                                payment,
                                              ).toStringAsFixed(2),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              (payment.remainingPayableAmount ??
                                                      0)
                                                  .toStringAsFixed(2),
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
          ),
        );
      },
    );
  }
}

// 🔹 Header widget
class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
