import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/LEDGER/ledger.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/PAYMENT%20DONE/payment_done.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/PENDING%20OUTGOING/pendingOutgoing.dart';
import 'package:purchaseorders2/widgets/outgoing payment/pre_outgoing.dart';
import 'package:purchaseorders2/widgets/outgoing%20payment/PARTIAL%20PAYMENT/partial_payment.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../providers/outgoing_payment_provider.dart';

class OutgoingPaymentPage extends StatefulWidget {
  const OutgoingPaymentPage({super.key});

  @override
  State<OutgoingPaymentPage> createState() => _OutgoingPaymentPageState();
}

class _OutgoingPaymentPageState extends State<OutgoingPaymentPage> {
  final ValueNotifier<String> _selectedStatusNotifier = ValueNotifier<String>(
    'pending',
  );

  final ValueNotifier<Set<String>> _hoveredButtonsNotifier =
      ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> _hoveredDateButtonsNotifier =
      ValueNotifier<Set<String>>({});
  final ValueNotifier<DateTime?> _fromDateNotifier = ValueNotifier<DateTime?>(
    null,
  );
  final ValueNotifier<DateTime?> _toDateNotifier = ValueNotifier<DateTime?>(
    null,
  );

  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _horizontalScrollController;
  GRN? grn;
  ApInvoice? apInvoice;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<OutgoingPaymentProvider>();

