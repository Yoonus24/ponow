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
  final ValueNotifier<Set<String>> _statusFilters = ValueNotifier(<String>{
    "Outgoing Posted",
  });

  final ValueNotifier<String> _vendorNotifier = ValueNotifier('');
  final ValueNotifier<DateTime?> _selectedDateNotifier = ValueNotifier(null);

  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final GlobalKey _autocompleteKey = GlobalKey();

  TextEditingController? _autoController;

  final int _skip = 0;
  final int _limit = 50;
  bool isInitialLoad = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      _applyFilters();
      await Provider.of<POProvider>(
        context,
        listen: false,
      ).fetchingVendors(vendorName: '', skip: _skip, limit: _limit);
    });
  }

  @override
  void dispose() {
    _vendorNotifier.dispose();
    _selectedDateNotifier.dispose();
    _vendorController.dispose();
    _dateController.dispose();
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

    if (value == "Outgoing Posted") {
      _statusFilters.value = {"Outgoing Posted"};
      return;
    }

    set.remove("Outgoing Posted");

    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.add(value);
    }

    if (set.isEmpty) {
      set.add("Outgoing Posted");
    }

    _statusFilters.value = set;
    _applyFilters();
  }

  void _applyFilters() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      Provider.of<APInvoiceProvider>(context, listen: false).fetchAPInvoices(
        status: _statusFilters.value.first,
        vendorName: _vendorNotifier.value,
        date: _selectedDateNotifier.value,
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

  Future<void> _selectDate() async {
    final backendDate = await _getServerDate();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateNotifier.value ?? backendDate,
      firstDate: DateTime(2000),
      lastDate: backendDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDateNotifier.value = picked; 

      _dateController.text =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";

      _applyFilters(); 
    }
  }

  void _clearDate() {
    _selectedDateNotifier.value = null;
    _dateController.clear();
    _applyFilters();
  }

  void _clearVendor() {
    _autoController?.clear();
    _vendorController.clear();
    _vendorNotifier.value = '';
    _applyFilters();
  }

  Widget _buildVendorField() {
    return Consumer<POProvider>(
      builder: (context, poProvider, _) {
        return SizedBox(
          height: 52,
          child: Autocomplete<String>(
            key: _autocompleteKey,
            optionsBuilder: (value) async {
              await poProvider.fetchingVendors(
                vendorName: value.text.trim(),
                skip: _skip,
                limit: _limit,
              );
              return poProvider.filteredVendorNames;
            },
            onSelected: (v) {
              _vendorController.text = v;
              _vendorNotifier.value = v;
              _applyFilters();
            },
            fieldViewBuilder: (context, controller, focusNode, _) {
              _autoController = controller;

              if (_vendorController.text != controller.text) {
                _vendorController.text = controller.text;
                _vendorController.selection = controller.selection;
              }

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
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          onPressed: _clearVendor,
                        )
                      : Icon(Icons.search, color: Colors.grey[600], size: 22),
                ),
                onChanged: (v) {
                  _vendorNotifier.value = v;
                  _applyFilters();
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
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
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 14.5),
                          ),
                          onTap: () {
                            onSelected(option);
                            FocusScope.of(context).unfocus();
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
          suffixIcon: ValueListenableBuilder<DateTime?>(
            valueListenable: _selectedDateNotifier,
            builder: (_, date, __) {
              return IconButton(
                icon: Icon(
                  date != null ? Icons.clear : Icons.calendar_today,
                  color: date != null ? Colors.redAccent : Colors.grey[700],
                  size: 20,
                ),
                onPressed: date != null ? _clearDate : _selectDate,
              );
            },
          ),
        ),
        onTap: _selectDate,
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
                  !(filters.length == 1 && filters.contains("Outgoing Posted"));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Invoice Type",
                          style: TextStyle(
                            fontSize: textSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),

                        const SizedBox(width: 8),

                        _typeButtonCompact("Goods", selected),
                        const SizedBox(width: 6),
                        _typeButtonCompact("Service", selected),
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
                        _statusMenuItem(
                          title: "Outgoing Posted",
                          value: "Outgoing Posted",
                        ),
                        _statusMenuItem(
                          title: "Partially Paid",
                          value: "Partially Paid",
                        ),
                        _statusMenuItem(
                          title: "Fully Paid",
                          value: "Fully Paid",
                        ),
                        _statusMenuItem(title: "Returned", value: "Returned"),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              _statusFilters.value = {"Outgoing Posted"};
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Reset Filters",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
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
    return Scaffold(
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
                    valueListenable: _selectedDateNotifier,
                    builder: (_, __, ___) {
                      return ValueListenableBuilder(
                        valueListenable: _invoiceType,
                        builder: (_, __, ___) {
                          return ValueListenableBuilder(
                            valueListenable: _statusFilters,
                            builder: (_, __, ___) {
                              return Consumer<APInvoiceProvider>(
                                builder: (context, provider, _) {
                                  if (provider.loading &&
                                      provider.isInitialLoad) {
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
                                            children: [
                                              Text(
                                                provider.error!,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.grey,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  var list = provider.apInvoices;
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
    );
  }
}
