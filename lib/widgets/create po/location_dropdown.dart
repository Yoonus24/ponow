import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../providers/po_provider.dart';
import '../../notifier/purchasenotifier.dart';

class LocationDropdown extends StatefulWidget {
  final InputDecoration Function(String, {bool isEditable}) inputDecoration;

  const LocationDropdown({super.key, required this.inputDecoration});

  @override
  State<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<LocationDropdown> {
  late FocusNode _focusNode;

  static const Color activeBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      final notifier = Provider.of<PurchaseOrderNotifier>(
        context,
        listen: false,
      );
      notifier.setLocationFocus(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poProvider = context.watch<POProvider>();
    final notifier = context.watch<PurchaseOrderNotifier>();

    final branches = List.of(poProvider.branches);

    int? selectedIndex;
    if (notifier.selectedLocation != null &&
        notifier.selectedLocation!.isNotEmpty) {
      final i = branches.indexWhere(
        (b) => b.location == notifier.selectedLocation,
      );
      if (i >= 0) selectedIndex = i;
    }

    final hasValue = selectedIndex != null;
    final isFocused = notifier.isLocationFocused;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
      child: DropdownButtonFormField2<int>(
        value: selectedIndex,
        isExpanded: true,
        isDense: true,
        focusNode: _focusNode,

        decoration: widget
            .inputDecoration("Location")
            .copyWith(
              filled: true,
              fillColor: Colors.white,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: '',
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              suffixIcon: hasValue
                  ? Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        splashRadius: 20,
                        onPressed: () {
                          notifier.clearLocation();
                          _focusNode.unfocus();
                        },
                      ),
                    )
                  : Padding(
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

        iconStyleData: const IconStyleData(icon: SizedBox.shrink()),

        dropdownStyleData: DropdownStyleData(
          maxHeight: 220,
          elevation: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
        ),

        items: branches.asMap().entries.map<DropdownMenuItem<int>>((entry) {
          final index = entry.key;
          final branch = entry.value;

          return DropdownMenuItem<int>(
            value: index,
            child: Text(
              '${branch.branchName} (${branch.location})',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          );
        }).toList(),

        onChanged: (index) {
          if (index == null) return;

          final selectedBranch = branches[index];

          notifier.setLocation(
            location: selectedBranch.location,
            locationName: selectedBranch.branchName,
          );

          _focusNode.unfocus();
        },

        validator: (value) {
          if (value == null) {
            return 'Please select a location';
          }
          return null;
        },
      ),
    );
  }
}
