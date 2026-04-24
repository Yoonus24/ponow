// ignore_for_file: unused_element

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/dio_client.dart'; // Import your DioClient

class PurchaseOrderService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>> fetchPurchaseOrder(
    String purchaseOrderId,
  ) async {
    final response = await _dio.get('/purchaseorders/$purchaseOrderId');

    final dynamic decoded = response.data;

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected PO format: expected JSON object');
  }

  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final response = await _dio.get('/pobusiness/');

    final List<dynamic> data = response.data;

    if (data.isNotEmpty && data.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data.first);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchVendorByName(String vendorName) async {
    if (vendorName.trim().isEmpty) return {};

    final response = await _dio.get(
      '/vendors/exact-name/',
      queryParameters: {'name': vendorName},
    );

    final dynamic decoded = response.data;

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is List && decoded.isNotEmpty) {
      return Map<String, dynamic>.from(decoded.first);
    }

    return {};
  }

  Future<Map<String, dynamic>> fetchShippingAddress() async {
    try {
      // Using the correct URL as specified
      final response = await DioClient.dio.get(
        '/purchasetestapi/poshippingaddress/',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first);
        }

        if (data is Map<String, dynamic>) {
          return data;
        }
      }

      return {};
    } catch (e) {
      print('Error fetching shipping address: $e');
      return {};
    }
  }

  Future<File> generatePurchaseOrderPdf(String purchaseOrderId) async {
    if (purchaseOrderId.trim().isEmpty) {
      throw Exception('purchaseOrderId is empty');
    }

    final Map<String, dynamic> poData = await fetchPurchaseOrder(
      purchaseOrderId,
    );

    final Map<String, dynamic> businessData = await fetchBusinessDetails();
    final Map<String, dynamic> shippingData = await fetchShippingAddress();

    final vendorName = (poData['vendorName'] ?? '').toString();
    final vendorData = await fetchVendorByName(vendorName);

    final List<dynamic> itemsRaw = (poData['items'] is List)
        ? List<dynamic>.from(poData['items'])
        : <dynamic>[];

    pw.MemoryImage? logoImage;
    try {
      logoImage = await _tryLoadLogoImage('assets/bestmummy.jpg');
    } catch (_) {
      logoImage = null;
    }

    String safeFormatDate(String? dateValue) {
      if (dateValue == null) return 'N/A';
      try {
        final dt = DateTime.parse(dateValue);
        return DateFormat('dd-MM-yyyy').format(dt);
      } catch (_) {
        return dateValue;
      }
    }

    final formattedOrderDate =
        (poData['orderDate'] != null &&
            poData['orderDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(poData['orderDate'].toString())
        : 'N/A';

    final poDate =
        (poData['orderDate'] != null &&
            poData['orderDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(poData['orderDate'].toString())
        : 'N/A';

    final dueDate =
        (poData['expectedDeliveryDate'] != null &&
            poData['expectedDeliveryDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(poData['expectedDeliveryDate'].toString())
        : 'N/A';

    final pendingOrderAmount = _safeNum(poData['pendingOrderAmount']);
    final amountInWords = _amountInWords(pendingOrderAmount);

    // Calculate totals from items
    final subtotal = _calculateSubtotal(itemsRaw);
    final totalTax = _calculateTotalTax(itemsRaw);
    final totalAmount = subtotal + totalTax;
    final cgstAmount = totalTax / 2;
    final sgstAmount = totalTax / 2;
    final taxPercentage = _getTaxPercentage(itemsRaw);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return <pw.Widget>[
            // Header Section - Matching sample PDF format
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo
                logoImage != null
                    ? pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    : pw.SizedBox(width: 80),

                pw.SizedBox(width: 10),

                // Company Details
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Purchase Order',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      // pw.SizedBox(height: 4),
                      pw.Text(
                        businessData['companyName']?.toString() ??
                            'Best Mummy Sweet & Cakes',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _joinNonEmpty([
                          businessData['address1']?.toString() ??
                              'No.72, Salai Bazar',
                          businessData['address2']?.toString(),
                        ]),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Tel.No: ${businessData['phoneNo']?.toString() ?? '6385576161'}',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'E-Mail: ${businessData['emailId']?.toString() ?? 'purchase@bestmummy.co.in'}',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'GSTIN: ${businessData['gstIn']?.toString() ?? '33AATFB4124B1ZW'}',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vendor Details, Shipping Address, PO Details - Matching sample PDF exactly
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor(0, 0, 0.5), // Dark blue background
                  ),
                  children: [
                    _tableHeaderCell('Vendor Details'),
                    _tableHeaderCell('Shipping Address'),
                    _tableHeaderCell('PO Details'),
                  ],
                ),
                // Content Row
                pw.TableRow(
                  children: [
                    // Vendor Details
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _joinNonEmpty([
                          poData['vendorName']?.toString() ??
                              vendorData['name']?.toString() ??
                              'Unknown Vendor',
                          'GSTIN: ${poData['gstNumber']?.toString() ?? vendorData['gstIn']?.toString() ?? ''}',
                          'Address: ${poData['address']?.toString() ?? vendorData['address']?.toString() ?? 'KHAJINI PLAZA, RAMANATHAPURAM'}',
                          'City: ${poData['city']?.toString() ?? vendorData['city']?.toString() ?? 'Ramanathapuram'}',
                          'State: ${poData['state']?.toString() ?? vendorData['state']?.toString() ?? 'Tamil Nadu'}',
                          'Country: ${poData['country']?.toString() ?? vendorData['country']?.toString() ?? 'India'}',
                          'Email: ${poData['contactpersonEmail']?.toString() ?? vendorData['emailId']?.toString() ?? ''}',
                          'Phone: ${poData['vendorContact']?.toString() ?? vendorData['phoneNo']?.toString() ?? '8190032417'}',
                        ], separator: '\n'),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),

                    // Shipping Address
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _joinNonEmpty([
                          'Shipping Address: ${shippingData['address']?.toString() ?? poData['shippingAddress']?.toString() ?? 'No: 95 B, GODOWN, DEVIATTINAM, RAMANATHAPURAM'}',
                          shippingData['address2']?.toString(),
                          shippingData['city']?.toString(),
                          shippingData['state']?.toString(),
                          shippingData['pincode']?.toString(),
                        ], separator: '\n'),
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),

                    // PO Details
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'PO No: ${poData['poNumber']?.toString() ?? poData['randomId']?.toString() ?? 'PO0546'}\n'
                        'PO Date: $poDate\n'
                        'Due Date: $dueDate\n'
                        'Payment Terms: ${(poData['paymentTerms'] != null && poData['paymentTerms'].toString().trim().isNotEmpty) ? poData['paymentTerms'].toString() : '7 days'}\n'
                        'Status: ${poData['poStatus']?.toString() ?? 'Approved'}\n'
                        'Currency: ${poData['currency']?.toString() ?? 'INR'}',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // pw.SizedBox(height: 16),

            // Items Table - Matching sample PDF exactly
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: pw.FlexColumnWidth(0.5), // S.No
                1: pw.FlexColumnWidth(2.5), // Description
                2: pw.FlexColumnWidth(1), // HsnCode
                3: pw.FlexColumnWidth(0.8), // No of Packing
                4: pw.FlexColumnWidth(0.8), // Qty
                5: pw.FlexColumnWidth(0.8), // Po Qty
                6: pw.FlexColumnWidth(1), // Unit Price
                7: pw.FlexColumnWidth(0.8), // Tax
                8: pw.FlexColumnWidth(1.2), // Amount
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor(0, 0, 0.5)),
                  children: [
                    _tableHeaderCell('S.No'),
                    _tableHeaderCell('Description'),
                    _tableHeaderCell('HsnCode'),
                    _tableHeaderCell('No of Packing'),
                    _tableHeaderCell('Qty'),
                    _tableHeaderCell('Po Qty'),
                    _tableHeaderCell('Unit Price'),
                    _tableHeaderCell('Tax'),
                    _tableHeaderCell('Amount'),
                  ],
                ),
                // Data Rows
                ..._buildItemRows(itemsRaw),
              ],
            ),

            // pw.SizedBox(height: 12),

            // Totals Section - Matching sample PDF format
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                _twoCellRow('Total Amount', _safeFixedString(subtotal)),
                _twoCellRow(
                  'Total Discount',
                  _safeFixedString(_calculateTotalDiscount(itemsRaw)),
                ),
                _twoCellRow(
                  'CGST @${taxPercentage}%',
                  _safeFixedString(cgstAmount),
                ),
                _twoCellRow(
                  'SGST @${taxPercentage}%',
                  _safeFixedString(sgstAmount),
                ),
                _twoCellRow(
                  'Round Off Amount',
                  _safeFixedString(_calculateRoundOff(totalAmount)),
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Amount In Words: $amountInWords',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Total [Including Tax]: ${_safeFixedString(totalAmount)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // pw.SizedBox(height: 16),

            // Terms & Conditions
            pw.Text(
              'Terms & Conditions',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            // pw.SizedBox(height: 6),
            ..._buildTermsAndConditions(poData['termsAndConditions']),

            pw.SizedBox(height: 16),

            // Declaration
            pw.Text(
              'Declaration:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            // pw.SizedBox(height: 6),
            pw.Text(
              poData['declaration']?.toString() ??
                  'We declare that this invoice shows the actual price of the described items and that all particulars are true and correct.',
              style: pw.TextStyle(fontSize: 10),
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 9)),
                pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save the PDF to a temporary directory
    final output = await getTemporaryDirectory();
    final filename =
        'purchase_order_${poData['poNumber']?.toString() ?? purchaseOrderId}.pdf';
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Helper methods
  double _calculateSubtotal(List<dynamic> items) {
    double total = 0;
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['pendingTotalPrice'] ?? item['totalPrice'] ?? 0);
      }
    }
    return total;
  }

  double _calculateTotalTax(List<dynamic> items) {
    double total = 0;
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['pendingTaxAmount'] ?? item['taxAmount'] ?? 0);
      }
    }
    return total;
  }

  double _calculateTotalDiscount(List<dynamic> items) {
    double total = 0;
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['discountAmount'] ?? 0);
      }
    }
    return total;
  }

  double _calculateRoundOff(double amount) {
    double rounded = (amount * 100).roundToDouble() / 100;
    double roundOff = rounded - amount;
    return double.parse(roundOff.toStringAsFixed(2));
  }

  double _getTaxPercentage(List<dynamic> items) {
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        final tax = _safeNum(item['taxPercentage']);
        if (tax > 0) {
          return tax;
        }
      }
    }
    return 0;
  }

  Future<pw.MemoryImage?> _tryLoadLogoImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }

  pw.Widget _tableHeaderCell(String title) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.TableRow _twoCellRow(String left, String right) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(left, style: pw.TextStyle(fontSize: 10)),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(right, style: pw.TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  List<pw.TableRow> _buildItemRows(List<dynamic> items) {
    if (items.isEmpty) {
      return [
        pw.TableRow(
          children: List.generate(
            9,
            (_) => pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('No items'),
            ),
          ),
        ),
      ];
    }

    return items.map<pw.TableRow>((item) {
      final index = (items.indexOf(item) + 1).toString();
      final desc =
          item?['itemName']?.toString() ??
          item?['description']?.toString() ??
          '';
      final hsn =
          item?['hsncode']?.toString() ?? item?['hsnCode']?.toString() ?? '';
      final noOfPacking = _safeFixedString(
        item?['pendingCount'] ?? item?['noOfPacking'] ?? item?['quantity'] ?? 0,
      );
      final qty = _safeFixedString(
        item?['pendingQuantity'] ?? item?['quantity'] ?? 0,
      );
      final poQty = _safeFixedString(
        item?['pendingTotalQuantity'] ?? item?['poQty'] ?? 0,
      );
      final unitPrice = _safeFixedString(
        item?['newPrice'] ?? item?['unitPrice'] ?? item?['price'] ?? 0,
      );
      final tax = '${_safeNum(item?['taxPercentage'] ?? item?['tax'] ?? 0)}%';
      final amount = _safeFixedString(
        item?['pendingTotalPrice'] ?? item?['totalPrice'] ?? 0,
      );

      return pw.TableRow(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(index, style: pw.TextStyle(fontSize: 9)),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(desc, style: pw.TextStyle(fontSize: 9)),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(hsn, style: pw.TextStyle(fontSize: 9)),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              noOfPacking,
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              qty,
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              poQty,
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              unitPrice,
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              tax,
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              amount,
              style: pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    }).toList();
  }

  String _safeFixedString(dynamic value) {
    final num v = _safeNum(value);
    return v.toStringAsFixed(2);
  }

  double _safeNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (_) {
      return 0.0;
    }
  }

  List<pw.Widget> _buildTermsAndConditions(dynamic terms) {
    if (terms is List && terms.isNotEmpty) {
      return terms.map<pw.Widget>((term) {
        return pw.Text(
          '- ${term?.toString() ?? ''}',
          style: pw.TextStyle(fontSize: 9),
        );
      }).toList();
    } else {
      return [
        pw.Text(
          '1. Please quote our Purchase Order No. in your Delivery Note.',
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          '2. Defective and excess quantity will not be accepted.',
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          '3. Subject to Ramanathapuram Jurisdiction Only.',
          style: pw.TextStyle(fontSize: 9),
        ),
      ];
    }
  }

  String _amountInWords(double amount) {
    if (amount <= 0) return 'Zero only';
    final whole = amount.floor();
    final fraction = ((amount - whole) * 100).round();
    final wholeWords = _convertNumberToWords(whole);
    final fractionWords = fraction > 0
        ? ' and ${_convertNumberToWords(fraction)} paise'
        : '';
    final capitalized = wholeWords.isNotEmpty
        ? wholeWords[0].toUpperCase() + wholeWords.substring(1)
        : 'Zero';
    return '$capitalized$fractionWords only';
  }

  String _convertNumberToWords(int number) {
    if (number == 0) return 'zero';
    final units = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
    ];
    final teens = [
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    final tens = [
      '',
      'ten',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    String threeDigits(int n) {
      String str = '';
      if (n >= 100) {
        str += '${units[n ~/ 100]} hundred';
        if (n % 100 != 0) str += ' ';
      }
      final rem = n % 100;
      if (rem >= 20) {
        str += tens[rem ~/ 10];
        if (rem % 10 != 0) str += ' ${units[rem % 10]}';
      } else if (rem >= 10) {
        str += teens[rem - 10];
      } else if (rem > 0) {
        str += units[rem];
      }
      return str;
    }

    final parts = <String>[];
    if (number >= 10000000) {
      final crore = number ~/ 10000000;
      parts.add('${threeDigits(crore)} crore');
      number = number % 10000000;
    }
    if (number >= 100000) {
      final lakh = number ~/ 100000;
      parts.add('${threeDigits(lakh)} lakh');
      number = number % 100000;
    }
    if (number >= 1000) {
      final thousand = number ~/ 1000;
      parts.add('${threeDigits(thousand)} thousand');
      number = number % 1000;
    }
    if (number > 0) {
      parts.add(threeDigits(number));
    }
    return parts.join(' ').trim();
  }

  String _joinNonEmpty(List<String?> values, {String separator = ', '}) {
    final List<String> nonEmpty = [];
    for (var s in values) {
      if (s != null) {
        final trimmed = s.toString().trim();
        if (trimmed.isNotEmpty && trimmed != 'null') nonEmpty.add(trimmed);
      }
    }
    return nonEmpty.join(separator);
  }
}
