import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po_item.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/widgets/create%20po/purchase_order_logic.dart';
import 'package:purchaseorders2/widgets/numeric_Calculator.dart';
import '../../models/discount_model.dart';

class DiscountSection extends StatefulWidget {
  final ValueNotifier<DiscountMode> discountMode;
  final TextEditingController overallDiscountController;
  final TextEditingController roundOffController;
  final double subtotal;
  final double itemWiseDiscount;
  final VoidCallback onCalculationsUpdate;
  final Future<void> Function() onApplyDiscount;
  final List<dynamic> poItems;
  final PurchaseOrderNotifier notifier;
  final PurchaseOrderLogic logic;

  const DiscountSection({
    super.key,
    required this.discountMode,
    required this.overallDiscountController,
    required this.roundOffController,
    required this.subtotal,
    required this.itemWiseDiscount,
    required this.onCalculationsUpdate,
    required this.onApplyDiscount,
    required this.poItems,
    required this.notifier,
    required this.logic,
  });

  @override
  State<DiscountSection> createState() => _DiscountSectionState();
}

class _DiscountSectionState extends State<DiscountSection> {
  final ValueNotifier<bool> _showInlineAlert = ValueNotifier(false);
  // bool _overallAppliedOnce = false;
  bool _isApplying = false;

  double get totalCGST {
    return widget.poItems.fold(
      0.0,
      (sum, item) => sum + (_getItemProperty(item, 'pendingCgst') ?? 0.0),
    );
  }

  double get totalSGST {
    return widget.poItems.fold(
      0.0,
      (sum, item) => sum + (_getItemProperty(item, 'pendingSgst') ?? 0.0),
    );
  }

  double get totalIGST {
    return widget.poItems.fold(
      0.0,
      (sum, item) => sum + (_getItemProperty(item, 'pendingIgst') ?? 0.0),
    );
  }

  double get overallDiscountAmount {
    return widget.notifier.overallDiscountAmount ?? 0.0;
  }

