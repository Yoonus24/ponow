import 'package:flutter/material.dart';

// ------------------ COLUMN WIDTHS ------------------

const double colItemName = 180; // Wider
const double colUOM = 70;
const double colOrdered = 70;
const double colReceived = 80;
const double colFree = 60;
const double colRate = 80;
const double colBefTax = 85;
const double colAfTax = 85;
const double colExpiry = 90;
const double colFinalPrice = 90;

// ------------------ CONSTANT HEIGHT ------------------

const double rowHeight = 48.0;

// ------------------ HEADER CELL ------------------

class TableHeaderCell extends StatelessWidget {
  final String text;
  final double width;
  final Alignment alignment; // ⭐ NEW

  const TableHeaderCell(
    this.text, {
    super.key,
    required this.width,
    this.alignment = Alignment.center, // ⭐ default center
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.grey[200],
      child: Align(
        alignment: alignment, // ⭐ apply alignment
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class CustomTableCell extends StatelessWidget {
  final String text;
  final double width;
  final bool isEvenRow;
  final Alignment alignment;

  const CustomTableCell({
    super.key,
    required this.text,
    required this.width,
    this.isEvenRow = false,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: rowHeight,
      decoration: const BoxDecoration(
        color: Colors.white, // FULL WHITE BACKGROUND
      ),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

// ------------------ TEXT FIELD CELL ------------------

class CustomTableTextFieldCell extends StatelessWidget {
  final Widget child;
  final double width;
  final bool isEvenRow;

  const CustomTableTextFieldCell({
    super.key,
    required this.child,
    required this.width,
    this.isEvenRow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: rowHeight,
      decoration: BoxDecoration(
        color: isEvenRow ? Colors.grey[50] : Colors.white,
      ),
      child: Center(child: child),
    );
  }
}

// ------------------ EXAMPLE TABLE ------------------

class ItemTableExample extends StatelessWidget {
  const ItemTableExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ----- HEADER ROW -----
        Row(
          children: const [
            TableHeaderCell("Item Name", width: colItemName),
            TableHeaderCell("UOM", width: colUOM),
            TableHeaderCell("Ordered", width: colOrdered),
            TableHeaderCell("Received", width: colReceived),
            TableHeaderCell("Free", width: colFree),
            TableHeaderCell("Rate", width: colRate),
            TableHeaderCell("Before Tax", width: colBefTax),
            TableHeaderCell("After Tax", width: colAfTax),
            TableHeaderCell("Expiry", width: colExpiry),
            TableHeaderCell("Final Price", width: colFinalPrice),
          ],
        ),

        // ----- SAMPLE ROW -----
        Row(
          children: const [
            CustomTableCell(
              text: "Paracetamol 500mg Tablet",
              width: colItemName,
            ),
            CustomTableCell(text: "TAB", width: colUOM),
            CustomTableCell(text: "100", width: colOrdered),
            CustomTableCell(text: "100", width: colReceived),
            CustomTableCell(text: "0", width: colFree),
            CustomTableCell(text: "2.50", width: colRate),
            CustomTableCell(text: "250.00", width: colBefTax),
            CustomTableCell(text: "275.00", width: colAfTax),
            CustomTableCell(text: "12/2025", width: colExpiry),
            CustomTableCell(text: "275.00", width: colFinalPrice),
          ],
        ),
      ],
    );
  }
}
