import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class GRNDebitPdf {
  static const String baseUrl = 'http://192.168.29.252:8000/nextjstestapi';
  static const String businessUrl =
      'https://yenerp.com/purchaseapi/pobusiness/';
  static const String vendorUrl =
      'http://192.168.29.252:8000/nextjstestapi/vendors/';

  // ================= FETCH GRN =================
  Future<Map<String, dynamic>> fetchGRN(String grnId) async {
    final response = await http.get(Uri.parse('$baseUrl/grns/$grnId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load GRN');
    }
  }

  // ================= FETCH BUSINESS =================
  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final response = await http.get(Uri.parse(businessUrl));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.isNotEmpty ? data.first : {};
    } else {
      throw Exception('Failed to load business details');
    }
  }

  // ================= FETCH VENDOR =================
  Future<Map<String, dynamic>> fetchVendorsDetails({String? vendorName}) async {
    try {
      final response = await http.get(Uri.parse(vendorUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final vendor = data.firstWhere(
          (v) =>
              v['vendorName']?.toString().toLowerCase() ==
              vendorName?.toLowerCase(),
          orElse: () => _fallbackVendor(vendorName),
        );
        return Map<String, dynamic>.from(vendor);
      }
      return _fallbackVendor(vendorName);
    } catch (_) {
      return _fallbackVendor(vendorName);
    }
  }

  Map<String, dynamic> _fallbackVendor(String? name) => {
    'vendorName': name ?? 'Unknown Vendor',
    'gstNumber': 'N/A',
    'address': 'Not Provided',
    'city': 'N/A',
    'state': 'N/A',
    'country': 'N/A',
    'contactpersonEmail': 'N/A',
    'contactpersonPhone': 'N/A',
  };

  // ================= LOAD LOGO =================
  Future<pw.MemoryImage> _loadLogoImage() async {
    final data = await rootBundle.load('assets/bestmummy.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  // ================= GENERATE PDF =================
  Future<File> generateGrnPdf(String grnId) async {
    final grnData = await fetchGRN(grnId);
    final businessData = await fetchBusinessDetails();
    final vendorData = await fetchVendorsDetails(
      vendorName: grnData['vendorName'],
    );
    final logoImage = await _loadLogoImage();

    final items = grnData['itemDetails'] is List
        ? grnData['itemDetails']
        : [grnData['itemDetails'] ?? {}];

    final subtotal = items.fold(
      0.0,
      (sum, i) => sum + (i['returnedTotalPrice']?.toDouble() ?? 0.0),
    );
    final totalTax = items.fold(
      0.0,
      (sum, i) =>
          sum +
          ((i['returnedCgst']?.toDouble() ?? 0.0) +
              (i['returnedSgst']?.toDouble() ?? 0.0)),
    );
    final totalDiscount = items.fold(
      0.0,
      (sum, i) => sum + (i['returnedDiscountAmount']?.toDouble() ?? 0.0),
    );
    final cgstTotal = items.fold(
      0.0,
      (sum, i) => sum + (i['returnedCgst']?.toDouble() ?? 0.0),
    );
    final sgstTotal = items.fold(
      0.0,
      (sum, i) => sum + (i['returnedSgst']?.toDouble() ?? 0.0),
    );
    final finalTotal =
        grnData['totalReturnedAmount']?.toDouble() ??
        (subtotal + totalTax - totalDiscount);

    final pdf = pw.Document();
    final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER WITH LOGO =====
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(logoImage, width: 100, height: 50),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'DEBIT NOTE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ===== BUSINESS INFO RIGHT =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        businessData['companyName'] ?? '',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(businessData['address1'] ?? ''),
                      pw.Text(businessData['address2'] ?? ''),
                      pw.Text('GSTIN: ${businessData['gstIn'] ?? ''}'),
                      pw.Text('Ph: ${businessData['phoneNo'] ?? ''}'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // ===== VENDOR / BILLING / DETAILS =====
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1),
                    ),
                    children: [
                      _headerCell('Vendor Details'),
                      _headerCell('Billing Address'),
                      _headerCell('Debit Note Details'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _normalCell(
                        '${vendorData['vendorName']}\n'
                        'GSTIN: ${vendorData['gstNumber']}\n'
                        'City: ${vendorData['city']}\n'
                        'State: ${vendorData['state']}\n'
                        'Phone: ${vendorData['contactpersonPhone']}',
                      ),
                      _normalCell(grnData['billingAddress'] ?? ''),
                      _normalCell(
                        'Note No: ${grnData['randomId'] ?? grnId}\n'
                        'Date: $formattedDate',
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ===== ITEMS TABLE =====
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(0.5),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(0.8),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1),
                  5: pw.FlexColumnWidth(1),
                  6: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1),
                    ),
                    children: [
                      _headerCell('SI'),
                      _headerCell('Description'),
                      _headerCell('Qty'),
                      _headerCell('Unit Price'),
                      _headerCell('Tax'),
                      _headerCell('Discount'),
                      _headerCell('Amount'),
                    ],
                  ),
                  ..._buildDebitItemRows(items),
                ],
              ),

              pw.SizedBox(height: 10),

              // ===== TOTALS =====
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  _totalRow('Subtotal', subtotal),
                  _totalRow('Total Tax', totalTax),
                  _totalRow('Total Discount', totalDiscount),
                  _totalRow('CGST', cgstTotal),
                  _totalRow('SGST', sgstTotal),
                  _totalRow('Final Total', finalTotal, bold: true),
                ],
              ),

              pw.SizedBox(height: 10),

              // ===== AMOUNT IN WORDS =====
              pw.Text(
                'Amount in Words: ${_amountInWords(finalTotal)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 15),

              // ===== TERMS =====
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('1. Debit note issued for returned/damaged goods.'),
              pw.Text('2. Returned goods will not be accepted again.'),
              pw.Text('3. Subject to local jurisdiction only.'),

              pw.SizedBox(height: 15),

              // ===== DECLARATION =====
              pw.Text(
                'Declaration:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'We declare that this debit note shows the actual value of returned goods and all particulars are true and correct.',
              ),

              pw.SizedBox(height: 30),

              // ===== SIGN =====
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Authorized Signatory'),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/DebitNote_${grnData['randomId'] ?? grnId}.pdf",
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ================= HELPERS =================
  pw.Widget _headerCell(String text) => pw.Padding(
    padding: pw.EdgeInsets.all(5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );

  pw.Widget _normalCell(String text) =>
      pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text(text));

  pw.TableRow _totalRow(String label, double value, {bool bold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(5),
          child: pw.Text(
            value.toStringAsFixed(2),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  List<pw.TableRow> _buildDebitItemRows(List<dynamic> items) {
    return items.asMap().entries.map<pw.TableRow>((entry) {
      final i = entry.key;
      final item = entry.value ?? {};
      return pw.TableRow(
        children: [
          _normalCell('${i + 1}'),
          _normalCell(item['itemName']?.toString() ?? ''),
          _normalCell(item['returnedQuantity']?.toString() ?? '0'),
          _normalCell(
            (item['unitPrice'] is num)
                ? item['unitPrice'].toStringAsFixed(2)
                : '0.00',
          ),
          _normalCell(
            (item['returnedTaxAmount'] is num)
                ? item['returnedTaxAmount'].toStringAsFixed(2)
                : '0.00',
          ),
          _normalCell(
            (item['returnedDiscountAmount'] is num)
                ? item['returnedDiscountAmount'].toStringAsFixed(2)
                : '0.00',
          ),
          _normalCell(
            (item['returnedFinalPrice'] is num)
                ? item['returnedFinalPrice'].toStringAsFixed(2)
                : '0.00',
          ),
        ],
      );
    }).toList();
  }

  // ===== AMOUNT TO WORDS =====
  String _amountInWords(double amount) {
    if (amount == 0) return 'Zero only';

    final whole = amount.toInt();
    final fraction = ((amount - whole) * 100).round();

    final wholeWords = _convertNumberToWords(whole);
    final fractionWords = fraction > 0
        ? ' and ${_convertNumberToWords(fraction)} paise'
        : '';

    return '${wholeWords[0].toUpperCase()}${wholeWords.substring(1)}$fractionWords only';
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

    if (number < 10) return units[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      return '${tens[number ~/ 10]} ${units[number % 10]}'.trim();
    }
    if (number < 1000) {
      return '${units[number ~/ 100]} hundred ${_convertNumberToWords(number % 100)}'
          .trim();
    }
    if (number < 100000) {
      return '${_convertNumberToWords(number ~/ 1000)} thousand ${_convertNumberToWords(number % 1000)}'
          .trim();
    }
    if (number < 10000000) {
      return '${_convertNumberToWords(number ~/ 100000)} lakh ${_convertNumberToWords(number % 100000)}'
          .trim();
    }
    return '${_convertNumberToWords(number ~/ 10000000)} crore ${_convertNumberToWords(number % 10000000)}'
        .trim();
  }
}
