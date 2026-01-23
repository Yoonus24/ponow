import 'package:flutter/material.dart';

class TableHeaderCell extends StatelessWidget {
  final String label;
  final double flex;

  const TableHeaderCell(this.label, {this.flex = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: flex,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class CustomTableCell extends StatelessWidget {
  final String text;
  final double flex;

  const CustomTableCell({required this.text, this.flex = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: flex,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// ===============================================
/// ⭐ MULTI-LINE TABLE CELL FOR ITEM NAME COLUMN ⭐
/// ===============================================
class MultiLineTableCell extends StatelessWidget {
  final String text;
  final double flex;

  const MultiLineTableCell({required this.text, this.flex = 130});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: flex,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        maxLines: 2, // ⭐ Allow 2 lines
        softWrap: true, // ⭐ Wrap to next line
        overflow: TextOverflow.visible, // ⭐ No ellipsis
      ),
    );
  }
}
