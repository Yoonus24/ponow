import 'package:flutter/material.dart';
import 'package:purchaseorders2/models/shippingandbillingaddress.dart';
import 'package:provider/provider.dart';
import '../models/po.dart';
import '../models/po_item.dart';
import '../models/vendorpurchasemodel.dart';
import '../providers/po_provider.dart';

class PurchaseOrderModel extends ChangeNotifier {
  final POProvider poProvider;
  PurchaseOrderModel(this.poProvider);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  final TextEditingController vendorContactController = TextEditingController();
  final TextEditingController uomController = TextEditingController();
  final TextEditingController expectedDeliveryDateController =
      TextEditingController();
  final TextEditingController eachQuantityController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  //final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController beforeTaxDiscountAmount = TextEditingController();
  final TextEditingController afterTaxDiscountAmount = TextEditingController();

  final TextEditingController TaxDiscountAmount = TextEditingController();
  final TextEditingController taxPercentageController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController paymentTermsController = TextEditingController();
  final TextEditingController shippingController = TextEditingController();
  final TextEditingController billingController = TextEditingController();
  final TextEditingController existingPriceController = TextEditingController();
  final TextEditingController newPriceController = TextEditingController();
  String? selectedVendor;
  String? selectedItem;
  String? selectedPaymentTerm;
  double totalOrderAmount = 0.0;
  List<Item> poItems = [];
  List<PurchaseItem> purchaseItems = [];
  List<Vendor> vendors = [];
  List<ShippingAddress> shippingAddress = [];
  List<BillingAddress> billingAddress = [];

  void initState() {
    _fetchVendors();
    _fetchItems('');
  }

