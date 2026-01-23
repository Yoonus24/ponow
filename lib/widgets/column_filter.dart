import 'package:flutter/material.dart';

class ColumnFilterDialog extends StatefulWidget {
  final List<String> columns;
  final Map<String, bool> columnVisibility;
  final Function(List<String>, Map<String, bool>) onApply;

  const ColumnFilterDialog({
    super.key,
    required this.columns,
    required this.columnVisibility,
    required this.onApply,
  });

  @override
  _ColumnFilterDialogState createState() => _ColumnFilterDialogState();
}

class _ColumnFilterDialogState extends State<ColumnFilterDialog> {
  late ValueNotifier<List<String>> columnsNotifier;
  late ValueNotifier<Map<String, bool>> visibilityNotifier;

  @override
  void initState() {
    super.initState();
    columnsNotifier = ValueNotifier<List<String>>(List.from(widget.columns));
    visibilityNotifier = ValueNotifier<Map<String, bool>>(Map.from(widget.columnVisibility));
  }

  @override
  void dispose() {
    columnsNotifier.dispose();
    visibilityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Reorder Columns'),
      content: SizedBox(
        width: double.maxFinite,
        child: ValueListenableBuilder<List<String>>(
          valueListenable: columnsNotifier,
          builder: (context, columns, _) {
            return ValueListenableBuilder<Map<String, bool>>(
              valueListenable: visibilityNotifier,
              builder: (context, columnVisibility, _) {
                return ReorderableListView(
                  shrinkWrap: true,
                  onReorder: (int oldIndex, int newIndex) {
                    final newColumns = List<String>.from(columns);
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = newColumns.removeAt(oldIndex);
                    newColumns.insert(newIndex, item);
                    columnsNotifier.value = newColumns;
                  },
                  children: [
                    for (int index = 0; index < columns.length; index++)
                      ListTile(
                        key: ValueKey(columns[index]),
                        title: Text(columns[index]),
                        trailing: Checkbox(
                          value: columnVisibility[columns[index]],
                          onChanged: (bool? value) {
                            final newVisibility = Map<String, bool>.from(columnVisibility);
                            newVisibility[columns[index]] = value ?? true;
                            visibilityNotifier.value = newVisibility;
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
       TextButton(
          onPressed: () {
            widget.onApply(columnsNotifier.value, visibilityNotifier.value);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}