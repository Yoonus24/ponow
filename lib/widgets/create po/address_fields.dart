import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import '../../models/shippingandbillingaddress.dart';

class AddressFields {
  static Widget buildExpectedDeliveryDateField({
    required PurchaseOrderNotifier notifier,
    required DateTime? Function(String) parseDate,
    required bool Function(String) shouldHandleTap,
    required InputDecoration Function(String, {bool isEditable})
    inputDecoration,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Builder(
        builder: (context) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (!shouldHandleTap('expectedDate')) return;

              final RenderBox box = context.findRenderObject() as RenderBox;
              final pos = box.localToGlobal(Offset.zero);
              final size = box.size;

              DateTime orderDate =
                  notifier.orderedDateController.text.isNotEmpty
                  ? (parseDate(notifier.orderedDateController.text) ??
                        DateTime.now())
                  : DateTime.now();

              final selectedValue = await showMenu<int>(
                context: context,
                color: Colors.white,
                position: RelativeRect.fromLTRB(
                  pos.dx,
                  pos.dy + size.height + 4,
                  pos.dx + size.width,
                  pos.dy + size.height + 200,
                ),
                constraints: BoxConstraints(
                  maxWidth: size.width,
                  minWidth: size.width,
                  maxHeight: 200,
                ),
                items: List.generate(20, (index) {
                  final days = index + 1;
                  final date = orderDate.add(Duration(days: days));

                  return PopupMenuItem<int>(
                    value: days,
                    height: 36,
                    child: Row(
                      children: [
                        Text('$days Day${days > 1 ? 's' : ''}'),
                        const Spacer(),
                        Text(
                          "${date.day.toString().padLeft(2, '0')}-"
                          "${date.month.toString().padLeft(2, '0')}-"
                          "${date.year}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );

              if (selectedValue != null) {
                final date = orderDate.add(Duration(days: selectedValue));
                notifier.expectedDeliveryDateController.text =
                    "${date.day.toString().padLeft(2, '0')}-"
                    "${date.month.toString().padLeft(2, '0')}-"
                    "${date.year}";
              }
            },
            child: AbsorbPointer(
              child: SizedBox(
                height: 50,
                child: TextFormField(
                  controller: notifier.expectedDeliveryDateController,
                  readOnly: true,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return ''; // no message, only red border
                    }
                    return null;
                  },

                  decoration: inputDecoration("Expected Date").copyWith(
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    hintText: '',
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                    contentPadding: const EdgeInsets.only(
                      left: 14,
                      right: 40,
                      top: 16,
                      bottom: 16,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey[600],
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget buildShippingAddressField({
    required PurchaseOrderNotifier notifier,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: SizedBox(
        height: 60,
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            final addresses = notifier.shippingAddress
                .where(
                  (e) => e.address.toLowerCase().contains(
                    textEditingValue.text.trim().toLowerCase(),
                  ),
                )
                .map((e) => e.address)
                .toList();

            return addresses;
          },
          onSelected: (selectedShippingAddress) {
            final selectedShippingDetails = notifier.shippingAddress.firstWhere(
              (e) => e.address == selectedShippingAddress,
              orElse: () => ShippingAddress(shippingId: '', address: ''),
            );

            notifier.setSelectedshippingaddress(
              selectedShippingDetails.shippingId,
            );
            notifier.shippingController.text = selectedShippingAddress;
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: notifier.shippingController,
                  focusNode: focusNode,
                  readOnly: true,
                  onTap: () {
                    notifier.setSelectedshippingaddress('');
                    focusNode.requestFocus();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      textEditingController.text = '';
                      textEditingController.selection =
                          TextSelection.fromPosition(TextPosition(offset: 0));
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Shipping Address',
                    labelStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 74, 122, 227),
                        width: 2.0,
                      ),
                    ),
                    contentPadding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                    isDense: false,
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: notifier.shippingController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              notifier.shippingController.clear();
                              notifier.setSelectedshippingaddress('');
                              focusNode.requestFocus();

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                textEditingController.text = '';
                                textEditingController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: 0),
                                    );
                              });
                            },
                          )
                        : null,
                    errorStyle: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a shipping address';
                    }
                    return null;
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
                child: Container(
                  width: 250,
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: options.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No shipping addresses found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option,
                                style: TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                onSelected(option);
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget buildBillingAddressField({
    required PurchaseOrderNotifier notifier,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: TextFormField(
        controller: notifier.billingController,
        decoration: InputDecoration(
          labelText: 'Billing Address',
          labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 74, 122, 227),
              width: 2.0,
            ),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          isDense: false,
          contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(fontSize: 12, color: Colors.red[700]),
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter billing address';
          }
          return null;
        },
        onChanged: (value) {
          if (value.isNotEmpty) {
            notifier.billingController.text = value;
            notifier.setSelectedbillingaddress(null);
          }
        },
      ),
    );
  }
}
