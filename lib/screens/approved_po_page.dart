import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/po/po.dart';
import '../providers/po/po_provider.dart';
import '../widgets/approved_po/approved_po_widget.dart';
import '../widgets/approved_po/gridview_approve_widget.dart';
import '../widgets/common_app_bar.dart';

class ApprovedPOPage extends StatefulWidget {
  const ApprovedPOPage({super.key});

  @override
  _ApprovedPOPageState createState() => _ApprovedPOPageState();
}

class _ApprovedPOPageState extends State<ApprovedPOPage> {
  final TextEditingController vendorCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<DateTimeRange?> selectedDateRange = ValueNotifier(null);
  final ValueNotifier<String> vendorName = ValueNotifier("");
  TextEditingController? _autoVendorCtrl;
  final ScrollController _scrollController = ScrollController();
  final int skip = 0;
  final int limit = 50;
  Timer? _vendorDebounce;
  List<String> _allVendors = [];
  List<String> _displayedVendors = [];
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final provider = context.read<POProvider>();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!provider.isLoading && provider.pos.length >= 50) {
          provider.fetchPOsWithFilters(
            status: "Approved,PartiallyReceived",
            vendorName: vendorName.value.isNotEmpty ? vendorName.value : null,
            fromDate: selectedDateRange.value?.start,
            toDate: selectedDateRange.value?.end,
            filterByField: "orderDate",
            skip: provider.pos.length,
            append: true,
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final provider = context.read<POProvider>();

      await provider.fetchApprovedPOsOnly();

      // ✅ FIX: LOAD ONLY IF CACHE EMPTY
      if (provider.vendorCache.isEmpty && !provider.vendorsLoaded) {
        await provider.fetchingAllVendors(vendorName: '', skip: 0, limit: 5000);
      }

      // ✅ USE CACHE (NO API CALL AGAIN)
      final vendors = provider.vendorCache;

      _allVendors = vendors.map((e) => e.vendorName).toList();
      _displayedVendors = List.from(_allVendors);

      if (_disposed || !mounted) {
        return;
      }

      isInitialized.value = true;
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<POProvider>();

    if (vendorName.value.isNotEmpty || selectedDateRange.value != null) {
      await _applyFilters();
    } else {
      await provider.fetchApprovedPOsOnly();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _vendorDebounce?.cancel();
    vendorCtrl.dispose();
    dateCtrl.dispose();
    _scrollController.dispose();
    isInitialized.dispose();
    selectedDateRange.dispose();
    vendorName.dispose();
    super.dispose();
  }

  void _searchVendor(String query) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) {
      _displayedVendors = List.from(_allVendors);
      return;
    }

    _displayedVendors = _allVendors
        .where((v) => v.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _applyFilters() async {
    final provider = context.read<POProvider>();

    DateTime? fromDate;
    DateTime? toDate;

    if (selectedDateRange.value != null) {
      final range = selectedDateRange.value!;

      fromDate = DateTime(range.start.year, range.start.month, range.start.day);

      // include the full end day
      toDate = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
      ).add(const Duration(days: 1));
    }

    await provider.fetchPOsWithFilters(
      status: "Approved,PartiallyReceived",
      vendorName: vendorName.value.isNotEmpty ? vendorName.value : null,
      fromDate: fromDate,
      toDate: toDate,
      filterByField: "orderDate",
      clearExisting: true,
    );
  }

  Future<void> _pickDateRange() async {
    DateTime initialDate;

    try {
      initialDate = ServerTimeService.now;
    } catch (_) {
      initialDate = DateTime.now();
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: initialDate,
      initialDateRange: selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent, // header + selected range
              onPrimary: Colors.white, // text on selected
              onSurface: Colors.black, // normal text
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, // Cancel / Save buttons
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || _disposed) {
      return;
    }

    if (picked != null) {
      selectedDateRange.value = picked;

      dateCtrl.text = "${_fmt(picked.start)} → ${_fmt(picked.end)}";

      _applyFilters();
    }
  }

  void _clearVendor() {
    vendorCtrl.clear();
    _autoVendorCtrl?.clear();
    _displayedVendors = List.from(_allVendors);
    vendorName.value = "";
    FocusScope.of(context).unfocus();
    _applyFilters();
  }

  void _clearDate() {
    selectedDateRange.value = null;
    dateCtrl.clear();
    _applyFilters();
  }

  void _clearAll() {
    vendorCtrl.clear();
    dateCtrl.clear();
    vendorName.value = "";
    selectedDateRange.value = null;
    _applyFilters();
  }

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";

  Widget _buildVendorField() {
    return Consumer<POProvider>(
      builder: (_, provider, __) {
        return ValueListenableBuilder<String>(
          valueListenable: vendorName,
          builder: (_, value, __) {
            return SizedBox(
              height: 52,
              child: Autocomplete<String>(
                optionsBuilder: (value) {
                  final query = value.text.toLowerCase().trim();

                  if (query.isEmpty) {
                    return _displayedVendors;
                  }

                  return _displayedVendors.where(
                    (vendor) => vendor.toLowerCase().contains(query),
                  );
                },
                onSelected: (selected) {
                  vendorCtrl.text = selected;
                  vendorName.value = selected;
                  _applyFilters();
                  FocusScope.of(context).unfocus();
                },

                fieldViewBuilder: (context, ctrl, fn, _) {
                  _autoVendorCtrl = ctrl;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (vendorCtrl.text.isNotEmpty &&
                        ctrl.text != vendorCtrl.text) {
                      ctrl.value = ctrl.value.copyWith(
                        text: vendorCtrl.text,
                        selection: TextSelection.collapsed(
                          offset: vendorCtrl.text.length,
                        ),
                      );
                    }
                  });

                  return TextField(
                    controller: ctrl,
                    focusNode: fn,
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
                      suffixIcon: ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                              onPressed: _clearVendor,
                            )
                          : Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                    ),
                    onChanged: (v) {
                      _searchVendor(v);

                      if (v.isEmpty) {
                        vendorName.value = "";
                        _applyFilters();
                      }
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
      },
    );
  }

  Widget _buildDateField() {
    return ValueListenableBuilder<DateTimeRange?>(
      valueListenable: selectedDateRange,
      builder: (_, value, __) {
        return SizedBox(
          height: 52,
          child: TextField(
            controller: dateCtrl,
            readOnly: true,
            onTap: _pickDateRange,
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
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 1.8,
                ),
              ),

              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: value != null
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: _clearDate,
                    )
                  : Icon(
                      Icons.calendar_today,
                      color: Colors.grey[700],
                      size: 20,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildVendorField()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildDateField()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Approved Purchase Orders"),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: RefreshIndicator(
          color: Colors.blueAccent,
          onRefresh: _onRefresh,

          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _filters(),

                  const SizedBox(height: 8),

                  ValueListenableBuilder<bool>(
                    valueListenable: isInitialized,
                    builder: (_, ready, __) {
                      if (!ready) {
                        return const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return Consumer<POProvider>(
                        builder: (_, provider, __) {
                          if (!isInitialized.value) {
                            return const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (provider.error != null) {
                            return Expanded(
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 140),

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
                                          onPressed: _onRefresh,
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

                          final list = provider.pos
                              .where(
                                (po) =>
                                    po.poStatus != "GRNConverted" &&
                                    po.poStatus != "ConvertedToGRN",
                              )
                              .toList();

                          if (list.isEmpty && !provider.isLoading) {
                            final hasFilters =
                                vendorName.value.isNotEmpty ||
                                selectedDateRange.value != null;

                            return Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              hasFilters
                                                  ? "No results for filters"
                                                  : "No approved POs Found",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 17,
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            if (hasFilters)
                                              TextButton(
                                                onPressed: _clearAll,
                                                child: const Text(
                                                  "Clear Filters",
                                                  style: TextStyle(
                                                    color: Colors.blueAccent,
                                                    fontWeight: FontWeight.w600,
                                                  ),
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

                          return Expanded(
                            child: GridViewApproveWidget<PO>(
                              items: list,
                              itemBuilder: (_, i) => ApprovedPOWidget(
                                po: list[i],
                                poProvider: provider,
                              ),
                              fixedHeight: 180,
                            ),
                          );
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
    );
  }
}
