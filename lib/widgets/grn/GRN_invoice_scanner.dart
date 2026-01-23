// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img;
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:printing/printing.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// List<CameraDescription>? cameras;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Auto Camera to PDF with OCR',
//       home: CameraToPdfScreen(),
//     );
//   }
// }

// class CameraToPdfScreen extends StatefulWidget {
//   const CameraToPdfScreen({super.key});

//   @override
//   _CameraToPdfScreenState createState() => _CameraToPdfScreenState();
// }

// class _CameraToPdfScreenState extends State<CameraToPdfScreen> {
//   CameraController? _controller;
//   bool isInitialized = false;
//   bool isFocused = false;
//   bool isClear = false;

//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//   }

//   Future<void> _initCamera() async {
//     final status = await Permission.camera.request();
//     if (!status.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Camera permission not granted')),
//       );
//       return;
//     }

//     _controller = CameraController(cameras![0], ResolutionPreset.high);
//     await _controller!.initialize();

//     setState(() {
//       isInitialized = true;
//     });

//     await Future.delayed(Duration(milliseconds: 500));
//     _focusCamera();
//   }

//   Future<void> _focusCamera() async {
//     try {
//       await _controller!.setFocusMode(FocusMode.auto);
//       await Future.delayed(Duration(seconds: 2), () {
//         setState(() {
//           isFocused = true;
//         });
//       });

//       if (isFocused) {
//         _checkImageClarity();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Focus failed. Try again')),
//         );
//       }
//     } catch (e) {
//       print("Error focusing camera: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to focus camera: $e')),
//       );
//     }
//   }

//   Future<void> _checkImageClarity() async {
//     await Future.delayed(Duration(seconds: 2));
//     setState(() {
//       isClear = true;
//     });

//     if (isClear) {
//       _captureAndGeneratePdf();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Image not clear, please focus again')),
//       );
//     }
//   }

//   Future<void> _captureAndGeneratePdf() async {
//     final tempDir = await getTemporaryDirectory();
//     final imgPath = p.join(tempDir.path, 'capture.jpg');
//     Map<String, dynamic> extracted = {}; // Changed to dynamic

//     try {
//       final XFile file = await _controller!.takePicture();
//       await file.saveTo(imgPath);

//       final imageBytes = await file.readAsBytes();
//       final image = img.decodeImage(imageBytes);

//       if (image != null) {
//         final croppedImage = img.copyCrop(image,
//             x: 50, y: 50, width: image.width - 100, height: image.height - 100);

//         final croppedImgPath = p.join(tempDir.path, 'cropped_capture.jpg');
//         final croppedImgFile = File(croppedImgPath)
//           ..writeAsBytesSync(img.encodeJpg(croppedImage));

//         final pdf = pw.Document();
//         final croppedImageBytes = await croppedImgFile.readAsBytes();

//         pdf.addPage(
//           pw.Page(
//             build: (pw.Context context) {
//               return pw.Center(
//                 child: pw.Image(pw.MemoryImage(croppedImageBytes)),
//               );
//             },
//           ),
//         );

//         extracted = await _performOCR(croppedImgFile);
//         print('Extracted Data: $extracted');

//         // Quantity analysis - now handles dynamic types
//         List<String> quantities = [];
//         if (extracted['Quantities'] is List) {
//           quantities = (extracted['Quantities'] as List)
//               .map((q) => q.toString())
//               .toList();
//         } else if (extracted['Quantities'] is String) {
//           quantities = extracted['Quantities'].split(',');
//         }

//         print('\n📊 EXTRACTED QUANTITIES:');
//         for (int i = 0; i < quantities.length; i++) {
//           print('Item ${i + 1} Quantity: ${quantities[i]}');
//         }

//         await Printing.layoutPdf(onLayout: (format) => pdf.save());

//         if (mounted) {
//           // Convert to String map if needed by the next screen
//           final Map<String, String> stringMap = {};
//           extracted.forEach((key, value) {
//             if (value is String) {
//               stringMap[key] = value;
//             } else if (value is List || value is Map) {
//               stringMap[key] = jsonEncode(value);
//             } else if (value != null) {
//               stringMap[key] = value.toString();
//             }
//           });
//           Navigator.of(context).pop(stringMap);
//         }
//       }
//     } catch (e) {
//       print("Error capturing or processing image: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed: $e')),
//         );
//         Navigator.of(context).pop();
//       }
//     }
//   }

