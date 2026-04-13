// grn_pdf.dart
// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:purchaseorders2/services/dio_client.dart';

class GRNPDF {
  final Dio _dio = DioClient.dio;
  static const String businessUrl = "/pobusiness/";
  static const String vendorBaseUrl = "/vendors/exact-name/";

  Future<Map<String, dynamic>> fetchGRN(String grnId) async {
    final response = await _dio.get('/grns/$grnId');

    final dynamic decoded = response.data;

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected GRN format: expected JSON object');
  }

  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final response = await _dio.get('/pobusiness/');
    final List<dynamic> data = response.data;

    if (data.isNotEmpty && data.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data.first);
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchVendorById(String vendorId) async {
    if (vendorId.trim().isEmpty) return {};

    final response = await _dio.get('/vendors/exact-name/$vendorId');

    final dynamic decoded = response.data;

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is List && decoded.isNotEmpty) {
      return Map<String, dynamic>.from(decoded.first);
    }

    return {};
  }

  Future<File> generateGRNPdf(String grnId) async {
    if (grnId.trim().isEmpty) {
      throw Exception('grnId is empty');
    }

    final Map<String, dynamic> grnData = await fetchGRN(grnId);
    final Map<String, dynamic> businessData = await fetchBusinessDetails();

    final vendorId = (grnData['vendorId'] ?? '').toString();
    final Map<String, dynamic> vendorData = await fetchVendorById(vendorId);

    final List<dynamic> itemsRaw = (grnData['itemDetails'] is List)
        ? List<dynamic>.from(grnData['itemDetails'])
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

    final formattedGRNDate =
        (grnData['grnDate'] != null &&
            grnData['grnDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(grnData['grnDate'].toString())
        : 'N/A';

    final poDate =
        (grnData['poDate'] != null &&
            grnData['poDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(grnData['poDate'].toString())
        : 'N/A';

    final invoiceDate =
        (grnData['invoiceDate'] != null &&
            grnData['invoiceDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(grnData['invoiceDate'].toString())
        : 'N/A';

    final totalReceivedAmount = _safeNum(grnData['totalReceivedAmount']);
    final amountInWords = _amountInWords(totalReceivedAmount);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return <pw.Widget>[
            // Header Section
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
                            'GOODS RECEIPT NOTE',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor(0, 0, 128 / 255),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            (businessData['companyName'] ?? '')
                                .toString()
                                .replaceAll(RegExp(r'[^\x00-\x7F]'), ''),
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

            // Vendor/Billing/GRN Details Table
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
                        'GRN Details',
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
                          grnData['vendorName']?.toString(),
                          'GSTIN: ${grnData['gstNumber'] ?? 'N/A'}',
                          grnData['address']?.toString(),
                          grnData['city']?.toString(),
                          grnData['state']?.toString(),
                          grnData['country']?.toString(),
                          'Email: ${grnData['contactpersonEmail'] ?? 'Not Provided'}',
                          'Phone: ${grnData['vendorContact'] ?? 'Not Provided'}',
                        ], separator: '\n'),
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        _joinNonEmpty([
                          grnData['billingAddress']?.toString() ??
                              'No.40, Kenikarai',
                          grnData['shippingAddress']?.toString() ??
                              'Ramanathapuram',
                        ]),
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'GRN No: ${grnData['randomId']?.toString() ?? grnId}\n'
                        'GRN Date: $formattedGRNDate\n'
                        'PO Date: $poDate\n'
                        'Invoice Date: $invoiceDate\n'
                        'Payment Terms: ${grnData['paymentTerms']?.toString() ?? 'N/A'}\n'
                        'Currency: ${grnData['currency']?.toString() ?? 'INR'}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Items Table - Wrap in pw.Column to allow breaking
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
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
                        _tableHeaderCell('PO Qty'),
                        _tableHeaderCell('Unit Price'),
                        _tableHeaderCell('Tax'),
                        _tableHeaderCell('Amount'),
                      ],
                    ),
                    ..._buildItemRows(itemsRaw),
                  ],
                ),
              ],
            ),

            // Summary Table
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
                    _safeFixedString(grnData['totalReceivedAmount']),
                  ),
                  _twoCellRow(
                    'Total Discount',
                    _safeFixedString(grnData['totalDiscount']),
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
                    _safeFixedString(grnData['grnRoundOffAmount']),
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Amount in Words: $amountInWords',
                          style: pw.TextStyle(fontSize: 12),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total: ${_safeFixedString(grnData['totalReceivedAmount'])}',
                          style: pw.TextStyle(fontSize: 12),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Terms & Conditions
            pw.Text(
              'Terms & Conditions',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ..._buildTermsAndConditions(grnData['termsAndConditions']),

            pw.SizedBox(height: 16),

            // Declaration
            pw.Text(
              'Declaration:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              grnData['declaration']?.toString() ??
                  'We declare that this invoice shows the actual price of the described items and that all particulars are true and correct.',
              style: pw.TextStyle(fontSize: 11),
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Row(
              children: [
                pw.Expanded(child: pw.Center(child: pw.Text('Page 1 of 1'))),
                pw.Text('Authorized Signatory'),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final safeId = (grnData['randomId'] ?? grnId).toString().replaceAll(
      '/',
      '_',
    );

    final filename = 'grn_$safeId.pdf';
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> generateAndOpenGRN(BuildContext context, String grnId) async {
    try {
      debugPrint("📄 Start generating GRN PDF: $grnId");

      /// STEP 1: Generate PDF
      final file = await GRNPDF().generateGRNPdf(grnId);

      debugPrint("✅ PDF generated at: ${file.path}");

      /// STEP 2: Open PDF (IMPORTANT FIX)
      final result = await OpenFilex.open(file.path);

      debugPrint("📂 Open result: ${result.message}");

      /// STEP 3: Handle open failure
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open PDF: ${result.message}")),
        );
      }
    } catch (e) {
      debugPrint("❌ PDF Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PDF generation failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _getTaxPercentage(List<dynamic> items) {
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        final tax = _safeNum(item['purchasetaxName']); // ✅ correct key

        if (tax > 0) {
          return tax / 2; // CGST/SGST split
        }
      }
    }

    return 0;
  }

  double _calculateCgst(List<dynamic> items) {
    double total = 0;

    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['cgst']); // ✅ correct key
      }
    }

    return total;
  }

  double _calculateSgst(List<dynamic> items) {
    double total = 0;

    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['sgst']); // ✅ correct key
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

  pw.Widget _tableHeaderCell(String title) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.white,
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
            child: pw.Text(left, style: pw.TextStyle(fontSize: 11)),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(right, style: pw.TextStyle(fontSize: 11)),
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

    return items.asMap().entries.map<pw.TableRow>((entry) {
      final index = entry.key;
      final item = entry.value ?? {};
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text('${index + 1}', style: pw.TextStyle(fontSize: 9)),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              item['itemName']?.toString() ?? '',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              item['hsnCode']?.toString() ?? '',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              _safeFixedString(item['nos']),
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              _safeFixedString(item['quantity']),
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              _safeFixedString(item['poQuantity']),
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              _safeFixedString(item['unitPrice']),
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              _safeNum(item['purchasetaxName']).toString(),
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(5),
            child: pw.Text(
              _safeFixedString(item['totalPrice']),
              style: pw.TextStyle(fontSize: 9),
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
          style: pw.TextStyle(fontSize: 11),
        );
      }).toList();
    } else {
      return [
        pw.Text(
          '1. Please quote our GRN No. in your Delivery Note.',
          style: pw.TextStyle(fontSize: 11),
        ),
        pw.Text(
          '2. Defective and excess quantity will not be accepted.',
          style: pw.TextStyle(fontSize: 11),
        ),
        pw.Text(
          '3. Subject to Ramanathapuram Jurisdiction Only.',
          style: pw.TextStyle(fontSize: 11),
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
        if (trimmed.isNotEmpty) nonEmpty.add(trimmed);
      }
    }
    return nonEmpty.join(separator);
  }
}
