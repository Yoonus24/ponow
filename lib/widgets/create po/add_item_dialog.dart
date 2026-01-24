// ignore_for_file: prefer_const_constructors_in_immutables, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';
import '../../models/discount_model.dart';
import '../../models/po_item.dart';
import '../../models/vendorpurchasemodel.dart';

// MARK: - Main Dialog Widget
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

// MARK: - State Class
class _AddItemDialogState extends State<AddItemDialog> {
  // MARK: - Form and State Variables
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  // MARK: - Value Notifiers
  final ValueNotifier<String> _itemWiseDiscountMode = ValueNotifier(
    "Percentage ( % )",
  );
  final ValueNotifier<bool> _refreshTrigger = ValueNotifier(false);
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  // MARK: - Text Editing Controllers
  final Map<String, TextEditingController> _fieldControllers = {};

  final ValueNotifier<bool> _isBefTaxEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isAfTaxEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isOverallDisabledFromItem = ValueNotifier(false);
  final FocusNode _eachQtyFocusNode = FocusNode();
  final ValueNotifier<bool> _isEachQtyFocused = ValueNotifier(false);

  // MARK: - Lifecycle Methods
  @override
  void initState() {
    super.initState();

    _initializeControllers();

    _eachQtyFocusNode.addListener(() {
      _isEachQtyFocused.value = _eachQtyFocusNode.hasFocus;
    });

    _fieldControllers['count']!.addListener(_refreshPreview);
    _fieldControllers['eachQuantity']!.addListener(_refreshPreview);
    _fieldControllers['newPrice']!.addListener(_refreshPreview);
    _fieldControllers['befTaxDiscount']!.addListener(_refreshPreview);
    _fieldControllers['afTaxDiscount']!.addListener(_refreshPreview);

    _isBefTaxEnabled.value = true;
    _isAfTaxEnabled.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final poNotifier = Provider.of<PurchaseOrderNotifier>(
        context,
        listen: false,
      );

      if (widget.editingItem == null) {
        poNotifier.isOverallDiscountActive = false;
        poNotifier.isOverallDisabledFromItem = false;

        _isBefTaxEnabled.value = true;
        _isAfTaxEnabled.value = true;

        print('🧹 Reset discount flags for NEW item dialog');
      }
    });
  }

  @override
  void dispose() {
    final poNotifier = Provider.of<PurchaseOrderNotifier>(
      context,
      listen: false,
    );

    poNotifier.isOverallDisabledFromItem = false;

    _fieldControllers['count']?.removeListener(_refreshPreview);
    _fieldControllers['eachQuantity']?.removeListener(_refreshPreview);
    _fieldControllers['newPrice']?.removeListener(_refreshPreview);
    _fieldControllers['befTaxDiscount']?.removeListener(_refreshPreview);
    _fieldControllers['afTaxDiscount']?.removeListener(_refreshPreview);

    _itemWiseDiscountMode.dispose();
    _refreshTrigger.dispose();
    _loadingNotifier.dispose();
    _isBefTaxEnabled.dispose();
    _isAfTaxEnabled.dispose();
    _isOverallDisabledFromItem.dispose();
    _eachQtyFocusNode.dispose();
    _isEachQtyFocused.dispose();

    super.dispose();
  }

  // MARK: - Initialization Methods
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

  /// OLD-STYLE EDIT INITIALIZATION (keeps logic unchanged)
  void _initializeWithEditingItem(Item item) {
    if (_isInitialized || !mounted) return;
    _isInitialized = true;

    print('🔄 Initializing dialog with editing item: ${item.itemName}');

    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);

    // 1️⃣ Prefer pending values first
    final double countValue = item.pendingCount ?? item.count ?? 1;
    final double eachQtyValue = item.pendingQuantity ?? item.eachQuantity ?? 0;
    final double quantityValue =
        item.pendingTotalQuantity ??
        item.quantity ??
        (countValue * eachQtyValue);

    // 2️⃣ Basic values into controllers
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

    final double befTaxDiscount = item.befTaxDiscount ?? 0.0;
    final double afTaxDiscount = item.afTaxDiscount ?? 0.0;

    _fieldControllers['befTaxDiscount']!.text = befTaxDiscount.toStringAsFixed(
      2,
    );
    _fieldControllers['afTaxDiscount']!.text = afTaxDiscount.toStringAsFixed(2);

    // 3️⃣ Item name & UOM
    notifier.itemController.text = item.itemName ?? '';
    notifier.uomController.text = item.uom ?? '';

    // 4️⃣ Discount type → Mode
    final String befTaxDiscountType =
        (item.befTaxDiscountType != null && item.befTaxDiscountType!.isNotEmpty)
        ? item.befTaxDiscountType!
        : "percentage";

    final String afTaxDiscountType =
        (item.afTaxDiscountType != null && item.afTaxDiscountType!.isNotEmpty)
        ? item.afTaxDiscountType!
        : "percentage";

    if (befTaxDiscountType == 'amount' || afTaxDiscountType == 'amount') {
      _itemWiseDiscountMode.value = 'Amount ( ₹ )';
      notifier.itemWiseDiscountMode = DiscountMode.fixedAmount;
      print('🎯 Discount Mode: AMOUNT (₹)');
    } else {
      _itemWiseDiscountMode.value = 'Percentage ( % )';
      notifier.itemWiseDiscountMode = DiscountMode.percentage;
      print('🎯 Discount Mode: PERCENTAGE (%)');
    }

    // 5️⃣ Update quantity, variance & preview
    _updateTotalQuantity(notifier);
    _updateVariance(notifier);
    _refreshPreview(); // ensures preview rebuild

    print('✅ Edit item initialization complete.');

    final poNotifier = Provider.of<PurchaseOrderNotifier>(
      context,
      listen: false,
    );

    // ✅ Item-wise discount present → lock only the opposite field
    if (befTaxDiscount > 0 || afTaxDiscount > 0) {
      // Disable overall toggle because item-wise is used
      poNotifier.isOverallDisabledFromItem = true;
      // But DO NOT mark overall as active
      poNotifier.isOverallDiscountActive = false;

      if (befTaxDiscount > 0) {
        // Entered in BEF → AF disabled, BEF stays enabled
        _isBefTaxEnabled.value = true;
        _isAfTaxEnabled.value = false;
      }

      if (afTaxDiscount > 0) {
        // Entered in AF → BEF disabled, AF stays enabled
        _isAfTaxEnabled.value = true;
        _isBefTaxEnabled.value = false;
      }
    } else {
      // No item-wise discount -> both enabled
      _isBefTaxEnabled.value = true;
      _isAfTaxEnabled.value = true;
    }
  }

  /// For cases when only editingIndex is passed (not editingItem)
  void _initializeEditingData(PurchaseOrderNotifier notifier) {
    if (_isInitialized) return;
    if (widget.editingIndex != null &&
        notifier.poItems.isNotEmpty &&
        widget.editingIndex! < notifier.poItems.length) {
      final item = notifier.poItems[widget.editingIndex!];
      _initializeWithEditingItem(item);
    } else {
      // New item defaults
      _fieldControllers['count']!.text = '1';
      _fieldControllers['befTaxDiscount']!.text = '0';
      _fieldControllers['afTaxDiscount']!.text = '0';
      _updateTotalQuantity(notifier);
      _updateVariance(notifier);
      _refreshPreview();
    }
  }

  // MARK: - UI Helper Methods
  void _openNumericCalculator({
    required String title,
    required TextEditingController controller,
    required String type, // "bef", "aft", "none"
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

          // ✅ Only opposite field should disable
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

          // ✅ Update overall toggle lock based on BOTH item-wise fields
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

          _refreshPreview();
        },
      ),
    );
  }

  // MARK: - Data Helper Methods
  dynamic _getItemProperty(dynamic item, String propertyName) {
    try {
      if (item == null) return null;
      if (item is Map<String, dynamic>) return item[propertyName];
      return _getPropertyValue(item, propertyName);
    } catch (_) {
      return null;
    }
  }

  dynamic _getPropertyValue(dynamic obj, String prop) {
    try {
      switch (prop) {
        case 'count':
          return obj.count;
        case 'eachQuantity':
          return obj.eachQuantity;
        case 'quantity':
          return obj.quantity;
        case 'existingPrice':
          return obj.existingPrice;
        case 'newPrice':
          return obj.newPrice;
        case 'taxPercentage':
          return obj.taxPercentage;
        case 'befTaxDiscount':
          return obj.befTaxDiscount;
        case 'afTaxDiscount':
          return obj.afTaxDiscount;
        case 'befTaxDiscountType':
          return obj.befTaxDiscountType;
        case 'uom':
          return obj.uom;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  void _refreshPreview() {
    // ✅ ADD EXTRA SAFETY CHECK
    if (!mounted) return;

    try {
      final notifier = Provider.of<PurchaseOrderNotifier>(
        context,
        listen: false,
      );

      _updateTotalQuantity(notifier);
      _updateVariance(notifier);

      // Toggle the trigger to rebuild listeners
      _refreshTrigger.value = !_refreshTrigger.value;

      // ✅ CHECK AGAIN BEFORE setState
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Ignore errors when widget is disposing
      print('⚠️ Safe ignore during dispose: $e');
    }
  }

  // MARK: - Responsive Helper Methods
  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  // MARK: - Main Build Method
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<PurchaseOrderNotifier>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_fieldControllers['count']!.text.isEmpty) {
        _initializeEditingData(notifier);
      }
    });

    InputDecoration dimmed(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 10,
          vertical: isMobile ? 8 : 10,
        ),
        border: OutlineInputBorder(), // default border
        enabledBorder: OutlineInputBorder(), // default grey border
        focusedBorder: OutlineInputBorder(), // default blue border
      );
    }

    InputDecoration normal(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 10,
          vertical: isMobile ? 8 : 10,
        ),
        border: OutlineInputBorder(), // default style
        enabledBorder: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(),
      );
    }

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
                // MARK: - Header Section
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
                        mainAxisSize: MainAxisSize.min, // VERY IMPORTANT FIX
                        children: [
                          // MARK: - Item Selection Section
                          // ITEM + UOM (ALWAYS 2 COLUMNS)
                          twoCol(
                            Autocomplete<String>(
                              optionsBuilder: (textValue) async {
                                final q = textValue.text.trim();
                                await notifier.fetchItems(q);
                                return notifier.purchaseItems
                                    .where(
                                      (item) => item.itemName
                                          .toLowerCase()
                                          .contains(q.toLowerCase()),
                                    )
                                    .map((e) => e.itemName)
                                    .toList();
                              },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        color: Colors.white,
                                        elevation: 4,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxHeight: 200,
                                            maxWidth: isMobile
                                                ? MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.8
                                                : 400,
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final option = options.elementAt(
                                                index,
                                              );
                                              return ListTile(
                                                dense: isMobile,
                                                title: Text(
                                                  option,
                                                  style: TextStyle(
                                                    fontSize: isMobile
                                                        ? 12
                                                        : 13,
                                                  ),
                                                ),
                                                onTap: () => onSelected(option),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                              onSelected: (v) {
                                notifier.setSelectedItem(v);
                                _updateItemDetails(notifier);
                                FocusScope.of(context).unfocus();
                                _refreshPreview();
                              },
                              fieldViewBuilder: (_, controller, node, __) {
                                notifier.itemController = controller;

                                return Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    TextFormField(
                                      controller: controller,
                                      focusNode: node,
                                      decoration: normal("Select Item *").copyWith(
                                        suffixIcon: controller.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  size: isMobile ? 16 : 18,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  controller.clear();
                                                  notifier.uomController
                                                      .clear();

                                                  // CLEAR ALL ITEM-RELATED FIELDS
                                                  _fieldControllers['count']!
                                                      .clear();
                                                  _fieldControllers['eachQuantity']!
                                                      .clear();
                                                  _fieldControllers['quantity']!
                                                      .clear();
                                                  _fieldControllers['existingPrice']!
                                                      .clear();
                                                  _fieldControllers['newPrice']!
                                                      .clear();
                                                  _fieldControllers['variance']!
                                                      .clear();
                                                  _fieldControllers['taxPercentage']!
                                                      .clear();
                                                  _fieldControllers['befTaxDiscount']!
                                                          .text =
                                                      '0';
                                                  _fieldControllers['afTaxDiscount']!
                                                          .text =
                                                      '0';

                                                  _itemWiseDiscountMode.value =
                                                      "Percentage ( % )";

                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                  _refreshPreview();
                                                },
                                              )
                                            : null,
                                      ),
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                      validator: (v) => v == null || v.isEmpty
                                          ? "Select item"
                                          : null,
                                    ),
                                  ],
                                );
                              },
                            ),
                            TextFormField(
                              controller: notifier.uomController,
                              readOnly: true,
                              decoration: dimmed("UOM"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          // MARK: - Quantity Section
                          // COUNT + EACH QTY (ALWAYS 2 COLUMNS)
                          twoCol(
                            TextFormField(
                              controller: _fieldControllers['count'],
                              readOnly: true,
                              decoration: normal("Count *"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                              onTap: () {
                                _openNumericCalculator(
                                  title: "Count",
                                  type: "none",
                                  controller: _fieldControllers['count']!,
                                );
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter count" : null,
                            ),

                            ValueListenableBuilder<bool>(
                              valueListenable: _isEachQtyFocused,
                              builder: (context, isFocused, _) {
                                return TextFormField(
                                  controller: _fieldControllers['eachQuantity'],
                                  focusNode: _eachQtyFocusNode,
                                  readOnly: true,
                                  decoration: normal(
                                    isFocused
                                        ? "Qty (Kg/Pcs/Nos) *"
                                        : "Quantity *",
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                  onTap: () {
                                    _eachQtyFocusNode
                                        .requestFocus(); // ensure focus
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
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          // MARK: - Price Section
                          // TOTAL QTY + EXISTING PRICE (ALWAYS 2 COLUMNS)
                          twoCol(
                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['quantity'],
                              decoration: dimmed("Total Quantity"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['existingPrice'],
                              decoration: dimmed("Existing Price"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          // NEW PRICE + VARIANCE (ALWAYS 2 COLUMNS)
                          twoCol(
                            TextFormField(
                              controller: _fieldControllers['newPrice'],
                              readOnly: true,
                              decoration: normal("Price *"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                              onTap: () {
                                _openNumericCalculator(
                                  title: "Price",
                                  type: "none",
                                  controller: _fieldControllers['newPrice']!,
                                );
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter price" : null,
                            ),

                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['variance'],
                              decoration: dimmed("Variance"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                          ),

                          SizedBox(height: isMobile ? 8 : 12),

                          // MARK: - Tax Section (ALWAYS 2 COLUMNS)
                          twoCol(
                            TextFormField(
                              readOnly: true,
                              controller: _fieldControllers['taxPercentage'],
                              decoration: dimmed("Tax %"),
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            SizedBox(),
                          ),

                          SizedBox(height: isMobile ? 12 : 16),

                          // MARK: - Discount Section
                          // DISCOUNT MODE TOGGLE
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
                                          _refreshPreview();
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
                                              DiscountMode.fixedAmount;
                                          _refreshPreview();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          SizedBox(height: isMobile ? 8 : 10),

                          // MARK: - Discount Fields (ALWAYS 2 COLUMNS)
                          twoCol(
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

                                return TextFormField(
                                  controller:
                                      _fieldControllers['befTaxDiscount'],
                                  readOnly: true,
                                  enabled: finalEnabled,
                                  decoration: normal("Before Tax Discount"),
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
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

                                return TextFormField(
                                  controller:
                                      _fieldControllers['afTaxDiscount'],
                                  readOnly: true,
                                  enabled: finalEnabled,
                                  decoration: normal("After Tax Discount"),
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
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
                          ),

                          SizedBox(height: isMobile ? 12 : 16),

                          //-------------------------  for summary preview ----------------------------//

                          // MARK: - Preview Section
                          // PREVIEW listens to refresh trigger so calculations update
                          // ValueListenableBuilder<bool>(
                          //   valueListenable: _refreshTrigger,
                          //   builder: (_, __, ___) {
                          //     return _buildPreviewCalculation(notifier);
                          //   },
                          // ),
                          SizedBox(height: isMobile ? 16 : 20),

                          // MARK: - Action Buttons
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

                              // Loading-aware button
                              ValueListenableBuilder<bool>(
                                valueListenable: _loadingNotifier,
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

  // MARK: - Discount UI Components
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

  //----------------------  for summary preview ---------------------------//

  // // MARK: - Preview Calculation Methods
  // // MARK: - Preview Calculation Methods
  // Widget _buildPreviewCalculation(PurchaseOrderNotifier notifier) {
  //   // Instead of local calculation, call backend API
  //   // This could be called asynchronously or on demand

  //   return FutureBuilder<Map<String, dynamic>>(
  //     future: _calculatePreviewFromBackend(),
  //     builder: (context, snapshot) {
  //       final bool isMobile =
  //           MediaQuery.of(context).size.width < 600; // ✅ ADD THIS

  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return Center(child: CircularProgressIndicator());
  //       }

  //       if (snapshot.hasError) {
  //         return Text('Error: ${snapshot.error}');
  //       }

  //       final data = snapshot.data ?? {};

  //       return Container(
  //         padding: EdgeInsets.all(isMobile ? 10 : 16),
  //         decoration: BoxDecoration(
  //           color: Colors.grey.shade50,
  //           borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
  //           border: Border.all(color: Colors.grey.shade300),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Calculation Preview (from backend)'),
  //             _buildPreviewRow(
  //               'Base Amount',
  //               '₹${(data['pendingTotalPrice'] ?? 0).toStringAsFixed(2)}',
  //               isMobile: isMobile, // ✅ ADD THIS
  //             ),
  //             _buildPreviewRow(
  //               'Before Tax Discount',
  //               '₹${(data['pendingBefTaxDiscountAmount'] ?? 0).toStringAsFixed(2)}',
  //               isMobile: isMobile, // ✅ ADD THIS
  //             ),
  //             _buildPreviewRow(
  //               'Tax Amount',
  //               '₹${(data['pendingTaxAmount'] ?? 0).toStringAsFixed(2)}',
  //               isMobile: isMobile, // ✅ ADD THIS
  //             ),
  //             _buildPreviewRow(
  //               'After Tax Discount',
  //               '₹${(data['pendingAfTaxDiscountAmount'] ?? 0).toStringAsFixed(2)}',
  //               isMobile: isMobile, // ✅ ADD THIS
  //             ),
  //             Divider(thickness: 1),
  //             _buildPreviewRow(
  //               'FINAL AMOUNT',
  //               '₹${(data['pendingFinalPrice'] ?? 0).toStringAsFixed(2)}',
  //               isBold: true,
  //               textColor: Colors.green[700],
  //               isMobile: isMobile, // ✅ ADD THIS
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<Map<String, dynamic>> _calculatePreviewFromBackend() async {
    // ----------------------------
    // Read current field values
    // ----------------------------
    final double count = double.tryParse(_fieldControllers['count']!.text) ?? 0;
    final double eachQty =
        double.tryParse(_fieldControllers['eachQuantity']!.text) ?? 0;
    final double price =
        double.tryParse(_fieldControllers['newPrice']!.text) ?? 0;
    final double befTaxDiscountValue =
        double.tryParse(_fieldControllers['befTaxDiscount']!.text) ?? 0;
    final double afTaxDiscountValue =
        double.tryParse(_fieldControllers['afTaxDiscount']!.text) ?? 0;
    final double taxPercentage =
        double.tryParse(_fieldControllers['taxPercentage']!.text) ?? 0;

    final double totalQuantity = count * eachQty;
    final double baseAmount = totalQuantity * price;

    // ----------------------------
    // HARD GUARDS
    // ----------------------------
    if (totalQuantity <= 0 || price <= 0) {
      return {
        'pendingTotalPrice': 0.0,
        'pendingBefTaxDiscountAmount': 0.0,
        'pendingAfTaxDiscountAmount': 0.0,
        'pendingTaxAmount': 0.0,
        'pendingFinalPrice': 0.0,
        'pendingDiscountAmount': 0.0,
      };
    }

    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
    final poProvider = Provider.of<POProvider>(context, listen: false);

    // ✅ FIX: Determine discount mode
    final bool isAmountMode =
        notifier.itemWiseDiscountMode == DiscountMode.fixedAmount;

    print('🔍 PREVIEW CALCULATION:');
    print('   Mode: ${isAmountMode ? "Amount (₹)" : "Percentage (%)"}');
    print('   Bef Tax Value: $befTaxDiscountValue');
    print('   Af Tax Value: $afTaxDiscountValue');
    print('   Base Amount: ₹$baseAmount');

    // ✅ FIX: Prepare parameters based on mode
    double befTaxDiscountToSend = 0.0;
    double afTaxDiscountToSend = 0.0;
    double befTaxDiscountAmountToSend = 0.0;
    double afTaxDiscountAmountToSend = 0.0;

    if (isAmountMode) {
      // AMOUNT MODE: Send amounts directly
      befTaxDiscountAmountToSend = befTaxDiscountValue;
      afTaxDiscountAmountToSend = afTaxDiscountValue;

      // Calculate equivalent percentages for display
      if (baseAmount > 0) {
        befTaxDiscountToSend = (befTaxDiscountValue / baseAmount) * 100;
      }

      double afterBefTax = baseAmount - befTaxDiscountValue;
      double taxAmount = afterBefTax * (taxPercentage / 100);
      double priceAfterTax = afterBefTax + taxAmount;

      if (priceAfterTax > 0) {
        afTaxDiscountToSend = (afTaxDiscountValue / priceAfterTax) * 100;
      }

      print('   Amount Mode -> Sending to backend:');
      print('     befTaxDiscountAmount: $befTaxDiscountAmountToSend');
      print('     afTaxDiscountAmount: $afTaxDiscountAmountToSend');
    } else {
      // PERCENTAGE MODE: Send percentages
      befTaxDiscountToSend = befTaxDiscountValue;
      afTaxDiscountToSend = afTaxDiscountValue;

      print('   Percentage Mode -> Sending to backend:');
      print('     befTaxDiscount: $befTaxDiscountToSend%');
      print('     afTaxDiscount: $afTaxDiscountToSend%');
    }

    // ✅ FIX: Call backend with correct parameters
    try {
      final result = await poProvider.calculateItemTotalsBackend(
        pendingTotalQuantity: totalQuantity,
        poQuantity: totalQuantity,
        newPrice: price,
        befTaxDiscount: isAmountMode ? 0.0 : befTaxDiscountToSend,
        afTaxDiscount: isAmountMode ? 0.0 : afTaxDiscountToSend,
        befTaxDiscountAmount: isAmountMode ? befTaxDiscountAmountToSend : 0.0,
        afTaxDiscountAmount: isAmountMode ? afTaxDiscountAmountToSend : 0.0,
        befTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        afTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        taxPercentage: taxPercentage,
        taxType: notifier.taxType,
      );

      print('✅ Backend Response:');
      print('   Final Price: ₹${result['pendingFinalPrice'] ?? 0}');
      print(
        '   AfTax Discount Amount: ₹${result['pendingAfTaxDiscountAmount'] ?? 0}',
      );

      return result;
    } catch (e) {
      print('❌ Preview calculation error: $e');

      return {
        'pendingTotalPrice': baseAmount,
        'pendingBefTaxDiscountAmount': isAmountMode
            ? befTaxDiscountValue
            : (baseAmount * befTaxDiscountValue / 100),
        'pendingAfTaxDiscountAmount': 0.0,
        'pendingTaxAmount': 0.0,
        'pendingFinalPrice': baseAmount,
        'pendingDiscountAmount': 0.0,
        'error': 'Preview calculation failed: $e',
      };
    }
  }

  Widget _buildPreviewRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 11 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Business Logic Methods
  void _toggleDiscountMode() {
    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
    final current = _itemWiseDiscountMode.value;

    if (current == 'Percentage ( % )') {
      _itemWiseDiscountMode.value = 'Amount ( ₹ )';
      notifier.itemWiseDiscountMode = DiscountMode.fixedAmount;
    } else {
      _itemWiseDiscountMode.value = 'Percentage ( % )';
      notifier.itemWiseDiscountMode = DiscountMode.percentage;
    }

    _refreshPreview();
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
    if (notifier.itemController.text.isEmpty) return;

    final selectedName = notifier.itemController.text;

    final selectedItem = notifier.purchaseItems.firstWhere(
      (item) => item.itemName == selectedName,
      orElse: () => PurchaseItem(
        itemName: '',
        purchasePrice: 0,
        purchasetaxName: 0,
        uom: '',
        purchaseItemId: '',
        purchasecategoryName: '',
        purchasesubcategoryName: '',
        hsnCode: '',
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
    _refreshPreview();
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

        // -------------------------------
        // 🔥 UPDATE ITEM VALUES
        // -------------------------------
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

        // -------------------------------
        // 🔢 ACCUMULATE TOTALS
        // -------------------------------
        totalSubTotal += baseAmount;
        totalTaxAmount += taxAmount;

        totalBefTaxDiscount += befTaxDiscAmt;
        totalAfTaxDiscount += afTaxDiscAmt;

        totalFinalAmount += finalPrice;
      }

      // -------------------------------
      // ✅ FIXED SUMMARY LOGIC
      // -------------------------------

      // 🔥 BOTH BEF + AF TAX ARE ITEM-WISE DISCOUNTS
      notifier.itemWiseDiscount = totalBefTaxDiscount + totalAfTaxDiscount;

      // 🔥 OVERALL DISCOUNT IS ONLY FROM OVERALL API
      if (!notifier.isOverallDiscountActive) {
        notifier.overallDiscountAmount = 0.0;
      }

      notifier.subTotal = totalSubTotal;
      notifier.pendingTaxAmount = totalTaxAmount;

      // -------------------------------
      // 🔄 FINAL TOTAL WITH ROUND OFF
      // -------------------------------
      final double roundOff =
          double.tryParse(notifier.roundOffController.text) ?? 0.0;

      notifier.calculatedFinalAmount = totalFinalAmount + roundOff;

      notifier.totalOrderAmount = notifier.calculatedFinalAmount;

      notifier.pendingOrderAmount = notifier.calculatedFinalAmount;

      notifier.pendingDiscountAmount =
          notifier.itemWiseDiscount + (notifier.overallDiscountAmount ?? 0.0);

      notifier.notifyListeners();

      // -------------------------------
      // 🧪 DEBUG (OPTIONAL)
      // -------------------------------
      print('📊 PO TOTALS CALCULATED');
      print('Subtotal: $totalSubTotal');
      print('Tax: $totalTaxAmount');
      print('Item-wise Discount: ${notifier.itemWiseDiscount}');
      print('Overall Discount: ${notifier.overallDiscountAmount}');
      print('Final Amount: ${notifier.totalOrderAmount}');
    } catch (e) {
      print('❌ Error calculating PO totals from backend: $e');
    }
  }

  // MARK: - Add/Update Item Method
  // MARK: - Add/Update Item Method
  Future<void> _addOrUpdateItem(PurchaseOrderNotifier notifier) async {
    if (!_formKey.currentState!.validate()) return;
    if (notifier.itemController.text.isEmpty) return;

    _loadingNotifier.value = true;

    try {
      final double count =
          double.tryParse(_fieldControllers['count']!.text) ?? 0;
      final double eachQty =
          double.tryParse(_fieldControllers['eachQuantity']!.text) ?? 0;
      final double newPrice =
          double.tryParse(_fieldControllers['newPrice']!.text) ?? 0;
      final double befTaxDiscount =
          double.tryParse(_fieldControllers['befTaxDiscount']!.text) ?? 0;
      final double afTaxDiscount =
          double.tryParse(_fieldControllers['afTaxDiscount']!.text) ?? 0;
      final double taxPercentage =
          double.tryParse(_fieldControllers['taxPercentage']!.text) ?? 0;

      final double totalQuantity = count * eachQty;
      final double baseAmount = totalQuantity * newPrice;

      // ✅ VALIDATION 1: Basic checks
      if (count <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Count must be greater than 0')));
        return;
      }

      if (eachQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity must be greater than 0')),
        );
        return;
      }

      if (newPrice <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Price must be greater than 0')));
        return;
      }

      // ✅ VALIDATION 2: Discount validation
      final bool isAmountMode =
          notifier.itemWiseDiscountMode == DiscountMode.fixedAmount;

      if (isAmountMode) {
        // Amount mode validation
        if (befTaxDiscount > baseAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Before-tax discount cannot exceed base amount'),
            ),
          );
          return;
        }

        double afterBefTax = baseAmount - befTaxDiscount;
        double taxAmount = afterBefTax * (taxPercentage / 100);
        double priceAfterTax = afterBefTax + taxAmount;

        if (afTaxDiscount > priceAfterTax) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('After-tax discount cannot exceed price after tax'),
            ),
          );
          return;
        }
      } else {
        // Percentage mode validation
        if (befTaxDiscount > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Before-tax discount cannot exceed 100%')),
          );
          return;
        }

        if (afTaxDiscount > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('After-tax discount cannot exceed 100%')),
          );
          return;
        }
      }

      // ✅ FIX: Prepare parameters differently for Amount vs Percentage mode
      Map<String, dynamic> backendParams = {
        'pendingTotalQuantity': totalQuantity,
        'poQuantity': totalQuantity,
        'newPrice': newPrice,
        'taxPercentage': taxPercentage,
        'taxType': notifier.taxType,
      };

      if (isAmountMode) {
        // ✅ AMOUNT MODE: Send amounts directly
        backendParams['befTaxDiscountAmount'] = befTaxDiscount;
        backendParams['afTaxDiscountAmount'] = afTaxDiscount;
        backendParams['befTaxDiscountType'] = 'amount';
        backendParams['afTaxDiscountType'] = 'amount';

        // Send 0 for percentages
        backendParams['befTaxDiscount'] = 0.0;
        backendParams['afTaxDiscount'] = 0.0;

        print('🔍 Sending to backend (AMOUNT MODE):');
        print('   befTaxDiscountAmount: $befTaxDiscount');
        print('   afTaxDiscountAmount: $afTaxDiscount');
      } else {
        // ✅ PERCENTAGE MODE: Send percentages
        backendParams['befTaxDiscount'] = befTaxDiscount;
        backendParams['afTaxDiscount'] = afTaxDiscount;
        backendParams['befTaxDiscountType'] = 'percentage';
        backendParams['afTaxDiscountType'] = 'percentage';

        // Send 0 for amounts
        backendParams['befTaxDiscountAmount'] = 0.0;
        backendParams['afTaxDiscountAmount'] = 0.0;

        print('🔍 Sending to backend (PERCENTAGE MODE):');
        print('   befTaxDiscount: $befTaxDiscount%');
        print('   afTaxDiscount: $afTaxDiscount%');
      }

      // Call backend API for calculation
      final poProvider = Provider.of<POProvider>(context, listen: false);
      final result = await poProvider.calculateItemTotalsBackend(
        pendingTotalQuantity: totalQuantity,
        poQuantity: totalQuantity,
        newPrice: newPrice,
        befTaxDiscount: isAmountMode
            ? 0.0
            : befTaxDiscount, // Send 0 for amount mode
        afTaxDiscount: isAmountMode
            ? 0.0
            : afTaxDiscount, // Send 0 for amount mode
        befTaxDiscountAmount: isAmountMode
            ? befTaxDiscount
            : 0.0, // Send amount for amount mode
        afTaxDiscountAmount: isAmountMode
            ? afTaxDiscount
            : 0.0, // Send amount for amount mode
        befTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        afTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        taxPercentage: taxPercentage,
        taxType: notifier.taxType,
      );

      // Check if result has error
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['error'])));
        return; // Don't proceed
      }

      // Get the selected purchase item from purchaseItems list
      final String selectedItemName = notifier.itemController.text;
      final PurchaseItem? selectedPurchaseItem = notifier.purchaseItems
          .firstWhere(
            (item) => item.itemName == selectedItemName,
            orElse: () => PurchaseItem(
              itemName: '',
              purchasePrice: 0,
              purchasetaxName: 0,
              uom: '',
              purchaseItemId: '',
              purchasecategoryName: '',
              purchasesubcategoryName: '',
              hsnCode: '',
            ),
          );

      // ✅ FIX: Correctly store discount values based on mode
      double finalBefTaxDiscount = isAmountMode
          ? befTaxDiscount
          : befTaxDiscount;
      double finalAfTaxDiscount = isAmountMode ? afTaxDiscount : afTaxDiscount;

      // For amount mode, store the amount, but we still need a percentage for display
      double befTaxPercentageForDisplay = 0.0;
      double afTaxPercentageForDisplay = 0.0;

      if (isAmountMode && baseAmount > 0) {
        // Calculate percentages for display
        befTaxPercentageForDisplay = (befTaxDiscount / baseAmount) * 100;

        double afterBefTax = baseAmount - befTaxDiscount;
        double taxAmount = afterBefTax * (taxPercentage / 100);
        double priceAfterTax = afterBefTax + taxAmount;

        if (priceAfterTax > 0) {
          afTaxPercentageForDisplay = (afTaxDiscount / priceAfterTax) * 100;
        }
      } else {
        befTaxPercentageForDisplay = befTaxDiscount;
        afTaxPercentageForDisplay = afTaxDiscount;
      }

      // Use the result from backend
      // Use the result from backend
      final Item newItem = Item(
        itemId: selectedPurchaseItem?.purchaseItemId,
        itemName: notifier.itemController.text,
        quantity: totalQuantity,
        existingPrice:
            double.tryParse(_fieldControllers['existingPrice']!.text) ?? 0,
        newPrice: newPrice,
        count: count,
        eachQuantity: eachQty,
        taxPercentage: taxPercentage,
        taxAmount: result['pendingTaxAmount'] ?? 0,

        // ✅ FIX 1: Store the correct percentage for display
        befTaxDiscount: isAmountMode
            ? befTaxPercentageForDisplay
            : befTaxDiscount,
        afTaxDiscount: isAmountMode ? afTaxPercentageForDisplay : afTaxDiscount,

        // ✅ FIX 2: Store the amounts from backend
        befTaxDiscountAmount: result['pendingBefTaxDiscountAmount'] ?? 0,
        afTaxDiscountAmount: result['pendingAfTaxDiscountAmount'] ?? 0,

        // ✅ FIX 3: Store correct discount types
        befTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        afTaxDiscountType: isAmountMode ? 'amount' : 'percentage',

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
        pendingBefTaxDiscountAmount: result['pendingBefTaxDiscountAmount'] ?? 0,
        pendingAfTaxDiscountAmount: result['pendingAfTaxDiscountAmount'] ?? 0,
        pendingTaxAmount: result['pendingTaxAmount'] ?? 0,
        pendingFinalPrice: result['pendingFinalPrice'] ?? 0,
        pendingTotalPrice: result['pendingTotalPrice'] ?? 0,
        pendingDiscountAmount: result['pendingDiscountAmount'] ?? 0,
        pendingCgst: result['pendingCgst'] ?? 0,
        pendingSgst: result['pendingSgst'] ?? 0,
        pendingIgst: result['pendingIgst'] ?? 0,
        expiryDate: '',
        hsnCode: selectedPurchaseItem?.hsnCode,
        purchasecategoryName: selectedPurchaseItem?.purchasecategoryName,
        purchasesubcategoryName: selectedPurchaseItem?.purchasesubcategoryName,
      );

      // ✅ FIX 4: Add debug logs
      print('🔍 DEBUG: Item created with discount values:');
      print(
        '   befTaxDiscount: ${newItem.befTaxDiscount} (${newItem.befTaxDiscountType})',
      );
      print('   befTaxDiscountAmount: ${newItem.befTaxDiscountAmount}');
      print(
        '   afTaxDiscount: ${newItem.afTaxDiscount} (${newItem.afTaxDiscountType})',
      );
      print('   afTaxDiscountAmount: ${newItem.afTaxDiscountAmount}');
      print('   finalPrice: ${newItem.finalPrice}');

      // ✅ CORRECTED: Add debug logs to see what's happening
      print('🔄 Adding item to list: ${newItem.itemName}');
      print('📊 Current items before: ${notifier.poItems.length}');
      print('💰 Discount Details:');
      print('   Mode: ${isAmountMode ? "Amount (₹)" : "Percentage (%)"}');
      print(
        '   Bef Tax: ${isAmountMode ? "₹$befTaxDiscount" : "$befTaxDiscount%"}',
      );
      print(
        '   Af Tax: ${isAmountMode ? "₹$afTaxDiscount" : "$afTaxDiscount%"}',
      );
      print('   Final Price: ₹${result['pendingFinalPrice'] ?? 0}');

      // ✅ SIMPLE AND CORRECT LOGIC:
      if (widget.editingIndex != null) {
        // Editing existing item
        notifier.poItems[widget.editingIndex!] = newItem;
        print('✏️ Updated item at index: ${widget.editingIndex}');
      } else {
        // Adding new item
        notifier.poItems.add(newItem);
        print('➕ Added new item');
      }

      print('📊 Current items after: ${notifier.poItems.length}');

      // ✅ CRITICAL: Notify listeners to update UI
      notifier.notifyListeners();

      // ✅ Calculate total PO amount from backend
      await _calculatePOTotalsFromBackend(notifier);

      // ✅ FORCE DIALOG CLOSE
      print('✅ Item added successfully, closing dialog...');
      if (mounted) {
        widget.onItemAdded(); // This should trigger parent to refresh
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error in _addOrUpdateItem: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      _loadingNotifier.value = false;
    }
  }
}