// // Updated to return Map<String, dynamic> to handle complex data
// // Updated _performOCR with more detailed logging
//   Future<Map<String, dynamic>> _performOCR(File imageFile) async {
//     print('\n=== STARTING OCR PROCESS ===');
//     try {
//       final text = await _performOCRFromImage(imageFile);
//       print('\n=== RAW OCR OUTPUT ===\n$text');

//       final cleanedText = cleanOcrText(text);
//       print('\n=== CLEANED OCR TEXT ===\n$cleanedText');

//       final extracted = extractFields(cleanedText);

//       // Enhanced fallback checks with more patterns
//       print('\n=== FALLBACK CHECKS ===');

//       // Invoice Number fallback
//       if (extracted['InvoiceNo'] == null) {
//         print('Checking fallback patterns for Invoice No...');
//         // More flexible pattern for invoice numbers
//         final fallbackInvNo = RegExp(r'([A-Z0-9]{3,}[- ][A-Z0-9]{2,})')
//             .firstMatch(cleanedText.toUpperCase());
//         if (fallbackInvNo != null) {
//           extracted['InvoiceNo'] = fallbackInvNo
//               .group(1)!
//               .replaceAll(' ', '')
//               .replaceAll(':', '')
//               .trim();
//           print('⚠️ Using fallback Invoice No: ${extracted['InvoiceNo']}');
//         }
//       }

//       // Date fallback
//       if (extracted['InvoiceDate'] == null) {
//         print('Checking fallback patterns for Date...');
//         // More flexible date pattern
//         final fallbackDate = RegExp(r'(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})')
//             .firstMatch(cleanedText);
//         if (fallbackDate != null) {
//           String rawDate =
//               fallbackDate.group(1)!.replaceAll(' ', '').replaceAll('/', '-');
//           // Fix common OCR errors
//           rawDate = rawDate.replaceAll('2L', '25').replaceAll('O', '0');
//           extracted['InvoiceDate'] = _parseDate(rawDate);
//           print('⚠️ Using fallback Date: ${extracted['InvoiceDate']}');
//         }
//       }

//       // Process quantities
//     if (extracted['Items'] != null) {
//     final items = extracted['Items'] as List<Map<String, dynamic>>;
//     // Create a separate Quantities list if needed
//     extracted['Quantities'] = items.map((item) => {
//           'quantity': item['quantity'],
//           'unit': item['unit']
//         }).toList();
//   }

//       print('\n=== FINAL EXTRACTED VALUES ===');
//       print('Invoice No: ${extracted['InvoiceNo'] ?? "Not found"}');
//       print('Invoice Date: ${extracted['InvoiceDate'] ?? "Not found"}');

//       if (extracted['Items'] != null) {
//         print('Extracted Items:');
//         for (final item in (extracted['Items'] as List<dynamic>)) {
//           print(
//               '${item['itemNo']}. ${item['itemName']} - Qty: ${item['quantity']} @ ${item['rate']}');
//         }
//       }

//       return extracted;
//     } catch (e) {
//       print("❌ OCR Processing Error: $e");
//       return {};
//     }
//   }

// // Helper function to clean OCR text
//   String cleanOcrText(String text) {
//     return text
//         .replaceAll('Invoicp', 'Invoice')
//         .replaceAll('Ivoice', 'Invoice')
//         .replaceAll('Numben', 'Number')
//         .replaceAll('Dato', 'Date')
//         .replaceAll('Quantiry', 'Quantity')
//         .replaceAll('Itoms', 'Items')
//         .replaceAll('Rato', 'Rate')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();
//   }

//   Future<String> _performOCRFromImage(File imageFile) async {
//     final inputImage = InputImage.fromFile(imageFile);
//     final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

//     try {
//       final RecognizedText recognizedText =
//           await textRecognizer.processImage(inputImage);
//       return recognizedText.text;
//     } catch (e) {
//       print("❌ OCR Error: $e");
//       return '';
//     } finally {
//       textRecognizer.close();
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Scan to PDF + OCR")),
//       body: isInitialized
//           ? Stack(
//               children: [
//                 CameraPreview(_controller!),
//                 if (!isFocused || !isClear)
//                   Center(child: CircularProgressIndicator()),
//               ],
//             )
//           : Center(child: CircularProgressIndicator()),
//     );
//   }
// }

// Map<String, dynamic> extractFields(String text) {
//   print('Starting extractFields with input text: $text');
//   final Map<String, dynamic> extracted = {};
//   print('Initialized extracted map: $extracted');
//   var preprocessedText = text.toUpperCase();
//   print('Preprocessed text to uppercase: $preprocessedText');
//   int itemNo = 1;

