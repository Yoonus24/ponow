import 'package:flutter/material.dart';
import 'package:purchaseorders2/notifier/purchasenotifier.dart';
import 'package:purchaseorders2/services/server_time_service.dart';
import '../../models/po/shippingandbillingaddress.dart';

class AddressFields {
  static Widget buildExpectedDeliveryDateField({
    required PurchaseOrderNotifier notifier,
    required DateTime? Function(String) parseDate,
    required bool Function(String) shouldHandleTap,
    required InputDecoration Function(String, {bool isEditable})
    inputDecoration,
  }) {
    return Padding(
      padding: EdgeInsets.zero,
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
                        ServerTimeService.now)
                  : ServerTimeService.now;

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

                Form.of(context).validate();
              }
            },
            child: AbsorbPointer(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
                child: TextFormField(
                  controller: notifier.expectedDeliveryDateController,
                  readOnly: true,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Expected delivery date is required';
                    }
                    return null;
                  },
                  decoration: inputDecoration("Expected Date").copyWith(
                    errorStyle: const TextStyle(height: 0, fontSize: 0),

                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    hintText: '',

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
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
    return _ShippingAddressField(notifier: notifier);
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
              color: const Color.fromARGB(255, 74, 122, 227),
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

// Shipping Address Field with LocationDropdown behavior
class _ShippingAddressField extends StatefulWidget {
  final PurchaseOrderNotifier notifier;

  const _ShippingAddressField({required this.notifier});

  @override
  State<_ShippingAddressField> createState() => _ShippingAddressFieldState();
}

class _ShippingAddressFieldState extends State<_ShippingAddressField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  List<ShippingAddress> _addresses = [];
  List<ShippingAddress> _filteredAddresses = [];
  bool _defaultSet = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.notifier.shippingController.text,
    );

    _controller.addListener(() {
      if (_controller.text != widget.notifier.shippingController.text) {
        widget.notifier.shippingController.text = _controller.text;
      }
    });

    _focusNode.addListener(() {
      widget.notifier.setLocationFocus(_focusNode.hasFocus);

      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _setDefaultIfNeeded() {
    if (_addresses.isNotEmpty && !_defaultSet && _controller.text.isEmpty) {
      final first = _addresses[0];
      _controller.text = first.address;
      widget.notifier.setSelectedshippingaddress(first.shippingId);
      widget.notifier.shippingController.text = first.address;
      _filteredAddresses = List.from(_addresses);
      _defaultSet = true;
    }
  }

  void _search(String value) {
    final q = value.toLowerCase();

    if (q.isEmpty) {
      _filteredAddresses = List.from(_addresses);
    } else {
      _filteredAddresses = _addresses.where((address) {
        return address.address.toLowerCase().contains(q);
      }).toList();
    }

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);

    if (_filteredAddresses.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 60),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredAddresses.length,
                itemBuilder: (_, i) {
                  final address = _filteredAddresses[i];

                  return ListTile(
                    title: Text(address.address),
                    onTap: () {
                      final selectedText = address.address;

                      widget.notifier.setSelectedshippingaddress(
                        address.shippingId,
                      );

                      widget.notifier.shippingController.value =
                          TextEditingValue(
                            text: selectedText,
                            selection: TextSelection.collapsed(
                              offset: selectedText.length,
                            ),
                          );

                      _controller.value = TextEditingValue(
                        text: selectedText,
                        selection: TextSelection.collapsed(
                          offset: selectedText.length,
                        ),
                      );

                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    _addresses = widget.notifier.shippingAddress;

    // Initialize filtered addresses if empty
    if (_filteredAddresses.isEmpty && _addresses.isNotEmpty) {
      _filteredAddresses = List.from(_addresses);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDefaultIfNeeded();
    });

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Shipping Address',
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
                  color: const Color.fromARGB(255, 74, 122, 227),
                  width: 2.0,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              isDense: false,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        _controller.clear();
                        widget.notifier.setSelectedshippingaddress('');
                        widget.notifier.shippingController.clear();
                        _filteredAddresses = List.from(_addresses);
                        _showOverlay();
                      },
                    )
                  : null,
              errorStyle: TextStyle(fontSize: 12, color: Colors.red[700]),
            ),
            onTap: () {
              _filteredAddresses = List.from(_addresses);
              _showOverlay();
            },
            onChanged: (value) {
              _search(value);

              widget.notifier.setSelectedshippingaddress('');
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a shipping address';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
