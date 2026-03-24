import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/widgets/create%20po/ItemAutocomplete.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';
import '../../models/discount_model.dart';
import '../../models/po_item.dart';
import '../../models/vendorpurchasemodel.dart';

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
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  final Map<String, TextEditingController> _fieldControllers = {};

  final ValueNotifier<bool> _isBefTaxEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isAfTaxEnabled = ValueNotifier(true);
  final FocusNode _eachQtyFocusNode = FocusNode();
  final ValueNotifier<bool> _isEachQtyFocused = ValueNotifier(false);
  ValueNotifier<List<String>> _filteredItemOptions = ValueNotifier([]);

  bool _itemsPreloaded = false;

  @override
  void initState() {
    super.initState();

    _initializeControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final poProvider = Provider.of<POProvider>(context, listen: false);

      if (!_itemsPreloaded) {
        await poProvider.preloadAllPurchaseItems();
        _itemsPreloaded = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _poNotifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
  }

  @override
  void dispose() {
    _poNotifier.isOverallDisabledFromItem = false;

    _itemWiseDiscountMode.dispose();
    _refreshTrigger.dispose();
    _loadingNotifier.dispose();
    _isBefTaxEnabled.dispose();
    _isAfTaxEnabled.dispose();
    _eachQtyFocusNode.dispose();
    _isEachQtyFocused.dispose();

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
    setState(() {});
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

    final double befTaxDiscount = item.befTaxDiscount ?? 0.0;
    final double afTaxDiscount = item.afTaxDiscount ?? 0.0;

    _fieldControllers['befTaxDiscount']!.text = befTaxDiscount.toStringAsFixed(
      2,
    );
    _fieldControllers['afTaxDiscount']!.text = afTaxDiscount.toStringAsFixed(2);

    notifier.itemController.text = item.itemName ?? '';
    notifier.uomController.text = item.uom ?? '';

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
    } else {
      _itemWiseDiscountMode.value = 'Percentage ( % )';
      notifier.itemWiseDiscountMode = DiscountMode.percentage;
    }

    _updateTotalQuantity(notifier);
    _updateVariance(notifier);

    final poNotifier = Provider.of<PurchaseOrderNotifier>(
      context,
      listen: false,
    );

    if (befTaxDiscount > 0 || afTaxDiscount > 0) {
      poNotifier.isOverallDisabledFromItem = true;
      poNotifier.isOverallDiscountActive = false;

      if (befTaxDiscount > 0) {
        _isBefTaxEnabled.value = true;
        _isAfTaxEnabled.value = false;
      }

      if (afTaxDiscount > 0) {
        _isAfTaxEnabled.value = true;
        _isBefTaxEnabled.value = false;
      }
    } else {
      _isBefTaxEnabled.value = true;
      _isAfTaxEnabled.value = true;
    }
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
          color: Color.fromARGB(255, 74, 122, 227),
          width: 2.0,
        ),
      ),

      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),

      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade300 : Colors.white,

      suffixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 40),

      errorStyle: TextStyle(fontSize: 12, color: Colors.red.shade700),
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
                          twoCol(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<POProvider>(
                                  builder: (context, poProvider, child) {
                                    return ItemAutocomplete(
                                      controller: notifier.itemController,
                                      notifier: notifier,
                                      poProvider: poProvider,
                                      onItemSelected: (selectedItemName) {
                                        if (selectedItemName.isEmpty) {
                                          _clearItemDetails();
                                          notifier.setSelectedItem('');
                                          return;
                                        }

                                        notifier.setSelectedItem(
                                          selectedItemName,
                                        );
                                        _updateItemDetails(notifier);
                                      },
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
                            TextFormField(
                              controller: _fieldControllers['count'],
                              readOnly: true,
                              decoration: _buildFieldDecoration("Pkt Count *"),
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
                              onTap: () {
                                _openNumericCalculator(
                                  title: "pkt Count",
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
                                  decoration: _buildFieldDecoration(
                                    isFocused
                                        ? "Qty (Kg/Pcs/Nos) *"
                                        : "Quantity *",
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
                            TextFormField(
                              controller: _fieldControllers['newPrice'],
                              readOnly: true,
                              decoration: _buildFieldDecoration("Price *"),
                              style: TextStyle(fontSize: isMobile ? 14 : 14),
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
                                  decoration: _buildFieldDecoration(
                                    "Before Tax Discount",
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 14,
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
                                  decoration: _buildFieldDecoration(
                                    "After Tax Discount",
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 14,
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
    } catch (e) {}
  }

  Future<void> _addOrUpdateItem(PurchaseOrderNotifier notifier) async {
    print("=========== ADD / UPDATE ITEM START ===========");

    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");
      return;
    }

    if (notifier.itemController.text.isEmpty) {
      print("Item name is empty");
      return;
    }

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

      print("User Inputs:");
      print("Count: $count");
      print("Each Quantity: $eachQty");
      print("New Price: $newPrice");
      print("Before Tax Discount: $befTaxDiscount");
      print("After Tax Discount: $afTaxDiscount");
      print("Tax Percentage: $taxPercentage");

      final double totalQuantity = count * eachQty;
      final double baseAmount = totalQuantity * newPrice;

      print("Calculated totalQuantity: $totalQuantity");
      print("Calculated baseAmount: $baseAmount");

      if (count <= 0) {
        print("Invalid count");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Count must be greater than 0')));
        return;
      }

      if (eachQty <= 0) {
        print("Invalid quantity");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity must be greater than 0')),
        );
        return;
      }

      if (newPrice <= 0) {
        print("Invalid price");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Price must be greater than 0')));
        return;
      }

      final bool isAmountMode =
          notifier.itemWiseDiscountMode == DiscountMode.fixedAmount;

      print("Discount Mode: ${isAmountMode ? "Amount" : "Percentage"}");

      if (isAmountMode) {
        if (befTaxDiscount > baseAmount) {
          print("Before tax discount exceeds base amount");
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

        print("After Bef Tax Price: $afterBefTax");
        print("Tax Amount: $taxAmount");
        print("Price After Tax: $priceAfterTax");

        if (afTaxDiscount > priceAfterTax) {
          print("After tax discount exceeds price after tax");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('After-tax discount cannot exceed price after tax'),
            ),
          );
          return;
        }
      } else {
        if (befTaxDiscount > 100) {
          print("Before tax discount > 100%");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Before-tax discount cannot exceed 100%')),
          );
          return;
        }

        if (afTaxDiscount > 100) {
          print("After tax discount > 100%");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('After-tax discount cannot exceed 100%')),
          );
          return;
        }
      }

      print("Preparing backend parameters...");

      Map<String, dynamic> backendParams = {
        'pendingTotalQuantity': totalQuantity,
        'poQuantity': totalQuantity,
        'newPrice': newPrice,
        'taxPercentage': taxPercentage,
        'taxType': notifier.taxType,
      };

      print("Backend Params: $backendParams");

      final poProvider = Provider.of<POProvider>(context, listen: false);

      print("Calling backend API calculateItemTotalsBackend...");

      final result = await poProvider.calculateItemTotalsBackend(
        pendingTotalQuantity: totalQuantity,
        poQuantity: widget.editingItem?.poQuantity ?? totalQuantity,
        newPrice: newPrice,
        befTaxDiscount: isAmountMode ? 0.0 : befTaxDiscount,
        afTaxDiscount: isAmountMode ? 0.0 : afTaxDiscount,
        befTaxDiscountAmount: isAmountMode ? befTaxDiscount : 0.0,
        afTaxDiscountAmount: isAmountMode ? afTaxDiscount : 0.0,
        befTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        afTaxDiscountType: isAmountMode ? 'amount' : 'percentage',
        taxPercentage: taxPercentage,
        taxType: notifier.taxType,
      );

      print("Backend Result: $result");

      if (result.containsKey('error')) {
        print("Backend returned error: ${result['error']}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['error'])));
        return;
      }

      final String selectedItemName = notifier.itemController.text;

      print("Selected Item Name: $selectedItemName");

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

      print("Selected Purchase Item: ${selectedPurchaseItem?.purchaseItemId}");

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
        befTaxDiscount: befTaxDiscount,
        afTaxDiscount: afTaxDiscount,
        befTaxDiscountAmount: result['pendingBefTaxDiscountAmount'] ?? 0,
        afTaxDiscountAmount: result['pendingAfTaxDiscountAmount'] ?? 0,
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
        hsnCode: selectedPurchaseItem?.hsnCode,
        purchasecategoryName: selectedPurchaseItem?.purchasecategoryName,
        purchasesubcategoryName: selectedPurchaseItem?.purchasesubcategoryName,
        randomId:
            widget.editingItem?.randomId ??
            "${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}",
      );

      print("Created new item:");
      print(newItem);

      if (widget.editingIndex != null) {
        final oldItem = notifier.poItems[widget.editingIndex!];

        newItem.randomId = oldItem.randomId; // 🔥 KEEP SAME ID

        notifier.poItems[widget.editingIndex!] = newItem;
      } else {
        final existingIndex = notifier.poItems.indexWhere(
          (item) => item.randomId == newItem.randomId,
        );
        if (existingIndex != -1) {
          print("Item already exists → merging quantities");

          final existingItem = notifier.poItems[existingIndex];

          existingItem.count = (existingItem.count ?? 0) + (newItem.count ?? 0);

          existingItem.pendingTotalQuantity =
              (existingItem.pendingTotalQuantity ?? 0) +
              (newItem.pendingTotalQuantity ?? 0);

          notifier.poItems[existingIndex] = existingItem;
        } else {
          print("Adding new item to PO list");
          notifier.poItems.add(newItem);
        }
      }

      notifier.notifyListeners();

      print("Recalculating PO totals from backend...");

      await _calculatePOTotalsFromBackend(notifier);

      print("=========== ITEM ADDED SUCCESSFULLY ===========");

      if (mounted) {
        widget.onItemAdded();
        Navigator.of(context).pop();

        notifier.itemController.clear();
        notifier.uomController.clear();

        _clearItemDetails();
      }
    } catch (e) {
      print("ERROR in addOrUpdateItem: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      _loadingNotifier.value = false;
      print("=========== ADD / UPDATE ITEM END ===========");
    }
  }
}
