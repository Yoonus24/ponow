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

  // Hardcoded blue color for focused/active state
  static const Color activeBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Update notifier when focus changes
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

    final branches = poProvider.branches;
    final selectedLocation = notifier.selectedLocation;
    final hasValue = selectedLocation != null && selectedLocation.isNotEmpty;
    final isFocused = notifier.isLocationFocused;

    final iconColor = hasValue
        ? Colors.transparent
        : isFocused
        ? activeBlue
        : Colors.grey.shade600;

    return DropdownButtonFormField2<String>(
      value: selectedLocation,
      isExpanded: true,
      isDense: true,
      focusNode: _focusNode,

      decoration: widget
          .inputDecoration('Location')
          .copyWith(
            labelText: 'Location',

            labelStyle: const TextStyle(color: Colors.black54, fontSize: 15),

            floatingLabelStyle: TextStyle(
              color: isFocused ? activeBlue : Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),

            floatingLabelBehavior: FloatingLabelBehavior.auto,

            hintText: 'Select Location',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),

            contentPadding: const EdgeInsets.fromLTRB(12, 12, 44, 8),

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: activeBlue, width: 2),
            ),

            suffixIcon: hasValue
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    splashRadius: 20,
                    color: isFocused ? activeBlue : Colors.grey.shade700,
                    onPressed: () {
                      notifier.clearLocation();
                      _focusNode.unfocus();
                    },
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),

      iconStyleData: IconStyleData(
        icon: hasValue
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: iconColor,
                  size: 22,
                ),
              ),
        iconSize: 22,
      ),

      dropdownStyleData: DropdownStyleData(
        maxHeight: 260,
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        offset: const Offset(0, -4),
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(40),
          thickness: WidgetStateProperty.all(6),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        openInterval: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),

      items: branches.map((branch) {
        final displayText = '${branch.branchName} (${branch.location})';

        return DropdownMenuItem<String>(
          value: branch.location,
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        );
      }).toList(),

      onChanged: (value) {
        if (value == null) return;

        final selectedBranch = branches.firstWhere(
          (b) => b.location == value,
          orElse: () => branches.first,
        );

        notifier.setLocation(
          location: selectedBranch.location,
          locationName: selectedBranch.branchName,
        );

        _focusNode.unfocus();
      },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a location';
        }
        return null;
      },
    );
  }
}
