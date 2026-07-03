import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/po/po_provider.dart';
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
  final GlobalKey _fieldKey = GlobalKey();
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

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _filtered.dispose();
    super.dispose();
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

    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final list = _filtered.value;

    if (list.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 2,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset.zero,
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final b = list[i];
                    final isLast = i == list.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(
                            horizontal: 0,
                            vertical: -1,
                          ),
                          title: Text(
                            "${b.branchName} (${b.location})",
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            _controller.text =
                                "${b.branchName} (${b.location})";

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
                        ),
                        if (!isLast)
                          Divider(
                            height: 0,
                            thickness: 0.5,
                            color: Colors.grey.shade200,
                          ),
                      ],
                    );
                  },
                ),
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
          key: _fieldKey,
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
                          if (_focusNode.hasFocus) {
                            _showOverlay();
                          }
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
