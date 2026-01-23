// import 'dart:io';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:poorder/models/po.dart';
// import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/services.dart' show rootBundle;

// class PurchaseOrderService {
//   static const String baseUrl = 'http://192.168.29.252:8000/nextjstestapi/purchaseapi';

//   Future<Map<String, dynamic>> fetchPurchaseOrder(
//       String purchaseOrderId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/purchaseorders/$purchaseOrderId'),
//     );

//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Failed to load purchase order');
//     }
//   }

//   Future<File> generatePurchaseOrderPdf(String purchaseOrderId) async {
//     // Fetch data from backend
//     final poData = await fetchPurchaseOrder(purchaseOrderId);
//     final itemData =
//         poData['items']?.isNotEmpty == true ? poData['items'][0] : {};

//     // Load the logo image from assets
//     final logoImage = await _loadLogoImage();

//     // Create PDF document
//     final pdf = pw.Document();
//     final formattedOrderDate = poData['orderDate'] != null
//         ? DateFormat('dd-MM-yyyy').format(DateTime.parse(poData['orderDate']))
//         : purchaseOrderId;

//     // Format date
//     final dateFormat = DateFormat('dd-MM-yyyy');
//     final poDate = poData['poDate'] != null
//         ? dateFormat.format(DateTime.parse(poData['poDate']))
//         : 'N/A';
//     final dueDate = poData['dueDate'] != null
//         ? dateFormat.format(DateTime.parse(poData['dueDate']))
//         : 'N/A';

//     // Format amount in words
//     final amountInWords = _amountInWords(poData['pendingOrderAmount'] ?? 0);

