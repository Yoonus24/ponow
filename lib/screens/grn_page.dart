import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/grn.dart';
import '../providers/grn_provider.dart';
import '../widgets/grn/grn_widget.dart';
import '../widgets/grn/grn_return_widget.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/grn/grid_view_widget.dart';
import '../providers/po_provider.dart';

class GRNPage extends StatefulWidget {
  const GRNPage({super.key});

  @override
  State<GRNPage> createState() => _GRNPageState();
}

class _GRNPageState extends State<GRNPage> {
  final ValueNotifier<String> _selectedButton = ValueNotifier<String>('active');
  final TextEditingController _vendorSearchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  TextEditingController? _autoController;
  final TextEditingController _vendorController = TextEditingController();

  final ValueNotifier<String> _vendorNotifier = ValueNotifier('');
  final ValueNotifier<DateTime?> _selectedDateNotifier = ValueNotifier(null);

  final GlobalKey _autocompleteKey = GlobalKey();
  DateTime? _selectedDate;
  bool _isInitialized = false;

  Timer? _debounceTimer;
  final int _skip = 0;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final poProvider = Provider.of<POProvider>(context, listen: false);

      // ✅ trigger initial load through same flow
      _selectedButton.value = 'active';
      _applyFilters();

      if (poProvider.filteredVendorNames.isEmpty) {
        await poProvider.fetchingVendors(
          vendorName: '',
          skip: _skip,
          limit: _limit,
        );
      }

      if (!mounted) return;
      _isInitialized = true; // no setState needed
    });

    _vendorNotifier.addListener(_onVendorFilterChanged);
    _selectedDateNotifier.addListener(_onDateFilterChanged);
    _selectedButton.addListener(_onStatusFilterChanged);
  }

  void _onVendorFilterChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _applyFilters();
      }
    });
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
    _vendorSearchController.dispose();
    _dateController.dispose();
    _vendorController.dispose();
    _vendorNotifier.dispose();
    _selectedDateNotifier.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (!mounted) return;

    final grnProvider = Provider.of<GRNProvider>(context, listen: false);

    String? backendStatus;

    if (_selectedButton.value == 'active') {
      backendStatus = 'active';
    } else if (_selectedButton.value == 'returned') {
      backendStatus = 'returned'; // used only to switch API
    }

    grnProvider.fetchFilteredGRNs(
      status: backendStatus,
      vendorName: _vendorNotifier.value.isNotEmpty
          ? _vendorNotifier.value
          : null,
      date: _selectedDate,
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
            optionsBuilder: (value) async {
              if (value.text.isEmpty) return const Iterable<String>.empty();

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

              FocusScope.of(context).unfocus();
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
                          onTap: () => onSelected(option),
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
                onPressed: date != null ? _clearDateFilter : _selectDate,
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
        // 🔥 SHOW LOADER WHEN FETCHING (FILTER / INITIAL / REFRESH)
        if (provider.isLoading && provider.grns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 200),
              Center(
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }

        if (provider.grns.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(
                child: Text(
                  "No GRNs found",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            // 🔥 MAIN GRID
            Padding(
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
                      date: _selectedDate,
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
            ),

            // 🔥 OVERLAY LOADER (WHEN FILTERING)
            if (provider.isLoading)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  void _clearVendorFilter() {
    _debounceTimer?.cancel();
    _autoController?.clear();
    _vendorController.clear();
    _vendorSearchController.clear();
    _vendorNotifier.value = '';
  }

  void _clearDateFilter() {
    _debounceTimer?.cancel();
    _selectedDate = null;
    _selectedDateNotifier.value = null;
    _dateController.clear();
  }

  Future<void> _selectDate() async {
    DateTime? serverNow;

    try {
      serverNow = ServerTimeService.now;
    } catch (_) {}

    if (!mounted) return;

    if (serverNow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to fetch server date. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? serverNow,
      firstDate: DateTime(2000),
      lastDate: serverNow,
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

    if (!mounted) return;

    if (picked != null) {
      _selectedDate = picked;
      _selectedDateNotifier.value = picked;
      _dateController.text = _formatDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}
