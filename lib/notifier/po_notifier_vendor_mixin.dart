import 'package:flutter/material.dart';
import '../models/po/vendorpurchasemodel.dart';
import 'po_notifier_state.dart';

mixin PONotifierVendorMixin on PurchaseOrderNotifierState {
  Future<void> fetchVendors1() async {
    if (vendorsLoaded) return;
    await poProvider.fetchingVendors();
    vendors = poProvider.vendors;
    vendorsLoaded = true;
    safeNotify();
  }

  Future<void> fetchAllVendors1() async {
    if (vendorsLoaded) return;

    vendorsLoading = true;

    await poProvider.fetchingAllVendors(vendorName: '', skip: 0, limit: 5000);

    vendorAllList = poProvider.vendorAllList;

    vendorsLoaded = true;
    vendorsLoading = false;

    safeNotify();
  }

  void clearSelectedVendor() {
    try {
      selectedVendor = '';
      selectedVendorDetails = null;
      selectedLocation = '';
      selectedLocationName = '';
      vendorContactController.value = TextEditingValue.empty;
      paymentTermsController.value = TextEditingValue.empty;
      creditLimitController.value = TextEditingValue.empty;
      addressController.value = TextEditingValue.empty;
      cityController.value = TextEditingValue.empty;
      stateController.value = TextEditingValue.empty;
      countryController.value = TextEditingValue.empty;
      postalCodeController.value = TextEditingValue.empty;
      gstNumberController.value = TextEditingValue.empty;
      safeNotify();
    } catch (e) {
      // Replicating original behaviour logic flow mapping
      debugPrint("ERROR: ${e.toString()}");
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      throw Exception(
        errorMessage.isNotEmpty ? errorMessage : 'Something went wrong',
      );
    }
  }

  void setSelectedVendors(String? vendorName) {
    if (disposed) return;
    selectedVendor = vendorName ?? '';
    if (vendorName != null) {
      selectedVendorDetails = vendorAllList.firstWhere(
        (vendor) => vendor.vendorName == vendorName,
        orElse: () => VendorAll(
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
          randomId: '',
        ),
      );
    } else {
      selectedVendorDetails = null;
    }
    safeNotify();
  }

  void setSelectedVendor(String? vendorName) {
    if (disposed) return;

    selectedVendor = vendorName ?? '';

    if (vendorName != null && vendorName.isNotEmpty) {
      final vendor = vendorAllList.cast<VendorAll?>().firstWhere(
        (v) => v?.vendorName == vendorName,
        orElse: () => null,
      );

      if (vendor == null) {
        debugPrint(
          'Vendor not found: $vendorName '
          'Available Vendors: ${vendorAllList.length}',
        );

        selectedVendorDetails = null;
        selectedVendorId = null;
        safeNotify();
        return;
      }

      selectedVendorDetails = vendor;
      selectedVendorId = vendor.vendorId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!disposed) {
          vendorContactController.text = vendor.contactpersonPhone;
          paymentTermsController.text = vendor.paymentTerms;
          creditLimitController.text = vendor.creditLimit.toString();
        }
      });
    } else {
      selectedVendorDetails = null;
      selectedVendorId = null;
    }

    safeNotify();
  }

  void setSelectedPaymentTerm(String? term) {
    if (disposed) return;

    selectedPaymentTerm = term ?? '';
    safeNotify();
  }

  void setSelectedshippingaddress(String? shippingId) {
    if (disposed) return;

    selectedShippingaddress = shippingId ?? '';
    safeNotify();
  }

  void setSelectedbillingaddress(String? businessId) {
    if (disposed) return;

    selectedBillingaddress = businessId ?? '';
    safeNotify();
  }

  Future<void> fetchBranches1() async {
    if (disposed) return;
    await poProvider.fetchBranches();
    safeNotify();
  }

  Future<void> fetchShippingAddress1() async {
    if (disposed) return;
    await poProvider.fetchShippingaddress();
    shippingAddress = poProvider.shippingAddress;
    safeNotify();
  }

  Future<void> fetchBillingAddress1() async {
    if (disposed) return;
    await poProvider.fetchBillingAddress();
    billingAddress = poProvider.billingAddress;
    safeNotify();
  }
}