import 'package:flutter/material.dart';

class OutgoingColumnFilter extends StatefulWidget {
  final List<String> allColumns;
  final Map<String, bool> columnVisibility;
  final Function(List<String>, Map<String, bool>) onApply;

  const OutgoingColumnFilter({
    super.key,
    required this.allColumns,
    required this.columnVisibility,
    required this.onApply,
  });

  @override
  State<OutgoingColumnFilter> createState() => _OutgoingColumnFilterState();
}

class _OutgoingColumnFilterState extends State<OutgoingColumnFilter> {
  late ValueNotifier<ColumnManager> _columnNotifier;

  @override
  void initState() {
    super.initState();
    final columnVisibility = Map<String, bool>.from(widget.columnVisibility);
    for (var column in widget.allColumns) {
      columnVisibility.putIfAbsent(column, () => true);
    }
    _columnNotifier = ValueNotifier(
      ColumnManager(List.from(widget.allColumns), columnVisibility),
    );
  }

  @override
  void dispose() {
    _columnNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isSmallScreen ? screenWidth - 32 : 450,
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 550),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Column Filter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Sub header with drag info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag to reorder columns',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final newManager = ColumnManager(
                          List.from(_columnNotifier.value.columns),
                          Map.from(_columnNotifier.value.columnVisibility),
                        );
                        for (var col in newManager.columns) {
                          newManager.columnVisibility[col] = true;
                        }
                        _columnNotifier.value = newManager;
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Show All',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Column list
            Expanded(
              child: ValueListenableBuilder<ColumnManager>(
                valueListenable: _columnNotifier,
                builder: (context, manager, _) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    buildDefaultDragHandles: false,
                    onReorder: (int oldIndex, int newIndex) {
                      final newManager = ColumnManager(
                        List.from(manager.columns),
                        Map.from(manager.columnVisibility),
                      );
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = newManager.columns.removeAt(oldIndex);
                      newManager.columns.insert(newIndex, item);
                      _columnNotifier.value = newManager;
                    },
                    itemCount: manager.columns.length,
                    itemBuilder: (context, index) {
                      final column = manager.columns[index];
                      final isVisible =
                          manager.columnVisibility[column] ?? true;

                      return Container(
                        key: ValueKey(column),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            column,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isVisible
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isVisible ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          trailing: Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: isVisible,
                              activeColor: Colors.blueAccent,
                              checkColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade400),
                              onChanged: (bool? value) {
                                final newManager = ColumnManager(
                                  List.from(manager.columns),
                                  Map.from(manager.columnVisibility),
                                );
                                newManager.columnVisibility[column] =
                                    value ?? true;
                                _columnNotifier.value = newManager;
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final manager = _columnNotifier.value;
                      widget.onApply(manager.columns, manager.columnVisibility);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColumnManager {
  final List<String> columns;
  final Map<String, bool> columnVisibility;

  ColumnManager(this.columns, this.columnVisibility);
}
