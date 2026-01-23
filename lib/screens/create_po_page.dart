// ignore_for_file: use_build_context_synchronously, unused_local_variable, deprecated_member_use, unused_element, library_private_types_in_public_api, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/po_template.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import 'package:purchaseorders2/providers/template_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/widgets/create%20po/save_template_dialog.dart';
import 'package:purchaseorders2/widgets/create%20po/template_list_dialog.dart';
import '../widgets/create po/purchase_order_logic.dart';
import '../widgets/create po/discount_section.dart';
import '../models/discount_model.dart';
import '../models/po.dart';
import '../widgets/create po/add_item_dialog.dart';
// import '../calculation/purchase_order_calculations.dart';
import '../widgets/create po/vendor_autocomplete.dart';
import '../widgets/create po/address_fields.dart';
import '../widgets/create po/items_table.dart';
import '../widgets/keyboard_dismisser.dart';
import '../widgets/create po/template_creation_screen.dart';

class PurchaseOrderDialog extends StatefulWidget {
  final PO? editingPO;
  final TemplateProvider templateProvider;
  final VoidCallback? onStatusChanged;

  const PurchaseOrderDialog({
    super.key,
    required this.templateProvider,
    this.editingPO,
    this.onStatusChanged,
  });

  @override
  _PurchaseOrderDialogState createState() => _PurchaseOrderDialogState();
}

