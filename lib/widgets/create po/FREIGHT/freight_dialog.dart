import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/freight.dart';
import 'package:purchaseorders2/models/freight_name_model.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import '../../numeric_Calculator.dart';

class FreightDialog extends StatefulWidget {
  final Function(List<FreightData>) onAdd;
  final List<FreightData>? initialFreights;

  const FreightDialog({super.key, required this.onAdd, this.initialFreights});

  @override
  State<FreightDialog> createState() => _FreightDialogState();
}

class _FreightDialogState extends State<FreightDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final ValueNotifier<String?> _taxCode = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _taxType = ValueNotifier<String?>(null);
  final ValueNotifier<double> _sgst = ValueNotifier<double>(0);
  final ValueNotifier<double> _cgst = ValueNotifier<double>(0);
  final ValueNotifier<double> _igst = ValueNotifier<double>(0);
  final ValueNotifier<double> _taxAmount = ValueNotifier<double>(0);
  final ValueNotifier<double> _total = ValueNotifier<double>(0);
  final ValueNotifier<String?> _selectedFreightId = ValueNotifier<String?>(
    null,
  );

  // Store freights with their individual calculations
  final ValueNotifier<List<FreightData>> _temporaryFreights = ValueNotifier([]);

  // Summary calculations
  final ValueNotifier<double> _totalFreightAmount = ValueNotifier<double>(0);
  final ValueNotifier<double> _totalTaxAmount = ValueNotifier<double>(0);
  final ValueNotifier<double> _grandTotal = ValueNotifier<double>(0);
  final ValueNotifier<bool> _isSaving = ValueNotifier<bool>(false);

  // Scroll controllers
  final ScrollController _leftVertical = ScrollController();
  final ScrollController _rightVertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  bool canAddFreight = false;
  bool canEditFreight = false;
  bool canDeleteFreight = false;

  InputDecoration _buildFieldDecoration(
    String label, {
    bool isReadOnly = false,
    String? hint,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: TextStyle(
        fontSize: isMobile ? 13 : 14,
        color: Colors.grey.shade800,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 74, 122, 227),
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade300 : Colors.white,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 40),
      errorStyle: TextStyle(fontSize: 12, color: Colors.red.shade700),
    );
  }

  @override
  void initState() {
    super.initState();

    // Sync vertical scrolling
    _leftVertical.addListener(() {
      if (_rightVertical.offset != _leftVertical.offset) {
        _rightVertical.jumpTo(_leftVertical.offset);
      }
    });

    _rightVertical.addListener(() {
      if (_leftVertical.offset != _rightVertical.offset) {
        _leftVertical.jumpTo(_rightVertical.offset);
      }
    });

    // Load initial freights if any
    if (widget.initialFreights != null && widget.initialFreights!.isNotEmpty) {
      _temporaryFreights.value = [...widget.initialFreights!];
      _updateSummaryCalculations();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final provider = context.read<POProvider>();

      try {
        await Future.wait([
          provider.fetchPurchaseTaxes(),
          provider.fetchFreightNames(),
        ]);
      } catch (e) {
        debugPrint("❌ Failed to load freight data: $e");
      }
    });
  }

  void _showTopError(String message) {
    final overlayState = Overlay.of(context, rootOverlay: true);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  void _updateSummaryCalculations() {
    double totalAmount = 0;
    double totalTax = 0;
    double total = 0;

    for (var freight in _temporaryFreights.value) {
      totalAmount += freight.amount;
      totalTax += freight.taxAmount;
      total += freight.total;
    }

    _totalFreightAmount.value = totalAmount;
    _totalTaxAmount.value = totalTax;
    _grandTotal.value = total;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _taxCode.dispose();
    _taxType.dispose();
    _sgst.dispose();
    _cgst.dispose();
    _igst.dispose();
    _taxAmount.dispose();
    _total.dispose();
    _selectedFreightId.dispose();
    _totalFreightAmount.dispose();
    _totalTaxAmount.dispose();
    _grandTotal.dispose();
    _isSaving.dispose();
    _temporaryFreights.dispose();
    _leftVertical.dispose();
    _rightVertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _openNumericCalculator({
    required String title,
    required TextEditingController controller,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => NumericCalculator(
        onValueSelected: (double p1) {
          controller.text = p1.toStringAsFixed(2);
          _calculate();
        },
      ),
    );

    if (result != null) {
      controller.text = result;
      _calculate();
    }
  }

  Future<void> _calculate() async {
    final provider = context.read<POProvider>();

    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount == 0) {
      _resetTaxValues();
      return;
    }

    try {
      final freight = await provider.calculateFreightTotals(
        amount: amount,
        taxCode: _taxCode.value ?? "0",
        taxType: _taxType.value ?? "cgst_sgst",
      );

      _sgst.value = freight.sgst ?? 0;
      _cgst.value = freight.cgst ?? 0;
      _igst.value = freight.igst ?? 0;
      _taxAmount.value = freight.taxAmount ?? 0;
      _total.value = (freight.amount ?? 0) + (freight.taxAmount ?? 0);
    } catch (e) {
      debugPrint("❌ Failed to calculate freight totals: $e");
      _resetTaxValues();
    }
  }

  void _resetTaxValues() {
    _sgst.value = 0;
    _cgst.value = 0;
    _igst.value = 0;
    _taxAmount.value = 0;
    _total.value = 0;
  }

  void _addToTemporaryList() {
    if (!canAddFreight) {
      _showTopError("No permission to add freight");
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<POProvider>();

    final selected = provider.freightNames.firstWhere(
      (f) => f.id == _selectedFreightId.value,
      orElse: () => FreightName(id: "", name: ""),
    );

    if (selected.id.isEmpty) {
      _showTopError("Please select a freight name");
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;

    if (amount <= 0) {
      _showTopError("Please enter a valid amount");
      return;
    }

    final freight = FreightData(
      id: selected.id,
      name: selected.name,
      amount: amount,
      taxAmount: _taxAmount.value,
      cgst: _cgst.value,
      sgst: _sgst.value,
      igst: _igst.value,
      taxCode: _taxCode.value ?? "0",
      taxType: _taxType.value ?? "cgst_sgst",
      total: _total.value,
    );

    // Check if already exists → update
    final List<FreightData> tempList = List.from(_temporaryFreights.value);
    final index = tempList.indexWhere((f) => f.id == freight.id);

    if (index != -1) {
      tempList[index] = freight; // update
    } else {
      tempList.add(freight); // add new
    }
    _temporaryFreights.value = tempList;
    _updateSummaryCalculations();

    _clearForm();
  }

  void _clearForm() {
    _amountController.clear();
    _taxCode.value = null;
    _taxType.value = null;
    _selectedFreightId.value = null;
    _resetTaxValues();
  }

  void _removeTemporaryFreight(int index) {
    final List<FreightData> tempList = List.from(_temporaryFreights.value);
    tempList.removeAt(index);
    _temporaryFreights.value = tempList;
    _updateSummaryCalculations();
  }

  void _editTemporaryFreight(FreightData freight) {
    _amountController.text = freight.amount.toStringAsFixed(2);
    _taxCode.value = freight.taxCode;
    _taxType.value = freight.taxType;
    _sgst.value = freight.sgst;
    _cgst.value = freight.cgst;
    _igst.value = freight.igst;
    _taxAmount.value = freight.taxAmount;
    _total.value = freight.total;
    _selectedFreightId.value = freight.id;

    final List<FreightData> tempList = List.from(_temporaryFreights.value);
    tempList.removeWhere(
      (f) => f.id == freight.id && f.amount == freight.amount,
    );
    _temporaryFreights.value = tempList;
    _updateSummaryCalculations();
  }

  Future<void> _submitAll() async {
    if (!canAddFreight) {
      _showTopError("No permission to add freight");
      return;
    }
    if (_temporaryFreights.value.isEmpty) {
      _showTopError("No freights to save");
      return;
    }

    _isSaving.value = true;

    try {
      // Simulate network delay or actual save operation
      await Future.delayed(const Duration(milliseconds: 500));

      widget.onAdd(_temporaryFreights.value);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showTopError("Error saving: $e");
      }
    } finally {
      _isSaving.value = false;
    }
  }

  Widget _buildFreightTable() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final double rowHeight = 48;

    return ValueListenableBuilder<List<FreightData>>(
      valueListenable: _temporaryFreights,
      builder: (context, temporaryFreights, child) {
        final int itemCount = temporaryFreights.length;

        if (itemCount == 0) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "No freight items added yet",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ),
          );
        }

        double tableHeight;
        if (itemCount <= 3) {
          tableHeight = rowHeight * (itemCount + 1);
        } else {
          tableHeight = rowHeight * 4;
        }

        final double nameWidth = isMobile ? 100 : 130;
        final double amountWidth = isMobile ? 70 : 80;
        final double taxWidth = isMobile ? 70 : 80;
        final double totalWidth = isMobile ? 70 : 80;
        final double actionsWidth = isMobile ? 100 : 120;

        return Container(
          height: tableHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Left fixed column (Name)
              Column(
                children: [
                  Container(
                    height: rowHeight,
                    width: nameWidth,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        "Name",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _leftVertical,
                      physics: itemCount <= 3
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: temporaryFreights.map((f) {
                          return Container(
                            height: rowHeight,
                            width: nameWidth,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Center(
                              child: Text(
                                f.name,
                                style: TextStyle(fontSize: isMobile ? 11 : 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              // Right scrollable columns
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      // Header row
                      Container(
                        height: rowHeight,
                        color: Colors.grey[200],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTableHeader("Amount", amountWidth, isMobile),
                            _buildTableHeader("Tax", taxWidth, isMobile),
                            _buildTableHeader("Total", totalWidth, isMobile),
                            Container(
                              width: actionsWidth,
                              alignment: Alignment.center,
                              child: Text(
                                "Actions",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 12 : 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table body
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _rightVertical,
                          physics: itemCount <= 3
                              ? const NeverScrollableScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: temporaryFreights.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final f = entry.value;

                              return Container(
                                height: rowHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTableCell(
                                      "₹${f.amount.toStringAsFixed(2)}",
                                      amountWidth,
                                      isMobile,
                                    ),
                                    _buildTableCell(
                                      "₹${f.taxAmount.toStringAsFixed(2)}",
                                      taxWidth,
                                      isMobile,
                                    ),
                                    _buildTableCell(
                                      "₹${f.total.toStringAsFixed(2)}",
                                      totalWidth,
                                      isMobile,
                                    ),
                                    Container(
                                      width: actionsWidth,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.edit,
                                            color: Colors.blueAccent,
                                            onPressed: () {
                                              if (!canEditFreight) {
                                                _showTopError(
                                                  "No permission to edit freight",
                                                );
                                                return;
                                              }

                                              _editTemporaryFreight(f);
                                            },
                                            isMobile: isMobile,
                                          ),
                                          SizedBox(width: isMobile ? 2 : 4),
                                          _buildActionButton(
                                            icon: Icons.delete,
                                            color: Colors.red,
                                            onPressed: () {
                                              if (!canDeleteFreight) {
                                                _showTopError(
                                                  "No permission to delete freight",
                                                );
                                                return;
                                              }

                                              _removeTemporaryFreight(index);
                                            },
                                            isMobile: isMobile,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return SizedBox(
      width: isMobile ? 32 : 40,
      height: isMobile ? 32 : 40,
      child: IconButton(
        icon: Icon(icon, size: isMobile ? 16 : 20, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        splashRadius: isMobile ? 20 : 24,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildTableHeader(String text, double width, bool isMobile) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : 13,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, double width, bool isMobile) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: isMobile ? 11 : 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSummarySection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Summary",
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),

        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                "Total Freight Amount:",
                _totalFreightAmount,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 6 : 8),
              _buildSummaryRow(
                "Total Tax Amount:",
                _totalTaxAmount,
                isMobile: isMobile,
              ),
              Divider(height: isMobile ? 16 : 20, color: Colors.grey.shade300),
              _buildSummaryRow(
                "Grand Total:",
                _grandTotal,
                isMobile: isMobile,
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    ValueNotifier<double> valueNotifier, {
    required bool isMobile,
    bool isBold = false,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              "₹${value.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: isBold ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<PermissionProvider>();

    canAddFreight = permission.hasPermission("yenerp", "freight", "add");
    canEditFreight = permission.hasPermission("yenerp", "freight", "edit");
    canDeleteFreight = permission.hasPermission("yenerp", "freight", "delete");
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget twoCol(Widget a, Widget b) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: a),
          SizedBox(width: isMobile ? 8 : 12),
          Flexible(child: b),
        ],
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 8 : 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 15 : 25),
          ),
          child: Container(
            width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 900,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              minHeight: 100,
            ),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 15 : 25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Fixed at top)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Manage Freight",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: isMobile ? 20 : 22),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 8 : 12),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. FIELDS SECTION
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              twoCol(
                                Consumer<POProvider>(
                                  builder: (context, provider, _) {
                                    if (provider.freightNames.isEmpty) {
                                      return InputDecorator(
                                        decoration: _buildFieldDecoration(
                                          "Freight Name *",
                                        ),
                                        child: const SizedBox(
                                          height: 20,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return ValueListenableBuilder<String?>(
                                      valueListenable: _selectedFreightId,
                                      builder: (context, selectedValue, _) {
                                        return DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          value:
                                              provider.freightNames.any(
                                                (f) => f.id == selectedValue,
                                              )
                                              ? selectedValue
                                              : null,
                                          decoration: _buildFieldDecoration(
                                            "Freight Name *",
                                          ),
                                          hint: const Text("Select Freight"),
                                          items: provider.freightNames.map((
                                            freight,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: freight.id,
                                              child: Text(
                                                freight.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            _selectedFreightId.value = value;
                                          },
                                          validator: (v) => v == null
                                              ? "Select freight"
                                              : null,
                                          icon: selectedValue == null
                                              ? Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey.shade700,
                                                )
                                              : GestureDetector(
                                                  onTap: () {
                                                    _selectedFreightId.value =
                                                        null;
                                                  },
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                          dropdownColor: Colors.white,
                                          menuMaxHeight: 250,
                                        );
                                      },
                                    );
                                  },
                                ),
                                TextFormField(
                                  controller: _amountController,
                                  readOnly: true,
                                  decoration: _buildFieldDecoration(
                                    "Amount *",
                                    hint: "Enter amount",
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 14,
                                  ),
                                  onTap: () {
                                    _openNumericCalculator(
                                      title: "Freight Amount",
                                      controller: _amountController,
                                    );
                                  },
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Enter amount"
                                      : null,
                                  onChanged: (_) => _calculate(),
                                ),
                              ),

                              SizedBox(height: isMobile ? 12 : 16),

                              twoCol(
                                Consumer<POProvider>(
                                  builder: (context, provider, _) {
                                    if (provider.purchaseTaxes.isEmpty) {
                                      return InputDecorator(
                                        decoration: _buildFieldDecoration(
                                          "Tax %",
                                        ),
                                        child: const SizedBox(
                                          height: 20,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return ValueListenableBuilder<String?>(
                                      valueListenable: _taxCode,
                                      builder: (context, taxCodeValue, child) {
                                        return DropdownButtonFormField<double>(
                                          isExpanded: true,
                                          value: taxCodeValue == null
                                              ? null
                                              : double.tryParse(taxCodeValue),
                                          decoration: _buildFieldDecoration(
                                            "Tax %",
                                          ),
                                          items: provider.purchaseTaxes.map((
                                            tax,
                                          ) {
                                            return DropdownMenuItem<double>(
                                              value: tax.purchasetaxPercentage,
                                              child: Text(
                                                "${tax.purchasetaxName} (${tax.purchasetaxPercentage}%)",
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              _taxCode.value = value.toString();
                                              _calculate();
                                            }
                                          },
                                          icon: taxCodeValue == null
                                              ? const Icon(
                                                  Icons.arrow_drop_down,
                                                )
                                              : GestureDetector(
                                                  onTap: () {
                                                    _taxCode.value = null;
                                                    _calculate();
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                  ),
                                                ),
                                          dropdownColor: Colors.white,
                                          menuMaxHeight: 200,
                                        );
                                      },
                                    );
                                  },
                                ),
                                ValueListenableBuilder<String?>(
                                  valueListenable: _taxType,
                                  builder: (context, taxTypeValue, child) {
                                    return DropdownButtonFormField<String>(
                                      value: taxTypeValue,
                                      decoration: _buildFieldDecoration(
                                        "Tax Type",
                                      ),
                                      hint: Text(
                                        "Select",
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: "cgst_sgst",
                                          child: Text(
                                            "CGST + SGST",
                                            style: GoogleFonts.poppins(
                                              fontSize: isMobile ? 14 : 14,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: "igst",
                                          child: Text(
                                            "IGST",
                                            style: GoogleFonts.poppins(
                                              fontSize: isMobile ? 14 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        _taxType.value = v;
                                        _calculate();
                                      },
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 14 : 14,
                                        color: Colors.black,
                                      ),
                                      dropdownColor: Colors.white,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey.shade700,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      elevation: 4,
                                      menuMaxHeight: 200,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Added Freights",
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: isMobile ? 6 : 8),
                            _buildFreightTable(),
                          ],
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Tax Breakdown Section
                        _buildTaxBreakdownSection(isMobile),

                        SizedBox(height: isMobile ? 16 : 20),

                        // 2. SUMMARY SECTION
                        _buildSummarySection(),

                        SizedBox(height: isMobile ? 16 : 20),

                        // 4. BUTTONS SECTION
                        Row(
                          children: [
                            // Clear button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _clearForm,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 10 : 14,
                                  ),
                                ),
                                child: Text(
                                  "Clear",
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),

                            // Add/Update button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addToTemporaryList,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 10 : 14,
                                  ),
                                ),
                                child: Text(
                                  "Add",
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),

                            // Save All button with loading state
                            Expanded(
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isSaving,
                                builder: (context, isSaving, child) {
                                  return ValueListenableBuilder<
                                    List<FreightData>
                                  >(
                                    valueListenable: _temporaryFreights,
                                    builder: (context, temporaryFreights, _) {
                                      return ElevatedButton(
                                        onPressed:
                                            isSaving ||
                                                temporaryFreights.isEmpty
                                            ? null
                                            : _submitAll,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: isMobile ? 10 : 14,
                                          ),
                                          disabledBackgroundColor:
                                              Colors.grey.shade300,
                                        ),
                                        child: isSaving
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                "Save (${temporaryFreights.length})",
                                                style: TextStyle(
                                                  fontSize: isMobile ? 13 : 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaxBreakdownSection(bool isMobile) {
    return ValueListenableBuilder<String?>(
      valueListenable: _taxCode,
      builder: (context, taxCodeValue, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _taxType,
          builder: (context, taxTypeValue, child) {
            final hasTaxSelected =
                taxCodeValue != null &&
                taxCodeValue.isNotEmpty &&
                taxTypeValue != null &&
                taxTypeValue.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tax Breakdown",
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),

                if (hasTaxSelected) ...[
                  if (taxTypeValue == "cgst_sgst") ...[
                    _buildTaxRow("CGST:", _cgst, isMobile),
                    _buildTaxRow("SGST:", _sgst, isMobile),
                  ] else if (taxTypeValue == "igst") ...[
                    _buildTaxRow("IGST:", _igst, isMobile),
                  ],

                  Divider(
                    height: isMobile ? 16 : 20,
                    color: Colors.grey.shade300,
                  ),

                  _buildTaxRow(
                    "Tax Amount:",
                    _taxAmount,
                    isMobile,
                    isBold: true,
                  ),
                ] else ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tax Details",
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          "No tax selected",
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: isMobile ? 16 : 20,
                    color: Colors.grey.shade300,
                  ),
                ],

                _buildTaxRow("Total Amount:", _total, isMobile, isBold: true),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTaxRow(
    String label,
    ValueNotifier<double> valueNotifier,
    bool isMobile, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: valueNotifier,
            builder: (context, value, child) {
              return Text(
                "₹${value.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isBold ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