//   // Normalize newlines to ensure proper line splitting
//   final normalizedText = text.replaceAll(RegExp(r'\r\n|\r|\n'), '\n');
//   final lines = normalizedText
//       .split('\n')
//       .map((line) => line.trim())
//       .where((line) => line.isNotEmpty)
//       .toList();
//   print('Split text into lines: ${lines.length} lines found');
//   print('📜 OCR Lines:');
//   for (var i = 0; i < lines.length; i++) {
//     print('Line ${i + 1}: "${lines[i]}"');
//   }

//   // 1. Invoice Number extraction
//   print('\n=== Extracting Invoice Number ===');
//   final invoiceNoPatterns = [
//     RegExp(r'\b([A-Z]+[-|/]\d+[-|/]\d{2}-\d{2})\b'),
//     RegExp(r'(?:INV|INY|BILL)\s*NO[\s:]*([A-Z0-9-]+)', caseSensitive: false),
//     RegExp(r'INV\s*NO[^\n]*?([A-Z0-9-]{4,})'),
//     RegExp(r'\b(SIT-\d+)\b'),
//   ];

//   preprocessedText = preprocessedText.replaceAll('|', '/');
//   for (final pattern in invoiceNoPatterns) {
//     final match = pattern.firstMatch(preprocessedText);
//     if (match != null) {
//       String candidate = match.group(1)!.trim();
//       if (!_isPartOfOtherField(candidate, preprocessedText)) {
//         extracted['InvoiceNo'] = candidate;
//         print('✅ Set InvoiceNo: ${extracted['InvoiceNo']}');
//         break;
//       }
//     }
//   }

//   // Fallback invoice number
//   if (!extracted.containsKey('InvoiceNo')) {
//     print('⚠️ No invoice number found, using fallback');
//     final fallbackMatch = RegExp(r'NO\.?\s*:?\s*([A-Z0-9/-]+)').firstMatch(preprocessedText);
//     if (fallbackMatch != null) {
//       extracted['InvoiceNo'] = fallbackMatch.group(1)!;
//       print('✅ Set fallback InvoiceNo: ${extracted['InvoiceNo']}');
//     } else {
//       print('❌ No invoice number found');
//     }
//   }

//   // 2. Date extraction
//   print('\n=== Extracting Date ===');
//   final datePatterns = [
//     RegExp(r'(?:DATE|INV\s*DATE|IRY\s*DATE|IRV\s*DATE|RV\s*DATE|INV\s*DALE)[\s:]*(\d{2})[\./](\d{2})[\./]?(\d{2,4})', caseSensitive: false),
//     RegExp(r'\b(\d{2})[-\s./](\d{2})[-\s./](\d{2,4})\b'),
//     RegExp(r'(?:DATE|INV\s*DATE|IRY\s*DATE|IRV\s*DATE|RV\s*DATE|INV\s*DALE)[\s:]*(\d{2})(\d{2})\s*(\d{4})\b', caseSensitive: false),
//     RegExp(r'(?:DATE|INV\s*DATE|IRY\s*DATE|IRV\s*DATE|RV\s*DATE|INV\s*DALE)[\s:]*(\d{8})\b', caseSensitive: false),
//   ];

//   for (final pattern in datePatterns) {
//     final match = pattern.firstMatch(preprocessedText);
//     if (match != null && match.groupCount >= 3) {
//       String rawDate = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
//       rawDate = rawDate.replaceAll(' ', '-').replaceAll('.', '-').replaceAll('/', '-');
//       String? parsedDate = _parseDate(rawDate);
//       if (parsedDate != null) {
//         extracted['InvoiceDate'] = parsedDate;
//         print('✅ Set InvoiceDate: ${extracted['InvoiceDate']}');
//         break;
//       }
//     } else if (match != null && match.group(1)?.length == 8) {
//       String rawDate = match.group(1)!;
//       rawDate = '${rawDate.substring(0, 2)}-${rawDate.substring(2, 4)}-${rawDate.substring(4, 8)}';
//       String? parsedDate = _parseDate(rawDate);
//       if (parsedDate != null) {
//         extracted['InvoiceDate'] = parsedDate;
//         print('✅ Set fallback InvoiceDate: ${extracted['InvoiceDate']}');
//         break;
//       }
//     }
//   }

