// ignore_for_file: library_private_types_in_public_api, dead_null_aware_expression, use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/ap.dart';
import '../providers/ap_invoice_provider.dart';
import '../providers/po_provider.dart';
import '../widgets/ap invoice/ap_invoice_widget.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/grn/grid_view_widget.dart';

class APInvoicePage extends StatefulWidget {
  const APInvoicePage({super.key});

  @override
  _APInvoicePageState createState() => _APInvoicePageState();
}

class _APInvoicePageState extends State<APInvoicePage> {
  final ValueNotifier<String> _invoiceType = ValueNotifier("Goods");
  final ValueNotifier<Set<String>> _statusFilters = ValueNotifier(<String>{});

  final ValueNotifier<String> _vendorNotifier = ValueNotifier('');
  final ValueNotifier<DateTimeRange?> _selectedDateRangeNotifier =
      ValueNotifier(null);
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final GlobalKey _autocompleteKey = GlobalKey();

  TextEditingController? _autoController;

  int _skip = 0;
  final int _limit = 50;
  Timer? _debounce;
  final ValueNotifier<List<String>> _allVendors = ValueNotifier([]);
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _applyFilters();

      final poProvider = context.read<POProvider>();
      final vendors = poProvider.vendorCache;

      final names = vendors
          .map((e) => e.vendorName ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (!mounted) return;

      _allVendors.value = names;
    });
  }

  Future<void> _loadMore() async {
    final provider = context.read<APInvoiceProvider>();

    if (!provider.hasMore || provider.isLoadingMore) return;

    provider.isLoadingMore = true;
    provider.notifyListeners();

    _skip += _limit;

    String? selectedStatus = _statusFilters.value.isEmpty
        ? null
        : _statusFilters.value.first;

    await provider.fetchAPInvoices(
      status: selectedStatus,
      vendorName: _vendorNotifier.value.isNotEmpty
          ? _vendorNotifier.value
          : null,
      skip: _skip,
      limit: _limit,
    );

    provider.isLoadingMore = false;
    provider.notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vendorNotifier.dispose();
    _selectedDateRangeNotifier.dispose();
    _vendorController.dispose();
    _dateController.dispose();
    _allVendors.dispose();
    _invoiceType.dispose();
    super.dispose();
  }

  Future<DateTime> _getServerDate() async {
    try {
      return ServerTimeService.now;
    } catch (_) {
      return DateTime.now();
    }
  }

  bool isGoodsInvoice(ApInvoice inv) {
    if (inv.itemDetails == null || inv.itemDetails!.isEmpty) return false;
    return inv.itemDetails!.any((item) => (item.quantity ?? 0) > 0);
  }

  void _toggleFilter(String value) {
    final set = Set<String>.from(_statusFilters.value);

    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.clear();
      set.add(value);
    }

    _statusFilters.value = set;

    _applyFilters();
  }

  void _applyFilters() {
    _skip = 0;
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      DateTime? fromDate;
      DateTime? toDate;

      final range = _selectedDateRangeNotifier.value;

      if (range != null) {
        fromDate = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        toDate = DateTime(range.end.year, range.end.month, range.end.day);
      }

      String? selectedStatus = _statusFilters.value.isEmpty
          ? null
          : _statusFilters.value.first;

      context.read<APInvoiceProvider>().fetchAPInvoices(
        status: selectedStatus,
        vendorName: _vendorNotifier.value.isNotEmpty
            ? _vendorNotifier.value
            : null,
        fromDate: fromDate,
        toDate: toDate,
      );
    });
  }

  PopupMenuItem<String> _statusMenuItem({
    required String title,
    required String value,
  }) {
    return PopupMenuItem<String>(
      enabled: false,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: _statusFilters,
        builder: (context, filters, _) {
          final isSelected = filters.contains(value);

          return InkWell(
            onTap: () => _toggleFilter(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: Colors.blueAccent,
                    onChanged: (_) => _toggleFilter(value),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final backendDate = await _getServerDate();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: backendDate,
      initialDateRange: _selectedDateRangeNotifier.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDateRangeNotifier.value = picked;

      _dateController.text =
          "${_formatDate(picked.start)} → ${_formatDate(picked.end)}";

      _applyFilters();
    }
  }

  void _clearDate() {
    _selectedDateRangeNotifier.value = null;
    _dateController.clear();
    _applyFilters();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  void _clearVendor() {
    _autoController?.clear();
    _vendorController.clear();
    _vendorNotifier.value = '';
    _applyFilters();
  }

  Widget _buildVendorField() {
    return SizedBox(
      height: 52,
      child: Autocomplete<String>(
        key: _autocompleteKey,
        optionsBuilder: (TextEditingValue value) {
          final query = value.text.toLowerCase().trim();
          final vendors = _allVendors.value;

          if (query.isEmpty) {
            return vendors;
          }

          return vendors.where(
            (vendor) => vendor.toLowerCase().contains(query),
          );
        },

        onSelected: (v) {
          _vendorController.text = v;
          _vendorNotifier.value = v;

          FocusScope.of(context).unfocus();

          _applyFilters();
        },

        fieldViewBuilder: (context, controller, focusNode, _) {
          _autoController = controller;

          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: "Vendor",
              labelStyle: TextStyle(color: Colors.grey[700]),

              filled: true,
              fillColor: Colors.grey[50],

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 1.8,
                ),
              ),

              suffixIcon: ValueListenableBuilder(
                valueListenable: _vendorNotifier,
                builder: (_, value, __) {
                  if (value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear, color: Colors.redAccent),
                      onPressed: _clearVendor,
                    );
                  }

                  return Icon(Icons.search, color: Colors.grey[700]);
                },
              ),
            ),
            onChanged: (v) {
              _vendorNotifier.value = v;
            },
          );
        },

        optionsViewBuilder: (context, onSelected, options) {
          final optionList = options.toList();

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: optionList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final option = optionList[index];

                    return ListTile(
                      dense: true,
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 14.5),
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
  }

  Widget _buildDateField() {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Date",
          labelStyle: TextStyle(color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.8),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: ValueListenableBuilder<DateTimeRange?>(
            valueListenable: _selectedDateRangeNotifier,
            builder: (_, range, __) {
              return IconButton(
                icon: Icon(
                  range != null ? Icons.clear : Icons.calendar_today,
                  color: range != null ? Colors.redAccent : Colors.grey[700],
                  size: 20,
                ),
                onPressed: range != null ? _clearDate : _selectDateRange,
              );
            },
          ),
        ),
        onTap: _selectDateRange,
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: _buildVendorField()),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: _buildDateField()),
        ],
      ),
    );
  }

  Widget _buildInvoiceTypeRow() {
    return ValueListenableBuilder<String>(
      valueListenable: _invoiceType,
      builder: (context, selected, _) {
        final width = MediaQuery.of(context).size.width;

        final iconSize = width * 0.055;
        final textSize = width < 360 ? 12.5 : 14.5;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: _statusFilters,
            builder: (context, filters, _) {
              final bool hasCustomFilter =
                  !(filters.length == 1 && filters.contains("Pending Payment"));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Invoice Type : ",
                          style: TextStyle(
                            fontSize: textSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),

                        const SizedBox(width: 8),

                        _typeButtonCompact("Goods", selected),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: hasCustomFilter ? Colors.grey.shade200 : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      color: Colors.white,
                      offset: const Offset(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      icon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.filter_list_rounded,
                          color: Colors.blueGrey[700],
                          size: iconSize,
                        ),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: InkWell(
                            onTap: () {
                              _statusFilters.value = {};
                              _applyFilters();
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.clear,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Clear Filter",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const PopupMenuDivider(),

                        _statusMenuItem(title: "Verified", value: "Verified"),
                        _statusMenuItem(
                          title: "Partially Paid",
                          value: "Partially Paid",
                        ),
                        _statusMenuItem(
                          title: "Fully Paid",
                          value: "Fully Paid",
                        ),
                        _statusMenuItem(title: "Returned", value: "Returned"),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _typeButtonCompact(String type, String selected) {
    final isSelected = type == selected;

    return GestureDetector(
      onTap: () => _invoiceType.value = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 12.5,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: const CommonAppBar(title: "AP Invoices"),
        body: Column(
          children: [
            _buildFilterRow(),
            _buildInvoiceTypeRow(),
            Expanded(
              child: RefreshIndicator(
                color: Colors.blueAccent,
                backgroundColor: Colors.white,
                displacement: 40,
                strokeWidth: 3,
                onRefresh: () async {
                  _applyFilters();
                },
                child: ValueListenableBuilder(
                  valueListenable: _vendorNotifier,
                  builder: (_, __, ___) {
                    return ValueListenableBuilder(
                      valueListenable: _selectedDateRangeNotifier,
                      builder: (_, __, ___) {
                        return ValueListenableBuilder(
                          valueListenable: _invoiceType,
                          builder: (_, __, ___) {
                            return ValueListenableBuilder(
                              valueListenable: _statusFilters,
                              builder: (_, __, ___) {
                                return Consumer<APInvoiceProvider>(
                                  builder: (context, provider, _) {
                                    if (provider.loading) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.blueAccent,
                                        ),
                                      );
                                    }

                                    if (provider.error != null) {
                                      return ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 200),

                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.redAccent,
                                                  size: 40,
                                                ),

                                                const SizedBox(height: 12),

                                                Text(
                                                  provider.error ??
                                                      "Something went wrong",
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),

                                                const SizedBox(height: 14),

                                                ElevatedButton(
                                                  onPressed: _applyFilters,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blueAccent,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: const Text("Retry"),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    List<ApInvoice> list = List.from(
                                      provider.apInvoices,
                                    );
                                    if (list.isEmpty) {
                                      return ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: const [
                                          SizedBox(height: 200),
                                          Center(
                                            child: Text(
                                              "No invoices found",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    return GridViewWidget<ApInvoice>(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      items: list,
                                      hasMore: provider.hasMore,
                                      isLoading: provider.isLoadingMore,
                                      onLoadMore: _loadMore,
                                      itemBuilder: (context, index) {
                                        return APInvoiceWidget(
                                          apinvoice: list[index],
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