//     // Debug print statements
//     print('CGST Value for pdf: ${itemData['pendingCgst']}');
//     print('SGST Value for pdf: ${itemData['pendingSgst']}');
//     print('Full PO Data for pdf: $poData');
//     print('totalPrice: ${itemData['pendingCgst']}');

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.all(20),
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Header section with logo
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Logo
//                   pw.Image(
//                     logoImage,
//                     width: 200, // Increased width
//                     height: 100, // Increased height
//                   ),
//                   // Purchase Order Title
//                   pw.Text(
//                     'Purchase Order',
//                     style: pw.TextStyle(
//                       fontSize: 20,
//                       fontWeight: pw.FontWeight.bold,
//                       color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
//                     ),
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 10),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.end,
//                 children: [
//                   pw.Column(
//                     mainAxisSize: pw.MainAxisSize.min,
//                     crossAxisAlignment: pw.CrossAxisAlignment.end,
//                     children: [
//                       pw.Text(
//                         'Best Mummy',
//                         style: pw.TextStyle(
//                           fontSize: 16,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.SizedBox(height: 4),
//                       pw.Table(
//                         columnWidths: {
//                           0: pw.IntrinsicColumnWidth(),
//                           1: pw.FixedColumnWidth(8),
//                           2: pw.IntrinsicColumnWidth(),
//                         },
//                         defaultVerticalAlignment:
//                             pw.TableCellVerticalAlignment.middle,
//                         children: [
//                           pw.TableRow(children: [
//                             pw.Text('No:', textAlign: pw.TextAlign.right),
//                             pw.SizedBox(),
//                             pw.Text(
//                                 poData['companyAddress'] ?? 'No.40, Kenikarai'),
//                           ]),
//                           pw.TableRow(children: [
//                             pw.Text('Tel:', textAlign: pw.TextAlign.right),
//                             pw.SizedBox(),
//                             pw.Text(poData['companyPhone'] ?? '9781234567'),
//                           ]),
//                           pw.TableRow(children: [
//                             pw.Text('Email:', textAlign: pw.TextAlign.right),
//                             pw.SizedBox(),
//                             pw.Text(poData['companyEmail'] ??
//                                 'bestmummypurchase@gmail.com'),
//                           ]),
//                           pw.TableRow(children: [
//                             pw.Text('GSTIN:', textAlign: pw.TextAlign.right),
//                             pw.SizedBox(),
//                             pw.Text(poData['companyGstin'] ?? 'Not Provided'),
//                           ]),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 20),
//               pw.Table(
//                 border: pw.TableBorder.all(),
//                 columnWidths: {
//                   0: pw.FlexColumnWidth(2),
//                   1: pw.FlexColumnWidth(1.5),
//                   2: pw.FlexColumnWidth(1.5),
//                 },
//                 children: [
//                   pw.TableRow(
//                     decoration: pw.BoxDecoration(
//                       color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
//                     ),
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Vendor Details',
//                           style: pw.TextStyle(
//                             fontSize: 14,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.white,
//                           ),
//                           textAlign: pw.TextAlign.center,
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Billing Address',
//                           style: pw.TextStyle(
//                             fontSize: 14,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.white,
//                           ),
//                           textAlign: pw.TextAlign.center,
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'PO Details',
//                           style: pw.TextStyle(
//                             fontSize: 14,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.white,
//                           ),
//                           textAlign: pw.TextAlign.center,
//                         ),
//                       ),
//                     ],
//                   ),
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           '${poData['vendorName'] ?? 'N/A'}\n'
//                           'GSTIN: ${poData['vendorGstin'] ?? 'Not Provided'}\n'
//                           'Address:\n'
//                           'City: ${poData['city'] ?? 'Not Provided'}\n'
//                           'State: ${poData['state'] ?? 'Not Provided'}\n'
//                           'Country: ${poData['country'] ?? 'Not Provided'}\n'
//                           'Email: ${poData['contactpersonEmail'] ?? 'Not Provided'}\n'
//                           'Phone: ${poData['contactpersonPhone'] ?? 'Not Provided'}',
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Billing Address:\n'
//                           '${poData['billingAddress1'] ?? 'No.40,Kenikarai'}\n'
//                           '${poData['billingAddress2'] ?? 'No.35,Arammani'}',
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: const pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'PO No: ${poData['randomId'] ?? purchaseOrderId}\n'
//                           'PO Date: $formattedOrderDate\n'
//                           'Due Date: $dueDate\n'
//                           'Payment Terms: ${poData['paymentTerms'] ?? '15days'}\n'
//                           'Currency: ${poData['currency'] ?? 'INR'}',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               pw.Table(
//                 border: pw.TableBorder.all(),
//                 columnWidths: {
//                   0: pw.FlexColumnWidth(0.5),
//                   1: pw.FlexColumnWidth(2),
//                   2: pw.FlexColumnWidth(0.8),
//                   3: pw.FlexColumnWidth(0.8),
//                   4: pw.FlexColumnWidth(0.8),
//                   5: pw.FlexColumnWidth(1),
//                   6: pw.FlexColumnWidth(1),
//                   7: pw.FlexColumnWidth(0.8),
//                   8: pw.FlexColumnWidth(1.2),
//                 },
//                 children: [
//                   pw.TableRow(
//                     decoration: pw.BoxDecoration(
//                       color: PdfColor(38 / 255, 89 / 255, 198 / 255, 1.0),
//                     ),
//                     children: [
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'SI No',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Description',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'hsnCode',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Count',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Qty',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Po Qty',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Unit Price',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Tax',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Amount',
//                           style: pw.TextStyle(color: PdfColors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                   ..._buildItemRows(poData['items'] ?? []),
//                 ],
//               ),
//               pw.Table(
//                 border: pw.TableBorder.all(),
//                 columnWidths: {
//                   0: pw.FlexColumnWidth(2),
//                   1: pw.FlexColumnWidth(1),
//                 },
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Total Amount')),
//                       pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text(
//                               '${poData['finalPrice']?.toStringAsFixed(2) ?? '385750.00'}')),
//                     ],
//                   ),
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Total Discount')),
//                       pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text(
//                               '${poData['pendingDiscountAmount']?.toStringAsFixed(2) ?? '385750.00'}')),
//                     ],
//                   ),
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text('CGST'),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                             '${itemData['pendingCgst']?.toStringAsFixed(2) ?? '0.00'}'),
//                       ),
//                     ],
//                   ),
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text('SGST'),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                             '${itemData['pendingSgst']?.toStringAsFixed(2) ?? '0.00'}'),
//                       ),
//                     ],
//                   ),
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text('Round Off Amount')),
//                       pw.Padding(
//                           padding: pw.EdgeInsets.all(5),
//                           child: pw.Text(
//                               '${poData['roundOffAmount']?.toStringAsFixed(2) ?? '0.0'}')),
//                     ],
//                   ),
//                 ],
//               ),
//               pw.Table(
//                 columnWidths: {
//                   0: pw.FlexColumnWidth(2),
//                   1: pw.FlexColumnWidth(1),
//                 },
//                 children: [
//                   pw.TableRow(
//                     children: [
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Amount in Words: ${_amountInWords(poData['pendingOrderAmount'] ?? 0)}',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                       pw.Padding(
//                         padding: pw.EdgeInsets.all(5),
//                         child: pw.Text(
//                           'Total [Including Tax]: ${poData['pendingOrderAmount']?.toStringAsFixed(2) ?? '0.00'}',
//                           style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text(
//                 'Terms & Conditions',
//                 style: pw.TextStyle(
//                   fontSize: 14,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 10),
//               ..._buildTermsAndConditions(poData['termsAndConditions'] ?? []),
//               pw.SizedBox(height: 20),
//               pw.Text(
//                 'Declaration:',
//                 style: pw.TextStyle(
//                   fontSize: 14,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: 10),
//               pw.Text(poData['declaration'] ??
//                   'We declare that this invoice shows the actual price of the described items and that all particulars are true and correct.'),
//               pw.SizedBox(height: 20),
//               pw.Row(
//                 children: [
//                   pw.Expanded(
//                     child: pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.center,
//                       children: [
//                         pw.Text('Page 1 of 1'),
//                       ],
//                     ),
//                   ),
//                   pw.Text('Authorized Signatory'),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     // Save the PDF file
//     final output = await getTemporaryDirectory();
//     final file = File(
//         "${output.path}/purchase_order_${poData['poNumber'] ?? purchaseOrderId}.pdf");
//     await file.writeAsBytes(await pdf.save());