//   // 3. Item extraction (Improved for single-line OCR text)
//   print('\n=== Extracting Items ===');
//   final List<Map<String, dynamic>> extractedItems = [];
//   print('Initialized items list: $extractedItems');

//   // Enhanced blocklist
//   final blocklist = RegExp(
//       r'^(?:SUB\s*TOTAL|GOODS\s*DESCRIPTION|HSN\s*CODE|MRP\s*QTY|RATE|AMOUNT|TOTAL|QTY|QUANTITY|CGST|SGST|GSTIN|GSTN|INV\s*NO|DATE|STIN|AMT|NET|MODE|SALES|TXBL|EST\s*MUMMY|STREET|SALAI|BAZAR|DLIP|RMD|VASAVI|COMPLEX|ALANGACHERI|ARANMANAI|RAMANATHAPURAM|PIN|PHONE|EMAIL|ERMAIL|AGENCY|SWEET\s*CAKES|LOCAL\s*BEAT|AMANATHAPURAM|MARIAMMAN|TAMIL|TANIL|NADU|FSSAI|TAX\s*INVOICE|ROUNDED\s*OFF|UTHEES\s*AGENCT|CASE\s*\d+|KGS\s*\d+|PCS\s*\d+|PKT\s*\d+|NOS\s*\d+|SREEAGENCY|SREE|CELL|BLNG|SHPPING|SHPPIN|BLN|PARTICULARS|QLYKG|QTY-KG|QTY\s*KG|FREE|DIS|TAX|ART|ELLISG|ELLIS|SHIPPING|CREDT|09096119|19059010|21069099|PARTICULARS\s*HSN\s*QLY|QLY\s*KG\s*FREE|CASE|KA|SI|ROUNDED|KG|CORE|NTEL|SE|^\d+$)\b',
//       caseSensitive: false);

//   // Pattern to match quantity and unit
//   final qtyPattern = RegExp(
//       r'\b(\d+\.?\d*)\s*(KG|KGS|PCS|PKT|NOS|CASE|G|GM|GRAM|KQ|ASE|ÇASE)\b',
//       caseSensitive: false);

//   // Pattern to match the start of an item (number followed by at least two meaningful words)
//   final itemStartPattern = RegExp(r'\b(\d+)\s+([A-Z\s]+(?:\d+\s*(?:KG|KGS|G|GM|GRAM|CASE|PCS|PKT|NOS))?\s*\d*)\b');

//   // Split the preprocessed text into segments based on headers
//   final segments = preprocessedText.split(RegExp(r'\b(GOODS\s*DESCRIPTION|PARTICULARS)\b', caseSensitive: false));
//   String? itemSection;

//   // Find the segment containing the item data (before "GOODS DESCRIPTION")
//   for (int i = 0; i < segments.length; i++) {
//     if (i < segments.length - 1) { // Items are before "GOODS DESCRIPTION"
//       itemSection = segments[i];
//       print('Found potential item section: $itemSection');
//       break;
//     }
//   }

//   if (itemSection != null) {
//     // Find all potential item starts
//     final itemMatches = itemStartPattern.allMatches(itemSection).toList();
//     for (int i = 0; i < itemMatches.length; i++) {
//       String quantityAtStart = itemMatches[i].group(1)!;
//       String potentialItemName = itemMatches[i].group(2)!;

//       // Ensure the item name has at least two words to avoid single-word non-items
//       final words = potentialItemName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
//       if (words.length < 2) {
//         print('Skipped item with insufficient words: $potentialItemName');
//         continue;
//       }

//       // Clean the item name
//       String itemName = potentialItemName
//           .replaceAll(
//               RegExp(r'\s*\d+\.?\d*\s*(KG|KGS|PCS|PKT|NOS|CASE|G|GM|GRAM|KQ|ASE|ÇASE)\s*$', caseSensitive: false),
//               '')
//           .replaceAll(RegExp(r'\s*\d+(?:GM|G|KG|KGS|PCS|PKT|NOS|CASE|KQ|ASE|ÇASE)\s*$', caseSensitive: false), '')
//           .replaceAll(RegExp(r'\s*\d+$'), '') // Remove trailing numbers
//           .trim();

