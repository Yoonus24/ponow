import 'dart:math';

import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/po/po_provider.dart';
import 'package:purchaseorders2/widgets/create_po/ItemAutocomplete.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';
import '../../models/po/discount_model.dart';
import '../../models/po/po_item.dart';
import '../../models/po/vendorpurchasemodel.dart';

class AddItemDialog extends StatefulWidget {
  final Function() onItemAdded;
  final int? editingIndex;
  final Item? editingItem;

  const AddItemDialog({
    super.key,
    required this.onItemAdded,
    this.editingIndex,
    this.editingItem,
  });

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;
  late PurchaseOrderNotifier _poNotifier;

  final ValueNotifier<String> _itemWiseDiscountMode = ValueNotifier(
    "Percentage ( % )",
  );
  final ValueNotifier<bool> _refreshTrigger = ValueNotifier(false);
  final ValueNotifier<bool> _itemFieldLoadingNotifier = ValueNotifier(false);

  final ValueNotifier<bool> _submitButtonLoadingNotifier = ValueNotifier(false);
  final Map<String, TextEditingController> _fieldControllers = {};

  final ValueNotifier<bool> _isBefTaxEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isAfTaxEnabled = ValueNotifier(true);
  final FocusNode _eachQtyFocusNode = FocusNode();
  final ValueNotifier<bool> _isEachQtyFocused = ValueNotifier(false);
  final ValueNotifier<String?> _errorField = ValueNotifier(null);
  final ValueNotifier<bool> _shakeTrigger = ValueNotifier(false);
  final ValueNotifier<List<String>> _filteredItemOptions = ValueNotifier([]);

  // Map to track validation errors for each field
  final Map<String, ValueNotifier<bool>> _fieldHasError = {};
  // Map to track shake triggers for each field
  final Map<String, ValueNotifier<bool>> _fieldShakeTrigger = {};

  final bool _itemsPreloaded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeErrorTrackers();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final notifier = Provider.of<PurchaseOrderNotifier>(
        context,
        listen: false,
      );

      notifier.itemController.clear();
      notifier.uomController.clear();
      _clearItemDetails();

