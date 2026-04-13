// ap_invoice_pdf.dart - Fixed round off
// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:purchaseorders2/services/dio_client.dart';

class APInvoicePDF {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>> fetchAPInvoice(String invoiceId) async {
    final uri = '/apinvoices/$invoiceId';
    final response = await _dio.get(
      uri,
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );

    final dynamic decoded = response.data;

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected AP Invoice format: expected JSON object');
  }

  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    try {
      final response = await _dio.get(
        '/pobusiness/',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      final data = response.data;

      if (data is List &&
          data.isNotEmpty &&
          data.first is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data.first);
      }

      return <String, dynamic>{};
    } catch (e) {
      debugPrint("❌ fetchBusinessDetails error: $e");
      return <String, dynamic>{};
    }
  }

  Future<Map<String, dynamic>> fetchVendorById(String vendorId) async {
    try {
      if (vendorId.trim().isEmpty) return {};

      final response = await _dio.get('/vendors/$vendorId');

      final decoded = response.data;

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is List && decoded.isNotEmpty) {
        return Map<String, dynamic>.from(decoded.first);
      }

      return {};
    } catch (e) {
      debugPrint("❌ fetchVendorById error: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchShippingAddress() async {
    try {
      final response = await _dio.get(
        'https://yenerp.com/purchaseapi/poshippingaddress/',
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.data is List) {
        final list = response.data as List;

        final match = list.firstWhere(
          (e) => e['randomId'] == 'SA003',
          orElse: () => list.isNotEmpty ? list[0] : {},
        );

        return Map<String, dynamic>.from(match);
      }

      return {};
    } catch (e) {
      debugPrint("❌ fetchShippingAddress error: $e");
      return {};
    }
  }

  Future<File> generateAPInvoicePdf(String invoiceId) async {
    if (invoiceId.trim().isEmpty) {
      throw Exception('invoiceId is empty');
    }

    final Map<String, dynamic> invoiceData = await fetchAPInvoice(invoiceId);
    final Map<String, dynamic> businessData = await fetchBusinessDetails();
    final shippingData = await fetchShippingAddress();
    final vendorId = (invoiceData['vendorId'] ?? '').toString();
    final Map<String, dynamic> vendourData = await fetchVendorById(vendorId);

    final List<dynamic> itemsRaw = (invoiceData['itemDetails'] is List)
        ? List<dynamic>.from(invoiceData['itemDetails'])
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

    final formattedInvoiceDate =
        (invoiceData['apinvoiceDate'] != null &&
            invoiceData['apinvoiceDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(invoiceData['apinvoiceDate'].toString())
        : 'N/A';

    final poDate =
        (invoiceData['poDate'] != null &&
            invoiceData['poDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(invoiceData['poDate'].toString())
        : 'N/A';

    final invoiceDate =
        (invoiceData['invoiceDate'] != null &&
            invoiceData['invoiceDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(invoiceData['invoiceDate'].toString())
        : 'N/A';

    final dueDate =
        (invoiceData['dueDate'] != null &&
            invoiceData['dueDate'].toString().trim().isNotEmpty)
        ? safeFormatDate(invoiceData['dueDate'].toString())
        : 'N/A';

    final invoiceAmount = _safeNum(invoiceData['invoiceAmount']);
    final amountInWords = _amountInWords(invoiceAmount);

    // Calculate tax percentage from items
    final taxPercentage = _getTaxPercentage(itemsRaw);

    // Calculate CGST and SGST totals
    final cgstTotal = _calculateCgst(itemsRaw);
    final sgstTotal = _calculateSgst(itemsRaw);

    // Get round off amount from API response - FIXED
    final roundOffAmount = _safeNum(invoiceData['apRoundOff']);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return <pw.Widget>[
            // Header - EXACT same as GRNPDF
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
                            'AP INVOICE',
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

            // Vendor/Billing/Invoice Details Table - EXACT same styling
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
                        'Shipping Address',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Invoice Details',
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
                          vendourData['vendorName']?.toString() ??
                              invoiceData['vendorName'],
                          'GSTIN: ${vendourData['gstNumber'] ?? 'N/A'}',
                          vendourData['address']?.toString(),
                          vendourData['city']?.toString(),
                          vendourData['state']?.toString(),
                          vendourData['country']?.toString(),
                          'Email: ${invoiceData['contactpersonEmail']?.isNotEmpty == true ? invoiceData['contactpersonEmail'] : 'Not Provided'}',
                          'Phone: ${invoiceData['vendorContact']?.isNotEmpty == true ? invoiceData['vendorContact'] : 'Not Provided'}',
                        ], separator: '\n'),
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        shippingData['address']?.toString() ??
                            'No: 95 B, GODOWN, DEVIPATTINAM, RAMANATHAPURAM',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Invoice No: ${invoiceData['randomId']?.toString() ?? invoiceId}\n'
                        'AP Invoice Date: $formattedInvoiceDate\n'
                        'Invoice Date: $invoiceDate\n'
                        'PO Date: $poDate\n'
                        'Due Days: ${invoiceData['dueDays'] ?? 'N/A'}\n'
                        'Payment Terms: ${invoiceData['paymentTerms'] ?? invoiceData['paymentTerm'] ?? 'N/A'}\n'
                        'Currency: ${invoiceData['currency']?.toString() ?? 'INR'}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Items Table - Wrap in pw.Column to allow breaking across pages
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
                        _tableHeaderCell('Tax %'),
                        _tableHeaderCell('Amount'),
                      ],
                    ),
                    ..._buildItemRows(itemsRaw),
                  ],
                ),
              ],
            ),

            // Summary Table - EXACT same layout as GRN
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
                    _safeFixedString(invoiceData['invoiceAmount']),
                  ),
                  _twoCellRow(
                    'Total Discount',
                    _safeFixedString(invoiceData['discountDetails']),
                  ),
                  if (taxPercentage > 0) ...[
                    _twoCellRow(
                      'CGST @ ${(taxPercentage / 2).toStringAsFixed(2)}%',
                      _safeFixedString(cgstTotal),
                    ),
                    _twoCellRow(
                      'SGST @ ${(taxPercentage / 2).toStringAsFixed(2)}%',
                      _safeFixedString(sgstTotal),
                    ),
                  ] else ...[
                    _twoCellRow('CGST @ 0%', '0.00'),
                    _twoCellRow('SGST @ 0%', '0.00'),
                  ],
                  _twoCellRow(
                    'Round Off Amount',
                    roundOffAmount.toStringAsFixed(
                      2,
                    ), // FIXED: Using apRoundOff from API
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
                          'Total: ${_safeFixedString(invoiceData['invoiceAmount'])}',
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
            ..._buildTermsAndConditions(invoiceData['termsAndConditions']),

            pw.SizedBox(height: 16),

            // Declaration
            pw.Text(
              'Declaration:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              invoiceData['declaration']?.toString() ??
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
    final safeId = (invoiceData['randomId'] ?? invoiceId).toString().replaceAll(
      '/',
      '_',
    );

    final filename = 'ap_invoice_$safeId.pdf';
    final file = File('${output.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  double _getTaxPercentage(List<dynamic> items) {
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        final tax = _safeNum(
          item['purchasetaxName'] ??
              item['taxPercentage'] ??
              item['taxpercent'] ??
              0,
        );
        if (tax > 0) {
          return tax;
        }
      }
    }
    return 0;
  }

  double _calculateCgst(List<dynamic> items) {
    double total = 0;
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['cgst']);
      }
    }
    return total;
  }

  double _calculateSgst(List<dynamic> items) {
    double total = 0;
    for (var item in items) {
      if (item is Map<String, dynamic>) {
        total += _safeNum(item['sgst']);
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
          children: List.generate(
            9,
            (index) => pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text(index == 1 ? 'No items' : ''),
            ),
          ),
        ),
      ];
    }

    return items.asMap().entries.map<pw.TableRow>((entry) {
      final index = entry.key;
      final item = entry.value ?? {};

      // Get tax percentage
      String taxPercentage = '';
      if (item.containsKey('purchasetaxName') &&
          item['purchasetaxName'] != null) {
        taxPercentage = _safeNum(item['purchasetaxName']).toStringAsFixed(2);
      } else if (item.containsKey('taxPercentage') &&
          item['taxPercentage'] != null) {
        taxPercentage = _safeNum(item['taxPercentage']).toStringAsFixed(2);
      }

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
              item['hsnCode']?.toString() ?? item['itemCode']?.toString() ?? '',
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
              _safeFixedString(item['poQuantity'] ?? item['eachQuantity']),
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
              taxPercentage.isEmpty ? '' : '$taxPercentage%',
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
          '1. Please quote our Invoice No. in your records.',
          style: pw.TextStyle(fontSize: 11),
        ),
        pw.Text(
          '2. Payment is due within the specified payment terms.',
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