//       // OCR corrections
//       itemName = itemName
//           .replaceAll('CHHEESE', 'CHEESE')
//           .replaceAll('OHICKEN', 'CHICKEN')
//           .replaceAll('PRENIUM', 'PREMIUM')
//           .replaceAll('PRERMIUM', 'PREMIUM')
//           .replaceAll('FLAVOURED1', 'FLAVOURED')
//           .replaceAll('ÇASE', 'CASE')
//           .replaceAll('KG1', 'KG')
//           .replaceAll('GANACHEGS', 'GANACHE')
//           .replaceAll('MAP', 'MIX')
//           .replaceAll(RegExp(r'^KG\s*', caseSensitive: false), '')
//           .replaceAll(RegExp(r'\s*KG\s*$', caseSensitive: false), '')
//           .trim();

//       // Skip invalid or blocklisted terms
//       if (itemName.isEmpty || blocklist.hasMatch(itemName) || itemName.length < 3) {
//         print('Skipped invalid/blocklisted item: $itemName');
//         continue;
//       }

//       // Find the quantity and unit after the item name
//       int startIndex = itemSection.indexOf(itemMatches[i].group(0)!);
//       String remainingText = itemSection.substring(startIndex + itemMatches[i].group(0)!.length);
//       final qtyMatch = qtyPattern.firstMatch(remainingText);

//       String? quantity;
//       String? unit;
//       if (qtyMatch != null) {
//         quantity = qtyMatch.group(1)?.trim();
//         unit = qtyMatch.group(2)?.trim() ?? 'UNKNOWN';
//         if (unit == 'KQ') unit = 'KG';
//         if (unit == 'ASE' || unit == 'ÇASE') unit = 'CASE';
//       } else {
//         // Look for quantity in the item name itself (e.g., "2 KG" in "RICH PREMIUM TRUFFLE 2 KG")
//         final embeddedQtyMatch = RegExp(r'\b(\d+\.?\d*)\s*(KG|KGS|PCS|PKT|NOS|CASE|G|GM|GRAM)\b', caseSensitive: false)
//             .firstMatch(potentialItemName);
//         if (embeddedQtyMatch != null) {
//           quantity = embeddedQtyMatch.group(1)?.trim();
//           unit = embeddedQtyMatch.group(2)?.trim() ?? 'CASE';
//         } else {
//           quantity = quantityAtStart;
//           unit = 'CASE'; // Default to CASE if no unit found
//         }
//       }

//       // Parse quantity
//       String parsedQuantity = quantity != null ? _parseQuantity(quantity, unit) : '1';
//       extractedItems.add({
//         'itemName': itemName,
//         'quantity': parsedQuantity,
//         'unit': unit ?? 'UNKNOWN'
//       });
//       print('Extracted item: $itemName, Qty: $parsedQuantity ${unit ?? 'UNKNOWN'}');
//     }
//   }

//   // Extract rates for items
//   final rateMatches = RegExp(r'\b(\d+\.\d{2})\b').allMatches(preprocessedText).toList();
//   int rateIndex = 0;
//   for (var item in extractedItems) {
//     while (rateIndex < rateMatches.length) {
//       String rate = rateMatches[rateIndex].group(1)!;
//       // Skip rates that are part of taxes, totals, or other non-rate values
//       if (rate == "42906.60" || rate == "3861.59" || rate == "9.00" || rate == "703.52" || rate == "259.60" || rate == "74.91") {
//         rateIndex++;
//         continue;
//       }
//       item['rate'] = rate;
//       print('Added rate ${item['rate']} for item: ${item['itemName']}');
//       rateIndex++;
//       break;
//     }
//   }

//   // Finalize items
//   print('\n=== Finalizing Items ===');
//   final seenNames = <String>{};
//   final List<Map<String, dynamic>> uniqueItems = [];
//   for (var item in extractedItems) {
//     String itemName = item['itemName'];
//     if (!seenNames.contains(itemName.toUpperCase())) {
//       uniqueItems.add({
//         'itemNo': (itemNo++).toString(),
//         'itemName': itemName,
//         'quantity': item['quantity'],
//         'unit': item['unit'],
//         'rate': item['rate']
//       });
//       seenNames.add(itemName.toUpperCase());
//     }
//   }

//   if (uniqueItems.isNotEmpty) {
//     extracted['Items'] = uniqueItems;
//     final itemNames = uniqueItems.map((item) => item['itemName']).join(', ');
//     print('📋 Dialog: Extracted Item Names: [$itemNames]');
//     print('✅ Set Items: $uniqueItems');
//   } else {
//     print('📋 Dialog: Extracted Item Names: []');
//     print('❌ No items extracted');
//   }