  // ✅ Update finalAmount calculation
  double get finalAmount {
    final roundOff = double.tryParse(widget.roundOffController.text) ?? 0.0;

    // Use notifier's calculated values instead of recalculating
    return (widget.notifier.calculatedFinalAmount ?? 0.0) + roundOff;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromNotifier();
    });
  }

  void _syncControllersFromNotifier() {
    final notifier = widget.notifier;

    // ✅ Overall discount value
    widget.overallDiscountController.text =
        (notifier.overallDiscountValue ?? 0.0).toStringAsFixed(2);

    if ((notifier.overallDiscountValue ?? 0) > 0) {
      widget.discountMode.value = DiscountMode.percentage;
    } else {
      widget.discountMode.value = DiscountMode.none;
    }
  }

  void _clearAllDiscounts() {
    print('🎯 Clearing ALL discounts (overall + item-wise)');

    final notifier = widget.notifier;

    widget.overallDiscountController.text = '0';
    widget.discountMode.value = DiscountMode.none;
    notifier.isOverallDiscountActive = false;
    notifier.isOverallDisabledFromItem = false;
    notifier.befTaxDiscountController.text = '0';
    notifier.afTaxDiscountController.text = '0';
    for (var item in widget.poItems) {
      try {
        if (item is Map<String, dynamic>) {
          item['befTaxDiscount'] = 0.0;
          item['befTaxDiscountAmount'] = 0.0;
          item['afTaxDiscount'] = 0.0;
          item['afTaxDiscountAmount'] = 0.0;
          item['pendingAfTaxDiscountAmount'] = 0.0;
          // item['itemOverallDiscountAmount'] = 0.0; // ❌ REMOVE - doesn't exist
          item['pendingDiscountAmount'] = 0.0;
          final quantity = item['quantity'] ?? 0.0;
          final newPrice = item['newPrice'] ?? 0.0;
          final taxPercentage = item['taxPercentage'] ?? 0.0;

          final baseAmount = quantity * newPrice;
          final taxAmount = baseAmount * (taxPercentage / 100);
          final finalPrice = baseAmount + taxAmount;

          item['finalPrice'] = finalPrice;
          item['pendingFinalPrice'] = finalPrice;
          item['taxAmount'] = taxAmount;
          item['pendingTaxAmount'] = taxAmount;
          item['totalPrice'] = baseAmount;
          item['pendingTotalPrice'] = baseAmount;
        } else if (item is Item) {
          item.befTaxDiscount = 0.0;
          item.befTaxDiscountAmount = 0.0;
          item.afTaxDiscount = 0.0;
          item.afTaxDiscountAmount = 0.0;
          item.pendingAfTaxDiscountAmount = 0.0;
          // item.itemOverallDiscountAmount = 0.0; // ❌ REMOVE - doesn't exist
          item.pendingDiscountAmount = 0.0;
          final quantity = item.quantity ?? 0.0;
          final newPrice = item.newPrice ?? 0.0;
          final taxPercentage = item.taxPercentage ?? 0.0;
          final baseAmount = quantity * newPrice;
          final taxAmount = baseAmount * (taxPercentage / 100);
          final finalPrice = baseAmount + taxAmount;
          item.finalPrice = finalPrice;
          item.pendingFinalPrice = finalPrice;
          item.taxAmount = taxAmount;
          item.pendingTaxAmount = taxAmount;
          item.totalPrice = baseAmount;
          item.pendingTotalPrice = baseAmount;
        }
      } catch (e) {
        print('⚠️ Error clearing discount for item: $e');
      }
    }

    notifier.overallDiscountAmount = 0.0;
    notifier.overallDiscountValue = 0.0;
    notifier.itemWiseDiscount = 0.0;

    _recalculateTotalsAfterDiscountClear();

    notifier.notifyListeners();
    widget.onCalculationsUpdate();

    print('✅ All discounts cleared, prices reset to original');
  }

  void _openNumericKeyboard({
    required String title,
    required TextEditingController controller,
  }) {
    showDialog(
      context: context,
      builder: (context) => NumericCalculator(
        varianceName: title,
        controller: controller,
        initialValue: double.tryParse(controller.text) ?? 0.0,
        onValueSelected: (value) {
          controller.text = value.toStringAsFixed(2);

          widget.logic.validateRoundOff();
          widget.notifier.calculateTotals();
          widget.onCalculationsUpdate();
        },
      ),
    );
  }

  void _clearAllItemDiscounts(dynamic item) {
    try {
      if (item is Map<String, dynamic>) {
        item['befTaxDiscount'] = 0.0;
        item['befTaxDiscountAmount'] = 0.0;
        item['afTaxDiscount'] = 0.0;
        item['afTaxDiscountAmount'] = 0.0;
        item['pendingAfTaxDiscountAmount'] = 0.0;
        // item['itemOverallDiscountAmount'] = 0.0;
        item['pendingDiscountAmount'] = 0.0;
      } else if (item is Item) {
        // ✅ ONLY EXISTING PROPERTIES
        item.befTaxDiscount = 0.0;
        item.befTaxDiscountAmount = 0.0;
        item.afTaxDiscount = 0.0;
        item.afTaxDiscountAmount = 0.0;
        item.pendingAfTaxDiscountAmount = 0.0;
        // item.itemOverallDiscountAmount = 0.0;
        item.pendingDiscountAmount = 0.0;
      }
    } catch (_) {}
  }

  void _clearAllItemProperties(dynamic object) {
    try {
      if (object is Item) {
        object.befTaxDiscount = 0.0;
        object.befTaxDiscountAmount = 0.0;
        object.afTaxDiscount = 0.0;
        object.afTaxDiscountAmount = 0.0;
        object.pendingAfTaxDiscountAmount = 0.0;
        // object.itemOverallDiscountAmount = 0.0;
        object.pendingDiscountAmount = 0.0;
      } else if (object is Map<String, dynamic>) {
        object['befTaxDiscount'] = 0.0;
        object['befTaxDiscountAmount'] = 0.0;
        object['afTaxDiscount'] = 0.0;
        object['afTaxDiscountAmount'] = 0.0;
        object['pendingAfTaxDiscountAmount'] = 0.0;
        // object['itemOverallDiscountAmount'] = 0.0;
        object['pendingDiscountAmount'] = 0.0;
      }
    } catch (_) {}
  }

  void _clearItemWiseDiscountFields() {
    widget.notifier.befTaxDiscountController.text = '0';
    widget.notifier.afTaxDiscountController.text = '0';
    widget.notifier.itemWiseDiscountMode = DiscountMode.percentage;
  }

  void _recalculateTotalsAfterDiscountClear() {
    double totalSubTotal = 0.0;
    double totalTax = 0.0;
    double totalFinalPrice = 0.0;
    double totalBefTaxDiscount = 0.0;
    double totalAfTaxDiscount = 0.0;

    for (var item in widget.poItems) {
      double price = _getItemProperty(item, 'newPrice') ?? 0.0;
      double qty = _getItemProperty(item, 'quantity') ?? 0.0;
      double base = price * qty;

      double taxPercentage = _getItemProperty(item, 'taxPercentage') ?? 0.0;
      double taxAmount = base * (taxPercentage / 100);

      double befTaxDiscountAmount =
          _getItemProperty(item, 'befTaxDiscountAmount') ?? 0.0;
      double afTaxDiscountAmount =
          _getItemProperty(item, 'afTaxDiscountAmount') ?? 0.0;

      double finalPrice =
          base + taxAmount - befTaxDiscountAmount - afTaxDiscountAmount;

      _setItemProperty(item, 'finalPrice', finalPrice);
      _setItemProperty(item, 'pendingFinalPrice', finalPrice);
      _setItemProperty(item, 'taxAmount', taxAmount);
      _setItemProperty(item, 'pendingTaxAmount', taxAmount);
      _setItemProperty(item, 'totalPrice', base);
      _setItemProperty(item, 'pendingTotalPrice', base);
      _setItemProperty(item, 'befTaxDiscountAmount', befTaxDiscountAmount);
      _setItemProperty(item, 'afTaxDiscountAmount', afTaxDiscountAmount);

      totalSubTotal += base;
      totalTax += taxAmount;
      totalFinalPrice += finalPrice;
      totalBefTaxDiscount += befTaxDiscountAmount;
      totalAfTaxDiscount += afTaxDiscountAmount;
    }

    widget.notifier.subTotal = totalSubTotal;
    widget.notifier.itemWiseDiscount = totalBefTaxDiscount;
    widget.notifier.overallDiscountAmount = totalAfTaxDiscount;

    double roundOff = double.tryParse(widget.roundOffController.text) ?? 0.0;

    double calculatedFinal =
        totalSubTotal +
        totalTax -
        (totalBefTaxDiscount + totalAfTaxDiscount) +
        roundOff;

    widget.notifier.calculatedFinalAmount = calculatedFinal;
    widget.notifier.totalOrderAmount = calculatedFinal;

    widget.notifier.pendingOrderAmount = calculatedFinal;
    widget.notifier.pendingTaxAmount = totalTax;
    widget.notifier.pendingDiscountAmount =
        totalBefTaxDiscount + totalAfTaxDiscount;

    print('📊 Recalculated after discount clear:');
    print('   Subtotal: $totalSubTotal');
    print('   Tax: $totalTax');
    print('   Bef Tax Discount: $totalBefTaxDiscount');
    print('   Af Tax Discount: $totalAfTaxDiscount');
    print('   Final: $calculatedFinal');
    print('   Round Off: $roundOff');
  }

  void _debugItemPrices() {
    print('🔍 DEBUG - Item Prices after discount clear:');
    for (var i = 0; i < widget.poItems.length; i++) {
      var item = widget.poItems[i];
      String name = _getItemProperty(item, 'itemName') ?? 'Item $i';
      double price = _getItemProperty(item, 'newPrice') ?? 0.0;
      double qty = _getItemProperty(item, 'quantity') ?? 0.0;
      double base = price * qty;
      double finalPrice = _getItemProperty(item, 'finalPrice') ?? 0.0;

      print('   $name: Price=$price, Qty=$qty, Base=$base, Final=$finalPrice');
    }
  }

  dynamic _getItemProperty(dynamic item, String propertyName) {
    try {
      if (item is Map<String, dynamic>) return item[propertyName];
      return _getPropertyValue(item, propertyName);
    } catch (_) {
      return null;
    }
  }

  dynamic _getPropertyValue(dynamic object, String name) {
    try {
      switch (name) {
        case 'newPrice':
          return object.newPrice;
        case 'quantity':
          return object.quantity;
        case 'befTaxDiscount':
          return object.befTaxDiscount;
        case 'taxPercentage':
          return object.taxPercentage;
        case 'pendingCount':
          return object.pendingCount;
        case 'pendingQuantity':
          return object.pendingQuantity;
        case 'pendingTotalQuantity':
          return object.pendingTotalQuantity;
        case 'pendingFinalPrice':
          return object.pendingFinalPrice;

        case 'pendingCgst':
          return object.pendingCgst;
        case 'pendingSgst':
          return object.pendingSgst;
        case 'pendingIgst':
          return object.pendingIgst;

        case 'finalPrice':
          return object.finalPrice;
        case 'taxAmount':
          return object.taxAmount;
        case 'totalPrice':
          return object.totalPrice;
        case 'befTaxDiscountAmount':
          return object.befTaxDiscountAmount;
        case 'afTaxDiscountAmount':
          return object.afTaxDiscountAmount;
        case 'discountAmount':
          return object.discountAmount;
        case 'pendingDiscountAmount':
          return object.pendingDiscountAmount;
        default:
          print('! Unknown property in _getPropertyValue: $name');
          return null;
      }
    } catch (_) {
      print('! Error getting property $name');
      return null;
    }
  }

  void _setItemProperty(dynamic item, String propertyName, dynamic value) {
    try {
      if (item is Map<String, dynamic>) {
        item[propertyName] = value;
        return;
      }

      switch (propertyName) {
        case 'finalPrice':
          item.finalPrice = value;
          break;
        case 'taxAmount':
          item.taxAmount = value;
          break;
        case 'totalPrice':
          item.totalPrice = value;
          break;
        case 'befTaxDiscountAmount':
          item.befTaxDiscountAmount = value;
          break;
        case 'afTaxDiscountAmount':
          item.afTaxDiscountAmount = value;
          break;
      }
    } catch (_) {}
  }

  double get actualItemWiseDiscount {
    double total = 0.0;
    for (var item in widget.poItems) {
      total += _getItemProperty(item, 'befTaxDiscountAmount') ?? 0.0;
      if (widget.discountMode.value == DiscountMode.none) {
        total += _getItemProperty(item, 'afTaxDiscountAmount') ?? 0.0;
      }
    }
    return total;
  }

  // double get overallDiscountAmount {
  //   if (widget.discountMode.value == DiscountMode.none) return 0.0;
  //   double total = 0.0;
  //   for (var item in widget.poItems) {
  //     total += _getItemProperty(item, 'afTaxDiscountAmount') ?? 0.0;
  //   }
  //   return total;
  // }

  double get totalTaxAmount {
    return widget.poItems.fold(
      0.0,
      (sum, item) => sum + (_getItemProperty(item, 'taxAmount') ?? 0.0),
    );
  }

  // double get finalAmount {
  //   final roundOff = double.tryParse(widget.roundOffController.text) ?? 0.0;
  //   return (widget.subtotal -
  //           (actualItemWiseDiscount + overallDiscountAmount) +
  //           totalTaxAmount +
  //           roundOff)
  //       .clamp(0, double.infinity);
  // }

  Future<void> _handleApplyDiscount() async {
    if (_isApplying) return;

    final mode = widget.discountMode.value;
    final discountText = widget.overallDiscountController.text.trim();
    final discountValue = double.tryParse(discountText) ?? 0.0;

    // ❌ Overall disabled
    if (mode == DiscountMode.none) {
      _showSnack('Enable overall discount to apply', Colors.blue);
      return;
    }

    // ❌ Empty / invalid
    if (discountValue <= 0) {
      _showSnack('Please enter a valid discount value', Colors.blue);
      return;
    }

    // ❌ No items
    if (widget.poItems.isEmpty) {
      _showSnack('Please add at least one item to apply discount', Colors.red);
      return;
    }

    // 🟡 ALREADY APPLIED CHECK
    final alreadyApplied = (widget.notifier.overallDiscountAmount ?? 0) > 0;

    if (alreadyApplied) {
      _showSnack('Discount already applied', Colors.orange);
      return;
    }

    _isApplying = true;

    try {
      await widget.onApplyDiscount();

      widget.onCalculationsUpdate();

      _showSnack('Discount applied successfully', Colors.green);
    } catch (e) {
      _showSnack('Failed to apply discount', Colors.red);
    } finally {
      _isApplying = false;
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 85, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),

          ValueListenableBuilder<bool>(
            valueListenable: _showInlineAlert,
            builder: (_, show, __) {
              if (!show) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Row(
                  children: const [
                    Icon(Icons.info, size: 14, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      "Overall discount enabled",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          _buildDiscountModeToggle(),
          const SizedBox(height: 16),
          _buildCompactInputRow(),
          const SizedBox(height: 16),
          _buildPricingSummary(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        const Text(
          'Overall Discount :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            ValueListenableBuilder<DiscountMode>(
              valueListenable: widget.discountMode,
              builder: (_, mode, __) {
                final isEnabled = mode != DiscountMode.none;
                return Switch(
                  value: isEnabled,
                  onChanged: widget.notifier.isOverallDisabledFromItem == true
                      ? null
                      : (val) {
                          if (val) {
                            widget.discountMode.value = DiscountMode.percentage;
                            _showInlineAlert.value = true;
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted) {
                                _showInlineAlert.value = false;
                              }
                            });
                          } else {
                            widget.discountMode.value = DiscountMode.none;
                            widget.overallDiscountController.text = "0";
                            _showInlineAlert.value = false;
                          }

                          widget.onCalculationsUpdate();
                        },

                  activeThumbColor: Colors.blue,
                );
              },
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: _clearAllDiscounts,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Clear",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountModeToggle() {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<DiscountMode>(
            valueListenable: widget.discountMode,
            builder: (_, mode, __) {
              return Row(
                children: [
                  Expanded(
                    child: _optionButton(
                      label: "Percentage",
                      icon: Icons.percent,
                      selected: mode == DiscountMode.percentage,
                      enabled: mode != DiscountMode.none,
                      onTap: () {
                        if (mode != DiscountMode.none) {
                          widget.discountMode.value = DiscountMode.percentage;
                          widget.onCalculationsUpdate();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _optionButton(
                      label: "Rupees",
                      icon: Icons.currency_rupee,
                      selected: mode == DiscountMode.fixedAmount,
                      enabled: mode != DiscountMode.none,
                      onTap: () {
                        if (mode != DiscountMode.none) {
                          widget.discountMode.value = DiscountMode.fixedAmount;
                          widget.onCalculationsUpdate();
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _optionButton({
    required String label,
    required IconData icon,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? (selected ? Colors.blue : Colors.grey.shade400)
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          color: selected ? Colors.blue.shade50 : Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected ? Colors.blue : Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInputRow() {
    return ValueListenableBuilder<DiscountMode>(
      valueListenable: widget.discountMode,
      builder: (_, mode, __) {
        String actualDiscountType = 'percentage';
        if (widget.poItems.isNotEmpty) {
          final firstItem = widget.poItems.first;
          if (firstItem is Item) {
            actualDiscountType = firstItem.afTaxDiscountType ?? 'percentage';
          }
        }

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  if (mode != DiscountMode.none) {
                    _openNumericKeyboard(
                      title: mode == DiscountMode.percentage
                          ? "Discount Percentage"
                          : "Discount Amount",
                      controller: widget.overallDiscountController,
                    );
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: widget.overallDiscountController,
                    decoration: InputDecoration(
                      labelText: mode == DiscountMode.none
                          ? "Discount (Disabled)"
                          : mode == DiscountMode.percentage
                          ? "Percentage"
                          : "Amount",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      suffixText: mode == DiscountMode.percentage ? "%" : "₹",
                      enabled: mode != DiscountMode.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<String?>(
                valueListenable: widget.logic.roundOffErrorNotifier,
                builder: (context, error, _) {
                  final hasError = error != null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _openNumericKeyboard(
                            title: "Round Off",
                            controller: widget.roundOffController,
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: widget.roundOffController,
                            decoration: InputDecoration(
                              labelText: "Round Off",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              prefixText: "₹ ",
                              contentPadding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                6,
                              ),
                              errorStyle: const TextStyle(
                                fontSize: 11,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            error,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isApplying ? null : _handleApplyDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          "Apply",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricingSummary() {
    final parsedRoundOff =
        double.tryParse(widget.roundOffController.text) ?? 0.0;
    double itemWise = widget.notifier.itemWiseDiscount ?? 0.0;
    double overall = widget.notifier.overallDiscountAmount ?? 0.0;
    double totalDisc = itemWise + overall;
    double subtotal = widget.notifier.subTotal ?? 0.0;
    double totalTax = widget.notifier.pendingTaxAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _summary("Sub Total", _fmt(subtotal)),

          if (totalTax > 0) _summary("Total Tax", "(+) ${_fmt(totalTax)}"),

          if (itemWise > 0)
            _summary("Item-wise Discount", "(-) ${_fmt(itemWise)}"),

          if (overall > 0) _summary("Overall Discount", "(-) ${_fmt(overall)}"),

          const Divider(),

          _summary("Total Discount", "(-) ${_fmt(totalDisc)}"),

          _summary(
            "Round Off / Adjustment",
            parsedRoundOff >= 0
                ? "(+) ${_fmt(parsedRoundOff)}"
                : "(-) ${_fmt(parsedRoundOff.abs())}",
          ),
          const Divider(thickness: 1.5),

          _summary(
            "FINAL AMOUNT",
            _fmt(widget.notifier.totalOrderAmount ?? 0.0),
            bold: true,
            color: Colors.green.shade700,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _showInlineAlert.dispose();
    super.dispose();
  }

  String _fmt(double amt) => "₹${amt.toStringAsFixed(2)}";

  Widget _summary(
    String label,
    String value, {
    bool bold = false,
    Color? color,
    double size = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: size,
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
