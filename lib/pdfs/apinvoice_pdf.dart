// ignore_for_file: avoid_print, unused_local_variable

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class APInvoicePDF {
  static const String baseUrl = 'http://192.168.29.252:8000/nextjstestapi';
  static const String businessUrl = 'https://yenerp.com/purchaseapi/pobusiness';
  static const String vendorUrl =
      'http://192.168.29.252:8000/nextjstestapi/vendors/';
  // Fetch AP Invoice data from the backend
  Future<Map<String, dynamic>> fetchAPInvoices(String invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/apinvoices/$invoiceId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Full GRN Data: $data');
        print('Item Details: ${data['itemDetails']}');
        return data;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load GRN: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching AP Invoice: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchBusinessDetails() async {
    final response = await http.get(Uri.parse(businessUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      } else {
        throw Exception('Business data list is empty');
      }
    } else {
      throw Exception('Failed to load business details');
    }
  }

  Future<Map<String, dynamic>> fetchVendorsDetails() async {
    final response = await http.get(Uri.parse(vendorUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      } else {
        throw Exception('Vendor data list is empty');
      }
    } else {
      throw Exception('Failed to load vendor details');
    }
  }

  // Generate the PDF for the AP Invoice
  Future<File> generateAPInvoicePdf(String invoiceId) async {
    // Fetch data from backend
    final apinvoice = await fetchAPInvoices(invoiceId);
    final businessData = await fetchBusinessDetails();
    final vendorData = await fetchVendorsDetails();

    // Handle itemDetails as a list, with fallback for single object or null
    final items = apinvoice['itemDetails'] is List
        ? apinvoice['itemDetails']
        : [apinvoice['itemDetails'] ?? {}];

    // Use first item for CGST/SGST if available, otherwise empty map
    final itemDetails = items.isNotEmpty ? items[0] : {};

    // Debug prints to verify data
    print('Items for PDF: $items');
    print('Item Details for PDF: $itemDetails');
    print('Item Name for PDF: ${itemDetails['itemName']}');
    print('CGST Value for PDF: ${itemDetails['cgst']}');
    print('SGST Value for PDF: ${itemDetails['sgst']}');
    print('Total Price for PDF: ${itemDetails['totalPrice']}');
    print('Final Price for PDF: ${apinvoice['invoiceAmount']}');

    // Load the logo image from assets
    final logoImage = await _loadLogoImage();

    // Create PDF document
    final pdf = pw.Document();
    final formattedOrderDate = apinvoice['poDate'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(apinvoice['poDate']))
        : invoiceId;

    // Format dates with null safety
    final dateFormat = DateFormat('dd-MM-yyyy');
    final invoiceDate = apinvoice['invoiceDate'] != null
        ? dateFormat.format(DateTime.parse(apinvoice['invoiceDate']))
        : 'N/A';
    final dueDate = apinvoice['invoiceDate'] != null
        ? dateFormat.format(DateTime.parse(apinvoice['invoiceDate']))
        : 'N/A';

    // Format amount in words with null safety
    final invoiceAmount = apinvoice['invoiceAmount'] != null
        ? (apinvoice['invoiceAmount'] is int
              ? apinvoice['invoiceAmount'].toDouble()
              : apinvoice['invoiceAmount'] as double)
        : 0.0;
    final amountInWords = _amountInWords(invoiceAmount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header section with logo
              // Logo centered at top
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo on the left
                  pw.Image(logoImage, width: 120, height: 60),
                  // Center title using Expanded
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'AP INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Best Mummy',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Table(
                        columnWidths: {
                          0: pw.IntrinsicColumnWidth(),
                          1: pw.FixedColumnWidth(8),
                          2: pw.IntrinsicColumnWidth(),
                        },
                        defaultVerticalAlignment:
                            pw.TableCellVerticalAlignment.middle,
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Text('No:', textAlign: pw.TextAlign.right),
                              pw.SizedBox(),
                              pw.Text(
                                businessData['address1'] ?? 'Not Provided',
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('Tel:', textAlign: pw.TextAlign.right),
                              pw.SizedBox(),
                              pw.Text(
                                businessData['phoneNo'] ?? 'Not Provided',
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('Email:', textAlign: pw.TextAlign.right),
                              pw.SizedBox(),
                              pw.Text(
                                businessData['emailId'] ?? 'Not Provided',
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('GSTIN:', textAlign: pw.TextAlign.right),
                              pw.SizedBox(),
                              pw.Text(businessData['gstIn'] ?? 'Not Provided'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Vendor Details',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Billing Address',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'AP Invoice Details',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${vendorData['vendorName'] ?? 'N/A'}\n'
                          'GSTIN: ${vendorData['gstNumber'] ?? 'Not Provided'}\n'
                          'Address: ${vendorData['address'] ?? 'Not Provided'}\n'
                          'City: ${vendorData['city'] ?? 'Not Provided'}\n'
                          'State: ${vendorData['state'] ?? 'Not Provided'}\n'
                          'Country: ${vendorData['country'] ?? 'Not Provided'}\n'
                          'Email: ${vendorData['contactpersonEmail'] ?? 'Not Provided'}\n'
                          'Phone: ${vendorData['contactpersonPhone'] ?? 'Not Provided'}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Billing Address:\n'
                          '${apinvoice['billingAddress'] ?? 'No.40, Kenikarai'}\n'
                          '${apinvoice['shippingAddress'] ?? 'No.35, Aranmanai'}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Invoice No: ${apinvoice['invoiceNo'] ?? invoiceId}\n'
                          'Invoice Date: $invoiceDate\n'
                          'Due Date: $dueDate\n'
                          'Payment Terms: ${apinvoice['paymentTerms'] ?? '15 days'}\n'
                          'Currency: ${apinvoice['currency'] ?? 'INR'}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
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
                      color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'SI No',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Description',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'HSN Code',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Qty',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Unit Price',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Tax',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Amount',
                          style: const pw.TextStyle(color: PdfColors.white),
                        ),
                      ),
                    ],
                  ),
                  ..._buildItemRows(items),
                ],
              ),
              //        pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total Amount'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(invoiceAmount.toStringAsFixed(2)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total Discount'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${apinvoice['totalDiscount']?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('CGST'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${itemDetails['cgst']?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('SGST'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${itemDetails['sgst']?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Round Off Amount'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          invoiceAmount != 0
                              ? (invoiceAmount.roundToDouble() - invoiceAmount)
                                    .toStringAsFixed(2)
                              : '0.00',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Amount in Words: $amountInWords',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Total [Including Tax]: ${invoiceAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Declaration:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                apinvoice['declaration'] ??
                    'We declare that this invoice shows the actual price of the described items and that all particulars are true and correct.',
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [pw.Text('Authorized Signatory')],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/goods_receipt_note_${apinvoice['randomId'] ?? invoiceId}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Load logo image from assets
  Future<pw.MemoryImage> _loadLogoImage() async {
    try {
      final data = await rootBundle.load('assets/bestmummy.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo image: $e');
      rethrow;
    }
  }

  // Build table rows for items
  List<pw.TableRow> _buildItemRows(List<dynamic> items) {
    if (items.isEmpty || items.every((item) => item == null || item.isEmpty)) {
      return [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('1'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('N/A'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('N/A'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('N/A'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('0.00'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('0.00'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('0.00'),
            ),
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
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('${index + 1}'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(item['itemName']?.toString() ?? 'N/A'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(item['hsnCode']?.toString() ?? 'N/A'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(item['stockQuantity']?.toString() ?? 'N/A'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              item['unitPrice'] != null
                  ? item['unitPrice'].toStringAsFixed(2)
                  : '0.00',
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(item['purchasetaxName']?.toString() ?? '0.00%'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              item['totalPrice'] != null
                  ? item['totalPrice'].toStringAsFixed(2)
                  : '0.00',
            ),
          ),
        ],
      );
    }).toList();
  }

  // Convert amount to words
  String _amountInWords(double amount) {
    if (amount == 0) return 'Zero only';

    final wholeNumber = amount.toInt();
    final fraction = ((amount - wholeNumber) * 100).round();

    final wholeWords = _convertNumberToWords(wholeNumber);
    final fractionWords = fraction > 0
        ? ' and ${_convertNumberToWords(fraction)} paise'
        : '';

    return '${wholeWords[0].toUpperCase()}${wholeWords.substring(1)}$fractionWords only';
  }

  // Convert number to words
  String _convertNumberToWords(int number) {
    if (number == 0) return '';

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
