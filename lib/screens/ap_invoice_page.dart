import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ap.dart';
import '../providers/ap_invoice_provider.dart';
import '../providers/po_provider.dart';
import '../widgets/ap invoice/ap_invoice_widget.dart';
import '../widgets/ap invoice/ap_viewinvoice_widget.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/grn/grid_view_widget.dart';
import '../widgets/common_bottom_nav.dart';

class APInvoicePage extends StatefulWidget {
  const APInvoicePage({super.key});

  @override
  _APInvoicePageState createState() => _APInvoicePageState();
}

class _APInvoicePageState extends State<APInvoicePage> {
  final ValueNotifier<String> _selectedButton = ValueNotifier("Pending");

  final ValueNotifier<String> _vendorNotifier = ValueNotifier('');
  final ValueNotifier<DateTime?> _selectedDateNotifier = ValueNotifier(null);

  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final GlobalKey _autocompleteKey = GlobalKey();

  TextEditingController? _autoController; // ✅ added

  final int _skip = 0;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      Provider.of<APInvoiceProvider>(context, listen: false).fetchAPInvoices();

      await Provider.of<POProvider>(
        context,
        listen: false,
      ).fetchingVendors(vendorName: '', skip: _skip, limit: _limit);
    });
  }

  @override
  void dispose() {
    _selectedButton.dispose();
    _vendorNotifier.dispose();
    _selectedDateNotifier.dispose();
    _vendorController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<DateTime> _getServerDate() async {
    final provider = Provider.of<POProvider>(context, listen: false);

    try {
      final s = await provider.getServerDate();
      if (s != null) {
        final p = s.split('-');
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
    } catch (_) {}
    return DateTime.now();
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
      _selectedDateNotifier.value = picked;
      _dateController.text =
          "${picked.day.toString().padLeft(2, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.year}";
    }
  }

  void _clearDate() {
    _selectedDateNotifier.value = null;
    _dateController.clear();
  }

  void _clearVendor() {
    _autoController?.clear(); // ✅ clear autocomplete controller
    _vendorController.clear();
    _vendorNotifier.value = '';
  }

  // ===================== VENDOR FIELD ========================
  Widget _buildVendorField() {
    return Consumer<POProvider>(
      builder: (context, poProvider, _) {
        return SizedBox(
          height: 48,
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
              FocusScope.of(context).unfocus();
            },
            fieldViewBuilder: (context, controller, focusNode, _) {
              _autoController = controller; // ✅ store reference

              // ✅ mirror text without overwriting user typing
              if (_vendorController.text != controller.text) {
                _vendorController.text = controller.text;
                _vendorController.selection = controller.selection;
              }

              return TextField(
                controller: controller, // ✅ use autocomplete controller
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: "Vendor",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clearVendor,
                        )
                      : const Icon(Icons.search, size: 20),
                ),
                onChanged: (v) {
                  _vendorNotifier.value = v;
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Material(
                elevation: 3,
                color: Colors.white, // ✅ dropdown background
                child: SizedBox(
                  height: 200,
                  child: ListView(
                    children: options
                        .map(
                          (e) => ListTile(
                            dense: true,
                            tileColor: Colors.white, // ✅ each row white
                            title: Text(
                              e,
                              style: const TextStyle(
                                color: Colors.black,
                              ), // ✅ text black
                            ),
                            onTap: () {
                              onSelected(e);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        )
                        .toList(),
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
      height: 48,
      child: TextField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Date",
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 14,
          ),
          border: const OutlineInputBorder(),

          // 🔥 IMPORTANT: limit suffix width
          suffixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),

          suffixIcon: ValueListenableBuilder(
            valueListenable: _selectedDateNotifier,
            builder: (_, date, __) {
              return GestureDetector(
                onTap: date != null ? _clearDate : _selectDate,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    date != null ? Icons.clear : Icons.calendar_today,
                    size: 18,
                  ),
                ),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _selectedButton.value = 'Pending';
                    Provider.of<APInvoiceProvider>(
                      context,
                      listen: false,
                    ).filterStatus = 'Pending';
                    Provider.of<APInvoiceProvider>(
                      context,
                      listen: false,
                    ).fetchAPInvoices();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected == 'Pending'
                        ? Colors.blueAccent.shade400
                        : Colors.blueAccent.shade100,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("AP List"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _selectedButton.value = 'Returned';
                    Provider.of<APInvoiceProvider>(
                      context,
                      listen: false,
                    ).filterStatus = 'Returned';
                    Provider.of<APInvoiceProvider>(
                      context,
                      listen: false,
                    ).fetchAPInvoices();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected == 'Returned'
                        ? Colors.blueAccent.shade400
                        : Colors.blueAccent.shade100,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("AP Returned"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<ApInvoice> _filterInvoices(List<ApInvoice> list) {
    return list.where((inv) {
      if (_vendorNotifier.value.isNotEmpty) {
        if ((inv.vendorName ?? "").toLowerCase() !=
            _vendorNotifier.value.toLowerCase()) {
          return false;
        }
      }

      final selectedDate = _selectedDateNotifier.value;
      if (selectedDate != null) {
        if (inv.invoiceDate == null) return false;

        try {
          final apiDate = DateTime.parse(inv.invoiceDate!);
          if (DateTime(apiDate.year, apiDate.month, apiDate.day) !=
              DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              )) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "AP Invoices"),
      body: Column(
        children: [
          _buildFilterRow(),
          _buildStatusButtons(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.blueAccent, // 🔵 BLUE LOADER
              backgroundColor: Colors.white,
              displacement: 40,
              strokeWidth: 3,

              onRefresh: () async {
                await Provider.of<APInvoiceProvider>(
                  context,
                  listen: false,
                ).fetchAPInvoices();
              },

              child: ValueListenableBuilder(
                valueListenable: _vendorNotifier,
                builder: (_, __, ___) {
                  return ValueListenableBuilder(
                    valueListenable: _selectedDateNotifier,
                    builder: (_, __, ___) {
                      return ValueListenableBuilder(
                        valueListenable: _selectedButton,
                        builder: (_, __, ___) {
                          return Consumer<APInvoiceProvider>(
                            builder: (context, provider, _) {
                              if (provider.loading) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent, // 🔵
                                  ),
                                );
                              }

                              var list = provider.apInvoices;

                              list = list.where((inv) {
                                if (_selectedButton.value == "Pending") {
                                  return inv.status == "Pending" ||
                                      inv.status == "Outgoing Posted" ||
                                      inv.status == "created";
                                }
                                return inv.status == "Returned";
                              }).toList();

                              list = _filterInvoices(list);

                              if (list.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No invoices found",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              return GridViewWidget<ApInvoice>(
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // 🔥 IMPORTANT
                                items: list,
                                itemBuilder: (context, index) {
                                  final inv = list[index];
                                  return _selectedButton.value == "Pending"
                                      ? APInvoiceWidget(apinvoice: inv)
                                      : APViewInvoiceWidget(apinvoice: inv);
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
