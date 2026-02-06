// purchaseorders2/pdfs/approved_pdf.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

/// PurchaseOrderService
///
/// - Fully null-safe PDF generation
/// - Fetches PO, business and vendor by vendorId (from PO)
/// - Safe numeric formatting (avoids calling toStringAsFixed() on null)
/// - Safe date handling
/// - Graceful fallback for missing logo asset
class PurchaseOrderService {
  static const String baseUrl = 'http://192.168.29.252:8000/nextjstestapi';
  static const String businessUrl =
      'http://yenerp.com/purchaseapi/pobusiness/'; // kept as-is
  static const String vendorBaseUrl =
      'http://192.168.29.252:8000/nextjstestapi/vendors/';

  /// Fetch a single purchase order by id
  Future<Map<String, dynamic>> fetchPurchaseOrder(
    String purchaseOrderId,
  ) async {
    final uri = Uri.parse('$baseUrl/purchaseorders/$purchaseOrderId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Unexpected PO format: expected JSON object');
    } else {
      throw Exception(
        'Failed to load purchase order: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Fetch business details (keeps original endpoint behavior)
  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final uri = Uri.parse(businessUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty && data.first is Map<String, dynamic>) {
        return data.first as Map<String, dynamic>;
      } else {
        // Return an empty map instead of throwing to allow graceful fallbacks
        return <String, dynamic>{};
      }
    } else {
      throw Exception(
        'Failed to load business details: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  /// Fetch vendor by vendorId (correct endpoint)
  Future<Map<String, dynamic>> fetchVendorById(String vendorId) async {
    if (vendorId.trim().isEmpty) {
      // Return empty map to avoid throwing too early; caller may decide.
      return <String, dynamic>{};
    }

    final uri = Uri.parse('$vendorBaseUrl$vendorId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map<String, dynamic>) {
        // Some APIs may return a single-element list; handle that defensively
        return decoded.first as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    } else {
      // Return empty map to allow PDF generation with fallback values
      return <String, dynamic>{};
    }
  }

  /// Generate PDF file for a purchase order id
  Future<File> generatePurchaseOrderPdf(String purchaseOrderId) async {
    if (purchaseOrderId.trim().isEmpty) {
      throw Exception('purchaseOrderId is empty');
    }

    // Fetch PO data
    final Map<String, dynamic> poData = await fetchPurchaseOrder(
      purchaseOrderId,
    );

    // Business & vendor
    final Map<String, dynamic> businessData = await fetchBusinessDetails();

    // vendorId is expected to be in the PO as "vendorId"
    final vendorId = (poData['vendorId'] ?? '').toString();
    final Map<String, dynamic> vendorData = await fetchVendorById(vendorId);

    // Items list (defensive)
    final List<dynamic> itemsRaw = (poData['items'] is List)
        ? List<dynamic>.from(poData['items'])
        : <dynamic>[];

    // Load logo image (graceful fallback)
    pw.MemoryImage? logoImage;
    try {
      logoImage = await _tryLoadLogoImage('assets/bestmummy.png');
    } catch (_) {
      logoImage = null;
    }

    // Date helpers
    String safeFormatDate(String? dateValue) {
      if (dateValue == null) return 'N/A';
      try {
        final dt = DateTime.parse(dateValue);
        return DateFormat('dd-MM-yyyy').format(dt);
      } catch (_) {
        // If it's already in dd-MM-yyyy or other safe string, return as-is
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

    // Amount and words
    final pendingOrderAmount = _safeNum(poData['pendingOrderAmount']);
    final amountInWords = _amountInWords(pendingOrderAmount);

    // Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row with optional logo and title
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 120,
                      height: 60,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(width: 120, height: 60, child: pw.SizedBox()),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'PURCHASE ORDER',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor(38 / 255, 89 / 255, 198 / 255),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Business details (right aligned column)
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        businessData['companyName']?.toString() ??
                            'Company Name',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _joinNonEmpty([
                          businessData['address1']?.toString(),
                          businessData['address2']?.toString(),
                        ], separator: ', '),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Tel: ${businessData['phoneNo']?.toString() ?? 'N/A'}',
                      ),
                      pw.Text(
                        'Email: ${businessData['emailId']?.toString() ?? 'N/A'}',
                      ),
                      pw.Text(
                        'GSTIN: ${businessData['gstIn']?.toString() ?? 'Not Provided'}',
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Top tables: Vendor Details | Billing | PO Details
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
                      color: PdfColor(38 / 255, 89 / 255, 198 / 255),
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
                            vendorData['vendorName']?.toString(),
                            'GSTIN: ${vendorData['gstNumber']?.toString() ?? 'N/A'}',
                            vendorData['address']?.toString() ??
                                'Address Not Provided',
                            vendorData['city']?.toString() ??
                                'City Not Provided',
                            vendorData['state']?.toString() ??
                                'State Not Provided',
                            vendorData['country']?.toString() ??
                                'Country Not Provided',
                            'Email: ${(vendorData['contactpersonEmail'] ?? vendorData['email'] ?? 'Not Provided').toString()}',
                            'Phone: ${(vendorData['contactpersonPhone']?['\$numberLong'] ?? vendorData['phone'] ?? 'Not Provided').toString()}',
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

              pw.SizedBox(height: 12),

              // Items table header + rows
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: pw.FlexColumnWidth(0.5),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(0.8),
                  3: pw.FlexColumnWidth(0.8),
                  4: pw.FlexColumnWidth(0.8),
                  5: pw.FlexColumnWidth(1),
                  6: pw.FlexColumnWidth(1),
                  7: pw.FlexColumnWidth(0.8),
                  8: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(38 / 255, 89 / 255, 198 / 255),
                    ),
                    children: [
                      _tableHeaderCell('SI No'),
                      _tableHeaderCell('Description'),
                      _tableHeaderCell('hsnCode'),
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

              pw.SizedBox(height: 12),

              // Totals table
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
                      'CGST',
                      _safeFixedString(
                        _firstItemValue(itemsRaw, 'pendingCgst'),
                      ),
                    ),
                    _twoCellRow(
                      'SGST',
                      _safeFixedString(
                        _firstItemValue(itemsRaw, 'pendingSgst'),
                      ),
                    ),
                    _twoCellRow(
                      'Round Off Amount',
                      _safeFixedString(poData['roundOffAmount']),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Amount in words and total including tax
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Amount in Words: $amountInWords',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Total [Including Tax]: ${_safeFixedString(poData['pendingOrderAmount'])}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

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

  /// Try to load logo; if it fails, return null
  Future<pw.MemoryImage?> _tryLoadLogoImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // asset not found or any error -> return null so PDF continues
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

  // Safe two-cell row
  pw.TableRow _twoCellRow(String left, String right) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(left)),
        pw.Padding(padding: pw.EdgeInsets.all(6), child: pw.Text(right)),
      ],
    );
  }

  // Build rows for items with full null-safety
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

  // Convert dynamic/nullable to a fixed string with 2 decimals for numbers
  String _safeFixedString(dynamic value) {
    final num v = _safeNum(value);
    return v.toStringAsFixed(2);
  }

  // Safely convert dynamic to num (double)
  double _safeNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (_) {
      return 0.0;
    }
  }

  // If items list has at least one item, try to return numeric field from first item
  dynamic _firstItemValue(List<dynamic> items, String key) {
    if (items.isEmpty) return 0;
    final first = items.first;
    if (first is Map<String, dynamic>) {
      return first[key];
    }
    return 0;
  }

  // Build terms and conditions list; supports either [] or missing
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
