import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/po.dart';
import '../providers/po_provider.dart';
import '../widgets/approved po/approved_po_widget.dart';
import '../widgets/approved po/gridview_approve_widget.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/common_bottom_nav.dart';

class ApprovedPOPage extends StatefulWidget {
  const ApprovedPOPage({super.key});

  @override
  _ApprovedPOPageState createState() => _ApprovedPOPageState();
}

class _ApprovedPOPageState extends State<ApprovedPOPage> {
  // ---------------- CONTROLLERS ----------------
  final TextEditingController vendorCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();

  // ---------------- VALUE NOTIFIERS ----------------
  final ValueNotifier<bool> isInitialized = ValueNotifier(false);
  final ValueNotifier<DateTime?> selectedDate = ValueNotifier(null);
  final ValueNotifier<String> vendorName = ValueNotifier("");

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

  // ---------------- APPLY FILTERS ----------------
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

  // ---------------- DATE PICKER ----------------
  Future<void> _pickDate() async {
    final provider = Provider.of<POProvider>(context, listen: false);

    DateTime initialDate = DateTime.now();
    try {
      final serverDate = await provider.getServerDate();
      if (serverDate != null && serverDate.isNotEmpty) {
        final parts = serverDate.split("-"); // dd-mm-yyyy
        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}

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
              primary: Colors.blueAccent, // header & selected date
              onPrimary: Colors.white, // header text
              onSurface: Colors.black, // date numbers
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, // OK / CANCEL
              ),
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

  // ---------------- CLEAR FILTERS ----------------
  void _clearVendor() {
    vendorCtrl.clear();
    vendorName.value = "";
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

  // ---------------- UI BUILDERS ----------------

  Widget _buildVendorField() {
    return Consumer<POProvider>(
      builder: (_, provider, __) {
        return ValueListenableBuilder<String>(
          valueListenable: vendorName,
          builder: (_, value, __) {
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue text) {
                provider.fetchingVendors(
                  vendorName: text.text.trim(),
                  skip: skip,
                  limit: limit,
                );

                return provider.filteredVendorNames;
              },

              onSelected: (selected) {
                vendorCtrl.text = selected;
                vendorName.value = selected;
                _applyFilters();
              },
              fieldViewBuilder: (context, ctrl, fn, submit) {
                ctrl.text = vendorCtrl.text; // Keep sync

                return TextField(
                  controller: vendorCtrl,
                  focusNode: fn,
                  decoration: InputDecoration(
                    labelText: "Vendor",
                    border: const OutlineInputBorder(),
                    suffixIcon: vendorCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearVendor,
                          )
                        : const Icon(Icons.search),
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
                return Material(
                  elevation: 6,
                  color: Colors.white, // ✅ DROPDOWN BACKGROUND
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white, // ✅ DOUBLE SAFETY
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final option = options.elementAt(i);
                        return ListTile(
                          tileColor: Colors.white, // ✅ EACH ROW WHITE
                          title: Text(
                            option,
                            style: const TextStyle(color: Colors.black),
                          ),
                          hoverColor: Colors.grey.shade100,
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                );
              },
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
        return TextField(
          controller: dateCtrl,
          readOnly: true,
          onTap: _pickDate,
          decoration: InputDecoration(
            labelText: "Date",
            border: const OutlineInputBorder(),
            suffixIcon: value != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearDate,
                  )
                : const Icon(Icons.calendar_today),
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

  // ---------------- MAIN BUILD ----------------
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // 🔥 FULL SCREEN
                ),
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
                            if (provider.isLoading) {
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
                                        "Error: ${provider.error}",
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _onRefresh,
                                        child: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final list = provider.pos.where((po) {
                              // ---------- VENDOR FILTER ----------
                              if (vendorName.value.isNotEmpty) {
                                final vendorMatch =
                                    po.vendorName?.toLowerCase().contains(
                                      vendorName.value.toLowerCase(),
                                    ) ??
                                    false;

                                if (!vendorMatch) return false;
                              }

                              // ---------- DATE FILTER (APPROVED DATE) ----------
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
                                              color: Colors
                                                  .blueAccent, // ✅ TEXT COLOR
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // ✅ GridView inside scroll → shrinkWrap true
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
