import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/po_provider.dart';
import '../../notifier/purchasenotifier.dart';

class LocationDropdown extends StatefulWidget {
  final InputDecoration Function(String, {bool isEditable}) inputDecoration;

  const LocationDropdown({super.key, required this.inputDecoration});

  @override
  State<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<LocationDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final LayerLink _layerLink = LayerLink();

  final ValueNotifier<List<dynamic>> _filtered = ValueNotifier<List<dynamic>>(
    [],
  );

  List<dynamic> _branches = [];
  bool _defaultSet = false;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);

    _focusNode.addListener(() {
      notifier.setLocationFocus(_focusNode.hasFocus);

      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  void _setDefaultIfNeeded(PurchaseOrderNotifier notifier) {
    if (_branches.isNotEmpty && !_defaultSet) {
      final first = _branches[0];

      _controller.text = "${first.branchName} (${first.location})";

      notifier.setLocation(
        location: first.location,
        locationName: first.branchName,
      );

      _filtered.value = _branches;

      _defaultSet = true;
    }
  }

  void _search(String value) {
    final q = value.toLowerCase();

    if (q.isEmpty) {
      _filtered.value = _branches;
    } else {
      _filtered.value = _branches.where((b) {
        return b.branchName.toLowerCase().contains(q) ||
            b.location.toLowerCase().contains(q);
      }).toList();
    }

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final list = _filtered.value;

    if (list.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 60), // field height
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
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final b = list[i];

                  return ListTile(
                    title: Text("${b.branchName} (${b.location})"),
                    onTap: () {
                      _controller.text = "${b.branchName} (${b.location})";

                      final notifier = Provider.of<PurchaseOrderNotifier>(
                        context,
                        listen: false,
                      );

                      notifier.setLocation(
                        location: b.location,
                        locationName: b.branchName,
                      );

                      _focusNode.unfocus();
                      _removeOverlay();
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
    final notifier = context.watch<PurchaseOrderNotifier>();
    final poProvider = context.watch<POProvider>();

    _branches = poProvider.branches;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDefaultIfNeeded(notifier);
    });

    return CompositedTransformTarget(
      link: _layerLink,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60, maxHeight: 60),
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,

          decoration: widget
              .inputDecoration("Location")
              .copyWith(
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _controller.clear();
                          notifier.clearLocation();
                          _filtered.value = _branches;
                          _showOverlay();
                        },
                      )
                    : const Icon(Icons.arrow_drop_down),
              ),

          onTap: () {
            _filtered.value = _branches;
            _showOverlay();
          },

          onChanged: (value) {
            _search(value);
          },
        ),
      ),
    );
  }
}
