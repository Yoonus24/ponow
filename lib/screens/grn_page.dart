import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/grn/grn.dart';
import '../providers/grn_provider.dart';
import '../widgets/grn/grn_widget.dart';
import '../widgets/grn/grn_return_widget.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/grn/grid_view_widget.dart';
import '../providers/po/po_provider.dart';

class GRNPage extends StatefulWidget {
  const GRNPage({super.key});

  @override
  State<GRNPage> createState() => _GRNPageState();
}

class _GRNPageState extends State<GRNPage> {
  final ValueNotifier<String> _selectedButton = ValueNotifier<String>('active');
  // final TextEditingController _vendorSearchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  TextEditingController? _autoController;
  final TextEditingController _vendorController = TextEditingController();

  final ValueNotifier<String> _vendorNotifier = ValueNotifier('');
  final ValueNotifier<DateTimeRange?> _selectedDateRangeNotifier =
      ValueNotifier(null);
  final GlobalKey _autocompleteKey = GlobalKey();
  DateTimeRange? _selectedDateRange;
  bool _isInitialized = false;

  Timer? _debounceTimer;
  final int _skip = 0;
  final int _limit = 50;
  List<String> _allVendors = [];
  // List<String> _displayedVendors = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final poProvider = context.read<POProvider>();
      final grnProvider = context.read<GRNProvider>();

      if (grnProvider.grns.isEmpty) {
        _selectedButton.value = 'active';
        _applyFilters();
      }

      final vendors = poProvider.vendorCache;

      _allVendors = vendors.map((e) => e.vendorName).toList();
      // _displayedVendors = List.from(_allVendors);

      if (!mounted) return;
      _isInitialized = true;
    });

    // _vendorNotifier.addListener(_onVendorFilterChanged);
    _selectedDateRangeNotifier.addListener(_onDateFilterChanged);
    _selectedButton.addListener(_onStatusFilterChanged);
  }

  void _onDateFilterChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applyFilters();
      }
    });
  }

  void _onStatusFilterChanged() {
    if (mounted) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _selectedButton.dispose();
    _dateController.dispose();
    _vendorController.dispose();
    _vendorNotifier.dispose();
    _selectedDateRangeNotifier.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (!mounted) return;

    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    String? backendStatus;

    if (_selectedButton.value == 'active') {
      backendStatus = 'active';
    } else if (_selectedButton.value == 'returned') {
      backendStatus = 'returned';
    }

    DateTime? fromDate;
    DateTime? toDate;

    if (_selectedDateRange != null) {
      fromDate = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );

      toDate = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
      );
    }

    grnProvider.fetchFilteredGRNs(
      status: backendStatus,
      vendorName: _vendorNotifier.value.isNotEmpty
          ? _vendorNotifier.value
          : null,
      fromDate: fromDate,
      toDate: toDate,
      skip: 0,
      limit: _limit,
    );
  }

  Widget _buildVendorField() {
    return Consumer<POProvider>(
      builder: (context, poProvider, _) {
        return SizedBox(
          height: 52,
          child: Autocomplete<String>(
            key: _autocompleteKey,
            optionsBuilder: (value) {
              final query = value.text.toLowerCase().trim();

              if (query.isEmpty) {
                return _allVendors;
              }

              return _allVendors.where(
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
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          onPressed: _clearVendorFilter,
                        )
                      : Icon(Icons.search, color: Colors.grey[600], size: 22),
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
                    constraints: BoxConstraints(
                      maxHeight: optionList.length * 48.0 > 240
                          ? 240
                          : optionList.length * 48.0,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: optionList.length,
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
        onTap: _selectDateRange,
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
            builder: (_, dateRange, __) {
              return IconButton(
                icon: Icon(
                  dateRange != null ? Icons.clear : Icons.calendar_today,
                  color: dateRange != null
                      ? Colors.redAccent
                      : Colors.grey[700],
                  size: 20,
                ),
                onPressed: dateRange != null
                    ? _clearDateFilter
                    : _selectDateRange,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildVendorField()),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildDateField()),
        ],
      ),
    );
  }

  Widget _buildStatusButtons() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedButton,
      builder: (context, selected, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            children: [
              _statusPill(
                title: "GRN List",
                value: "active",
                selected: selected,
                onTap: () {
                  _selectedButton.value = 'active';
                },
              ),
              const SizedBox(width: 8),
              _statusPill(
                title: "GRN Returned",
                value: "returned",
                selected: selected,
                onTap: () {
                  _selectedButton.value = 'returned';
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusPill({
    required String title,
    required String value,
    required String selected,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selected == value;

    return Expanded(
      child: Material(
        elevation: isSelected ? 2 : 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
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

  Widget _buildContent() {
    return Consumer<GRNProvider>(
      builder: (context, provider, _) {
        //  SHOW LOADER WHEN FETCHING (FILTER / INITIAL / REFRESH)
        if (provider.isLoading && provider.grns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
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
                    const SizedBox(height: 10),
                    Text(
                      provider.error ?? "Something went wrong",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (provider.grns.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: const Center(
                    child: Text(
                      "No GRNs found",
                      style: TextStyle(color: Colors.grey, fontSize: 17),
                    ),
                  ),
                ),
              );
            },
          );
        }

        /// ✅ DATA
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridViewWidget<GRN>(
            items: provider.grns,
            hasMore: provider.hasMore,
            isLoading: provider.isLoadMore,
            onLoadMore: () async {
              if (!provider.isLoading &&
                  !provider.isLoadMore &&
                  provider.hasMore) {
                await provider.fetchFilteredGRNs(
                  status: _selectedButton.value == 'active'
                      ? 'active'
                      : 'returned',
                  vendorName: _vendorNotifier.value.isNotEmpty
                      ? _vendorNotifier.value
                      : null,
                  fromDate: _selectedDateRange?.start,
                  toDate: _selectedDateRange?.end,
                  skip: provider.grns.length,
                  limit: provider.limit,
                  loadMore: true,
                );
              }
            },
            itemBuilder: (context, index) {
              final grn = provider.grns[index];
              return _selectedButton.value == 'returned'
                  ? GRNReturnWidget(grn: grn)
                  : GRNWidget(grn: grn);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: const CommonAppBar(title: "Goods Receipt Notes"),
        body: Column(
          children: [
            _buildFilterRow(),
            _buildStatusButtons(),
            Expanded(
              child: RefreshIndicator(
                color: Colors.blueAccent,
                backgroundColor: Colors.white,
                displacement: 40,
                strokeWidth: 3,
                onRefresh: () async {
                  await Future.sync(() => _applyFilters());
                },
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearVendorFilter() {
    _debounceTimer?.cancel();
    _autoController?.clear();
    _vendorController.clear();
    _vendorNotifier.value = '';
    _applyFilters();
  }

  void _clearDateFilter() {
    _debounceTimer?.cancel();
    _selectedDateRange = null;
    _selectedDateRangeNotifier.value = null;
    _dateController.clear();
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    DateTime serverNow;

    try {
      serverNow = ServerTimeService.now;
    } catch (_) {
      serverNow = DateTime.now();
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: serverNow,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDateRange = picked;
      _selectedDateRangeNotifier.value = picked;

      _dateController.text =
          "${_formatDate(picked.start)} → ${_formatDate(picked.end)}";

      // _applyFilters();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}
