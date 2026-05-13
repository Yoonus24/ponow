import 'package:flutter/material.dart';

class TableHeaderCell extends StatelessWidget {
  final String label;
  final double flex;

  const TableHeaderCell(this.label, {super.key, this.flex = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: flex,

      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),

      alignment: Alignment.centerLeft,

      child: Text(
        label,

        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          height: 1,
        ),
      ),
    );
  }
}

class CustomTableCell extends StatelessWidget {
  final String text;
  final double flex;

  const CustomTableCell({super.key, required this.text, this.flex = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),

      width: flex,

      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),

      alignment: Alignment.center,

      child: Text(
        text,

        style: const TextStyle(fontSize: 13, height: 0.9),

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

        textAlign: TextAlign.center,
      ),
    );
  }
}

class MultiLineTableCell extends StatelessWidget {
  final String text;
  final double flex;

  const MultiLineTableCell({super.key, required this.text, this.flex = 130});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),

      width: flex,

      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),

      alignment: Alignment.centerLeft,

      child: Text(
        text,

        style: const TextStyle(fontSize: 13, height: 0.9),

        maxLines: null,

        softWrap: true,

        overflow: TextOverflow.visible,
      ),
    );
  }
}
