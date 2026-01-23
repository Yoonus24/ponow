import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/providers/po_provider.dart';
import '../../models/vendorpurchasemodel.dart';

class VendorAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final PurchaseOrderNotifier notifier;
  final POProvider poProvider;
  final Function(String) onVendorSelected;

  const VendorAutocomplete({
    super.key,
    required this.controller,
    required this.notifier,
    required this.poProvider,
    required this.onVendorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          final input = textEditingValue.text.trim();

          poProvider.currentSkip = 0;

          await poProvider.fetchingAllVendors(
            vendorName: input,
            skip: 0,
            limit: 50,
            append: false,
          );

          return poProvider.filteredVendorNames;
        },

        // ============================================================
        // ✅ SELECT VENDOR (STABLE)
        // ============================================================
        onSelected: (selectedVendor) {
          controller.text = selectedVendor;
          onVendorSelected(selectedVendor);

          VendorAll? selectedVendorDetails;

          try {
            selectedVendorDetails = notifier.vendorAllList.firstWhere(
              (v) => v.vendorName == selectedVendor,
            );
          } catch (_) {
            selectedVendorDetails = VendorAll(
              vendorName: selectedVendor,
              contactpersonPhone: '',
              vendorId: '',
              paymentTerms: '',
              contactpersonEmail: '',
              address: '',
              country: '',
              state: '',
              city: '',
              postalCode: 0,
              gstNumber: '',
              creditLimit: 0,
            );
          }

          notifier.vendorContactController.text =
              selectedVendorDetails.contactpersonPhone;

          notifier.paymentTermsController.text =
              selectedVendorDetails.paymentTerms;

          notifier.creditLimitController.text = selectedVendorDetails
              .creditLimit
              .toString();

          // ✅ Close keyboard AFTER selection
          Future.microtask(() {
            FocusManager.instance.primaryFocus?.unfocus();
          });
        },

        // ============================================================
        // ✅ YOUR ORIGINAL FIELD UI (UNCHANGED)
        // ============================================================
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.text != textEditingController.text &&
                    controller.text.isNotEmpty) {
                  textEditingController.text = controller.text;
                }
              });

              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
                child: TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Select Vendor',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 74, 122, 227),
                        width: 2.0,
                      ),
                    ),

                    // 🔵 Added more space inside the field
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 7, // increased for visibility
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    // 🔵 Push icon further right (better visibility)
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 48, // increases right-side spacing
                      minHeight: 40,
                    ),

                    suffixIcon: textEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            onPressed: () async {
                              textEditingController.clear();
                              controller.clear();

                              poProvider.currentSkip = 0;
                              poProvider.filteredVendorNames.clear();
                              poProvider.vendorAllList.clear();

                              await poProvider.fetchingAllVendors(
                                vendorName: '',
                                skip: 0,
                                limit: 50,
                                append: false,
                              );

                              FocusScope.of(context).requestFocus(focusNode);
                            },
                          )
                        : null,

                    errorStyle: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a vendor';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (controller.text != value) {
                      controller.text = value;
                    }
                  },
                ),
              );
            },

        // ============================================================
        // ✅ DROPDOWN (TAP ALWAYS WORKS)
        // ============================================================
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
              child: Container(
                width: 250,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView.builder(
                  controller: poProvider.vendorAllScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);

                    return ListTile(
                      title: Text(option, style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        onSelected(option);

                        // ✅ Delay focus removal safely
                        Future.microtask(() {
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
