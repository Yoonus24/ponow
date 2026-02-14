import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/models/freight.dart';
import 'package:purchaseorders2/models/freight_name_model.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';

import '../../widgets/numeric_Calculator.dart';

class FreightDialog extends StatefulWidget {
  final Function(FreightData) onAdd;
  final FreightData? editingFreight;

  const FreightDialog({super.key, required this.onAdd, this.editingFreight});

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final provider = context.read<POProvider>();

      try {
        await Future.wait([
          provider.fetchPurchaseTaxes(),
          provider.fetchFreightNames(),
        ]);

        if (widget.editingFreight != null) {
          final f = widget.editingFreight!;

          _amountController.text = f.amount.toStringAsFixed(2);
          _taxCode.value = f.taxCode;
          _taxType.value = f.taxType;
          _sgst.value = f.sgst;
          _cgst.value = f.cgst;
          _igst.value = f.igst;
          _taxAmount.value = f.taxAmount;
          _total.value = f.total;

          final match = provider.freightNames.firstWhere(
            (x) => x.id == f.id,
            orElse: () => FreightName(id: "", name: ""),
          );

          if (match.id.isNotEmpty) {
            _selectedFreightId.value = f.id;
          }
        }
      } catch (e) {
        debugPrint("❌ Failed to load freight data: $e");
      }
    });
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

    if (amount == 0) return;

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
      print("Freight calc error: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<POProvider>();

    final selected = provider.freightNames.firstWhere(
      (f) => f.id == _selectedFreightId.value,
      orElse: () => FreightName(id: "", name: ""),
    );

    final freight = FreightData(
      id: selected.id,
      name: selected.name,
      amount: double.tryParse(_amountController.text) ?? 0,
      taxAmount: _taxAmount.value,
      cgst: _cgst.value,
      sgst: _sgst.value,
      igst: _igst.value,
      taxCode: _taxCode.value ?? "0",
      taxType: _taxType.value ?? "cgst_sgst",
      total: _total.value,
    );

    widget.onAdd(freight);

    Navigator.pop(context);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 850,
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 15 : 25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.editingFreight != null
                          ? "Update Freight"
                          : "Add Freight",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: isMobile ? 20 : 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: isMobile ? 8 : 12),
                          // Freight Name and Amount side by side
                          twoCol(
                            Consumer<POProvider>(
                              builder: (context, provider, _) {
                                // 👉 Show spinner while API loads
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

                                // 👉 Show dropdown after data loads
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

                                      validator: (v) =>
                                          v == null ? "Select freight" : null,

                                      icon: selectedValue == null
                                          ? Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey.shade700,
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                _selectedFreightId.value = null;
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
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
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
                                // 👉 Show spinner while API loads
                                if (provider.purchaseTaxes.isEmpty) {
                                  return InputDecorator(
                                    decoration: _buildFieldDecoration("Tax %"),
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

                                // 👉 Show dropdown after data loads
                                return ValueListenableBuilder<String?>(
                                  valueListenable: _taxCode,
                                  builder: (context, taxCodeValue, child) {
                                    return DropdownButtonFormField<double>(
                                      isExpanded: true,

                                      initialValue: taxCodeValue == null
                                          ? null
                                          : double.tryParse(taxCodeValue),

                                      decoration: _buildFieldDecoration(
                                        "Tax %",
                                      ),

                                      items: provider.purchaseTaxes.map((tax) {
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
                                          ? const Icon(Icons.arrow_drop_down)
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

                                  decoration: _buildFieldDecoration("Tax Type"),

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

                          SizedBox(height: isMobile ? 16 : 20),
                          ValueListenableBuilder<String?>(
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

                                  return Container(
                                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Tax Breakdown",
                                          style: TextStyle(
                                            fontSize: isMobile ? 13 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        SizedBox(height: isMobile ? 8 : 12),

                                        if (hasTaxSelected) ...[
                                          if (taxTypeValue == "cgst_sgst") ...[
                                            ValueListenableBuilder<double>(
                                              valueListenable: _cgst,
                                              builder: (context, cgstValue, child) {
                                                return twoCol(
                                                  Text(
                                                    "CGST:",
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 13
                                                          : 14,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹${cgstValue.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 13
                                                          : 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                );
                                              },
                                            ),
                                            SizedBox(height: isMobile ? 6 : 8),
                                            ValueListenableBuilder<double>(
                                              valueListenable: _sgst,
                                              builder: (context, sgstValue, child) {
                                                return twoCol(
                                                  Text(
                                                    "SGST:",
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 13
                                                          : 14,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹${sgstValue.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 13
                                                          : 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                );
                                              },
                                            ),
                                          ] else if (taxTypeValue ==
                                              "igst") ...[
                                            ValueListenableBuilder<double>(
                                              valueListenable: _igst,
                                              builder: (context, igstValue, child) {
                                                return twoCol(
                                                  Text(
                                                    "IGST:",
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 13
                                                          : 14,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹${igstValue.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      fontSize: isMobile
                                                          ? 13
                                                          : 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                          SizedBox(height: isMobile ? 8 : 12),
                                          Divider(color: Colors.grey.shade400),
                                          SizedBox(height: isMobile ? 8 : 12),

                                          ValueListenableBuilder<double>(
                                            valueListenable: _taxAmount,
                                            builder:
                                                (
                                                  context,
                                                  taxAmountValue,
                                                  child,
                                                ) {
                                                  return twoCol(
                                                    Text(
                                                      "Tax Amount:",
                                                      style: TextStyle(
                                                        fontSize: isMobile
                                                            ? 13
                                                            : 14,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                    ),
                                                    Text(
                                                      "₹${taxAmountValue.toStringAsFixed(2)}",
                                                      style: TextStyle(
                                                        fontSize: isMobile
                                                            ? 14
                                                            : 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  );
                                                },
                                          ),
                                        ] else ...[
                                          twoCol(
                                            Text(
                                              "Tax Details",
                                              style: TextStyle(
                                                fontSize: isMobile ? 13 : 14,
                                                fontWeight: FontWeight.w600,
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
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          SizedBox(height: isMobile ? 8 : 12),
                                          Divider(color: Colors.grey.shade400),
                                          SizedBox(height: isMobile ? 8 : 12),
                                        ],

                                        SizedBox(height: isMobile ? 6 : 8),
                                        ValueListenableBuilder<double>(
                                          valueListenable: _total,
                                          builder: (context, totalValue, child) {
                                            return twoCol(
                                              Text(
                                                "Total Amount:",
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14 : 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                "₹${totalValue.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  fontSize: isMobile ? 15 : 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey.shade700,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: isMobile ? 20 : 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color.fromARGB(
                                    255,
                                    74,
                                    122,
                                    227,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 16 : 20,
                                    vertical: isMobile ? 8 : 12,
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 20 : 24,
                                    vertical: isMobile ? 10 : 14,
                                  ),
                                ),
                                child: Text(
                                  widget.editingFreight != null
                                      ? "Update Freight"
                                      : "Add Freight",
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
