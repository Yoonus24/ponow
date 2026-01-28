import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Outgoing PDF generator
class OutgoingPdf {
  static const String baseUrl = 'http://192.168.29.252:8000/nextjstestapi';
  static const String businessUrl =
      'http://192.168.29.252:8000/nextjstestapi/pobusiness';
  static const String vendorByNameUrl =
      'http://192.168.29.252:8000/nextjstestapi/purchas/vendors/exact-name/';

  /// Fetch single Outgoing by id
  Future<Map<String, dynamic>> fetchFilteredOutgoings(String outgoingId) async {
    final uri = Uri.parse('$baseUrl/outgoingpayments/$outgoingId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsing Outgoing from JSON. Keys: ${data.keys.toList()}');
        return data as Map<String, dynamic>;
      } else {
        print('API Error fetchFilteredOutgoings: ${response.statusCode}');
        throw Exception('Failed to load outgoing: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching outgoing $outgoingId: $e');
      rethrow;
    }
  }

  /// Fetch business details
  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final uri = Uri.parse(businessUrl);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return (data.first as Map<String, dynamic>);
        } else {
          throw Exception('Business data list is empty');
        }
      } else {
        throw Exception(
          'Failed to load business details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching business details: $e');
      rethrow;
    }
  }

  /// Fetch vendor by exact name
  Future<Map<String, dynamic>> fetchVendorByName(String vendorName) async {
    try {
      final encoded = Uri.encodeQueryComponent(vendorName);
      final uri = Uri.parse('$vendorByNameUrl?name=$encoded');

      print('🔍 Fetching Vendor URL → $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          throw Exception('Unexpected vendor payload');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Vendor not found: $vendorName');
      } else {
        print('Vendor API response: ${response.statusCode} ${response.body}');
        throw Exception(
          'Failed to load vendor details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching vendor: $e');
      rethrow;
    }
  }

  /// Generate PDF file for outgoing
  Future<File> generateOutgoingPdf(String outgoingId) async {
    try {
      // Fetch data
      final outgoing = await fetchFilteredOutgoings(outgoingId);
      final businessData = await fetchBusinessDetails();

      // Fetch vendor
      Map<String, dynamic> vendorData = {};
      final vendorName = (outgoing['vendorName'] ?? '').toString().trim();
      if (vendorName.isNotEmpty) {
        try {
          vendorData = await fetchVendorByName(vendorName);
        } catch (e) {
          print('Vendor fetch by name failed for "$vendorName": $e');
          vendorData = {};
        }
      } else {
        print('No vendorName present in outgoing JSON; vendorData left empty');
      }

      // Items array safe parsing
      final rawItems = outgoing['itemDetails'];
      final List<dynamic> items = rawItems is List
          ? rawItems
          : (rawItems == null ? <dynamic>[] : <dynamic>[rawItems]);

      // Load logo
      final logoImage = await _loadLogoImage();

      // Prepare derived fields
      final dateFormat = DateFormat('dd-MM-yyyy');
      final formattedOrderDate = outgoing['invoiceDate'] != null
          ? _tryFormatDateString(outgoing['invoiceDate'].toString(), dateFormat)
          : outgoingId;
      final invoiceDate = outgoing['invoiceDate'] != null
          ? _tryFormatDateString(outgoing['invoiceDate'].toString(), dateFormat)
          : 'N/A';

      final paidAmount = _calculatePaidAmountFromMap(outgoing);

      final payableAmount = (outgoing['payableAmount'] is num)
          ? (outgoing['payableAmount'] as num).toDouble()
          : (outgoing['totalPayableAmount'] is num
                ? (outgoing['totalPayableAmount'] as num).toDouble()
                : 0.0);

      final amountInWords = _amountInWords(payableAmount);

      // Debug prints
      print('Generating PDF Table Rows for items (count=${items.length}):');
      for (var it in items) {
        print(' - item: ${it ?? {}}');
      }

      // Build PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(logoImage, outgoing, outgoingId),
                pw.SizedBox(height: 20),

                // Vendor/Business/Outgoing Details Table
                _buildDetailsTable(
                  outgoing,
                  businessData,
                  vendorData,
                  formattedOrderDate,
                  outgoingId,
                ),
                pw.SizedBox(height: 20),

                // Items Table
                _buildItemsTable(outgoing, items, invoiceDate),
                pw.SizedBox(height: 20),

                // Summary Table
                _buildSummaryTable(outgoing, paidAmount, payableAmount),
                pw.SizedBox(height: 20),

                // Amount in Words and Total
                _buildAmountSection(amountInWords, payableAmount),
              ],
            );
          },
        ),
      );

      // Save and return
      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/outgoing_${outgoing['randomId'] ?? outgoingId}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error generating outgoing PDF: $e');
      rethrow;
    }
  }

  /// Build Header Section
  pw.Widget _buildHeaderSection(
    pw.ImageProvider logoImage,
    Map<String, dynamic> outgoing,
    String outgoingId,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(logoImage, width: 200, height: 100),
            pw.SizedBox(height: 5),
            pw.Text(
              'Payment Method: ${outgoing['paymentMethod'] ?? 'N/A'}',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'PENDING PAYMENT',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Outgoing No: ${outgoing['randomId'] ?? outgoingId}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Details Table - CORRECTED VERSION
  pw.Widget _buildDetailsTable(
    Map<String, dynamic> outgoing,
    Map<String, dynamic> businessData,
    Map<String, dynamic> vendorData,
    String formattedOrderDate,
    String outgoingId,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header Row - Each header correctly aligned with its column
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
          ),
          children: [
            // VENDOR DETAILS Header - Left aligned with vendor details column
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'VENDOR DETAILS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            // BUSINESS DETAILS Header - Center aligned with business details column
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'BUSINESS DETAILS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            // OUTGOING DETAILS Header - Right aligned with outgoing details column
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'OUTGOING DETAILS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        // Content Row - Each data column properly aligned under its header
        pw.TableRow(
          children: [
            // VENDOR DETAILS Column - Left aligned
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Name:',
                    '${vendorData['vendorName'] ?? outgoing['vendorName'] ?? 'N/A'}',
                  ),
                  _buildDetailRow(
                    'GSTIN:',
                    '${vendorData['gstNumber'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'Address:',
                    '${vendorData['address'] ?? outgoing['address'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'City:',
                    '${vendorData['city'] ?? outgoing['city'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'State:',
                    '${vendorData['state'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'Country:',
                    '${vendorData['country'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'Email:',
                    '${vendorData['contactpersonEmail'] ?? outgoing['contactpersonEmail'] ?? 'Not Provided'}',
                  ),
                ],
              ),
            ),
            // BUSINESS DETAILS Column - Center aligned
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Business Name:', 'Best Mummy'),
                  _buildDetailRow(
                    'GSTIN:',
                    '${businessData['gstIn'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'Address:',
                    '${businessData['address1'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'Phone:',
                    '${businessData['phoneNo'] ?? 'Not Provided'}',
                  ),
                  _buildDetailRow(
                    'Email:',
                    '${businessData['emailId'] ?? 'Not Provided'}',
                  ),
                ],
              ),
            ),
            // OUTGOING DETAILS Column - Right aligned
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Outgoing No:',
                    '${outgoing['randomId'] ?? outgoingId}',
                  ),
                  pw.SizedBox(height: 10),
                  _buildDetailRow('Date:', formattedOrderDate),
                  pw.SizedBox(height: 10),
                  _buildDetailRow(
                    'Invoice No:',
                    '${outgoing['invoiceNo'] ?? 'N/A'}',
                  ),
                  pw.SizedBox(height: 10),
                  _buildDetailRow('Invoice Date:', formattedOrderDate),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: Build detail row with label and value
  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Items Table
  pw.Widget _buildItemsTable(
    Map<String, dynamic> outgoing,
    List<dynamic> items,
    String invoiceDate,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(1), // Invoice No
        1: pw.FlexColumnWidth(1), // Invoice Date
        2: pw.FlexColumnWidth(1.5), // Vendor Name
        3: pw.FlexColumnWidth(1.2), // Item Name
        4: pw.FlexColumnWidth(0.8), // Tax Details
        5: pw.FlexColumnWidth(0.8), // Tax Amount
        6: pw.FlexColumnWidth(1), // Without Tax
        7: pw.FlexColumnWidth(1), // With Tax
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
          ),
          children: [
            _buildHeaderCell('INVOICE NO'),
            _buildHeaderCell('INVOICE DATE'),
            _buildHeaderCell('VENDOR NAME'),
            _buildHeaderCell('ITEM NAME'),
            _buildHeaderCell('TAX %'),
            _buildHeaderCell('TAX AMOUNT'),
            _buildHeaderCell('WITHOUT TAX'),
            _buildHeaderCell('WITH TAX'),
          ],
        ),
        // Data Rows
        if (items.isEmpty)
          pw.TableRow(
            children: List.generate(8, (_) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                alignment: pw.Alignment.center,
                child: pw.Text('N/A', textAlign: pw.TextAlign.center),
              );
            }),
          )
        else
          ...items.map((raw) {
            final item = (raw is Map<String, dynamic>)
                ? raw
                : <String, dynamic>{};
            final taxPercent = (item['purchasetaxName'] is num)
                ? (item['purchasetaxName'] as num).toDouble()
                : 0.0;
            final taxAmount = (item['taxAmount'] is num)
                ? (item['taxAmount'] as num).toDouble()
                : 0.0;

            // Calculate without tax and with tax values
            String withoutTaxValue = '0.00';
            String withTaxValue = '0.00';
            try {
              if (taxPercent != 0) {
                withoutTaxValue =
                    ((taxAmount / (taxPercent / 100)) *
                            (100 / (100 + taxPercent)))
                        .toStringAsFixed(2);
                withTaxValue = (taxAmount / (taxPercent / 100)).toStringAsFixed(
                  2,
                );
              } else {
                final tp = (item['totalPrice'] is num)
                    ? (item['totalPrice'] as num).toDouble()
                    : 0.0;
                withoutTaxValue = tp.toStringAsFixed(2);
                withTaxValue = tp.toStringAsFixed(2);
              }
            } catch (_) {
              withoutTaxValue = '0.00';
              withTaxValue = '0.00';
            }

            return pw.TableRow(
              children: [
                _buildDataCell(outgoing['invoiceNo']?.toString() ?? 'N/A'),
                _buildDataCell(invoiceDate),
                _buildDataCell(outgoing['vendorName']?.toString() ?? 'N/A'),
                _buildDataCell(item['itemName']?.toString() ?? 'N/A'),
                _buildDataCell(taxPercent.toStringAsFixed(2)),
                _buildDataCell(taxAmount.toStringAsFixed(2)),
                _buildDataCell(withoutTaxValue),
                _buildDataCell(withTaxValue),
              ],
            );
          }).toList(),
      ],
    );
  }

  /// Build Summary Table
  pw.Widget _buildSummaryTable(
    Map<String, dynamic> outgoing,
    double paidAmount,
    double payableAmount,
  ) {
    final remainingAmount = (outgoing['totalPayableAmount'] is num)
        ? (outgoing['totalPayableAmount'] as num).toDouble() - paidAmount
        : payableAmount - paidAmount;

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1)},
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor(38 / 255, 89 / 255, 198 / 255, 0.1),
          ),
          children: [
            _buildHeaderCell('DESCRIPTION', alignLeft: true),
            _buildHeaderCell('AMOUNT', alignLeft: false),
          ],
        ),
        // Discount Row
        pw.TableRow(
          children: [
            _buildDataCell('Discount', alignLeft: true),
            _buildDataCell(
              '${(outgoing['discountDetails'] is num ? (outgoing['discountDetails'] as num).toDouble().toStringAsFixed(2) : (outgoing['discountDetails']?.toString() ?? '0.00'))}',
              alignLeft: false,
            ),
          ],
        ),
        // Paid Amount Row
        pw.TableRow(
          children: [
            _buildDataCell('Paid Amount', alignLeft: true),
            _buildDataCell(paidAmount.toStringAsFixed(2), alignLeft: false),
          ],
        ),
        // Remaining Amount Row
        pw.TableRow(
          children: [
            _buildDataCell('Remaining Payable Amount', alignLeft: true),
            _buildDataCell(
              remainingAmount.toStringAsFixed(2),
              alignLeft: false,
            ),
          ],
        ),
        // Total Row
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'TOTAL PAYABLE AMOUNT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                payableAmount.toStringAsFixed(2),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Amount Section
  pw.Widget _buildAmountSection(String amountInWords, double payableAmount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Amount in Words
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Amount in Words:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                amountInWords,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Total Amount
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Rs. ${payableAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '(Including Tax)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper: Build header cell
  pw.Widget _buildHeaderCell(String text, {bool alignLeft = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Helper: Build data cell
  pw.Widget _buildDataCell(String text, {bool alignLeft = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  /// Helper: try formatting date strings safely
  String _tryFormatDateString(String input, DateFormat fmt) {
    try {
      final clean = input.split('.').first.split('+').first.trim();
      final dt = DateTime.parse(clean);
      return fmt.format(dt);
    } catch (_) {
      return input.length > 10 ? input.substring(0, 10) : input;
    }
  }

  /// Load logo from assets
  Future<pw.MemoryImage> _loadLogoImage() async {
    try {
      final data = await rootBundle.load('assets/bestmummy.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo image: $e');
      rethrow;
    }
  }

  /// Calculate paid amount from outgoing map
  double _calculatePaidAmountFromMap(Map<String, dynamic> payment) {
    final status = (payment['status'] ?? '').toString().toLowerCase();
    if (status == 'fully paid' || status == 'fullypaid') {
      return (payment['totalPayableAmount'] is num)
          ? (payment['totalPayableAmount'] as num).toDouble()
          : 0.0;
    } else if (status == 'partially paid' || status == 'partiallypaid') {
      return (payment['partialAmount'] is num)
          ? (payment['partialAmount'] as num).toDouble()
          : 0.0;
    } else if (status == 'advance paid' || status == 'advancepaid') {
      return (payment['advanceAmount'] is num)
          ? (payment['advanceAmount'] as num).toDouble()
          : 0.0;
    } else {
      final advance = (payment['advanceAmount'] is num)
          ? (payment['advanceAmount'] as num).toDouble()
          : 0.0;
      final partial = (payment['partialAmount'] is num)
          ? (payment['partialAmount'] as num).toDouble()
          : 0.0;
      final full = (payment['fullPaymentAmount'] is num)
          ? (payment['fullPaymentAmount'] as num).toDouble()
          : 0.0;
      return advance + partial + full;
    }
  }

  // Convert amount to words (INR, paise)
  String _amountInWords(double amount) {
    if (amount == 0) return 'Zero Rupees Only';

    final wholeNumber = amount.toInt();
    final fraction = ((amount - wholeNumber) * 100).round();

    final wholeWords = _convertNumberToWords(wholeNumber);
    final fractionWords = fraction > 0
        ? ' and ${_convertNumberToWords(fraction)} Paise'
        : '';

    return '${wholeWords[0].toUpperCase()}${wholeWords.substring(1)} Rupees$fractionWords Only';
  }

  // Convert number to words (Indian system)
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
      final ten = tens[number ~/ 10];
      final unit = units[number % 10];
      return unit.isEmpty ? ten : '$ten $unit';
    }
    if (number < 1000) {
      final hundred = units[number ~/ 100];
      final remainder = number % 100;
      final remainderWords = remainder > 0
          ? ' ${_convertNumberToWords(remainder)}'
          : '';
      return '$hundred hundred$remainderWords';
    }
    if (number < 100000) {
      final thousand = _convertNumberToWords(number ~/ 1000);
      final remainder = number % 1000;
      final remainderWords = remainder > 0
          ? ' ${_convertNumberToWords(remainder)}'
          : '';
      return '$thousand thousand$remainderWords';
    }
    if (number < 10000000) {
      final lakh = _convertNumberToWords(number ~/ 100000);
      final remainder = number % 100000;
      final remainderWords = remainder > 0
          ? ' ${_convertNumberToWords(remainder)}'
          : '';
      return '$lakh lakh$remainderWords';
    }
    final crore = _convertNumberToWords(number ~/ 10000000);
    final remainder = number % 10000000;
    final remainderWords = remainder > 0
        ? ' ${_convertNumberToWords(remainder)}'
        : '';
    return '$crore crore$remainderWords';
  }
}
