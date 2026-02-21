// purchaseorders2/pdfs/approved_pdf.dart
// ignore_for_file: unused_element

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class PurchaseOrderService {
  static const String baseUrl = 'http://192.168.29.184:8000/nextjstestapi';
  static const String businessUrl = 'http://yenerp.com/purchaseapi/pobusiness/';
  static const String vendorBaseUrl =
      'http://192.168.29.184:8000/nextjstestapi/vendors/exact-name/';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<Map<String, dynamic>> fetchPurchaseOrder(
    String purchaseOrderId,
  ) async {
    final uri = '$baseUrl/purchaseorders/$purchaseOrderId';

    final response = await _dio.get(
      uri,
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );

    final dynamic decoded = response.data;

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected PO format: expected JSON object');
  }

  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final response = await _dio.get(
      businessUrl,
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );

    final List<dynamic> data = response.data;

    if (data.isNotEmpty && data.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data.first);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchVendorById(String vendorId) async {
    if (vendorId.trim().isEmpty) return {};

    final response = await _dio.get(
      '$vendorBaseUrl$vendorId',
      options: Options(receiveTimeout: const Duration(seconds: 30)),
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

  Future<File> generatePurchaseOrderPdf(String purchaseOrderId) async {
    if (purchaseOrderId.trim().isEmpty) {
      throw Exception('purchaseOrderId is empty');
    }

    final Map<String, dynamic> poData = await fetchPurchaseOrder(
      purchaseOrderId,
    );

    final Map<String, dynamic> businessData = await fetchBusinessDetails();

    final vendorId = (poData['vendorId'] ?? '').toString();
    final Map<String, dynamic> vendorData = await fetchVendorById(vendorId);

    final List<dynamic> itemsRaw = (poData['items'] is List)
        ? List<dynamic>.from(poData['items'])
        : <dynamic>[];

    pw.MemoryImage? logoImage;
    try {
      logoImage = await _tryLoadLogoImage('assets/bestmummy.png');
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
        (poData['poDate'] != null &&
            poData['poDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(poData['poDate'].toString())
        : 'N/A';

    final dueDate =
        (poData['dueDate'] != null &&
            poData['dueDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(poData['dueDate'].toString())
        : 'N/A';

    final pendingOrderAmount = _safeNum(poData['pendingOrderAmount']);
    final amountInWords = _amountInWords(pendingOrderAmount);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 10),
                        child: logoImage != null
                            ? pw.Container(
                                width: 60,
                                height: 60,
                                child: pw.Image(
                                  logoImage,
                                  fit: pw.BoxFit.contain,
                                ),
                              )
                            : pw.SizedBox(),
                      ),

                      pw.Padding(
                        padding: pw.EdgeInsets.only(left: 50),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Purchase Order',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor(0, 0, 128 / 255),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              businessData['companyName']?.toString() ?? '',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              _joinNonEmpty([
                                businessData['address1']?.toString(),
                                businessData['address2']?.toString(),
                              ]),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Tel.No: ${businessData['phoneNo'] ?? ''}',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'E-Mail: ${businessData['emailId'] ?? ''}',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'GSTIN: ${businessData['gstIn'] ?? ''}',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(0, 0, 128 / 255),
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Vendor Details',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Billing Address',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'PO Details',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          _joinNonEmpty([
                            poData['vendorName']?.toString(),
                            'GSTIN: ${poData['gstNumber'] ?? 'N/A'}',
                            poData['address']?.toString(),
                            poData['city']?.toString(),
                            poData['state']?.toString(),
                            poData['country']?.toString(),
                            'Email: ${poData['contactpersonEmail'] ?? 'Not Provided'}',
                            'Phone: ${poData['vendorContact'] ?? 'Not Provided'}',
                          ], separator: '\n'),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          _joinNonEmpty([
                            poData['billingAddress1']?.toString() ??
                                'No.40, Kenikarai',
                            poData['billingAddress2']?.toString() ??
                                'Ramanathapuram',
                          ]),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'PO No: ${poData['randomId']?.toString() ?? purchaseOrderId}\n'
                          'PO Date: $formattedOrderDate\n'
                          'Due Date: $dueDate\n'
                          'Payment Terms: ${poData['paymentTerms']?.toString() ?? 'N/A'}\n'
                          'Currency: ${poData['currency']?.toString() ?? 'INR'}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: pw.FlexColumnWidth(0.7),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(0.8),
                  5: pw.FlexColumnWidth(1),
                  6: pw.FlexColumnWidth(1),
                  7: pw.FlexColumnWidth(0.8),
                  8: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(0, 0, 128 / 255),
                    ),
                    children: [
                      _tableHeaderCell('S.No'),
                      _tableHeaderCell('Description'),
                      _tableHeaderCell('HsnCode'),
                      _tableHeaderCell('Count'),
                      _tableHeaderCell('Qty'),
                      _tableHeaderCell('Po Qty'),
                      _tableHeaderCell('Unit Price'),
                      _tableHeaderCell('Tax'),
                      _tableHeaderCell('Amount'),
                    ],
                  ),
                  ..._buildItemRows(itemsRaw),
                ],
              ),

              pw.Container(
                width: double.infinity,
                child: pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    _twoCellRow(
                      'Total Amount',
                      _safeFixedString(poData['pendingOrderAmount']),
                    ),

                    _twoCellRow(
                      'Total Discount',
                      _safeFixedString(poData['pendingDiscountAmount']),
                    ),

                    _twoCellRow(
                      'CGST @ ${_getTaxPercentage(itemsRaw)}%',
                      _safeFixedString(_calculateCgst(itemsRaw)),
                    ),

                    _twoCellRow(
                      'SGST @ ${_getTaxPercentage(itemsRaw)}%',
                      _safeFixedString(_calculateSgst(itemsRaw)),
                    ),

                    _twoCellRow(
                      'Round Off Amount',
                      _safeFixedString(poData['roundOffValue']),
                    ),

                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Amount in Words: $amountInWords',
                            style: pw.TextStyle(fontSize: 12),
                            textAlign: pw.TextAlign.right,
                            // same as others
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Total: ${_safeFixedString(poData['pendingOrderAmount'])}',
                            style: pw.TextStyle(fontSize: 12), // normal
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              pw.SizedBox(height: 16),

              // Terms & Conditions
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ..._buildTermsAndConditions(poData['termsAndConditions']),

              pw.SizedBox(height: 16),

              pw.Text(
                'Declaration:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                poData['declaration']?.toString() ??
                    'We declare that this invoice shows the actual price of the described items and that all particulars are true and correct.',
              ),

              pw.SizedBox(height: 20),

              // Footer row
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Center(child: pw.Text('Page 1 of 1'))),
                  pw.Text('Authorized Signatory'),
                ],
              ),
            ],
          );
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

  double _getTaxPercentage(List<dynamic> items) {
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        final tax = _safeNum(item['taxPercentage']);

        if (tax > 0) {
          return tax / 2; // CGST / SGST split
        }
      }
    }

    return 0;
  }

  double _calculateCgst(List<dynamic> items) {
    double total = 0;

    for (var item in items) {
      if (item is Map<String, dynamic>) {
        final tax = _safeNum(item['pendingTaxAmount']);
        total += tax / 2;
      }
    }

    return total;
  }

  double _calculateSgst(List<dynamic> items) {
    double total = 0;

    for (var item in items) {
      if (item is Map<String, dynamic>) {
        final tax = _safeNum(item['pendingTaxAmount']);
        total += tax / 2;
      }
    }

    return total;
  }

  Future<pw.MemoryImage?> _tryLoadLogoImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }

  // Create table header cell
  pw.Widget _tableHeaderCell(String title) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white)),
    );
  }

  pw.TableRow _twoCellRow(String left, String right) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(left, style: pw.TextStyle(fontSize: 12)),
          ),
        ),

        pw.Padding(
          padding: pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(right, style: pw.TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  List<pw.TableRow> _buildItemRows(List<dynamic> items) {
    if (items.isEmpty) {
      return [
        pw.TableRow(
          children: [
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text('No items'),
            ),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
            pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text('')),
          ],
        ),
      ];
    }

    return items.map<pw.TableRow>((item) {
      final si = (items.indexOf(item) + 1).toString();
      final desc = item?['itemName']?.toString() ?? '';
      final hsn = item?['hsncode']?.toString() ?? '';
      final count = _safeFixedString(item?['pendingCount']);
      final qty = _safeFixedString(item?['pendingQuantity']);
      final poQty = _safeFixedString(item?['pendingTotalQuantity']);
      final unitPrice = _safeFixedString(item?['newPrice']);
      final tax = item?['taxPercentage']?.toString() ?? '';
      final amount = _safeFixedString(item?['pendingTotalPrice']);

      return pw.TableRow(
        children: [
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(si)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(desc)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(hsn)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(count)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(qty)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(poQty)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(unitPrice)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(tax)),
          pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(amount)),
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

  dynamic _firstItemValue(List<dynamic> items, String key) {
    if (items.isEmpty) return 0;
    final first = items.first;
    if (first is Map<String, dynamic>) {
      return first[key];
    }
    return 0;
  }

  List<pw.Widget> _buildTermsAndConditions(dynamic terms) {
    if (terms is List && terms.isNotEmpty) {
      return terms.map<pw.Widget>((term) {
        return pw.Paragraph(text: '- ${term?.toString() ?? ''}');
      }).toList();
    } else {
      return [
        pw.Text(
          '1. Please quote our Purchase Order No. in your Delivery Note.',
        ),
        pw.Text('2. Defective and excess quantity will not be accepted.'),
        pw.Text('3. Subject to Ramanathapuram Jurisdiction Only.'),
      ];
    }
  }

  // Amount in words (simple implementation, supports rupee portion and paise)
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

  // Convert integer to words (supports upto crores)
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

  // Helper: join non-empty strings with separator
  String _joinNonEmpty(List<String?> values, {String separator = ', '}) {
    final List<String> nonEmpty = [];
    for (var s in values) {
      if (s != null) {
        final trimmed = s.toString().trim();
        if (trimmed.isNotEmpty) nonEmpty.add(trimmed);
      }
    }
    return nonEmpty.join(separator);
  }
}
