import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grn.dart';
import '../providers/grn_provider.dart';
import '../widgets/grn/grn_widget.dart';
import '../widgets/grn/grn_return_widget.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/grn/grid_view_widget.dart';
import '../widgets/common_bottom_nav.dart';
import '../providers/po_provider.dart';

class GRNPage extends StatefulWidget {
  const GRNPage({super.key});

  @override
  State<GRNPage> createState() => _GRNPageState();
}

class _GRNPageState extends State<GRNPage> {
  final ValueNotifier<String> _selectedButton = ValueNotifier<String>('active');
  final ValueNotifier<String> _selectedVendorNotifier = ValueNotifier('');
  final TextEditingController _vendorSearchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final ValueNotifier<int> _uiRefresh = ValueNotifier(0);

  final GlobalKey _autocompleteKey = GlobalKey();
  DateTime? _selectedDate;
  bool _isInitialized = false;

  final int _skip = 0;
  final int _limit = 50;

  // ✅ SAFE refresh
  void _refresh() {
    if (!mounted) return;
    _uiRefresh.value++;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final grnProvider = Provider.of<GRNProvider>(context, listen: false);
      final poProvider = Provider.of<POProvider>(context, listen: false);

      // Set default filter
      grnProvider.setFilterStatus('active');

      await grnProvider.fetchFilteredGRNs();
      await poProvider.fetchingVendors(
        vendorName: '',
        skip: _skip,
        limit: _limit,
      );

      if (!mounted) return;
      _isInitialized = true;
      _refresh();
    });

    _vendorSearchController.addListener(() {
      if (!mounted) return;
      if (_vendorSearchController.text != _selectedVendorNotifier.value) {
        _selectedVendorNotifier.value = _vendorSearchController.text;
      }
    });

    _selectedVendorNotifier.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _uiRefresh.dispose();
    _selectedButton.dispose();
    _selectedVendorNotifier.dispose();
    _vendorSearchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (!mounted) return;
    _refresh();
  }

  // ------------------- Vendor Field -------------------
  Widget _buildVendorField() {
    return Consumer<POProvider>(
      builder: (context, poProvider, _) {
        return Autocomplete<String>(
          key: _autocompleteKey,

          optionsBuilder: (value) async {
            await poProvider.fetchingVendors(
              vendorName: value.text.trim(),
              skip: _skip,
              limit: _limit,
            );
            return poProvider.filteredVendorNames;
          },

          onSelected: (vendor) {
            _selectedVendorNotifier.value = vendor;
            _vendorSearchController.text = vendor;
            FocusScope.of(context).unfocus();
          },

          // ✅ WHITE DROPDOWN
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220, // 🔥 LIMIT DROPDOWN HEIGHT
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.65,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              option,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },

          fieldViewBuilder: (context, controller, focusNode, _) {
            if (_vendorSearchController.text != controller.text) {
              controller.text = _vendorSearchController.text;
            }

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Vendor',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: const OutlineInputBorder(),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearVendorFilter,
                      )
                    : const Icon(Icons.search, size: 20),
              ),
              onChanged: (value) {
                _vendorSearchController.text = value;
                _selectedVendorNotifier.value = value;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Date',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        border: const OutlineInputBorder(),

        // ✅ DO NOT let suffix take extra width
        suffixIconConstraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),

        suffixIcon: _selectedDate != null
            ? GestureDetector(
                onTap: _clearDateFilter,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.clear, size: 18),
                ),
              )
            : const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.calendar_today, size: 18),
              ),
      ),
      onTap: () => _selectDate(context),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _selectedButton.value = 'active';
                    Provider.of<GRNProvider>(
                      context,
                      listen: false,
                    ).setFilterStatus('active');
                    _refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected == 'active'
                        ? Colors.blueAccent.shade400
                        : Colors.blueAccent.shade100,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("GRN List"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _selectedButton.value = 'returned';
                    Provider.of<GRNProvider>(
                      context,
                      listen: false,
                    ).setFilterStatus('returned');
                    _refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected == 'returned'
                        ? Colors.blueAccent.shade400
                        : Colors.blueAccent.shade100,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("GRN Returned"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Consumer<GRNProvider>(
      builder: (context, provider, _) {
        // 🔹 Loading state
        if (!_isInitialized || provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = _getFilteredGRNs(provider);

        // 🔹 EMPTY STATE → MUST BE SCROLLABLE
        if (list.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(
                child: Text(
                  "No GRNs found",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          );
        }

        // 🔹 DATA STATE → GRID (already scrollable)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GridViewWidget<GRN>(
            items: list,
            itemBuilder: (context, index) {
              final grn = list[index];
              return provider.filterStatus == 'returned'
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
    return ValueListenableBuilder(
      valueListenable: _uiRefresh,
      builder: (_, __, ___) {
        return Scaffold(
          appBar: const CommonAppBar(title: "Goods Receipt Notes"),
          body: Column(
            children: [
              _buildFilterRow(),
              _buildStatusButtons(),

              // ✅ FULL SCREEN PULL-TO-REFRESH
              Expanded(
                child: RefreshIndicator(
                  color: Colors.blueAccent, // ✅ LOADER COLOR
                  backgroundColor: Colors.white, // ✅ BG COLOR
                  displacement: 40, // optional (nice spacing)
                  strokeWidth: 3, // optional (thickness)

                  onRefresh: () async {
                    final grnProvider = Provider.of<GRNProvider>(
                      context,
                      listen: false,
                    );
                    await grnProvider.fetchFilteredGRNs();
                  },

                  child: _buildContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearVendorFilter() {
    if (!mounted) return;
    _selectedVendorNotifier.value = '';
    _vendorSearchController.clear();
    _refresh();
  }

  void _clearDateFilter() {
    if (!mounted) return;
    _selectedDate = null;
    _dateController.clear();
    _refresh();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              surface: Colors.white,
              primary: Colors.blueAccent, // header & selected date
              onPrimary: Colors.white, // header text
              onSurface: Colors.black, // date numbers
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, // OK / CANCEL
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      _selectedDate = picked;
      _dateController.text = _formatDate(picked);
      _refresh();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  List<GRN> _getFilteredGRNs(GRNProvider grnProvider) {
    return grnProvider.grns.where((grn) {
      final filter = grnProvider.filterStatus;

      // -------- STATUS FILTER --------
      if (filter == 'active') {
        final s = grn.status?.toLowerCase() ?? '';
        if (!(s == 'active' || s.contains('partial'))) return false;
      } else if (filter == 'returned') {
        if (!(grn.status?.toLowerCase().contains('returned') ?? false)) {
          return false;
        }
      }

      // -------- VENDOR FILTER --------
      if (_selectedVendorNotifier.value.isNotEmpty) {
        final vendorMatch =
            grn.vendorName?.toLowerCase().contains(
              _selectedVendorNotifier.value.toLowerCase(),
            ) ??
            false;
        if (!vendorMatch) return false;
      }

      // -------- DATE FILTER --------
      if (_selectedDate != null) {
        if (grn.grnDate == null || grn.grnDate!.isEmpty) return false;

        final apiDate = DateTime.tryParse(grn.grnDate!);
        if (apiDate == null) return false;

        final selected = _selectedDate!;
        if (apiDate.year != selected.year ||
            apiDate.month != selected.month ||
            apiDate.day != selected.day) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