class _PurchaseOrderDialogState extends State<PurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ValueNotifier<bool> _refreshUI = ValueNotifier(false);
  bool _isDisposed = false;
  bool _logicInitialized = false;

  late PurchaseOrderNotifier notifier;
  late POProvider poProvider;
  late TemplateProvider templateProvider;
  late PurchaseOrderLogic logic;
  late BuildContext _safeScaffoldContext;

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
      if (!mounted || _isDisposed) return;

      // 🔥 CLEAR OLD DATA ONLY FOR CREATE PO
      if (widget.editingPO == null) {
        print('🧹 Clearing old notifier data for NEW PO');

        notifier.poItems.clear();
        notifier.clearSelectedVendor();
        notifier.editingIndex = null;

        notifier.vendorContactController.clear();
        notifier.paymentTermsController.clear();
        notifier.creditLimitController.clear();
        notifier.billingController.clear();
        notifier.shippingController.clear();

        notifier.overallDiscountController.text = '0';
        notifier.roundOffController.text = '0';

        notifier.subTotal = 0.0;
        notifier.itemWiseDiscount = 0.0;
        notifier.overallDiscountAmount = 0.0;
        notifier.calculatedFinalAmount = 0.0;
        notifier.totalOrderAmount = 0.0;
        notifier.pendingOrderAmount = 0.0;
        notifier.pendingDiscountAmount = 0.0;
        notifier.pendingTaxAmount = 0.0;

        notifier.discountMode.value = DiscountMode.none;
        _overallDiscountMode.value = DiscountMode.none;
        _itemWiseDiscountMode.value = 'Percentage ( % )';

        _vendorAutocompleteController.clear();

        notifier.calculateTotals();
      }

      // ✅ NOW SAFE TO INITIALIZE
      logic.initializeData();
    });
  }

  void _clearOnlyDataNotControllers() {
    try {
      print('🧹 Clearing only data (not controllers)');

      final notifier = Provider.of<PurchaseOrderNotifier>(
        context,
        listen: false,
      );

      notifier.selectedVendor = null;
      notifier.selectedVendorDetails = null;
      notifier.poItems.clear();

      // ✅ ADD THIS LINE
      notifier.expectedDeliveryDateController.text = '';

      notifier.calculateTotals();
      print('✅ Only data cleared (controllers untouched)');
    } catch (e) {
      print('⚠️ Error clearing data: $e');
    }
  }

  void _initializeLogic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;

      notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
      poProvider = Provider.of<POProvider>(context, listen: false);
      templateProvider = widget.templateProvider;

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
      logic.initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
    poProvider = Provider.of<POProvider>(context, listen: false);

    templateProvider = widget.templateProvider;

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
    if (!_totalOrderAmount.hasListeners) return;

    try {
      _totalOrderAmount.value = notifier.totalOrderAmount;
    } catch (_) {
      // ignore update after dispose
    }
  }

  void _triggerUIRefresh() {
    if (!mounted || _isDisposed) return;
    if (!_refreshUI.hasListeners) return;

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

  Widget _buildSaveButton() {
    return SizedBox(
      width: 130,
      height: 45,
      child: ElevatedButton(
        onPressed: () async {
          if (!_shouldHandleTap('saveOrder')) return;
          await logic.savePurchaseOrder(
            vendorSectionKey: _vendorSectionKey,
            billingSectionKey: _billingSectionKey,
            itemsSectionKey: _itemsSectionKey,
          );

          if (!mounted || _isDisposed) return;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          widget.editingPO != null ? 'Update Order' : 'Save Order',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Template button
  Widget _buildTemplateButton() {
    final isSmall = MediaQuery.of(context).size.width < 450;
    final bool isEditMode = widget.editingPO != null;

    if (isEditMode) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 160),
        offset: const Offset(0, 40),

        // Button UI
        icon: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? 4 : 6,
            horizontal: isSmall ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange[500]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Template',
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[500],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Dropdown items
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'create_new',
            child: Row(
              children: [
                const Icon(
                  Icons.add_circle_outlined,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Create New Template',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'use',
            child: Row(
              children: [
                const Icon(
                  Icons.folder_open_outlined,
                  size: 18,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Use Existing Template',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Menu actions
        onSelected: (value) async {
          if (value == 'create_new') {
            await _navigateToTemplateCreateScreen();
          } else if (value == 'use') {
            _showTemplateList();
          }
        },
      ),
    );
  }

  void _safeClearAndClose() {
    print('🔄 Safe clear and close');

    try {
      // Clear items list (safe, no controllers)
      notifier.poItems.clear();

      // Clear vendor selection (safe)
      notifier.selectedVendor = null;
      notifier.selectedVendorDetails = null;

      // Clear addresses by setting text (safe if controllers exist)
      try {
        notifier.billingController.text = '';
        notifier.shippingController.text = '';
      } catch (e) {
        print('⚠️ Controllers already disposed, skipping clear');
      }

      // Recalculate
      notifier.calculateTotals();
    } catch (e) {
      print('⚠️ Error in safe clear: $e');
    }

    // Close dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _navigateToTemplateCreateScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TemplateCreationScreen(editingPO: null, editingTemplate: null),
      ),
    );

    if (result == true && mounted) {
      logic.resetAllFields();

      notifier.poItems.clear();
      notifier.clearSelectedVendor();
      notifier.editingIndex = null;

      notifier.orderedDateController.clear();
      notifier.expectedDeliveryDateController.clear();
      notifier.billingController.clear();
      notifier.shippingController.clear();
      notifier.creditLimitController.clear();
      notifier.vendorContactController.clear();
      notifier.paymentTermsController.clear();
      _vendorAutocompleteController.clear();

      notifier.overallDiscountController.text = '0';
      notifier.roundOffController.text = '0';

      notifier.subTotal = 0.0;
      notifier.itemWiseDiscount = 0.0;
      notifier.overallDiscountAmount = 0.0;
      notifier.calculatedFinalAmount = 0.0;
      notifier.totalOrderAmount = 0.0;

      _updateTotalOrderAmount();
      _triggerUIRefresh();
    }
  }

  PO _createEmptyPO() {
    return PO(
      purchaseOrderId: '',
      vendorName: '',
      vendorContact: '',
      items: [],
      totalOrderAmount: 0.0,
      pendingOrderAmount: 0.0,
      pendingDiscountAmount: 0.0,
      pendingTaxAmount: 0.0,
      paymentTerms: '',
      shippingAddress: '',
      billingAddress: '',
      contactpersonEmail: '',
      address: '',
      country: '',
      state: '',
      city: '',
      postalCode: 0,
      gstNumber: '',
      creditLimit: 0,
      orderDate: DateTime.now().toIso8601String(),
      createdDate: DateTime.now().toIso8601String(),
      randomId: '',
    );
  }

  void _saveCurrentAsTemplate() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (notifier.poItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          elevation: 6,
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: const Text(
              'Please add items before saving as template',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );

      return;
    }

    if (notifier.selectedVendor == null || notifier.selectedVendor!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vendor before saving as template'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SaveTemplateDialog(
        onSave: (templateName) async {
          FocusManager.instance.primaryFocus?.unfocus();

          final currentPO = _createPOFromCurrentData(notifier);

          final success = await templateProvider.createTemplate(
            currentPO,
            templateName,
          );

          if (!mounted || _isDisposed) return;

          if (success) {
            ScaffoldMessenger.of(_safeScaffoldContext).showSnackBar(
              SnackBar(
                content: Text('Template "$templateName" saved successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 160),
              ),
            );
          }
        },
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

  void _editPO(BuildContext context, PO po) {
    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
    notifier.setEditingPO(po);

    print('🔄 Opening edit dialog for PO: ${po.purchaseOrderId}');
    print('   Vendor: ${po.vendorName}');
    print('   Items count: ${po.items.length}');
    print('   Total amount: ${po.totalOrderAmount}');

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => PurchaseOrderDialog(
        key: UniqueKey(),
        editingPO: po,
        templateProvider: context.read<TemplateProvider>(),
      ),
    ).then((result) async {
      print('📝 Edit dialog closed with result: $result');

      if (!mounted) return;

      // Clear editing PO safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifier.setEditingPO(null);
        }
      });

      if (result == true) {
        print('✅ PO edit was successful');
        // ✅ Refresh PO list safely
        final poProvider = Provider.of<POProvider>(context, listen: false);
        await poProvider.fetchPOs();

        if (!mounted) return;

        if (widget.onStatusChanged != null) {
          widget.onStatusChanged!();
        }

        // ✅ Show success message safely
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Purchase Order updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ PO edit was cancelled or failed');
      }
    });
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

  void _showTemplateList() {
    showDialog(
      context: context,
      builder: (context) => TemplateListDialog(
        onTemplateSelected: (template) {
          _loadTemplate(template);
        },
      ),
    );
  }

  void _loadTemplate(POTemplate template) {
    // Apply template using logic method (handles all vendor + address + items)
    logic.applyTemplate(template);

    // Update total amount
    _updateTotalOrderAmount();

    // Refresh UI
    _triggerUIRefresh();
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

    // remove listeners
    notifier.removeListener(_updateTotalOrderAmount);

    // dispose ONLY local controllers / notifiers
    _vendorAutocompleteController.dispose();
    _scrollController.dispose();
    _totalOrderAmount.dispose();
    _itemWiseDiscountMode.dispose();
    _overallDiscountMode.dispose();
    _refreshUI.dispose();

    super.dispose();
  }

  void _safeClearController(TextEditingController controller) {
    if (!mounted || _isDisposed) return;

    try {
      // Always clear safely using value
      controller.value = TextEditingValue.empty;
    } catch (e) {
      debugPrint('⚠️ Error clearing controller safely: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _safeScaffoldContext = context;
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _refreshUI,
      builder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final isTablet = width >= 600 && width <= 1100;
        final isMobile = width < 600;

        double tabletPadding = isTablet ? 10 : 16;
        double tabletSpacing = isTablet ? 10 : 16;
        double tabletFont = isTablet ? 14 : 16;
        double tabletTitleFont = isTablet ? 18 : 20;

        return WillPopScope(
          onWillPop: () async {
            return true;
          },

          child: Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(
                widget.editingPO != null
                    ? 'Edit Purchase Order'
                    : 'Create Purchase Order',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
            ),

            body: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: KeyboardDismisser(
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
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.all(isTablet ? 10 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMobile) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: TextFormField(
                                            decoration:
                                                _inputDecoration(
                                                  'PO ID',
                                                  isEditable: false,
                                                ).copyWith(
                                                  fillColor: nonEditableColor,
                                                ),
                                            readOnly: true,
                                            enabled: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: VendorAutocomplete(
                                          controller:
                                              _vendorAutocompleteController,
                                          notifier: notifier,
                                          poProvider: poProvider,
                                          onVendorSelected: (selectedVendor) {
                                            logic.onVendorSelected(
                                              selectedVendor,
                                            );
                                            _triggerUIRefresh();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTablet ? 10 : 16),
                                ] else ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: VendorAutocomplete(
                                          controller:
                                              _vendorAutocompleteController,
                                          notifier: notifier,
                                          poProvider: poProvider,
                                          onVendorSelected: (selectedVendor) {
                                            logic.onVendorSelected(
                                              selectedVendor,
                                            );
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

                                if (!isMobile) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: TextFormField(
                                            controller: notifier
                                                .vendorContactController,
                                            decoration:
                                                _inputDecoration(
                                                  'Vendor Contact Information',
                                                  isEditable: false,
                                                ).copyWith(
                                                  fillColor: nonEditableColor,
                                                ),
                                            readOnly: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: TextFormField(
                                            controller:
                                                notifier.paymentTermsController,
                                            decoration:
                                                _inputDecoration(
                                                  'Payment Terms',
                                                  isEditable: false,
                                                ).copyWith(
                                                  fillColor: nonEditableColor,
                                                ),
                                            readOnly: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTablet ? 10 : 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: GestureDetector(
                                            child: AbsorbPointer(
                                              child: TextFormField(
                                                controller: notifier
                                                    .orderedDateController,
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
                                  SizedBox(height: isTablet ? 10 : 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
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
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                if (!isMobile) ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  SizedBox(height: isTablet ? 10 : 16),
                                ],

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 1.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // TOTAL AMOUNT (full visible text, no overflow)
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Row(
                                            children: [
                                              const Text(
                                                "Total Ord Amt: ",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              ValueListenableBuilder<double>(
                                                valueListenable:
                                                    _totalOrderAmount,
                                                builder:
                                                    (
                                                      context,
                                                      totalAmount,
                                                      child,
                                                    ) {
                                                      return Text(
                                                        totalAmount
                                                            .toStringAsFixed(2),
                                                        style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.blueAccent,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      SizedBox(
                                        width: 120,
                                        child: _buildTemplateButton(),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  key: _itemsSectionKey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: ItemsTable(
                                    notifier: notifier,
                                    onAddItem: () =>
                                        _showAddItemDialog(context),
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
                                          activeColor: Colors.blueAccent,
                                        ),
                                        const Text("CGST/SGST"),
                                        const SizedBox(width: 20),
                                        Radio<int>(
                                          value: 2,
                                          groupValue: selectedTaxType,
                                          onChanged: (int? value) {
                                            logic.onTaxTypeChanged(value, 2);
                                          },
                                          activeColor: Colors.blueAccent,
                                        ),
                                        const Text("IGST"),
                                      ],
                                    );
                                  },
                                ),

                                DiscountSection(
                                  discountMode: _overallDiscountMode,
                                  overallDiscountController:
                                      notifier.overallDiscountController,
                                  roundOffController:
                                      notifier.roundOffController,
                                  subtotal: notifier.subTotal,
                                  itemWiseDiscount: notifier.itemWiseDiscount,
                                  onCalculationsUpdate: () {
                                    _triggerUIRefresh();

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (!mounted || _isDisposed) return;
                                          _triggerUIRefresh();
                                        });
                                  },

                                  onApplyDiscount: logic.applyDiscount,
                                  poItems: notifier.poItems,
                                  notifier: notifier,
                                  logic: logic,
                                ),

                                SizedBox(height: isTablet ? 10 : 16),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall =
                                constraints.maxWidth <
                                420; // Mobile compact mode
                            final buttonHeight = isSmall ? 42.0 : 48.0;
                            final fontSize = isSmall ? 11.0 : 13.0;
                            final spacing = isSmall ? 8.0 : 12.0;

                            Widget buildActionButton({
                              required String text,
                              required Color color,
                              required VoidCallback? onPressed,
                              Widget? child,
                            }) {
                              return Expanded(
                                child: SizedBox(
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: onPressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          isSmall ? 14 : 20,
                                        ),
                                      ),
                                    ),
                                    child:
                                        child ??
                                        Text(
                                          text,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                  ),
                                ),
                              );
                            }

                            return Row(
                              children: [
                                // SAVE AS TEMPLATE
                                if (widget.editingPO == null) ...[
                                  buildActionButton(
                                    text: "Save as Template",
                                    color: Colors.orange,
                                    onPressed: _saveCurrentAsTemplate,
                                  ),
                                  SizedBox(width: spacing),
                                ],

                                // CANCEL
                                // In PurchaseOrderDialog build() method:
                                buildActionButton(
                                  text: "Cancel",
                                  color: Colors.grey.shade700,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),

                                SizedBox(width: spacing),

                                // SAVE / UPDATE ORDER
                                buildActionButton(
                                  text: widget.editingPO != null
                                      ? "Update Order"
                                      : "Save Order",
                                  color: Colors.blueAccent,
                                  onPressed: logic.isSaving.value
                                      ? null
                                      : () async {
                                          if (!_shouldHandleTap('saveOrder'))
                                            return;

                                          await logic.savePurchaseOrder(
                                            vendorSectionKey: _vendorSectionKey,
                                            billingSectionKey:
                                                _billingSectionKey,
                                            itemsSectionKey: _itemsSectionKey,
                                          );

                                          if (!mounted || _isDisposed) return;
                                        },
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: logic.isSaving,
                                    builder: (_, saving, __) {
                                      return saving
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              widget.editingPO != null
                                                  ? "Update Order"
                                                  : "Save Order",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
