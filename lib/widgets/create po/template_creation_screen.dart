// ignore_for_file: use_build_context_synchronously, unused_local_variable, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:purchaseorders2/calculation/purchase_order_calculations.dart';
import 'package:purchaseorders2/models/discount_model.dart';
import 'package:purchaseorders2/models/po.dart';
import 'package:purchaseorders2/models/po_template.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/widgets/create%20po/add_item_dialog.dart';
import 'package:purchaseorders2/widgets/create%20po/address_fields.dart';
import 'package:purchaseorders2/widgets/create%20po/discount_section.dart';
import 'package:purchaseorders2/widgets/create%20po/items_table.dart';
import 'package:purchaseorders2/widgets/create%20po/purchase_order_logic.dart';
import 'package:purchaseorders2/widgets/create%20po/vendor_autocomplete.dart';
import 'package:purchaseorders2/widgets/keyboard_dismisser.dart';

class TemplateCreationScreen extends StatefulWidget {
  final PO? editingPO;
  final POTemplate? editingTemplate;

  const TemplateCreationScreen({
    super.key,
    this.editingPO,
    this.editingTemplate,
  });

  @override
  _TemplateCreationScreenState createState() => _TemplateCreationScreenState();
}

class _TemplateCreationScreenState extends State<TemplateCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ValueNotifier<bool> _refreshUI = ValueNotifier(false);
  bool _isDisposed = false;

  late PurchaseOrderNotifier notifier;
  late POProvider poProvider;
  late TemplateProvider templateProvider;
  late PurchaseOrderLogic logic;

  final TextEditingController _vendorAutocompleteController =
      TextEditingController();
  final Map<String, DateTime> _lastTapTime = {};
  final Duration _tapThrottleDuration = const Duration(milliseconds: 300);

  final ValueNotifier<double> _totalOrderAmount = ValueNotifier(0.0);
  final ValueNotifier<String> _itemWiseDiscountMode = ValueNotifier(
    'Percentage ( % )',
  );
  final ValueNotifier<DiscountMode> _overallDiscountMode = ValueNotifier(
    DiscountMode.none,
  );

  final GlobalKey _vendorSectionKey = GlobalKey();
  final GlobalKey _billingSectionKey = GlobalKey();
  final GlobalKey _itemsSectionKey = GlobalKey();

  static const Color nonEditableColor = Color(0xFFF5F5F5);
  static const Color editableColor = Colors.white;
  static const Color borderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        logic.initializeData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
    poProvider = Provider.of<POProvider>(context, listen: false);
    templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    logic = PurchaseOrderLogic(
      context: context,
      notifier: notifier,
      poProvider: poProvider,
      templateProvider: templateProvider,
      editingPO: widget.editingPO,
      vendorController: _vendorAutocompleteController,
      totalOrderAmount: _totalOrderAmount,
      overallDiscountMode: _overallDiscountMode,
      itemWiseDiscountMode: _itemWiseDiscountMode,
      refreshUI: _refreshUI,
      formKey: _formKey,
      isDisposed: () => _isDisposed,
    );

    notifier.addListener(_updateTotalOrderAmount);
  }

  void _updateTotalOrderAmount() {
    if (!mounted || _isDisposed) return;
    _totalOrderAmount.value = notifier.calculatedFinalAmount;
    notifier.totalOrderAmount = notifier.calculatedFinalAmount;
  }

  void _triggerUIRefresh() {
    if (!mounted || _isDisposed) return;
    _refreshUI.value = !_refreshUI.value;
  }

  bool _shouldHandleTap(String fieldId) {
    final now = DateTime.now();
    final lastTap = _lastTapTime[fieldId];
    if (lastTap != null && now.difference(lastTap) < _tapThrottleDuration) {
      return false;
    }
    _lastTapTime[fieldId] = now;
    return true;
  }

  InputDecoration _inputDecoration(String label, {bool isEditable = true}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 74, 122, 227),
          width: 2.0,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      isDense: false,
      contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      filled: true,
      fillColor: isEditable ? editableColor : nonEditableColor,
      errorStyle: TextStyle(fontSize: 12, color: Colors.red[700]),
    );
  }

  Widget _buildSaveTemplateButton() {
    return SizedBox(
      width: 150,
      height: 45,
      child: ElevatedButton(
        onPressed: () async {
          if (!_shouldHandleTap('saveTemplate')) return;
          await _saveTemplate();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange, // Changed to orange for Template
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: const Text(
          'SAVE TEMPLATE',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // In the _saveTemplate method of TemplateCreationScreen

  Future<void> _saveTemplate() async {
    // 1. Validate form
    if (!_formKey.currentState!.validate()) {
      _showValidationError('Please fill all required fields');
      return;
    }
    final roundOffError = logic.roundOffErrorNotifier.value;
    if (roundOffError != null) {
      _showValidationError(roundOffError);
      return;
    }

    // 2. Validate vendor (same as PurchaseOrderDialog)
    if (_vendorAutocompleteController.text.isEmpty ||
        notifier.selectedVendor == null ||
        notifier.selectedVendor!.isEmpty) {
      _showValidationError(
        'Please select a vendor from the dropdown',
        scrollKey: _vendorSectionKey,
      );
      return;
    }

    // 3. Validate billing address (same as PurchaseOrderDialog)
    if (notifier.billingController.text.isEmpty) {
      _showValidationError(
        'Please enter billing address',
        scrollKey: _billingSectionKey,
      );
      return;
    }

    // 4. Validate items (same as PurchaseOrderDialog)
    if (notifier.poItems.isEmpty) {
      _showValidationError(
        'Please add at least one item',
        scrollKey: _itemsSectionKey,
      );
      return;
    }

    // 5. Validate tax type is selected
    if (logic.selectedTaxType.value == 0) {
      _showValidationError('Please select tax type (CGST/SGST or IGST)');
      return;
    }

    // Show template name dialog
    final templateName = await _showTemplateNameDialog();
    if (templateName == null || templateName.isEmpty) {
      return;
    }

    // Create PO from current data
    final currentPO = _createPOFromCurrentData(notifier);

    // Save template
    final success = await templateProvider.createTemplate(
      currentPO,
      templateName,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "$templateName" saved successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        ),
      );

      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save template: ${templateProvider.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        ),
      );
    }
  }

  void _showValidationError(String message, {GlobalKey? scrollKey}) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      ),
    );

    if (scrollKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = scrollKey.currentContext;
        if (context != null && !_isDisposed) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    }
  }

  Future<String?> _showTemplateNameDialog() async {
    final controller = TextEditingController(); // ❌ no auto-generate

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // ✅ dialog white
        title: const Text(
          'Template Name',
          style: TextStyle(color: Colors.black),
        ),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            labelText: 'Enter template name',
            labelStyle: TextStyle(color: Colors.black),
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Template name is required';
            }
            if (value.length < 3) {
              return 'Template name must be at least 3 characters';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.black54), // ✅ cancel grey
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text.length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white), // ✅ save white
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onItemAdded: () {
          if (!mounted || _isDisposed) return;
          _updateTotalOrderAmount();
          notifier.calculateTotals();
          _triggerUIRefresh();
        },
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, int index) async {
    if (index < 0 || index >= notifier.poItems.length) return;

    final itemToEdit = notifier.poItems[index];
    await showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onItemAdded: () {
          if (!mounted || _isDisposed) return;
          _updateTotalOrderAmount();
          notifier.calculateTotals();
          _triggerUIRefresh();
        },
        editingIndex: index,
        editingItem: itemToEdit,
      ),
    );
  }

  PO _createPOFromCurrentData(PurchaseOrderNotifier notifier) {
    return PO(
      purchaseOrderId: '',
      vendorName: notifier.selectedVendor ?? '',
      vendorContact: notifier.vendorContactController.text,
      items: notifier.poItems,
      totalOrderAmount: notifier.totalOrderAmount,
      pendingOrderAmount: notifier.pendingOrderAmount,
      pendingDiscountAmount: notifier.pendingDiscountAmount,
      pendingTaxAmount: notifier.pendingTaxAmount,
      paymentTerms: notifier.paymentTermsController.text,
      shippingAddress: notifier.shippingController.text,
      billingAddress: notifier.billingController.text,
      contactpersonEmail:
          notifier.selectedVendorDetails?.contactpersonEmail ?? '',
      address: notifier.selectedVendorDetails?.address ?? '',
      country: notifier.selectedVendorDetails?.country ?? '',
      state: notifier.selectedVendorDetails?.state ?? '',
      city: notifier.selectedVendorDetails?.city ?? '',
      postalCode: notifier.selectedVendorDetails?.postalCode ?? 0,
      gstNumber: notifier.selectedVendorDetails?.gstNumber ?? '',
      creditLimit: notifier.selectedVendorDetails?.creditLimit ?? 0,
      orderDate: DateTime.now().toIso8601String(),
      createdDate: DateTime.now().toIso8601String(),
      randomId: '',
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    notifier.removeListener(_updateTotalOrderAmount);
    _vendorAutocompleteController.dispose();
    _scrollController.dispose();
    _totalOrderAmount.dispose();
    _itemWiseDiscountMode.dispose();
    _overallDiscountMode.dispose();
    _refreshUI.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _refreshUI,
      builder: (context, _, __) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              widget.editingTemplate != null
                  ? 'Edit Template'
                  : 'Create Template',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700], // Changed to orange for Template
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                if (mounted && !_isDisposed) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              // Optional: Add template icon
              IconButton(
                icon: Icon(Icons.description, color: Colors.orange[700]),
                onPressed: () {
                  // Show template info or help
                },
                tooltip: 'Template Information',
              ),
            ],
          ),
          body: KeyboardDismisser(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (mounted && !_isDisposed) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            if (!isMobile) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: TextFormField(
                                        decoration: _inputDecoration(
                                          'Template ID',
                                          isEditable: false,
                                        ).copyWith(fillColor: nonEditableColor),
                                        readOnly: true,
                                        enabled: false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: VendorAutocomplete(
                                      controller: _vendorAutocompleteController,
                                      notifier: notifier,
                                      poProvider: poProvider,
                                      onVendorSelected: (selectedVendor) {
                                        logic.onVendorSelected(selectedVendor);
                                        _triggerUIRefresh();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: VendorAutocomplete(
                                      controller: _vendorAutocompleteController,
                                      notifier: notifier,
                                      poProvider: poProvider,
                                      onVendorSelected: (selectedVendor) {
                                        logic.onVendorSelected(selectedVendor);
                                        _triggerUIRefresh();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child:
                                        AddressFields.buildExpectedDeliveryDateField(
                                          notifier: notifier,
                                          parseDate: logic.parseDate,
                                          shouldHandleTap: _shouldHandleTap,
                                          inputDecoration: _inputDecoration,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                            ],

                            // Vendor Details Section
                            if (!isMobile) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: TextFormField(
                                        controller:
                                            notifier.vendorContactController,
                                        decoration: _inputDecoration(
                                          'Vendor Contact Information',
                                          isEditable: false,
                                        ).copyWith(fillColor: nonEditableColor),
                                        readOnly: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: TextFormField(
                                        controller:
                                            notifier.paymentTermsController,
                                        decoration: _inputDecoration(
                                          'Payment Terms',
                                          isEditable: false,
                                        ).copyWith(fillColor: nonEditableColor),
                                        readOnly: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Dates Section
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: GestureDetector(
                                        child: AbsorbPointer(
                                          child: TextFormField(
                                            controller:
                                                notifier.orderedDateController,
                                            decoration: _inputDecoration(
                                              'Order Date',
                                              isEditable: true,
                                            ),
                                            readOnly: true,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please select order date';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        AddressFields.buildExpectedDeliveryDateField(
                                          notifier: notifier,
                                          parseDate: logic.parseDate,
                                          shouldHandleTap: _shouldHandleTap,
                                          inputDecoration: _inputDecoration,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Credit Limit
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: TextFormField(
                                        controller:
                                            notifier.creditLimitController,
                                        decoration: _inputDecoration(
                                          'Credit Limit',
                                          isEditable: true,
                                        ),
                                        readOnly: false,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: Container()),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Address Section
                            if (!isMobile) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child:
                                        AddressFields.buildBillingAddressField(
                                          notifier: notifier,
                                        ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        AddressFields.buildShippingAddressField(
                                          notifier: notifier,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Total Amount Display
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Total Order Amount: ",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  ValueListenableBuilder<double>(
                                    valueListenable: _totalOrderAmount,
                                    builder: (context, totalAmount, child) {
                                      return Text(
                                        totalAmount.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .orange[700], // Changed to orange
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Items Table Section
                            Container(
                              key: _itemsSectionKey,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ItemsTable(
                                notifier: notifier,
                                onAddItem: () => _showAddItemDialog(context),
                                onEditItem: _showEditItemDialog,
                                onRemoveItem: (item) {
                                  notifier.removeItem(item);
                                  notifier.calculateTotals();
                                  notifier.notifyListeners();
                                },

                                // ✅ SIMPLE DIRECT PROPERTY ACCESS (NO CALCULATION)
                                getItemProperty: (item, String property) {
                                  switch (property) {
                                    case 'count':
                                      return item.count ?? 0.0;
                                    case 'eachQuantity':
                                      return item.eachQuantity ?? 0.0;
                                    case 'quantity':
                                      return item.quantity ?? 0.0;
                                    case 'pendingFinalPrice':
                                      return item.pendingFinalPrice ?? 0.0;
                                    case 'pendingTotalPrice':
                                      return item.pendingTotalPrice ?? 0.0;
                                    case 'pendingTaxAmount':
                                      return item.pendingTaxAmount ?? 0.0;
                                    default:
                                      return 0.0;
                                  }
                                },

                                itemWiseDiscountMode:
                                    notifier.itemWiseDiscountMode,
                              ),
                            ),
                            const SizedBox(height: 0),

                            // Tax Section
                            const Text(
                              'Select Tax Type:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: logic.selectedTaxType,
                              builder: (context, selectedTaxType, child) {
                                return Row(
                                  children: [
                                    Radio<int>(
                                      value: 1,
                                      groupValue: selectedTaxType,
                                      onChanged: (int? value) {
                                        logic.onTaxTypeChanged(value, 1);
                                      },
                                      activeColor:
                                          Colors.orange, // Changed to orange
                                    ),
                                    const Text(
                                      "CGST/SGST",
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                    const SizedBox(width: 20),
                                    Radio<int>(
                                      value: 2,
                                      groupValue: selectedTaxType,
                                      onChanged: (int? value) {
                                        logic.onTaxTypeChanged(value, 2);
                                      },
                                      activeColor:
                                          Colors.orange, // Changed to orange
                                    ),
                                    const Text(
                                      "IGST",
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 2),

                            // Discount Section
                            DiscountSection(
                              discountMode: _overallDiscountMode,
                              overallDiscountController:
                                  notifier.overallDiscountController,
                              roundOffController: notifier.roundOffController,
                              subtotal: notifier.subTotal,
                              itemWiseDiscount: notifier.itemWiseDiscount,
                              onCalculationsUpdate: () {
                                _triggerUIRefresh();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _triggerUIRefresh();
                                });
                              },
                              onApplyDiscount: logic.applyDiscount,
                              poItems: notifier.poItems,
                              notifier: notifier,
                              logic: logic,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer Section with SAVE TEMPLATE Button (REPLACED SAVE ORDER)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: isMobile
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Cancel Button
                              Expanded(
                                child: SizedBox(
                                  height: 45,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey[300],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          30.0,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (mounted && !_isDisposed) {
                                        logic.resetAllFields();
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Save Template Button
                              Expanded(child: _buildSaveTemplateButton()),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Cancel Button
                              SizedBox(
                                width: 130,
                                height: 45,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (mounted && !_isDisposed) {
                                      logic.resetAllFields();
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildSaveTemplateButton(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