//   // 4. GSTIN extraction
//   print('\n=== Extracting GSTIN ===');
//   final gstinMatch = RegExp(r'(?:GSTIN|GSTN|STIN)\s*:?\s*(\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z])\b', caseSensitive: false)
//       .firstMatch(preprocessedText);
//   if (gstinMatch != null) {
//     extracted['GSTIN'] = gstinMatch.group(1)!;
//     print('✅ Set GSTIN: ${extracted['GSTIN']}');
//   } else {
//     print('❌ No GSTIN found');
//   }

//   // 5. Total amount extraction
//   print('\n=== Extracting Total Amount ===');
//   final totalMatch = RegExp(r'(?:TXBL\s*AMT|NET\s*AMT|NET\s*ARNT|TOTAL|ART|NCT\s*ARNT)[\s:.]*(\d+\.\d{2,})', caseSensitive: false)
//       .firstMatch(preprocessedText) ??
//       RegExp(r'\b(\d+\.\d{2,})\b').firstMatch(preprocessedText);
//   if (totalMatch != null) {
//     extracted['TotalAmount'] = totalMatch.group(1)!;
//     print('✅ Set TotalAmount: ${extracted['TotalAmount']}');
//   } else {
//     print('❌ No Total Amount found');
//   }

//   print('\n=== Final Extracted Data ===');
//   print('Final extracted map: $extracted');
//   return extracted;
// }

// String _parseQuantity(String quantity, String unit) {
//   print('Parsing quantity: $quantity with unit: $unit');
//   try {
//     String parsedQuantity = quantity.replaceAll(RegExp(r'[^\d.]'), '');
//     double value = double.parse(parsedQuantity);

//     // Convert based on unit
//     if (unit.toUpperCase() == 'G' || unit.toUpperCase() == 'GM' || unit.toUpperCase() == 'GRAM') {
//       value = value / 1000; // Convert grams to kilograms
//     }
//     parsedQuantity = value.toStringAsFixed(3); // Keep 3 decimal places
//     print('✅ Parsed quantity: $parsedQuantity');
//     return parsedQuantity.isEmpty ? '1' : parsedQuantity;
//   } catch (e) {
//     print('❌ Invalid quantity format: $quantity');
//     return '1';
//   }
// }

// String? _parseDate(String rawDate) {
//   print('Parsing date: $rawDate');
//   try {
//     final parts = rawDate.split('-');
//     if (parts.length != 3) {
//       print('❌ Invalid date parts: $rawDate');
//       return null;
//     }

//     int day = int.parse(parts[0]);
//     int month = int.parse(parts[1]);
//     int year = int.parse(parts[2]);

//     if (year < 100) {
//       year += year < 50 ? 2000 : 1900;
//     }

//     if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > 2100) {
//       print('❌ Invalid date values: $rawDate');
//       return null;
//     }

//     return '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString().padLeft(4, '0')}';
//   } catch (e) {
//     print('❌ Invalid date format: $rawDate');
//     return null;
//   }
// }

// bool _isPartOfOtherField(String candidate, String text) {
//   return RegExp(r'\b\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z]\b').hasMatch(candidate) ||
//       RegExp(r'\b\d{10}\b').hasMatch(candidate);
// }

// void processAndPrintExtractedData(String ocrText) {
//   final extracted = extractFields(ocrText);

//   // Derive Quantities from Items
//   if (extracted['Items'] != null) {
//     final items = extracted['Items'] as List<Map<String, dynamic>>;
//     extracted['Quantities'] = items.map((item) => {
//           'quantity': item['quantity'],
//           'unit': item['unit']
//         }).toList();
//   }

//   print('\n=== FINAL EXTRACTED VALUES ===');
//   print('Invoice No: ${extracted['InvoiceNo'] ?? "Not found"}');
//   print('Invoice Date: ${extracted['InvoiceDate'] ?? "Not found"}');
//   print('GSTIN: ${extracted['GSTIN'] ?? "Not found"}');
//   print('Total Amount: ${extracted['TotalAmount'] ?? "Not found"}');

//   if (extracted['Items'] != null) {
//     print('Extracted Items:');
//     for (final item in (extracted['Items'] as List<dynamic>)) {
//       print('${item['itemNo']}. ${item['itemName']} - Qty: ${item['quantity']} ${item['unit']}${item['rate'] != null ? ' @ ${item['rate']}' : ''}');
//     }
//   }

//   if (extracted['Quantities'] != null) {
//     print('Extracted Quantities:');
//     for (final qty in (extracted['Quantities'] as List<dynamic>)) {
//       print('Qty: ${qty['quantity']} ${qty['unit']}');
//     }
//   }
// }


