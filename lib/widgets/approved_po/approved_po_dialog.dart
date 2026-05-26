import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/core/errors/app_error_handler.dart';
import 'package:purchaseorders2/core/utils/app_snackbar.dart';
import 'package:purchaseorders2/models/po/po.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/services/ai/ai_invoice_model.dart';
import 'package:purchaseorders2/widgets/approved_po/approved_po_logic.dart';
import 'package:purchaseorders2/widgets/create_po/FREIGHT/freight_dialog.dart';
import 'approved_po_tables.dart';

class ApprovedPODialog extends StatefulWidget {
  final PO po;
  final POProvider poProvider;
  final VoidCallback onUpdated;
  final AIInvoiceResponse? aiResponse;
  const ApprovedPODialog({
    super.key,
    required this.po,
    required this.poProvider,
    required this.onUpdated,
    this.aiResponse,
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
      aiResponse: widget.aiResponse,
    );

    _logic.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logic.updateTabletStatus(MediaQuery.of(context).size.width);
  }

  Future<void> _showConvertToGRNConfirmation() async {
    if (!mounted) {
      return;
    }
    final isValid = await _logic.validateBeforeGRN();

    if (!isValid) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
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
                Navigator.of(ctx).pop(false);
              },

              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),

              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _logic.convertPoToGRN(context);
    }
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

              await _logic.poProvider.fetchApprovedPOsOnly();
            } catch (e, stackTrace) {
              debugPrint("Freight update error: $e");

              if (!mounted) return;

              final appError = AppErrorHandler.handle(
                e,
                stackTrace: stackTrace,
              );

              AppSnackbar.showError(context, appError);
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _logic.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permission = context.watch<PermissionProvider>();
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
        return ValueListenableBuilder<bool>(
          valueListenable: _logic.isInvoiceHighlighted,

          builder: (context, isHighlighted, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),

              curve: Curves.easeInOut,

              decoration: BoxDecoration(
                color: isHighlighted
                    ? const Color.fromARGB(255, 255, 251, 2).withOpacity(0.30)
                    : Colors.transparent,

                borderRadius: BorderRadius.circular(4),
              ),

              child: TextFormField(
                controller: _logic.invoiceNumberController,

                style: const TextStyle(fontSize: 11),

                maxLength: 50,

                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),

                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9\-_\/]'),
                  ),
                ],

                buildCounter:
                    (
                      context, {
                      required int currentLength,
                      required bool isFocused,
                      int? maxLength,
                    }) => null,

                decoration: InputDecoration(
                  filled: true,

                  fillColor: isHighlighted
                      ? const Color.fromARGB(255, 255, 251, 2).withOpacity(0.20)
                      : Colors.white,

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

                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),

                onChanged: (value) {
                  _validateInvoiceNumber(value);
                },
              ),
            );
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
    final permission = context.watch<PermissionProvider>();

    bool canEditFreight = permission.hasPermission("yenerp", "freight", "edit");
    final hasFreight =
        _logic.po.freights != null && _logic.po.freights!.isNotEmpty;

    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: () {
          if (!canEditFreight) {
            _logic.showTopError("No permission to edit freight");
            return;
          }

          _openFreightDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: canEditFreight ? Colors.blueAccent : Colors.grey,
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
        /// ✅ ORDERED SUBTOTAL (WITH FALLBACK)
        final double orderedSubTotal = _logic.po.items.fold<double>(
          0.0,
          (sum, i) =>
              sum +
              (i.poQuantitypendingTotalPrice ?? i.pendingTotalPrice ?? 0.0),
        );

        /// ✅ ORDERED DISCOUNT (WITH FALLBACK)
        final double orderedDiscount = _logic.po.items.fold<double>(
          0.0,
          (sum, i) =>
              sum +
              (i.poQuantityDiscountAmount ?? i.pendingDiscountAmount ?? 0.0),
        );

        /// ✅ ORDERED TAX (WITH FALLBACK)
        final double orderedTax = _logic.po.items.fold<double>(
          0.0,
          (sum, i) =>
              sum + (i.poQuantityTaxAmount ?? i.pendingTaxAmount ?? 0.0),
        );

        /// ✅ FINAL (ALREADY FIXED IN LOGIC)
        final double orderedItemsFinal = _logic.orderedFinalAmount;

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
              isOrdered ? orderedSubTotal : _logic.receivedSubTotal,
            ),

            /// 🔹 DISCOUNT
            _summaryRow(
              isOrdered ? "Order Discount" : "Received Discount",
              isOrdered ? orderedDiscount : _logic.pendingDiscountFromItems,
            ),

            /// 🔹 FREIGHT
            _summaryRow("Freight", _logic.totalFreightAmount),

            /// 🔹 TAX
            _summaryRow("Tax", isOrdered ? orderedTax : _logic.itemTaxAmount),

            /// 🔹 ROUND OFF
            _summaryRow("Round Off", _logic.roundOffAmount.value),

            /// 🔹 FINAL AMOUNT
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          /// 🔹 DISCOUNT LABEL + ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 20), // 👈 adjust spacing here
              /// 🏷️ LABEL
              const Text(
                "Discount :",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),

              const SizedBox(width: 6),

              /// 👉 RIGHT SIDE CONTENT
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /// 🔥 TOGGLE SWITCH (Before / After Tax)
                    ValueListenableBuilder<bool>(
                      valueListenable: _logic.isBefTaxDiscount,
                      builder: (context, isBefTax, _) {
                        return Row(
                          children: [
                            Text(
                              isBefTax ? "Before Tax" : "After Tax",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),

                            Switch(
                              value: !isBefTax,
                              onChanged: (val) {
                                _logic.isBefTaxDiscount.value = !val;
                              },
                              activeThumbColor: Colors.blueAccent,
                              activeTrackColor: Colors.blueAccent.withOpacity(
                                0.4,
                              ),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.grey.shade300,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(width: 6),

                    /// 🔢 DISCOUNT INPUT
                    SizedBox(
                      width: 70,
                      child: InkWell(
                        onTap: () {
                          _logic.showNumericCalculator(
                            controller: _logic.discountInputController,
                            varianceName: 'Enter Discount',
                            onValueSelected: () {
                              _logic.applyOverallDiscountViaAPI();
                            },
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
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
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

                    /// ❌ CLEAR BUTTON
                    InkWell(
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
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔢 ROUND OFF FIELD
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
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final permission = context.watch<PermissionProvider>();

    bool canConvert = permission.hasPermission(
      "yenerp",
      "purchaseorders_approved",
      "approve",
    );

    bool canRevert = permission.hasPermission(
      "yenerp",
      "purchaseorders_approved",
      "approve",
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Revert PO Button
          SizedBox(
            width: 110, // ✅ Increased from 90 to 110
            child: ElevatedButton(
              onPressed: () {
                if (!canRevert) {
                  _logic.showTopError("No permission to revert PO");
                  return;
                }
                _logic.revertPO(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: canRevert ? Colors.blueAccent : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Revert PO',
                style: TextStyle(fontSize: 11),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Close Button
          SizedBox(
            width: 85, // ✅ Increased from 70 to 85
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 11),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Convert to GRN Button
          ValueListenableBuilder<bool>(
            valueListenable: _logic.isSaving,
            builder: (context, saving, _) {
              return SizedBox(
                width: 125, // ✅ Increased from 100 to 125
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (!canConvert) {
                            _logic.showTopError("No permission to convert GRN");
                            return;
                          }
                          _showConvertToGRNConfirmation();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRevert
                        ? Colors.blueAccent
                        : Colors.grey,
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
                ),
              );
            },
          ),
        ],
      ),
    );
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
