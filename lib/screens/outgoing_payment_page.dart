import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/ap.dart';
import 'package:purchaseorders2/models/grn.dart';
import 'package:purchaseorders2/widgets/outgoing payment/ledger.dart';
import 'package:purchaseorders2/widgets/outgoing payment/payment_done.dart';
import 'package:purchaseorders2/widgets/outgoing payment/pendingOutgoing.dart';
import 'package:purchaseorders2/widgets/outgoing payment/pre_outgoing.dart';
import 'package:purchaseorders2/widgets/outgoing payment/partial_payment.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/common_bottom_nav.dart';
import '../providers/outgoing_payment_provider.dart';
import 'package:dio/dio.dart';

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
  DateTime? _serverNow;
  late final Dio _dio;

  @override
  void initState() {
    super.initState();

    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

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

  // List<Outgoing> filterPayments(List<Outgoing> allPayments, String uiStatus) {
  //   return allPayments.where((payment) {
  //     final status = payment.status?.toLowerCase() ?? '';

  //     switch (uiStatus) {
  //       case 'active':
  //         return status == 'pending';
  //       case 'partially_paid':
  //         return status == 'partially paid';
  //       case 'payment_done':
  //         return status == 'fully paid';
  //       case 'ledger':
  //         return true;
  //       default:
  //         return status == uiStatus;
  //     }
  //   }).toList();
  // }

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

  Future<void> _fetchServerDateTime() async {
    try {
      final response = await _dio.get('https://yenerp.com/liveapi/datetime');

      if (response.statusCode == 200) {
        final data = response.data;
        final dateStr = data['datetime'];

        if (dateStr != null && dateStr is String) {
          _serverNow = DateTime.parse(dateStr);
        }
      }
    } on DioException catch (e) {
      // 🌐 Internet illa → silent fail (UI already handles date logic)
      debugPrint('Server datetime fetch failed: ${e.type}');
    } catch (e) {
      debugPrint('Server datetime fetch failed: $e');
    }
  }

  Future<void> _fetchDataForStatus(String status) async {
    final provider = context.read<OutgoingPaymentProvider>();

    // ❌ DO NOTHING for pending
    // PendingOutgoing widget handles its own fetch
    if (status == 'pending') return;

    if (status == 'payment_done') {
      await provider.fetchFilteredOutgoings(
        status: 'Fully Paid',
        filterBy: 'invoiceDate',
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

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    // ✅ Always refresh server time first
    await _fetchServerDateTime();

    final DateTime serverDate = _serverNow ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: serverDate,
      firstDate: isFromDate
          ? DateTime(2000)
          : (_fromDateNotifier.value ?? DateTime(2000)),
      lastDate: isFromDate ? (_toDateNotifier.value ?? serverDate) : serverDate,
      selectableDayPredicate: (DateTime day) {
        if (isFromDate && _toDateNotifier.value != null) {
          return day.isBefore(_toDateNotifier.value!) ||
              day.isAtSameMomentAs(_toDateNotifier.value!);
        } else if (!isFromDate && _fromDateNotifier.value != null) {
          return day.isAfter(_fromDateNotifier.value!) ||
              day.isAtSameMomentAs(_fromDateNotifier.value!);
        }
        return true;
      },

      // 🎨 Custom theme: white bg, black text, blue accent
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 38, 89, 198), // blue accent
              onPrimary: Colors.white,
              onSurface: Colors.black, // date text
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 38, 89, 198),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final currentToDate = _toDateNotifier.value;
      final currentFromDate = _fromDateNotifier.value;

      if (isFromDate &&
          currentToDate != null &&
          picked.isAfter(currentToDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('From date cannot be after To date')),
        );
        return;
      }
      if (!isFromDate &&
          currentFromDate != null &&
          picked.isBefore(currentFromDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To date cannot be before From date')),
        );
        return;
      }

      if (isFromDate) {
        _fromDateNotifier.value = picked;
      } else {
        _toDateNotifier.value = picked;
      }

      await _fetchDataForStatus(_selectedStatusNotifier.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: 'Outgoing Payments'),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 80, child: _buildFilterButtons()),
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
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
                      builder: (context, fromDate, _) {
                        return _buildDateFilterButton(
                          'FROM DATE',
                          true,
                          'dateBtn1',
                          fromDate,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: _toDateNotifier,
                      builder: (context, toDate, _) {
                        return _buildDateFilterButton(
                          'TO DATE',
                          false,
                          'dateBtn2',
                          toDate,
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

  List<Widget> _buildAllFilterButtons(String selectedStatus) {
    return [
      _buildFilterButton('PENDING OUTGOING', 'pending', 'btn1', selectedStatus),
      _buildFilterButton(
        'PRE OUTGOING',
        'partially_paid',
        'btn2',
        selectedStatus,
      ),
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
    final baseWidth = 140.0;
    final baseHeight = 45.0;
    final selectedWidth = baseWidth * 1.1;
    final selectedHeight = baseHeight * 1.1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ValueListenableBuilder<Set<String>>(
        key: ValueKey(uniqueId),
        valueListenable: _hoveredButtonsNotifier,
        builder: (context, hoveredButtons, _) {
          final isHovered = hoveredButtons.contains(uniqueId);
          final currentWidth = isSelected
              ? selectedWidth
              : (isHovered ? baseWidth * 1.05 : baseWidth);
          final currentHeight = isSelected
              ? selectedHeight
              : (isHovered ? baseHeight * 1.05 : baseHeight);

          return MouseRegion(
            onEnter: (_) {
              _hoveredButtonsNotifier.value = {
                ..._hoveredButtonsNotifier.value,
                uniqueId,
              };
            },
            onExit: (_) {
              _hoveredButtonsNotifier.value = {..._hoveredButtonsNotifier.value}
                ..remove(uniqueId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: currentWidth,
              height: currentHeight,
              child: ElevatedButton(
                onPressed: () {
                  _selectedStatusNotifier.value = status;
                  _searchController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color.fromARGB(255, 38, 89, 198)
                      : const Color.fromARGB(255, 74, 122, 227),
                  foregroundColor: Colors.white,
                  elevation: isSelected ? 8 : (isHovered ? 4 : 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateFilterButton(
    String label,
    bool isFromDate,
    String uniqueId,
    DateTime? date,
  ) {
    final baseWidth = 140.0;
    final baseHeight = 45.0;
    final displayText = date != null
        ? '${label.split(' ')[0]}: ${date.day}/${date.month}/${date.year}'
        : label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: _hoveredDateButtonsNotifier,
        builder: (context, hoveredButtons, _) {
          final isHovered = hoveredButtons.contains(uniqueId);
          final currentWidth = isHovered ? baseWidth * 1.05 : baseWidth;
          final currentHeight = isHovered ? baseHeight * 1.05 : baseHeight;

          return MouseRegion(
            onEnter: (_) {
              _hoveredDateButtonsNotifier.value = {
                ..._hoveredDateButtonsNotifier.value,
                uniqueId,
              };
            },
            onExit: (_) {
              _hoveredDateButtonsNotifier.value = {
                ..._hoveredDateButtonsNotifier.value,
              }..remove(uniqueId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: currentWidth,
              height: currentHeight,
              child: OutlinedButton(
                onPressed: () => _selectDate(context, isFromDate),
                style: OutlinedButton.styleFrom(
                  backgroundColor: date != null
                      ? const Color.fromARGB(255, 230, 240, 255)
                      : Colors.white,
                  foregroundColor: date != null
                      ? const Color.fromARGB(255, 38, 89, 198)
                      : const Color.fromARGB(255, 74, 122, 227),
                  side: BorderSide(
                    color: isHovered
                        ? const Color.fromARGB(255, 38, 89, 198)
                        : const Color.fromARGB(255, 74, 122, 227),
                    width: 1.5,
                  ),
                  elevation: isHovered ? 4 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFromDate ? Icons.calendar_today : Icons.calendar_month,
                      size: 16,
                      color: date != null
                          ? const Color.fromARGB(255, 38, 89, 198)
                          : const Color.fromARGB(255, 74, 122, 227),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        displayText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: date != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
