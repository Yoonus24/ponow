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
  final TextEditingController _vendorSearchController = TextEditingController();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  final ValueNotifier<String?> _selectedVendorNotifier = ValueNotifier(null);
  final FocusNode _vendorFocusNode = FocusNode();
  final LayerLink _vendorLayerLink = LayerLink();
  OverlayEntry? _vendorOverlay;

  // PDF loading state as ValueNotifier map
  final ValueNotifier<Map<int, bool>> _loadingPdfNotifier = ValueNotifier({});

  // Loading and error state notifiers
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> errorNotifier = ValueNotifier<String>("");
  final ScrollController verticalScrollController = ScrollController();
  final ScrollController horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _vendorSearchController.addListener(() {
      _searchQueryNotifier.value = _vendorSearchController.text.toLowerCase();
    });

    // Close overlay when focus changes
    _vendorFocusNode.addListener(() {
      if (!_vendorFocusNode.hasFocus) {
        _closeVendorOverlay();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void didUpdateWidget(covariant Ledger oldWidget) {
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
      final provider = Provider.of<OutgoingPaymentProvider>(
        context,
        listen: false,
      );

      await provider.fetchAllOutgoings(
        fromDate: widget.fromDate,
        toDate: widget.toDate,
      );

      loadingNotifier.value = false;
    } catch (e) {
      final provider = Provider.of<OutgoingPaymentProvider>(
        context,
        listen: false,
      );

      errorNotifier.value = provider.error.isNotEmpty
          ? provider.error
          : "Something went wrong";

      loadingNotifier.value = false;
    }
  }

  Future<void> _handleRefresh() async {
    final provider = Provider.of<OutgoingPaymentProvider>(
      context,
      listen: false,
    );

    await provider.fetchAllOutgoings(
      fromDate: widget.fromDate,
      toDate: widget.toDate,
    );
  }

  void _closeVendorOverlay() {
    _vendorOverlay?.remove();
    _vendorOverlay = null;
  }

  void _showVendorOverlay(List<String> vendors) {
    _closeVendorOverlay();

    final query = _vendorSearchController.text.toLowerCase();
    final filtered = vendors
        .where((v) => v.toLowerCase().contains(query))
        .toList();

    if (filtered.isEmpty) return;

    _vendorOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeVendorOverlay,
        child: CompositedTransformFollower(
          link: _vendorLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 230,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (filtered.length * 10.0).clamp(0, 200),
                    minHeight: 0, // Important: Allow minimum height to be 0
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics:
                        const ClampingScrollPhysics(), // Better scroll physics
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final vendor = filtered[index];
                      final isLastItem = index == filtered.length - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -4),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            title: Text(
                              vendor,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _selectedVendorNotifier.value = vendor;
                              _vendorSearchController.text = vendor;
                              _closeVendorOverlay();
                              _vendorFocusNode.unfocus();
                            },
                          ),
                          if (!isLastItem)
                            Divider(
                              height: 0,
                              thickness: 0.5,
                              color: Colors.grey.shade200,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_vendorOverlay!);
  }

  void _clearVendorFilter() {
    _vendorSearchController.clear();
    _selectedVendorNotifier.value = null;
    _searchQueryNotifier.value = '';
    _closeVendorOverlay();
  }

  List<Outgoing> _filterPayments(
    List<Outgoing> payments,
    String query,
    String? selectedVendor,
  ) {
    if (selectedVendor == null && query.isEmpty) {
      return payments;
    }

    return payments.where((payment) {
      final matchesSearch =
          query.isEmpty ||
          (payment.vendorName?.toLowerCase().contains(query) == true) ||
          (payment.invoiceNo?.toLowerCase().contains(query) == true);

      final matchesVendor =
          selectedVendor == null || payment.vendorName == selectedVendor;

      return matchesSearch && matchesVendor;
    }).toList();
  }

  double _calculateRemainingAmount(Outgoing p) {
    final original =
        p.originalTotalPayableAmount ??
        ((p.totalPaidAmount ?? 0) + (p.totalPayableAmount ?? 0));

    final paid = p.totalPaidAmount ?? 0;

    return (original - paid).clamp(0, double.infinity);
  }

  double _calculatePaidAmount(Outgoing payment) {
    return payment.totalPaidAmount ?? payment.paidAmount ?? 0.0;
  }

  Future<void> _generatePdf(int index, Outgoing payment) async {
    // Update loading state
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
      // Clear loading state
      final updatedMap = Map<int, bool>.from(_loadingPdfNotifier.value);
      updatedMap.remove(index);
      _loadingPdfNotifier.value = updatedMap;
    }
  }

  @override
  void dispose() {
    _closeVendorOverlay();
    _vendorSearchController.dispose();
    _searchQueryNotifier.dispose();
    _selectedVendorNotifier.dispose();
    _vendorFocusNode.dispose();
    loadingNotifier.dispose();
    errorNotifier.dispose();
    _loadingPdfNotifier.dispose();
    verticalScrollController.dispose();
    horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'LEDGER',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 230,
                    child: CompositedTransformTarget(
                      link: _vendorLayerLink,
                      child: Consumer<OutgoingPaymentProvider>(
                        builder: (context, provider, __) {
                          final availableVendors =
                              provider.payments
                                  .map((e) => e.vendorName ?? '')
                                  .where((e) => e.isNotEmpty)
                                  .toSet()
                                  .toList()
                                ..sort();

                          return ValueListenableBuilder<String?>(
                            valueListenable: _selectedVendorNotifier,
                            builder: (context, selectedVendor, _) {
                              final hasText =
                                  _vendorSearchController.text.isNotEmpty;

                              return TextField(
                                controller: _vendorSearchController,
                                focusNode: _vendorFocusNode,
                                decoration: InputDecoration(
                                  labelText: selectedVendor != null && !hasText
                                      ? selectedVendor
                                      : 'Search Vendor',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  suffixIcon:
                                      (hasText || selectedVendor != null)
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: _clearVendorFilter,
                                        )
                                      : const Icon(Icons.search, size: 20),
                                ),
                                onTap: () {
                                  if (availableVendors.isNotEmpty) {
                                    _showVendorOverlay(availableVendors);
                                  }
                                },
                                onChanged: (value) {
                                  if (value.isEmpty && selectedVendor == null) {
                                    _clearVendorFilter();
                                  } else if (availableVendors.isNotEmpty) {
                                    _showVendorOverlay(availableVendors);
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<OutgoingPaymentProvider>(
                builder: (context, provider, __) {
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

                            return RefreshIndicator(
                              onRefresh: _handleRefresh,
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
                              ),
                            );
                          }

                          return ValueListenableBuilder<String>(
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

                                  if (filteredPayments.isEmpty) {
                                    return RefreshIndicator(
                                      onRefresh: _handleRefresh,
                                      child: ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 300),
                                          Center(
                                            child: Text(
                                              "No ledger entries found",
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
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      controller: horizontalScrollController,
                                      child: SingleChildScrollView(
                                        controller: horizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: SingleChildScrollView(
                                          controller: verticalScrollController,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          child: SizedBox(
                                            width: 1300,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // HEADER
                                                Container(
                                                  color: Colors.blueAccent,
                                                  child: const Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 1,
                                                        child: _TableHeaderCell(
                                                          'PDF',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Payment Date',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 3,
                                                        child: _TableHeaderCell(
                                                          'Vendor Name',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Payment',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Reference',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Invoice Date',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Account Payable',
                                                          isNumeric: true,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Paid Amount',
                                                          isNumeric: true,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: _TableHeaderCell(
                                                          'Remaining',
                                                          isNumeric: true,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // ROWS
                                                ValueListenableBuilder<
                                                  Map<int, bool>
                                                >(
                                                  valueListenable:
                                                      _loadingPdfNotifier,
                                                  builder: (_, loadingMap, __) {
                                                    return ListView.builder(
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          filteredPayments
                                                              .length,
                                                      itemBuilder: (context, index) {
                                                        final payment =
                                                            filteredPayments[index];
                                                        final isEven =
                                                            index % 2 == 0;
                                                        final isLoadingPdf =
                                                            loadingMap[index] ==
                                                            true;

                                                        return Container(
                                                          decoration: BoxDecoration(
                                                            color: isEven
                                                                ? Colors.white
                                                                : Colors
                                                                      .grey
                                                                      .shade50,
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300,
                                                              ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                flex: 1,
                                                                child: SizedBox(
                                                                  height: 60,
                                                                  child: Center(
                                                                    child:
                                                                        isLoadingPdf
                                                                        ? const SizedBox(
                                                                            height:
                                                                                20,
                                                                            width:
                                                                                20,
                                                                            child: CircularProgressIndicator(
                                                                              strokeWidth: 2,
                                                                            ),
                                                                          )
                                                                        : IconButton(
                                                                            icon: const Icon(
                                                                              Icons.picture_as_pdf,
                                                                              color: Colors.redAccent,
                                                                              size: 22,
                                                                            ),
                                                                            onPressed: () => _generatePdf(
                                                                              index,
                                                                              payment,
                                                                            ),
                                                                            padding:
                                                                                EdgeInsets.zero,
                                                                            constraints: const BoxConstraints(
                                                                              minWidth: 32,
                                                                              minHeight: 32,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  payment.paymentDate !=
                                                                          null
                                                                      ? DateFormat(
                                                                          'dd-MM-yyyy',
                                                                        ).format(
                                                                          payment
                                                                              .paymentDate!,
                                                                        )
                                                                      : 'N/A',
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 3,
                                                                child: _tableCell(
                                                                  payment.vendorName ??
                                                                      'N/A',
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  payment.paymentMethod ??
                                                                      'N/A',
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  payment.neftNo ??
                                                                      '-',
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  payment.invoiceDate !=
                                                                          null
                                                                      ? DateFormat(
                                                                          'dd-MM-yyyy',
                                                                        ).format(
                                                                          payment
                                                                              .invoiceDate!,
                                                                        )
                                                                      : 'N/A',
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  (payment.originalTotalPayableAmount ??
                                                                          payment
                                                                              .totalPayableAmount ??
                                                                          payment
                                                                              .payableAmount ??
                                                                          0)
                                                                      .toStringAsFixed(
                                                                        2,
                                                                      ),
                                                                  isNumeric:
                                                                      true,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  _calculatePaidAmount(
                                                                    payment,
                                                                  ).toStringAsFixed(
                                                                    2,
                                                                  ),
                                                                  isNumeric:
                                                                      true,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 2,
                                                                child: _tableCell(
                                                                  payment.status ==
                                                                          'Partially Paid'
                                                                      ? _calculateRemainingAmount(
                                                                          payment,
                                                                        ).toStringAsFixed(
                                                                          2,
                                                                        )
                                                                      : '-',
                                                                  isNumeric:
                                                                      true,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final bool isNumeric;

  const _TableHeaderCell(this.text, {this.isNumeric = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Text(
        text,
        textAlign: isNumeric ? TextAlign.right : TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

Widget _tableCell(String text, {bool isNumeric = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Text(
      text,
      textAlign: isNumeric ? TextAlign.right : TextAlign.center,
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}