  @override
  void dispose() {
    vendorContactController.dispose();
    expectedDeliveryDateController.dispose();
    quantityController.dispose();
    //unitPriceController.dispose();
    newPriceController.dispose();
    existingPriceController.dispose();
    taxPercentageController.dispose();
    discountController.dispose();
    uomController.dispose();
    eachQuantityController.dispose();
    countController.dispose();
    paymentTermsController.dispose();
    billingController.dispose();
    shippingController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendors() async {
    await poProvider.fetchingVendors();
    vendors = poProvider.vendors;
    notifyListeners();
  }

  Future<void> fetchShippingaddress() async {
    await poProvider.fetchShippingaddress();
    shippingAddress = poProvider.shippingAddress;
    notifyListeners();
  }

  Future<void> fetchBillingaddress() async {
    await poProvider.fetchBillingAddress();
    billingAddress = poProvider.billingAddress;
    notifyListeners();
  }

  Future<void> _fetchItems(String query) async {
    //await poProvider.fetchingPurchaseItems();
    await poProvider.searchPurchaseItems(query);
    purchaseItems = poProvider.purchaseItems;
    notifyListeners();
  }

  void updateItemDetails(String? itemName) {
    if (itemName != null) {
      final selectedItem = purchaseItems.firstWhere(
        (item) => item.itemName == itemName,
        orElse: () => PurchaseItem(
          itemName: '',
          purchasePrice: 0.0,
          purchasetaxName: 0.0,
          purchaseItemId: '',
          uom: '',
          purchasecategoryName: '',
          purchasesubcategoryName: '',
          hsnCode: '',
          //  expiryDate: '',
        ),
      );
      newPriceController.text = selectedItem.purchasePrice.toString();
      //  unitPriceController.text = selectedItem.purchasePrice.toString();
      taxPercentageController.text = selectedItem.purchasetaxName.toString();
      uomController.text = selectedItem.uom.toString();
      notifyListeners();
    }
  }

  void calculateTotals() {
    double total = 0.0;
    for (var item in poItems) {
      total += item.totalPrice ?? 0.0; // Handle null case safely
    }
    totalOrderAmount = total;
    notifyListeners();
  }

  void resetControllers() {
    vendorContactController.clear();
    expectedDeliveryDateController.clear();
    quantityController.clear();
    //unitPriceController.clear();
    newPriceController.clear();
    taxPercentageController.clear();
    discountController.clear();
    uomController.clear();
    eachQuantityController.clear();
    countController.clear();
    selectedVendor = null;
    selectedItem = null;
    poItems.clear();
    totalOrderAmount = 0.0;
    notifyListeners();
  }

  void addItem() {
    if (selectedItem != null) {
      final item = purchaseItems.firstWhere(
        (item) => item.itemName == selectedItem,
        orElse: () => PurchaseItem(
          itemName: '',
          purchasePrice: 0.0,
          purchasetaxName: 0.0,
          purchaseItemId: '',
          uom: '',
          purchasecategoryName: '',
          purchasesubcategoryName: '',
          hsnCode: '',
          // expiryDate: '',
        ),
      );

      //final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
      final discount = double.tryParse(discountController.text) ?? 0.0;
      final count = double.tryParse(countController.text) ?? 0.0;
      final eachQuantity = double.tryParse(eachQuantityController.text) ?? 0.0;
      final quantity = count * eachQuantity;
      final existingPrice = double.tryParse(existingPriceController.text);
      final newPrice = double.tryParse(newPriceController.text) ?? 0.0;
      final totalPriceBeforeDiscount = quantity * newPrice;
      final discountPrice = (totalPriceBeforeDiscount * discount) / 100;
      final priceAfterDiscount = totalPriceBeforeDiscount - discountPrice;

      final taxPercentage =
          double.tryParse(taxPercentageController.text) ?? 0.0;
      final taxAmount = (priceAfterDiscount * taxPercentage) / 100;

      final finalPrice = priceAfterDiscount + taxAmount;

      final poItem = Item(
        itemName: selectedItem!,
        quantity: quantity,
        existingPrice: existingPrice,
        newPrice: newPrice,
        pendingCount: count,
        pendingQuantity: eachQuantity,
        taxPercentage: taxPercentage,
        discount: discount,
        totalPrice: finalPrice,
        sgst: 0.0,
        cgst: 0.0,
        barcode: '',
        uom: item.uom,
        itemId: '',
        expiryDate: '',
        afTaxDiscountType: '',
        befTaxDiscountType: '',
      );

      poItems.add(poItem);
      calculateTotals();
      resetItemFields();
      notifyListeners();
    }
  }

  void resetItemFields() {
    quantityController.clear();
    //unitPriceController.clear();
    newPriceController.clear();
    taxPercentageController.clear();
    uomController.clear();
    discountController.clear();
    selectedItem = null;
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      expectedDeliveryDateController.text = "${picked.toLocal()}".split(' ')[0];
      notifyListeners();
    }
  }

  void submitPurchaseOrder(BuildContext context) async {
    final poProvider = Provider.of<POProvider>(context, listen: false);

    final selectedVendorDetails = poProvider.vendorAllList.firstWhere(
      (vendor) => vendor.vendorName == selectedVendor,
      orElse: () {
        print("Vendor not found");
        return VendorAll(
          vendorName: '',
          contactpersonPhone: '',
          vendorId: '',
          paymentTerms: 'No Payment Term Selected',
          contactpersonEmail: '',
          address: '',
          country: '',
          state: '',
          city: '',
          postalCode: 0,
          gstNumber: '',
          creditLimit: 0,
        );
      },
    );
    if (formKey.currentState?.validate() ?? false) {
      if (selectedVendor == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a vendor')));
        return;
      }

      if (poItems.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please add at least one item')));
        return;
      }

      final po = PO(
        purchaseOrderId: '',
        vendorName: selectedVendor!,
        vendorContact: vendorContactController.text,
        expectedDeliveryDate: expectedDeliveryDateController.text,
        paymentTerms: selectedPaymentTerm ?? '',
        shippingAddress: shippingController.text,
        billingAddress: billingController.text,
        items: poItems,
        totalOrderAmount: totalOrderAmount,
        contactpersonEmail: '',
        address: '',
        country: '',
        state: '',
        city: '',
        postalCode: 0,
        gstNumber: '',
        creditLimit: 0,
      );

      try {
        // po.items = poProvider.items;
        await poProvider.postPO(po, selectedVendorDetails);
        resetControllers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase order submitted successfully!')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting purchase order: $error')),
        );
      }
    }
  }
}