      await provider.fetchGrnList();
      await provider.fetchApInvoices();
      await provider.fetchVendors();
      await provider.fetchInvoiceNumbers();
    });
  }

  dynamic _getBackendStatus(String uiStatus) {
    switch (uiStatus) {
      case 'pending':
        return ['created', 'Pending'];
      case 'payment_done':
        return 'Fully Paid';
      case 'partial_payment':
        return 'Partially Paid';
      case 'partially_paid':
        return 'Advance Paid';
      case 'ledger':
        return null;
      default:
        return null;
    }
  }

  void debugFiltering() {
    final provider = context.read<OutgoingPaymentProvider>();

    if (kDebugMode) {
      print('=== DEBUG FILTERING ===');
      print('Total payments: ${provider.allPayments.length}');
      print('UI Status: ${_selectedStatusNotifier.value}');
      print('Payment statuses found:');

      for (final payment in provider.allPayments.take(5)) {
        print(' - ${payment.outgoingId}: "${payment.status}"');
      }

      final pendingPayments = provider.allPayments
          .where((p) => p.status?.toLowerCase() == 'pending')
          .toList();
      print('Payments with "pending" status: ${pendingPayments.length}');
    }
  }

  Future<void> _fetchDataForStatus(String status) async {
    final provider = context.read<OutgoingPaymentProvider>();

    final fromDate = _fromDateNotifier.value;
    final toDate = _toDateNotifier.value;

    if (status == 'pending') {
      await provider.fetchFilteredOutgoings(
        status: 'Pending',
        filterBy: 'invoiceDate',
        fromDate: fromDate,
        toDate: toDate,
        limit: 100,
      );
    }

    if (status == 'payment_done') {
      await provider.fetchFilteredOutgoings(
        status: 'Fully Paid',
        filterBy: 'invoiceDate',
        fromDate: fromDate,
        toDate: toDate,
        limit: 100,
      );
    }

    if (status == 'partial_payment') {
      await provider.fetchFilteredOutgoings(
        status: 'Partially Paid',
        filterBy: 'invoiceDate',
        fromDate: fromDate,
        toDate: toDate,
        limit: 100,
      );
    }

    await provider.fetchVendors();
  }

  @override
  void dispose() {
    _selectedStatusNotifier.dispose();
    _hoveredButtonsNotifier.dispose();
    _hoveredDateButtonsNotifier.dispose();
    _fromDateNotifier.dispose();
    _toDateNotifier.dispose();
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: 'Outgoing Payments'),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterButtons(),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _selectedStatusNotifier,
              builder: (context, selectedStatus, _) {
                final backendStatus = _getBackendStatus(selectedStatus);

                switch (selectedStatus) {
                  case 'partial_payment':
                    return PartialPaymentPage(
                      status: backendStatus ?? 'Partially Paid',
                    );

                  case 'payment_done':
                    return PaymentDonePage(
                      status: 'Fully Paid',
                      fromDate: _fromDateNotifier.value,
                      toDate: _toDateNotifier.value,
                    );

                  case 'partially_paid':
                    return const PreOutgoing();

                  case 'ledger':
                    return Ledger(
                      status: '',
                      fromDate: _fromDateNotifier.value,
                      toDate: _toDateNotifier.value,
                    );

                  default:
                    return PendingOutgoing(filterStatus: selectedStatus);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Center(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ValueListenableBuilder<String>(
              valueListenable: _selectedStatusNotifier,
              builder: (context, selectedStatus, _) {
                final buttons = _buildAllFilterButtons(selectedStatus);
                buttons.sort((a, b) {
                  final aIsSelected =
                      a.key is ValueKey &&
                      (a.key as ValueKey).value == selectedStatus;
                  final bIsSelected =
                      b.key is ValueKey &&
                      (b.key as ValueKey).value == selectedStatus;
                  return aIsSelected ? -1 : (bIsSelected ? 1 : 0);
                });

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...buttons,
                    const SizedBox(width: 16),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: _fromDateNotifier,
                      builder: (_, __, ___) {
                        return ValueListenableBuilder<DateTime?>(
                          valueListenable: _toDateNotifier,
                          builder: (context, ___, ____) {
                            return _buildDateRangeButton();
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    final from = _fromDateNotifier.value;
    final to = _toDateNotifier.value;

    final bool isSelected = from != null || to != null;

    String label = "DATE";

    if (from != null && to != null) {
      label =
          "${from.day}/${from.month}/${from.year} - "
          "${to.day}/${to.month}/${to.year}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        elevation: isSelected ? 2 : 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await _selectDateRange(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.blueGrey[800],
                ),

                const SizedBox(width: 6),

                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14.5,
                  ),
                ),

                /// CLEAR BUTTON
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      _fromDateNotifier.value = null;
                      _toDateNotifier.value = null;

                      await _fetchDataForStatus(_selectedStatusNotifier.value);
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime serverDate;

    try {
      serverDate = ServerTimeService.now;
    } catch (_) {
      serverDate = DateTime.now();
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: serverDate,
      initialDateRange:
          (_fromDateNotifier.value != null && _toDateNotifier.value != null)
          ? DateTimeRange(
              start: _fromDateNotifier.value!,
              end: _toDateNotifier.value!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 38, 89, 198),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _fromDateNotifier.value = picked.start;
      _toDateNotifier.value = picked.end;

      await _fetchDataForStatus(_selectedStatusNotifier.value);
    }
  }

  List<Widget> _buildAllFilterButtons(String selectedStatus) {
    return [
      _buildFilterButton('PENDING OUTGOING', 'pending', 'btn1', selectedStatus),
      // _buildFilterButton( // PRE OUTGOING button hidden
      //   'PRE OUTGOING',
      //   'partially_paid',
      //   'btn2',
      //   selectedStatus,
      // ),
      _buildFilterButton(
        'PARTIAL PAYMENT',
        'partial_payment',
        'btn4',
        selectedStatus,
      ),
      _buildFilterButton(
        'PAYMENT DONE',
        'payment_done',
        'btn5',
        selectedStatus,
      ),
      _buildFilterButton('LEDGER', 'ledger', 'btn6', selectedStatus),
    ];
  }

  Widget _buildFilterButton(
    String label,
    String status,
    String uniqueId,
    String selectedStatus,
  ) {
    final isSelected = status == selectedStatus;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        elevation: isSelected ? 2 : 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _selectedStatusNotifier.value = status;
            _searchController.clear();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey[800],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