      _itemFieldLoadingNotifier.value = false;
    });
  }

  void _initializeErrorTrackers() {
    final fields = [
      'item',
      'count',
      'eachQuantity',
      'newPrice',
      'befDiscount',
      'afDiscount',
    ];

    for (String field in fields) {
      _fieldHasError[field] = ValueNotifier(false);
      _fieldShakeTrigger[field] = ValueNotifier(false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _poNotifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
  }

  @override
  void dispose() {
    _poNotifier.isOverallDisabledFromItem = false;
    _filteredItemOptions.dispose();
    _itemWiseDiscountMode.dispose();
    _refreshTrigger.dispose();
    _itemFieldLoadingNotifier.dispose();
    _submitButtonLoadingNotifier.dispose();
    _isBefTaxEnabled.dispose();
    _isAfTaxEnabled.dispose();
    _eachQtyFocusNode.dispose();
    _isEachQtyFocused.dispose();

    // Dispose error trackers
    for (var notifier in _fieldHasError.values) {
      notifier.dispose();
    }
    for (var notifier in _fieldShakeTrigger.values) {
      notifier.dispose();
    }

    super.dispose();
  }

  void _clearItemDetails() {
    _fieldControllers['eachQuantity']?.text = '';
    _fieldControllers['quantity']?.text = '';
    _fieldControllers['existingPrice']?.text = '';
    _fieldControllers['newPrice']?.text = '';
    _fieldControllers['variance']?.text = '';
    _fieldControllers['taxPercentage']?.text = '';

    _fieldControllers['befTaxDiscount']?.text = '0';
    _fieldControllers['afTaxDiscount']?.text = '0';

    _poNotifier.uomController.clear();

    _isBefTaxEnabled.value = true;
    _isAfTaxEnabled.value = true;
    _poNotifier.isOverallDisabledFromItem = false;

    // Clear error states
    for (var notifier in _fieldHasError.values) {
      notifier.value = false;
    }
    _errorField.value = null;
  }

  void _initializeControllers() {
    _fieldControllers['count'] = TextEditingController();
    _fieldControllers['eachQuantity'] = TextEditingController();
    _fieldControllers['quantity'] = TextEditingController();
    _fieldControllers['existingPrice'] = TextEditingController();
    _fieldControllers['newPrice'] = TextEditingController();
    _fieldControllers['variance'] = TextEditingController();
    _fieldControllers['taxPercentage'] = TextEditingController();
    _fieldControllers['befTaxDiscount'] = TextEditingController();
    _fieldControllers['afTaxDiscount'] = TextEditingController();
  }

  void _initializeWithEditingItem(Item item) {
    if (_isInitialized || !mounted) return;
    _isInitialized = true;

    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);

    final double countValue = item.pendingCount ?? item.count ?? 1;
    final double eachQtyValue = item.pendingQuantity ?? item.eachQuantity ?? 0;
    final double quantityValue =
        item.pendingTotalQuantity ??
        item.quantity ??
        (countValue * eachQtyValue);

    _fieldControllers['count']!.text = countValue.toString();
    _fieldControllers['eachQuantity']!.text = eachQtyValue.toString();
    _fieldControllers['quantity']!.text = quantityValue.toString();

    _fieldControllers['existingPrice']!.text = (item.existingPrice ?? 0)
        .toStringAsFixed(2);

    _fieldControllers['newPrice']!.text = (item.newPrice ?? 0).toStringAsFixed(
      2,
    );

    _fieldControllers['taxPercentage']!.text = (item.taxPercentage ?? 0)
        .toStringAsFixed(2);

    /// 🔥 IMPORTANT FIX STARTS HERE

    final String befType = (item.befTaxDiscountType.isNotEmpty)
        ? item.befTaxDiscountType
        : "percentage";

    final String afType = (item.afTaxDiscountType.isNotEmpty)
        ? item.afTaxDiscountType
        : "percentage";

    final bool isAmountMode = befType == 'amount' || afType == 'amount';

    if (isAmountMode) {
      // ✅ Load ₹ values
      _fieldControllers['befTaxDiscount']!.text =
          (item.befTaxDiscountAmount ?? 0).toStringAsFixed(2);

      _fieldControllers['afTaxDiscount']!.text = (item.afTaxDiscountAmount ?? 0)
          .toStringAsFixed(2);

      _itemWiseDiscountMode.value = 'Amount ( ₹ )';
      notifier.itemWiseDiscountMode = DiscountMode.amount;
    } else {
      // ✅ Load % values
      _fieldControllers['befTaxDiscount']!.text = (item.befTaxDiscount ?? 0)
          .toStringAsFixed(2);

      _fieldControllers['afTaxDiscount']!.text = (item.afTaxDiscount ?? 0)
          .toStringAsFixed(2);

      _itemWiseDiscountMode.value = 'Percentage ( % )';
      notifier.itemWiseDiscountMode = DiscountMode.percentage;
    }

    /// 🔥 IMPORTANT FIX ENDS HERE

    notifier.itemController.text = item.itemName ?? '';
    notifier.uomController.text = item.uom ?? '';

    _updateTotalQuantity(notifier);
    _updateVariance(notifier);

    final poNotifier = Provider.of<PurchaseOrderNotifier>(
      context,
      listen: false,
    );

    final double befVal =
        double.tryParse(_fieldControllers['befTaxDiscount']!.text) ?? 0;

    final double afVal =
        double.tryParse(_fieldControllers['afTaxDiscount']!.text) ?? 0;

    if (befVal > 0 || afVal > 0) {
      poNotifier.isOverallDisabledFromItem = true;
      poNotifier.isOverallDiscountActive = false;

      if (befVal > 0) {
        _isBefTaxEnabled.value = true;
        _isAfTaxEnabled.value = false;
      }

      if (afVal > 0) {
        _isAfTaxEnabled.value = true;
        _isBefTaxEnabled.value = false;
      }
    } else {
      _isBefTaxEnabled.value = true;
      _isAfTaxEnabled.value = true;
    }
  }

  bool _validateInputs() {
    // Clear all previous errors
    for (var notifier in _fieldHasError.values) {
      notifier.value = false;
    }

    final count = double.tryParse(_fieldControllers['count']!.text) ?? 0;
    final qty = double.tryParse(_fieldControllers['eachQuantity']!.text) ?? 0;
    final price = double.tryParse(_fieldControllers['newPrice']!.text) ?? 0;

    final befVal =
        double.tryParse(_fieldControllers['befTaxDiscount']!.text) ?? 0;
    final afVal =
        double.tryParse(_fieldControllers['afTaxDiscount']!.text) ?? 0;

    final totalQty = count * qty;
    final totalAmount = totalQty * price;

    final isPercentage =
        _poNotifier.itemWiseDiscountMode == DiscountMode.percentage;

    bool isValid = true;
    String errorField = "";
    String errorMessage = "";

    // ❌ NEGATIVE
    if (count < 0) {
      isValid = false;
      errorField = "count";
      errorMessage = "Negative values are not allowed";
    } else if (qty < 0) {
      isValid = false;
      errorField = "eachQuantity";
      errorMessage = "Negative values are not allowed";
    } else if (price < 0) {
      isValid = false;
      errorField = "newPrice";
      errorMessage = "Negative values are not allowed";
    }
    // ❌ ZERO
    else if (count == 0) {
      isValid = false;
      errorField = "count";
      errorMessage = "Count must be greater than 0";
    } else if (qty == 0) {
      isValid = false;
      errorField = "eachQuantity";
      errorMessage = "Quantity must be greater than 0";
    } else if (price == 0) {
      isValid = false;
      errorField = "newPrice";
      errorMessage = "Price must be greater than 0";
    }
    // ❌ DISCOUNT (ONLY ACTIVE FIELD)
    else if (isPercentage) {
      if (befVal > 0 && befVal >= 100) {
        isValid = false;
        errorField = "befDiscount";
        errorMessage = "Before tax discount cannot be 100% or more";
      } else if (afVal > 0 && afVal >= 100) {
        isValid = false;
        errorField = "afDiscount";
        errorMessage = "After tax discount cannot be 100% or more";
      }
    } else {
      if (befVal > 0 && befVal >= totalAmount) {
        isValid = false;
        errorField = "befDiscount";
        errorMessage = "Before tax discount exceeds total amount";
      } else if (afVal > 0 && afVal >= totalAmount) {
        isValid = false;
        errorField = "afDiscount";
        errorMessage = "After tax discount exceeds total amount";
      }
    }

    if (!isValid) {
      if (_fieldHasError.containsKey(errorField)) {
        _fieldHasError[errorField]!.value = true;
      }

      _errorField.value = errorField;

      if (_fieldShakeTrigger.containsKey(errorField)) {
        _fieldShakeTrigger[errorField]!.value = false;
        Future.microtask(() => _fieldShakeTrigger[errorField]!.value = true);
      }

      _showRequiredFieldSnackBar(errorMessage);
    } else {
      _errorField.value = null;
    }

    return isValid;
  }

  void _showRequiredFieldSnackBar(String message) {
    if (!mounted) return;
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

  void _initializeEditingData(PurchaseOrderNotifier notifier) {
    if (_isInitialized) return;
    if (widget.editingIndex != null &&
        notifier.poItems.isNotEmpty &&
        widget.editingIndex! < notifier.poItems.length) {
      final item = notifier.poItems[widget.editingIndex!];
      _initializeWithEditingItem(item);
    } else {
      _fieldControllers['count']!.text = '1';
      _fieldControllers['befTaxDiscount']!.text = '0';
      _fieldControllers['afTaxDiscount']!.text = '0';
      _updateTotalQuantity(notifier);
      _updateVariance(notifier);
    }
  }

  InputDecoration _buildFieldDecoration(
    String label, {
    bool isReadOnly = false,
    String? hint,
    bool hasError = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,

      labelStyle: TextStyle(
        fontSize: isMobile ? 13 : 14,
        color: hasError ? Colors.red.shade700 : Colors.grey.shade800,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade500),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: hasError ? Colors.red.shade400 : Colors.grey.shade500,
          width: hasError ? 2.0 : 1.0,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: hasError
              ? Colors.red.shade700
              : Color.fromARGB(255, 74, 122, 227),
          width: hasError ? 2.0 : 2.0,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
      ),

      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),

      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade300 : Colors.white,

      suffixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 40),

      errorStyle: TextStyle(fontSize: 12, color: Colors.red.shade700),
      errorText: hasError
          ? " "
          : null, // Show error space but without text (text handled by snackbar)
    );
  }

  void _openNumericCalculator({
    required String title,
    required TextEditingController controller,
    required String type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => NumericCalculator(
        varianceName: title,
        controller: controller,
        initialValue: double.tryParse(controller.text) ?? 0,
        onValueSelected: (value) {
          controller.text = value.toStringAsFixed(2);

          final notifier = Provider.of<PurchaseOrderNotifier>(
            context,
            listen: false,
          );

          /// ✅ Instant total quantity update
          if (title.toLowerCase().contains("count") ||
              title.toLowerCase().contains("quantity")) {
            _updateTotalQuantity(notifier);
          }

          /// ✅ Instant variance update
          if (title.toLowerCase().contains("price")) {
            _updateVariance(notifier);
          }

          if (type == "bef") {
            _fieldHasError['befDiscount']!.value = false;
          }

          if (type == "aft") {
            _fieldHasError['afDiscount']!.value = false;
          }

          if (type == "none") {
            if (title.toLowerCase().contains("count") &&
                _fieldHasError.containsKey('count')) {
              _fieldHasError['count']!.value = false;
            }

            if (title.toLowerCase().contains("quantity") &&
                _fieldHasError.containsKey('eachQuantity')) {
              _fieldHasError['eachQuantity']!.value = false;
            }

            if (title.toLowerCase().contains("price") &&
                _fieldHasError.containsKey('newPrice')) {
              _fieldHasError['newPrice']!.value = false;
            }
          }

          if (type == "bef") {
            if (value > 0) {
              _isAfTaxEnabled.value = false;
            } else {
              _isAfTaxEnabled.value = true;
            }
          }

          if (type == "aft") {
            if (value > 0) {
              _isBefTaxEnabled.value = false;
            } else {
              _isBefTaxEnabled.value = true;
            }
          }

          final poNotifier = Provider.of<PurchaseOrderNotifier>(
            context,
            listen: false,
          );

          final befVal =
              double.tryParse(_fieldControllers['befTaxDiscount']!.text) ?? 0;

          final aftVal =
              double.tryParse(_fieldControllers['afTaxDiscount']!.text) ?? 0;

          if (befVal > 0 || aftVal > 0) {
            poNotifier.isOverallDisabledFromItem = true;
          } else {
            poNotifier.isOverallDisabledFromItem = false;
          }
        },
      ),
    );
  }

  Widget _buildDiscountToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: isMobile ? 6 : 10,
        ),
        constraints: BoxConstraints(minWidth: isMobile ? 70 : 90),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 11 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShakeWrapper({
    required Widget child,
    required ValueNotifier<bool> shakeTrigger,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: shakeTrigger,
      builder: (context, trigger, _) {
        if (!trigger) return child;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          builder: (context, value, _) {
            final double damping = (1 - value);
            final double wave = sin(value * 20);
            final double shakeValue = wave * 8 * damping;

            return Transform.translate(
              offset: Offset(shakeValue, 0),
              child: child,
            );
          },
          onEnd: () {
            Future.microtask(() => shakeTrigger.value = false);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<PurchaseOrderNotifier>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final poProvider = Provider.of<POProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_fieldControllers['count']!.text.isEmpty) {
        _initializeEditingData(notifier);
      }
    });

    Widget twoCol(Widget a, Widget b) {
      return Row(
        children: [
          Expanded(child: a),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(child: b),
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
                      widget.editingIndex != null ? "Edit Item" : "Add Item",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: isMobile ? 20 : 22),
                      onPressed: () {
                        _poNotifier.isOverallDisabledFromItem = false;

                        final notifier = Provider.of<PurchaseOrderNotifier>(
                          context,
                          listen: false,
                        );

                        notifier.itemController.clear();
                        notifier.uomController.clear();
                        _clearItemDetails();

                        Navigator.pop(context);
                      },
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
                          twoCol(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<POProvider>(
                                  builder: (context, poProvider, child) {
                                    return _buildShakeWrapper(
                                      shakeTrigger: _fieldShakeTrigger['item']!,
                                      child: ValueListenableBuilder<bool>(
                                        valueListenable:
                                            _fieldHasError['item']!,
                                        builder: (_, hasError, __) {
                                          return ValueListenableBuilder<bool>(
                                            valueListenable:
                                                _itemFieldLoadingNotifier,
                                            builder: (_, isLoading, __) {
                                              return IgnorePointer(
                                                ignoring: isLoading,
                                                child: Opacity(
                                                  opacity: isLoading ? 0.8 : 1,
                                                  child: ItemAutocomplete(
                                                    controller:
                                                        notifier.itemController,
                                                    notifier: notifier,
                                                    poProvider: poProvider,
                                                    hasError: hasError,
                                                    isPreloading: isLoading,
                                                    onItemSelected:
                                                        (selectedItemName) {
                                                          _fieldHasError['item']!
                                                                  .value =
                                                              false;

                                                          if (selectedItemName
                                                              .isEmpty) {
                                                            _clearItemDetails();
                                                            notifier
                                                                .setSelectedItem(
                                                                  '',
                                                                );
                                                            return;
                                                          }

                                                          notifier
                                                              .setSelectedItem(
                                                                selectedItemName,
                                                              );
                                                          _updateItemDetails(
                                                            notifier,
                                                          );
                                                        },
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            SizedBox(
                              height: 60,
                              child: TextFormField(
                                controller: notifier.uomController,
                                readOnly: true,
                                decoration: _buildFieldDecoration(
                                  "UOM",
                                  isReadOnly: true,
                                ),
                                style: TextStyle(fontSize: isMobile ? 14 : 14),
                              ),
                            ),
                          ),
                          twoCol(
                            _buildShakeWrapper(
                              shakeTrigger: _fieldShakeTrigger['count']!,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _fieldHasError['count']!,
                                builder: (_, hasError, __) {
                                  return TextFormField(
                                    controller: _fieldControllers['count'],
                                    readOnly: true,
                                    decoration: _buildFieldDecoration(
                                      "Pkt Count *",
                                      hasError: hasError,
                                    ),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 14,
                                    ),
                                    onTap: () {
                                      _openNumericCalculator(
                                        title: "pkt Count",
                                        type: "none",
                                        controller: _fieldControllers['count']!,
                                      );
                                    },
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Enter count"
                                        : null,
                                  );
                                },
                              ),
                            ),

                            ValueListenableBuilder<bool>(
                              valueListenable: _isEachQtyFocused,
                              builder: (context, isFocused, _) {
                                return _buildShakeWrapper(
                                  shakeTrigger:
                                      _fieldShakeTrigger['eachQuantity']!,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _fieldHasError['eachQuantity']!,
                                    builder: (_, hasError, __) {
                                      return TextFormField(
                                        controller:
                                            _fieldControllers['eachQuantity'],
                                        focusNode: _eachQtyFocusNode,
                                        readOnly: true,
                                        decoration: _buildFieldDecoration(
                                          isFocused
                                              ? "Qty (Kg/Pcs/Nos) *"
                                              : "Quantity *",
                                          hasError: hasError,
                                        ),
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 14,
                                        ),
                                        onTap: () {
                                          _eachQtyFocusNode.requestFocus();
                                          _openNumericCalculator(
                                            title: "Quantity",
                                            type: "none",
                                            controller:
                                                _fieldControllers['eachQuantity']!,
                                          );
                                        },
                                        validator: (v) => v == null || v.isEmpty
                                            ? "Enter qty"
                                            : null,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          twoCol(
                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['quantity'],
                              decoration: _buildFieldDecoration(
                                "Total Quantity",
                                isReadOnly: true,
                              ),
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
                            ),
                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['existingPrice'],
                              decoration: _buildFieldDecoration(
                                "Existing Price",
                                isReadOnly: true,
                              ),
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
                            ),
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          twoCol(
                            _buildShakeWrapper(
                              shakeTrigger: _fieldShakeTrigger['newPrice']!,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _fieldHasError['newPrice']!,
                                builder: (_, hasError, __) {
                                  return TextFormField(
                                    controller: _fieldControllers['newPrice'],
                                    readOnly: true,
                                    decoration: _buildFieldDecoration(
                                      "Price *",
                                      hasError: hasError,
                                    ),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 14,
                                    ),
                                    onTap: () {
                                      _openNumericCalculator(
                                        title: "Price",
                                        type: "none",
                                        controller:
                                            _fieldControllers['newPrice']!,
                                      );
                                    },
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Enter price"
                                        : null,
                                  );
                                },
                              ),
                            ),

                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['variance'],
                              decoration: _buildFieldDecoration(
                                "Variance",
                                isReadOnly: true,
                              ),
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
                            ),
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          twoCol(
                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['taxPercentage'],
                              decoration: _buildFieldDecoration(
                                "Tax %",
                                isReadOnly: true,
                              ),
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
                            ),
                            SizedBox(),
                          ),

                          SizedBox(height: isMobile ? 12 : 16),

                          ValueListenableBuilder<String>(
                            valueListenable: _itemWiseDiscountMode,
                            builder: (_, mode, __) {
                              return Row(
                                mainAxisAlignment: isMobile
                                    ? MainAxisAlignment.spaceBetween
                                    : MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Item-wise Discount:",
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildDiscountToggleOption(
                                        label: "Percentage",
                                        isSelected: mode == "Percentage ( % )",
                                        onTap: () {
                                          _itemWiseDiscountMode.value =
                                              "Percentage ( % )";
                                          notifier.itemWiseDiscountMode =
                                              DiscountMode.percentage;
                                          // Clear discount error when mode changes
                                          if (_fieldHasError.containsKey(
                                            'discount',
                                          )) {
                                            _fieldHasError['discount']!.value =
                                                false;
                                          }
                                        },
                                      ),
                                      SizedBox(width: isMobile ? 4 : 8),
                                      _buildDiscountToggleOption(
                                        label: "Amount",
                                        isSelected: mode == "Amount ( ₹ )",
                                        onTap: () {
                                          _itemWiseDiscountMode.value =
                                              "Amount ( ₹ )";
                                          notifier.itemWiseDiscountMode =
                                              DiscountMode.amount;
                                          // Clear discount error when mode changes
                                          if (_fieldHasError.containsKey(
                                            'discount',
                                          )) {
                                            _fieldHasError['discount']!.value =
                                                false;
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          SizedBox(height: isMobile ? 8 : 10),

                          twoCol(
                            /// ✅ BEFORE TAX
                            ValueListenableBuilder<bool>(
                              valueListenable: _isBefTaxEnabled,
                              builder: (_, enabled, __) {
                                final poNotifier =
                                    Provider.of<PurchaseOrderNotifier>(
                                      context,
                                      listen: false,
                                    );

                                final finalEnabled =
                                    enabled &&
                                    !poNotifier.isOverallDiscountActive;

                                return _buildShakeWrapper(
                                  shakeTrigger:
                                      _fieldShakeTrigger['befDiscount']!, // ✅ FIX
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _fieldHasError['befDiscount']!, // ✅ FIX
                                    builder: (_, hasError, __) {
                                      return TextFormField(
                                        controller:
                                            _fieldControllers['befTaxDiscount'],
                                        readOnly: true,
                                        enabled: finalEnabled,
                                        decoration: _buildFieldDecoration(
                                          "Before Tax Discount",
                                          hasError: hasError,
                                        ),
                                        onTap: finalEnabled
                                            ? () {
                                                _openNumericCalculator(
                                                  title: "Before Tax Discount",
                                                  controller:
                                                      _fieldControllers['befTaxDiscount']!,
                                                  type: "bef",
                                                );
                                              }
                                            : null,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                            /// ✅ AFTER TAX
                            ValueListenableBuilder<bool>(
                              valueListenable: _isAfTaxEnabled,
                              builder: (_, enabled, __) {
                                final poNotifier =
                                    Provider.of<PurchaseOrderNotifier>(
                                      context,
                                      listen: false,
                                    );

                                final finalEnabled =
                                    enabled &&
                                    !poNotifier.isOverallDiscountActive;

                                return _buildShakeWrapper(
                                  shakeTrigger:
                                      _fieldShakeTrigger['afDiscount']!, // ✅ FIX
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _fieldHasError['afDiscount']!, // ✅ FIX
                                    builder: (_, hasError, __) {
                                      return TextFormField(
                                        controller:
                                            _fieldControllers['afTaxDiscount'],
                                        readOnly: true,
                                        enabled: finalEnabled,
                                        decoration: _buildFieldDecoration(
                                          "After Tax Discount",
                                          hasError: hasError,
                                        ),
                                        onTap: finalEnabled
                                            ? () {
                                                _openNumericCalculator(
                                                  title: "After Tax Discount",
                                                  controller:
                                                      _fieldControllers['afTaxDiscount']!,
                                                  type: "aft",
                                                );
                                              }
                                            : null,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: isMobile ? 16 : 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _poNotifier.isOverallDisabledFromItem = false;

                                  notifier.itemController.clear();
                                  notifier.uomController.clear();
                                  _clearItemDetails();

                                  Navigator.pop(context);
                                },

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

                              ValueListenableBuilder<bool>(
                                valueListenable: _submitButtonLoadingNotifier,
                                builder: (_, isLoading, __) {
                                  return ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => _addOrUpdateItem(notifier),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 20 : 24,
                                        vertical: isMobile ? 10 : 14,
                                      ),
                                    ),
                                    child: isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            widget.editingIndex != null
                                                ? "Update Item"
                                                : "Submit",
                                            style: TextStyle(
                                              fontSize: isMobile ? 13 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  );
                                },
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

  void _updateTotalQuantity(PurchaseOrderNotifier notifier) {
    final count = double.tryParse(_fieldControllers['count']!.text) ?? 0;
    final eachQty =
        double.tryParse(_fieldControllers['eachQuantity']!.text) ?? 0;

    _fieldControllers['quantity']!.text = (count * eachQty).toStringAsFixed(2);
  }

  void _updateVariance(PurchaseOrderNotifier notifier) {
    final existing =
        double.tryParse(_fieldControllers['existingPrice']!.text) ?? 0;
    final newPrice = double.tryParse(_fieldControllers['newPrice']!.text) ?? 0;

    _fieldControllers['variance']!.text = (newPrice - existing).toStringAsFixed(
      2,
    );
  }

  void _updateItemDetails(PurchaseOrderNotifier notifier) {
    if (notifier.itemController.text.trim().isEmpty) {
      _fieldHasError['item']!.value = true;

      _fieldShakeTrigger['item']!.value = false;
      Future.microtask(() => _fieldShakeTrigger['item']!.value = true);

      _showRequiredFieldSnackBar("Please select an item");

      return;
    }
    final selectedName = notifier.itemController.text;

    final selectedItem = notifier.purchaseItems.firstWhere(
      (item) => item.itemName == selectedName,
      orElse: () => PurchaseItem(
        itemName: '',
        itemCode: '',
        purchasePrice: 0,
        purchasetaxName: 0,
        uom: '',
        purchaseItemId: '',
        purchasecategoryName: '',
        purchasesubcategoryName: '',
        hsnCode: '',
        randomId: '',
        locationId: '',
      ),
    );

    if (selectedItem.itemName.isEmpty) return;

    _fieldControllers['existingPrice']!.text = selectedItem.purchasePrice
        .toStringAsFixed(2);
    _fieldControllers['newPrice']!.text = selectedItem.purchasePrice
        .toStringAsFixed(2);
    _fieldControllers['taxPercentage']!.text = selectedItem.purchasetaxName
        .toStringAsFixed(2);

    notifier.uomController.text = selectedItem.uom;

    _updateVariance(notifier);
  }

  Future<void> _calculatePOTotalsFromBackend(
    PurchaseOrderNotifier notifier,
  ) async {
    try {
      final poProvider = Provider.of<POProvider>(context, listen: false);

      double totalSubTotal = 0.0;
      double totalTaxAmount = 0.0;

      double totalBefTaxDiscount = 0.0;
      double totalAfTaxDiscount = 0.0;

      double totalFinalAmount = 0.0;

      for (final item in notifier.poItems) {
        final result = await poProvider.calculateItemTotalsBackend(
          pendingTotalQuantity: item.pendingTotalQuantity ?? item.quantity ?? 0,
          poQuantity: item.poQuantity ?? item.quantity ?? 0,
          newPrice: item.newPrice ?? 0,

          befTaxDiscount: item.befTaxDiscount ?? 0,
          afTaxDiscount: item.afTaxDiscount ?? 0,

          befTaxDiscountAmount: item.befTaxDiscountAmount ?? 0,
          afTaxDiscountAmount: item.afTaxDiscountAmount ?? 0,

          befTaxDiscountType: item.befTaxDiscountType ?? 'percentage',
          afTaxDiscountType: item.afTaxDiscountType ?? 'percentage',

          taxPercentage: item.taxPercentage ?? 0,
          taxType: item.taxType ?? 'cgst_sgst',
        );

        final double baseAmount =
            (item.pendingTotalQuantity ?? item.quantity ?? 0) *
            (item.newPrice ?? 0);

        final double taxAmount = result['pendingTaxAmount'] ?? 0.0;
        final double finalPrice = result['pendingFinalPrice'] ?? 0.0;

        final double befTaxDiscAmt =
            result['pendingBefTaxDiscountAmount'] ?? 0.0;
        final double afTaxDiscAmt = result['pendingAfTaxDiscountAmount'] ?? 0.0;

        item.totalPrice = baseAmount;
        item.pendingTotalPrice = baseAmount;

        item.taxAmount = taxAmount;
        item.pendingTaxAmount = taxAmount;

        item.finalPrice = finalPrice;
        item.pendingFinalPrice = finalPrice;

        item.pendingDiscountAmount = (result['pendingDiscountAmount'] ?? 0.0);

        item.pendingCgst = result['pendingCgst'] ?? 0.0;
        item.pendingSgst = result['pendingSgst'] ?? 0.0;
        item.pendingIgst = result['pendingIgst'] ?? 0.0;

        totalSubTotal += baseAmount;
        totalTaxAmount += taxAmount;

        totalBefTaxDiscount += befTaxDiscAmt;
        totalAfTaxDiscount += afTaxDiscAmt;

        totalFinalAmount += finalPrice;
      }

      notifier.itemWiseDiscount = totalBefTaxDiscount + totalAfTaxDiscount;

      if (!notifier.isOverallDiscountActive) {
        notifier.overallDiscountAmount = 0.0;
      }

      notifier.subTotal = totalSubTotal;
      notifier.pendingTaxAmount = totalTaxAmount;

      final double roundOff =
          double.tryParse(notifier.roundOffController.text) ?? 0.0;

      notifier.calculatedFinalAmount = totalFinalAmount + roundOff;

      notifier.totalOrderAmount = notifier.calculatedFinalAmount;

      notifier.pendingOrderAmount = notifier.calculatedFinalAmount;

      notifier.pendingDiscountAmount =
          notifier.itemWiseDiscount + (notifier.overallDiscountAmount ?? 0.0);

      notifier.notifyListeners();
    } catch (e) {
      return Future.error("Failed to calculate totals: $e");
    }
  }

  Future<void> _addOrUpdateItem(PurchaseOrderNotifier notifier) async {
    if (!_formKey.currentState!.validate()) return;

    if (notifier.itemController.text.trim().isEmpty) {
      _fieldHasError['item']!.value = true;

      _fieldShakeTrigger['item']!.value = false;
      Future.microtask(() => _fieldShakeTrigger['item']!.value = true);

      _showRequiredFieldSnackBar("Please select an item");
      return;
    }

    if (!_validateInputs()) return;

    _submitButtonLoadingNotifier.value = true;

    try {
      final double count =
          double.tryParse(_fieldControllers['count']!.text) ?? 0;

      final double eachQty =
          double.tryParse(_fieldControllers['eachQuantity']!.text) ?? 0;

      final double newPrice =
          double.tryParse(_fieldControllers['newPrice']!.text) ?? 0;

      final double befValue =
          double.tryParse(_fieldControllers['befTaxDiscount']!.text) ?? 0;

      final double afValue =
          double.tryParse(_fieldControllers['afTaxDiscount']!.text) ?? 0;

      final double taxPercentage =
          double.tryParse(_fieldControllers['taxPercentage']!.text) ?? 0;

      final double totalQuantity = count * eachQty;

      final bool isAmountMode =
          notifier.itemWiseDiscountMode == DiscountMode.amount;

      final String befType = (befValue > 0 && afValue == 0)
          ? (isAmountMode ? "amount" : "percentage")
          : "percentage";

      final String afType = (afValue > 0 && befValue == 0)
          ? (isAmountMode ? "amount" : "percentage")
          : "percentage";

      final poProvider = Provider.of<POProvider>(context, listen: false);

      final result = await poProvider.calculateItemTotalsBackend(
        pendingTotalQuantity: totalQuantity,
        poQuantity: widget.editingItem?.poQuantity ?? totalQuantity,
        newPrice: newPrice,
        befTaxDiscount: befType == "percentage" ? befValue : 0.0,
        afTaxDiscount: afType == "percentage" ? afValue : 0.0,
        befTaxDiscountAmount: befType == "amount" ? befValue : 0.0,
        afTaxDiscountAmount: afType == "amount" ? afValue : 0.0,
        befTaxDiscountType: befType,
        afTaxDiscountType: afType,
        taxPercentage: taxPercentage,
        taxType: notifier.taxType,
      );

      final selectedItemName = notifier.itemController.text;

      final PurchaseItem selectedPurchaseItem = notifier.purchaseItems
          .firstWhere(
            (item) =>
                item.itemName.trim().toLowerCase() ==
                selectedItemName.trim().toLowerCase(),
            orElse: () => PurchaseItem(
              itemName: '',
              itemCode: '',
              purchasePrice: 0,
              purchasetaxName: 0,
              uom: '',
              purchaseItemId: '',
              purchasecategoryName: '',
              purchasesubcategoryName: '',
              hsnCode: '',
              randomId: '',
              locationId: '',
            ),
          );
      final Item newItem = Item(
        itemId: selectedPurchaseItem.purchaseItemId,
        itemName: notifier.itemController.text,
        itemCode: selectedPurchaseItem.itemCode ?? '',
        locationId: selectedPurchaseItem.locationId ?? '',

        /// IMPORTANT
        /// Use correct master randomId like PI1437
        /// NEVER generated timestamp randomId
        randomId:
            selectedPurchaseItem.randomId ?? widget.editingItem?.randomId ?? '',

        befTaxDiscountType: befType,
        afTaxDiscountType: afType,

        quantity: totalQuantity,
        existingPrice:
            double.tryParse(_fieldControllers['existingPrice']!.text) ?? 0,
        newPrice: newPrice,

        count: count,
        eachQuantity: eachQty,

        taxPercentage: taxPercentage,
        taxAmount: result['pendingTaxAmount'] ?? 0,

        befTaxDiscount: befType == "percentage"
            ? befValue
            : (result['befTaxDiscount'] ?? 0.0),

        afTaxDiscount: afType == "percentage"
            ? afValue
            : (result['afTaxDiscount'] ?? 0.0),

        befTaxDiscountAmount: befType == "amount"
            ? befValue
            : (result['pendingBefTaxDiscountAmount'] ?? 0.0),

        afTaxDiscountAmount: afType == "amount"
            ? afValue
            : (result['pendingAfTaxDiscountAmount'] ?? 0.0),

        totalPrice: result['pendingTotalPrice'] ?? 0,
        finalPrice: result['pendingFinalPrice'] ?? 0,

        variance:
            newPrice -
            (double.tryParse(_fieldControllers['existingPrice']!.text) ?? 0),

        uom: notifier.uomController.text,
        taxType: notifier.taxType,

        pendingCount: count,
        pendingQuantity: eachQty,
        pendingTotalQuantity: totalQuantity,

        pendingTaxAmount: result['pendingTaxAmount'] ?? 0,
        pendingFinalPrice: result['pendingFinalPrice'] ?? 0,
        pendingTotalPrice: result['pendingTotalPrice'] ?? 0,
        pendingDiscountAmount: result['pendingDiscountAmount'] ?? 0,

        pendingCgst: result['pendingCgst'] ?? 0,
        pendingSgst: result['pendingSgst'] ?? 0,
        pendingIgst: result['pendingIgst'] ?? 0,

        expiryDate: '',
        hsnCode: selectedPurchaseItem.hsnCode,
        purchasecategoryName: selectedPurchaseItem.purchasecategoryName,
        purchasesubcategoryName: selectedPurchaseItem.purchasesubcategoryName,
      );

      /// EDIT FLOW
      if (widget.editingIndex != null) {
        notifier.poItems[widget.editingIndex!] = newItem;
      } else {
        final existingIndex = notifier.poItems.indexWhere(
          (i) => i.itemId == newItem.itemId && i.uom == newItem.uom,
        );

        if (existingIndex != -1) {
          final existingItem = notifier.poItems[existingIndex];

          final newQty = (existingItem.quantity ?? 0) + (newItem.quantity ?? 0);

          final newCount = (existingItem.count ?? 0) + (newItem.count ?? 0);

          existingItem.quantity = newQty;
          existingItem.count = newCount;

          existingItem.pendingTotalQuantity = newQty;
          existingItem.pendingCount = newCount;

          existingItem.pendingQuantity =
              newQty / (newCount == 0 ? 1 : newCount);

          existingItem.newPrice = newItem.newPrice;

          /// IMPORTANT FIX
          existingItem.randomId = newItem.randomId;
        } else {
          notifier.poItems.add(newItem);
        }
      }

      notifier.notifyListeners();

      await _calculatePOTotalsFromBackend(notifier);

      if (mounted) {
        widget.onItemAdded();
        Navigator.of(context).pop();

        notifier.itemController.clear();
        notifier.uomController.clear();
        _clearItemDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      _submitButtonLoadingNotifier.value = false;
    }
  }
}
