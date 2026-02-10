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

    final iconColor = hasValue
        ? Colors.transparent
        : isFocused
            ? activeBlue
            : Colors.grey.shade600;

    return DropdownButtonFormField2<int>(
      value: selectedIndex,

      isExpanded: true,
      isDense: true,
      focusNode: _focusNode,

      decoration: widget.inputDecoration('Location').copyWith(
        labelText: 'Location',
        labelStyle:
            const TextStyle(color: Colors.black54, fontSize: 15),
        floatingLabelStyle: TextStyle(
          color: isFocused ? activeBlue : Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintText: 'Select Location',
        hintStyle:
            TextStyle(color: Colors.grey.shade600, fontSize: 14),
        contentPadding:
            const EdgeInsets.fromLTRB(12, 12, 44, 8),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.shade400),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: activeBlue, width: 2),
        ),

        suffixIcon: hasValue
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 20,
                ),
                splashRadius: 20,
                color: isFocused
                    ? activeBlue
                    : Colors.grey.shade700,
                onPressed: () {
                  notifier.clearLocation();
                  _focusNode.unfocus();
                },
              )
            : null,
      ),

      iconStyleData: IconStyleData(
        icon: hasValue
            ? const SizedBox.shrink()
            : Padding(
                padding:
                    const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
      ),

      dropdownStyleData: DropdownStyleData(
        maxHeight: 260,
        elevation: 4,
        padding:
            const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),

      items: branches.asMap().entries.map((entry) {
        final index = entry.key;
        final branch = entry.value;

        return DropdownMenuItem<int>(
          value: index,
          child: Text(
            '${branch.branchName} (${branch.location})',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        );
      }).toList(),

      onChanged: (index) {
        if (index == null) return;

        final selectedBranch = branches[index];

        notifier.setLocation(
          location: selectedBranch.location,
          locationName:
              selectedBranch.branchName,
        );

        _focusNode.unfocus();
      },

      validator: (value) {
        if (value == null) {
          return 'Please select a location';
        }
        return null;
      },
    );
  }
}