//     return file;
//   }

//   Future<pw.MemoryImage> _loadLogoImage() async {
//     final data = await rootBundle.load('assets/bestmummy.png');
//     return pw.MemoryImage(data.buffer.asUint8List());
//   }

//   List<pw.TableRow> _buildItemRows(List<dynamic> items) {
//     return items.map<pw.TableRow>((item) {
//       return pw.TableRow(
//         children: [
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text('${items.indexOf(item) + 1}')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['itemName'] ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['hsncode']?.toString() ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['pendingCount']?.toString() ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['pendingQuantity']?.toString() ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['pendingTotalQuantity']?.toString() ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['newPrice']?.toStringAsFixed(2) ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child: pw.Text(item['taxPercentage']?.toString() ?? '')),
//           pw.Padding(
//               padding: pw.EdgeInsets.all(5),
//               child:
//                   pw.Text(item['pendingTotalPrice']?.toStringAsFixed(2) ?? '')),
//         ],
//       );
//     }).toList();
//   }

//   List<pw.Widget> _buildTermsAndConditions(List<dynamic> terms) {
//     if (terms.isEmpty) {
//       return [
//         pw.Text(
//             '1. Please quote our Purchase Order No. in your Delivery Note.'),
//         pw.Text('2. Defective and excess quantity will not be accepted.'),
//         pw.Text('3. Subject to Ramanathapuram Jurisdiction Only.'),
//       ];
//     }

//     return terms.map<pw.Widget>((term) {
//       return pw.Text('${terms.indexOf(term) + 1}. $term');
//     }).toList();
//   }

//   String _amountInWords(double amount) {
//     if (amount == 0) return 'Zero only';

//     final wholeNumber = amount.toInt();
//     final fraction = ((amount - wholeNumber) * 100).round();

//     final wholeWords = _convertNumberToWords(wholeNumber);
//     final fractionWords =
//         fraction > 0 ? ' and ${_convertNumberToWords(fraction)} cents' : '';

//     return '${wholeWords[0].toUpperCase()}${wholeWords.substring(1)}$fractionWords only';
//   }

//   String _convertNumberToWords(int number) {
//     if (number == 0) return '';

//     final units = [
//       '',
//       'one',
//       'two',
//       'three',
//       'four',
//       'five',
//       'six',
//       'seven',
//       'eight',
//       'nine'
//     ];
//     final teens = [
//       'ten',
//       'eleven',
//       'twelve',
//       'thirteen',
//       'fourteen',
//       'fifteen',
//       'sixteen',
//       'seventeen',
//       'eighteen',
//       'nineteen'
//     ];
//     final tens = [
//       '',
//       'ten',
//       'twenty',
//       'thirty',
//       'forty',
//       'fifty',
//       'sixty',
//       'seventy',
//       'eighty',
//       'ninety'
//     ];

//     if (number < 10) return units[number];
//     if (number < 20) return teens[number - 10];
//     if (number < 100) {
//       return '${tens[number ~/ 10]} ${units[number % 10]}'.trim();
//     }
//     if (number < 1000) {
//       return '${units[number ~/ 100]} hundred ${_convertNumberToWords(number % 100)}'
//           .trim();
//     }
//     if (number < 100000) {
//       return '${_convertNumberToWords(number ~/ 1000)} thousand ${_convertNumberToWords(number % 1000)}'
//           .trim();
//     }
//     if (number < 10000000) {
//       return '${_convertNumberToWords(number ~/ 100000)} lakh ${_convertNumberToWords(number % 100000)}'
//           .trim();
//     }
//     return '${_convertNumberToWords(number ~/ 10000000)} crore ${_convertNumberToWords(number % 10000000)}'
//         .trim();
//   }
// }
