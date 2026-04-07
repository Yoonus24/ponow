// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/widgets/approved po/approved_po_logic.dart';
import 'package:purchaseorders2/widgets/create%20po/freight_dialog.dart';
import 'approved_po_tables.dart';

class ApprovedPODialog extends StatefulWidget {
  final PO po;
  final POProvider poProvider;
  final VoidCallback onUpdated;

  const ApprovedPODialog({
    super.key,
    required this.po,
    required this.poProvider,
    required this.onUpdated,
  });

  @override
  _ApprovedPODialogState createState() => _ApprovedPODialogState();
}

class _ApprovedPODialogState extends State<ApprovedPODialog> {
  late ApprovedPOLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = ApprovedPOLogic(
      po: widget.po,
      poProvider: widget.poProvider,
      context: context,
      onUpdated: widget.onUpdated,
    );

    _logic.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logic.updateTabletStatus(MediaQuery.of(context).size.width);
  }

  Future<void> _showConvertToGRNConfirmation() async {
    print("🟢 _showConvertToGRNConfirmation START");

    if (!mounted) {
      print("⚠️ Widget not mounted. Aborting dialog.");
      return;
    }

    print("📢 Showing confirmation dialog...");

    final bool? confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        print("🪟 Dialog builder executed");

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Conversion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'Are you sure you want to convert this PO to GRN?',
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () {
                print("❌ User pressed CANCEL");
                Navigator.of(ctx).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                print("✅ User pressed CONFIRM");
                Navigator.of(ctx).pop(true);
                // print("⚙️ Calling convertPoToGRN()");
                _logic.convertPoToGRN(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    print("📥 Dialog result: $confirmed");

    if (!mounted) {
      print("⚠️ Widget unmounted after dialog");
      return;
    }

    if (confirmed == true && mounted) {
      print("🚀 User confirmed. Starting PO → GRN conversion");

      Future.microtask(() {
        print("⚙️ Calling convertPoToGRN()");
        _logic.convertPoToGRN(context);
      });
    } else {
      print("⛔ Conversion cancelled by user");
    }

    print("🏁 _showConvertToGRNConfirmation END");
  }

  void _openFreightDialog() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return FreightDialog(
          initialFreights: _logic.po.freights ?? [],
          onAdd: (freightList) async {
            try {
              final updatedFreights = freightList;

              final totalAmount = updatedFreights.fold<double>(
                0.0,
                (sum, f) => sum + f.amount,
              );

              final totalTax = updatedFreights.fold<double>(
                0.0,
                (sum, f) => sum + f.taxAmount,
              );

              await _logic.poProvider.updatePO(
                _logic.po.copyWith(
                  freights: updatedFreights,
                  totalFreightAmount: totalAmount,
                  totalFreightTaxAmount: totalTax,
                ),
              );

              _logic.po.freights = updatedFreights;
              _logic.po.totalFreightAmount = totalAmount;
              _logic.po.totalFreightTaxAmount = totalTax;
              _logic.recalculateFinalAmountAfterDiscount();
              _logic.refreshUI();

              // ❌ REMOVE THIS BLOCK
              // Navigator.pop(dialogContext);
            } catch (e) {
              debugPrint("Freight update error: $e");
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      elevation: 0,
      child: SizedBox.expand(child: _buildDialogContent()),
    );
  }

  Widget _buildDialogContent() {
    return ScaffoldMessenger(
      key: _logic.dialogMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildDialogHeader(),
              _buildItemsTablesSection(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Form(
        key: _logic.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Vendor: ${widget.po.vendorName}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "PO No: ${widget.po.randomId}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_fixedHeightField(_buildInvoiceNumberField())],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_fixedHeightField(_buildInvoiceDateField())],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fixedHeightField(Widget child) {
    return Container(height: 30, alignment: Alignment.center, child: child);
  }

  Widget _buildInvoiceNumberField() {
    return ValueListenableBuilder<String?>(
      valueListenable: _logic.invoiceValidationMessage,
      builder: (context, error, _) {
        return TextFormField(
          controller: _logic.invoiceNumberController,
          style: const TextStyle(fontSize: 11),
          maxLength: 50,
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_\/]')),
          ],
          buildCounter:
              (
                context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) => null,

          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 7,
              horizontal: 6,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
                width: error != null ? 2.0 : 1.0,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
                width: error != null ? 2.0 : 1.0,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.blueAccent,
                width: error != null ? 2.0 : 1.0,
              ),
            ),

            hintText: "Invoice No",
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),

          onChanged: (value) {
            _validateInvoiceNumber(value);
          },
        );
      },
    );
  }

  void _validateInvoiceNumber(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      _logic.invoiceValidationMessage.value = null;
      return;
    }

    if (trimmed.length > 50) {
      _logic.invoiceValidationMessage.value = "Maximum 50 characters allowed";
      return;
    }

    final regex = RegExp(r'^[A-Za-z0-9\-_/]+$');

    if (!regex.hasMatch(trimmed)) {
      _logic.invoiceValidationMessage.value =
          "Only letters, numbers, -, /, _ allowed";
      return;
    }

    _logic.invoiceValidationMessage.value = null;
  }

  Widget _buildInvoiceDateField() {
    return ValueListenableBuilder(
      valueListenable: _logic.invoiceDateValidationMessage,
      builder: (context, error, _) {
        return TextFormField(
          controller: _logic.invoiceDateController,
          readOnly: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
                width: error != null ? 2.0 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
                width: error != null ? 2.0 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(
                color: error != null ? Colors.red : Colors.grey.shade400,
                width: error != null ? 2.0 : 1.0,
              ),
            ),
            hintText: "dd-MM-yyyy",
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 1),
              child: Icon(Icons.calendar_today, size: 13, color: Colors.grey),
            ),
          ),
          onTap: () => _logic.selectInvoiceDate(context),
        );
      },
    );
  }

  Widget _buildItemsTablesSection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    _buildOrderedItemsSection(),
                    const SizedBox(height: 16),
                    _buildReceivedItemsSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderedItemsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ORDERED ITEMS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: const Icon(
                        Icons.filter_list,
                        size: 25,
                        color: Colors.black87,
                      ),
                      onPressed: () => _logic.showColumnFilterDialog(context),
                    ),
                  ],
                ),
              ),
              // Table
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: ApprovedPOTable(
                  logic: _logic,
                  isOrdered: true,
                  rowHeight: 30.0,
                  minVisibleRows: 7,
                ),
              ),
              // Summary Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey.shade400)),
                ),
                child: Column(
                  children: [
                    _buildBackendSummary(isOrdered: true),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceivedItemsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "RECEIVED ITEMS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: const Icon(
                        Icons.filter_list,
                        size: 25,
                        color: Colors.black87,
                      ),
                      onPressed: () => _logic.showColumnFilterDialog(context),
                    ),
                  ],
                ),
              ),
              // Table
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: ApprovedPOTable(
                  logic: _logic,
                  isOrdered: false,
                  rowHeight: 30.0,
                  minVisibleRows: 7,
                ),
              ),
              // Summary and Discount Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey.shade400)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBackendSummary(isOrdered: false),

                    const SizedBox(height: 6),

                    _buildAddFreightButton(),

                    const SizedBox(height: 8),

                    _buildDiscountField(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddFreightButton() {
    final hasFreight =
        _logic.po.freights != null && _logic.po.freights!.isNotEmpty;

    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: _openFreightDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasFreight ? Colors.blueAccent : Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        child: Text(
          hasFreight ? "Edit Freight" : "Add Freight",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBackendSummary({required bool isOrdered}) {
    return ValueListenableBuilder<int>(
      valueListenable: _logic.uiRefresh,
      builder: (_, __, ___) {
        final double orderedItemsFinal = _logic.po.items.fold<double>(
          0.0,
          (sum, i) => sum + ((i.poQuantitypendingFinalPrice ?? 0.0)),
        );

        final double orderedFinalWithExtras =
            orderedItemsFinal +
            _logic.totalFreightAmount +
            _logic.roundOffAmount.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            /// 🔹 SUB TOTAL
            _summaryRow(
              "Sub Total",
              isOrdered
                  ? _logic.po.items.fold<double>(
                      0.0,
                      (sum, i) =>
                          sum + ((i.poQuantitypendingTotalPrice ?? 0.0)),
                    )
                  : _logic.receivedSubTotal,
            ),

            /// 🔹 DISCOUNT
            _summaryRow(
              isOrdered ? "Order Discount" : "Received Discount",
              isOrdered
                  ? _logic.po.items.fold<double>(
                      0.0,
                      (sum, i) => sum + ((i.poQuantityDiscountAmount ?? 0.0)),
                    )
                  : _logic.pendingDiscountFromItems,
            ),

            /// 🔹 FREIGHT
            _summaryRow("Freight", _logic.totalFreightAmount),

            /// 🔹 TAX
            _summaryRow(
              "Tax",
              isOrdered
                  ? _logic.po.items.fold<double>(
                      0.0,
                      (sum, i) => sum + ((i.poQuantityTaxAmount ?? 0.0)),
                    )
                  : _logic.itemTaxAmount,
            ),

            /// 🔹 ROUND OFF
            _summaryRow("Round Off", _logic.roundOffAmount.value),

            /// 🔹 FINAL AMOUNT ✅ FIXED
            _summaryRow(
              "Final Amount",
              isOrdered ? orderedFinalWithExtras : _logic.receivedFinalAmount,
              highlight: true,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String label, double? value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "$label: ₹ ",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            (value ?? 0.0).toStringAsFixed(2),
            style: TextStyle(
              fontSize: 10,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _logic.isBefTaxDiscount,
                builder: (context, isBefTax, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _logic.isBefTaxDiscount.value = true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isBefTax
                                ? Colors.blueAccent
                                : Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            border: Border.all(
                              color: isBefTax
                                  ? Colors.blueAccent
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            'Bef Tax',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isBefTax
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _logic.isBefTaxDiscount.value = false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: !isBefTax
                                ? Colors.green
                                : Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            border: Border.all(
                              color: !isBefTax
                                  ? Colors.green
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            'Af Tax',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: !isBefTax
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(width: 4),
              SizedBox(
                width: 70,
                child: InkWell(
                  onTap: () {
                    _logic.showNumericCalculator(
                      controller: _logic.discountInputController,
                      varianceName: 'Enter Discount',
                      onValueSelected: () {},
                      isItemField: false,
                    );
                  },
                  child: IgnorePointer(
                    child: TextField(
                      controller: _logic.discountInputController,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        hintText: 'Amount',
                        hintStyle: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),
              ValueListenableBuilder<bool>(
                valueListenable: _logic.isBefTaxDiscount,
                builder: (context, isBefTax, _) {
                  return InkWell(
                    onTap: () => _logic.applyOverallDiscountViaAPI(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isBefTax ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.save,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 4),
              // ===== CLEAR ICON =====
              ValueListenableBuilder<bool>(
                valueListenable: _logic.isBefTaxDiscount,
                builder: (context, isBefTax, _) {
                  return InkWell(
                    onTap: () => _logic.clearDiscountFromAllItems(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.clear,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 6),
          _buildRoundOffField(),
        ],
      ),
    );
  }

  Widget _buildRoundOffField() {
    return ValueListenableBuilder<String?>(
      valueListenable: _logic.roundOffErrorNotifier,
      builder: (context, error, _) {
        final hasError = error != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Round Off: ₹',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 70,
                  child: InkWell(
                    onTap: () {
                      _logic.showNumericCalculator(
                        controller: _logic.discountPriceController,
                        varianceName: 'Enter Round Off',
                        onValueSelected: () {
                          _logic.updateRoundOff(
                            _logic.discountPriceController.text,
                          );
                          _logic.validateRoundOff();
                        },
                        isItemField: false,
                      );
                    },
                    child: IgnorePointer(
                      child: TextField(
                        controller: _logic.discountPriceController,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 2.0,
                            horizontal: 4.0,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: hasError ? Colors.red : Colors.grey,
                              width: hasError ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                print(
                  "🔁 Revert PO button clicked for PO: ${widget.po.randomId}",
                );
                _logic.revertPO(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Revert PO',
                style: TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _logic.isSaving,
              builder: (context, saving, _) {
                return ElevatedButton(
                  onPressed: saving ? null : _showConvertToGRNConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Convert to GRN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }
}

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
