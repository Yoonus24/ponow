import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../models/po.dart';
import '../providers/po_provider.dart';
import '../widgets/approved po/approved_po_widget.dart';
import '../widgets/approved po/gridview_approve_widget.dart';
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
  final ValueNotifier<DateTime?> selectedDate = ValueNotifier(null);
  final ValueNotifier<String> vendorName = ValueNotifier("");
  TextEditingController? _autoVendorCtrl;

  final int skip = 0;
  final int limit = 50;
  Timer? _vendorDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  Future<void> _onRefresh() async {
    final provider = context.read<POProvider>();

    if (vendorName.value.isNotEmpty || selectedDate.value != null) {
      await _applyFilters();
    } else {
      await provider.fetchApprovedPOsOnly();
    }
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<POProvider>(context, listen: false);

    await provider.fetchApprovedPOsOnly();
    await provider.fetchingVendors(vendorName: "", skip: skip, limit: limit);

    isInitialized.value = true;
  }

  @override
  void dispose() {
    _vendorDebounce?.cancel();
    vendorCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    final provider = Provider.of<POProvider>(context, listen: false);

    DateTime? fromDate;
    DateTime? toDate;

    if (selectedDate.value != null) {
      fromDate = selectedDate.value;
      toDate = selectedDate.value!.add(const Duration(days: 1));
    }

    await provider.fetchPOsWithFilters(
      status: "Approved",
      vendorName: vendorName.value.isNotEmpty ? vendorName.value : null,
      fromDate: fromDate,
      toDate: toDate,
      filterByField: "approvedDate",
      clearExisting: true,
    );
  }

  Future<void> _pickDate() async {
    DateTime initialDate;

    try {
      initialDate = ServerTimeService.now;
    } catch (_) {
      initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? initialDate,
      firstDate: DateTime(2000),
      lastDate: initialDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              background: Colors.white,
              surface: Colors.white,
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
      selectedDate.value = picked;
      dateCtrl.text = _fmt(picked);
      _applyFilters();
    }
  }

  void _clearVendor() {
    vendorCtrl.clear();
    _autoVendorCtrl?.clear();
    vendorName.value = "";
    FocusScope.of(context).unfocus();
    _applyFilters();
  }

  void _clearDate() {
    selectedDate.value = null;
    dateCtrl.clear();
    _applyFilters();
  }

  void _clearAll() {
    vendorCtrl.clear();
    dateCtrl.clear();
    vendorName.value = "";
    selectedDate.value = null;
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
                optionsBuilder: (TextEditingValue text) {
                  return provider.filteredVendorNames;
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
                      vendorName.value = v;

                      _vendorDebounce?.cancel();
                      _vendorDebounce = Timer(
                        const Duration(milliseconds: 500),
                        () {
                          if (v.isNotEmpty) {
                            _applyFilters();
                          }
                        },
                      );
                    },
                  );
                },

                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final option = options.elementAt(i);
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
    return ValueListenableBuilder<DateTime?>(
      valueListenable: selectedDate,
      builder: (_, value, __) {
        return SizedBox(
          height: 52,
          child: TextField(
            controller: dateCtrl,
            readOnly: true,
            onTap: _pickDate,
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

      body: RefreshIndicator(
        color: Colors.blueAccent,
        onRefresh: _onRefresh,

        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _filters(),

                    const SizedBox(height: 8),

                    ValueListenableBuilder<bool>(
                      valueListenable: isInitialized,
                      builder: (_, ready, __) {
                        if (!ready) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        return Consumer<POProvider>(
                          builder: (_, provider, __) {
                            if (provider.isLoading && provider.pos.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 120),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (provider.error != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 120),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "${provider.error}",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final list = provider.pos.where((po) {
                              if (po.poStatus != 'Approved' &&
                                  po.poStatus != 'PartiallyReceived') {
                                return false;
                              }

                              if (vendorName.value.isNotEmpty) {
                                final vendorMatch =
                                    po.vendorName?.toLowerCase().contains(
                                      vendorName.value.toLowerCase(),
                                    ) ??
                                    false;

                                if (!vendorMatch) return false;
                              }

                              if (selectedDate.value != null) {
                                final approvedDateStr = po.approvedDate;
                                if (approvedDateStr == null ||
                                    approvedDateStr.isEmpty) {
                                  return false;
                                }

                                final approvedDate = DateTime.tryParse(
                                  approvedDateStr,
                                );
                                if (approvedDate == null) return false;

                                final selected = selectedDate.value!;
                                final sameDay =
                                    approvedDate.year == selected.year &&
                                    approvedDate.month == selected.month &&
                                    approvedDate.day == selected.day;

                                if (!sameDay) return false;
                              }

                              return true;
                            }).toList();

                            if (list.isEmpty) {
                              final hasFilters =
                                  vendorName.value.isNotEmpty ||
                                  selectedDate.value != null;

                              return Padding(
                                padding: const EdgeInsets.only(top: 140),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        hasFilters
                                            ? "No results for filters"
                                            : "No approved POs Found",
                                        style: const TextStyle(
                                          color: Colors.grey,
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
                              );
                            }

                            return GridViewApproveWidget<PO>(
                              items: list,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, i) => ApprovedPOWidget(
                                po: list[i],
                                poProvider: provider,
                              ),
                              fixedHeight: 220,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
