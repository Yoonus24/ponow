// import 'dart:convert';
// import 'dart:math';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
// import 'dart:io';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:provider/provider.dart';
// import 'package:purchaseorders2/models/po.dart';
// import 'package:purchaseorders2/notifier/purchasenotifier.dart';
// import 'package:purchaseorders2/providers/po_provider.dart'; // Correct import
// import 'package:purchaseorders2/widgets/approved_po_widget.dart';
// import 'package:purchaseorders2/widgets/gridview_approve_widget.dart';

// List<CameraDescription>? camera;

// class DocumentScannerScreen extends StatefulWidget {
//   const DocumentScannerScreen({super.key});
//   @override
//   State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
// }

// class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
//   CameraController? _controller;
//   bool isInitialized = false;
//   bool isFocused = false;
//   bool isClear = false;
//   bool isCameraVisible = false;
//   final TextEditingController _vendorSearchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//   List<PO> _filteredPOs = [];
//   List<PO> _scannedPOs = [];
//   int _skip = 0;
//   final int _limit = 50;
//   bool _hasSearched = false;
//   bool _showDropdown = false;
//   bool _isLoadingMore = false;
//   final ScrollController _scrollController = ScrollController();
//   Map<String, dynamic>? _scannedData;
//   bool _showScannedResults = false;
//   final GlobalKey<AnimatedListState> _scannedListKey =
//       GlobalKey<AnimatedListState>();

//   @override
//   void initState() {
//     super.initState();
//     final poProvider = Provider.of<POProvider>(context,
//         listen: false); // From po_provider.dart
//     poProvider.initVendorScrollListener();
//     _scrollController.addListener(_scrollListener);
//   }

//   void _scrollListener() {
//     if (_scrollController.position.pixels ==
//         _scrollController.position.maxScrollExtent) {
//       _loadMoreVendors();
//     }
//   }

//   Future<void> _loadMoreVendors() async {
//     if (_isLoadingMore) return;

//     setState(() {
//       _isLoadingMore = true;
//     });

//     final poProvider = Provider.of<POProvider>(context, listen: false);
//     await poProvider.fetchingVendors(
//       vendorName: _vendorSearchController.text,
//       skip: _skip + _limit,
//       limit: _limit,
//     );

//     setState(() {
//       _skip += _limit;
//       _isLoadingMore = false;
//     });
//   }

//   void _toggleDropdown() {
//     final poProvider = Provider.of<POProvider>(context, listen: false);

//     if (!_showDropdown) {
//       poProvider.fetchingVendors(
//         vendorName: _vendorSearchController.text,
//         skip: 0,
//         limit: _limit,
//       );
//     }

//     setState(() {
//       _showDropdown = !_showDropdown;
//       _showScannedResults = false;
//     });

//     if (_showDropdown) {
//       _searchFocusNode.requestFocus();
//     } else {
//       _searchFocusNode.unfocus();
//     }
//   }

//   Future<void> _onVendorSelected(String vendor) async {
//     final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
//     final poProvider = Provider.of<POProvider>(context, listen: false);

//     notifier.setSelectedVendor(vendor);
//     await poProvider.fetchPOsByVendor(vendor);

//     setState(() {
//       _hasSearched = true;
//       _filteredPOs = poProvider.approvedPos
//           .where((po) => po.vendorName?.toLowerCase() == vendor.toLowerCase())
//           .toList();
//       _showDropdown = false;
//       _showScannedResults = false;
//     });
//   }

//   Future<void> _initCamera() async {
//     final status = await Permission.camera.request();
//     if (!status.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Camera permission not granted')),
//       );
//       return;
//     }

//     if (camera == null || camera!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No cameras available')),
//       );
//       return;
//     }

//     _controller = CameraController(camera![0], ResolutionPreset.high);
//     try {
//       await _controller!.initialize();
//       setState(() {
//         isInitialized = true;
//       });
//       await Future.delayed(const Duration(milliseconds: 500));
//       await _focusCamera();
//     } catch (e) {
//       print('Error initializing camera: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to initialize camera: $e')),
//       );
//     }
//   }

//   Future<void> _focusCamera() async {
//     try {
//       await _controller!.setFocusMode(FocusMode.auto);
//       await Future.delayed(const Duration(seconds: 2));
//       setState(() {
//         isFocused = true;
//       });

//       if (isFocused) {
//         await _checkImageClarity();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Focus failed. Try again')),
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
//     await Future.delayed(const Duration(seconds: 2));
//     setState(() {
//       isClear = true;
//     });

//     if (isClear) {
//       await _captureAndProcessImage();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Image not clear, please focus again')),
//       );
//     }
//   }

//   Future<void> _captureAndProcessImage() async {
//     final tempDir = await getTemporaryDirectory();
//     final imgPath = p.join(tempDir.path, 'capture.jpg');

//     try {
//       final XFile file = await _controller!.takePicture();
//       await file.saveTo(imgPath);

//       final imageBytes = await file.readAsBytes();
//       final image = img.decodeImage(imageBytes);

//       if (image == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to decode image')),
//         );
//         return;
//       }

//       final croppedImage = img.copyCrop(
//         image,
//         x: 50,
//         y: 50,
//         width: image.width - 100,
//         height: image.height - 100,
//       );

//       final croppedImgPath = p.join(tempDir.path, 'cropped_capture.jpg');
//       final croppedImgFile = File(croppedImgPath)
//         ..writeAsBytesSync(img.encodeJpg(croppedImage));

//       await _performOCR(croppedImgFile);
//     } catch (e) {
//       print("Error capturing or processing image: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to process image: $e')),
//       );
//     } finally {
//       setState(() {
//         isCameraVisible = false;
//       });
//       if (_controller != null) {
//         await _controller!.dispose();
//         _controller = null;
//       }
//     }
//   }

//   Future<void> _performOCR(File imageFile) async {
//     print('\n=== STARTING DOCUMENT SCAN PROCESS ===');
//     try {
//       print('📷 Processing image...');
//       final text = await _performOCRFromImage(imageFile);
//       print('\n=== RAW OCR OUTPUT ===\n$text');

//       final cleanedText = _cleanOCRText(text);
//       print('\n=== CLEANED OCR TEXT ===\n$cleanedText');

//       print('\n🔍 Extracting fields...');
//       _scannedData = await extractFields(text);

//       if (_scannedData == null ||
//           _scannedData!['items'] == null ||
//           (_scannedData!['items'] as List).isEmpty) {
//         print('❌ No items found in scanned document');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No item details found in document')),
//         );
//         return;
//       }

//       final poProvider = Provider.of<POProvider>(context, listen: false);
//       print('\n🔎 Matching against POs...');
//       await poProvider.fetchPOsByVendor(_scannedData!['vendor']);
//       final matchedPOs = poProvider.approvedPos.where((po) {
//         print('\nChecking PO: ${po.randomId}');

//         final scannedVendor =
//             _scannedData?['vendor']?.toString().toUpperCase() ?? '';
//         final poVendor = po.vendorName?.toUpperCase() ?? '';
//         final vendorSimilarity =
//             _calculateItemSimilarity(scannedVendor, poVendor);

//         print('Vendor: Scanned="$scannedVendor", PO="$poVendor"');
//         print(
//             'Vendor Similarity: ${(vendorSimilarity * 100).toStringAsFixed(1)}%');
//         if (vendorSimilarity < 0.8) {
//           print('❌ Vendor does not match');
//           return false;
//         }

//         final scannedItems = _scannedData!['items'] as List;
//         print('🔢 Scanned Items: ${scannedItems.length}');

//         for (var scannedItem in scannedItems) {
//           final scannedName =
//               scannedItem['itemName']?.toString().toLowerCase() ??
//                   scannedItem['scannedName']?.toString().toLowerCase() ??
//                   '';
//           final scannedPrice = scannedItem['apiPrice'] is double
//               ? scannedItem['apiPrice']
//               : double.tryParse(scannedItem['scannedPrice'].toString()) ?? 0.0;

//           print('\n🔍 Checking Item: $scannedName (₹$scannedPrice)');

//           bool itemExists = po.items.any((poItem) {
//             final poName = poItem.itemName?.toLowerCase() ?? '';
//             final poPrice = poItem.newPrice ?? 0.0;
//             final similarity = _calculateItemSimilarity(scannedName, poName);
//             final priceDiff = (poPrice - scannedPrice).abs();

//             print('|-- PO Item: $poName (₹$poPrice)');
//             print('|-- Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
//             print('|-- Price Diff: ₹$priceDiff');

//             return similarity >= 0.75 && priceDiff <= (poPrice * 0.05);
//           });

//           if (!itemExists) {
//             print('❌ No matching item in PO');
//             return false;
//           }
//         }
//         print('✅ PO matched successfully');
//         return true;
//       }).toList();

//       print('\n=== MATCHING RESULTS ===');
//       print('Found ${matchedPOs.length} matching POs');
//       if (matchedPOs.isNotEmpty) {
//         print('Matched POs:');
//         for (var po in matchedPOs) {
//           print(' - PO: ${po.randomId}, Vendor: ${po.vendorName}');
//           print('   Items:');
//           for (var item in po.items) {
//             print('     - ${item.itemName}: ₹${item.newPrice}');
//           }
//         }
//       } else {
//         print('No matching POs found');
//       }

//       setState(() {
//         _scannedPOs = matchedPOs;
//         _showScannedResults = true;
//         _hasSearched = true;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           duration: const Duration(seconds: 3),
//           content: Text(matchedPOs.isNotEmpty
//               ? 'Found ${matchedPOs.length} matching PO(s)'
//               : 'No matching POs found'),
//         ),
//       );
//     } catch (e, stackTrace) {
//       print('❌ OCR Processing Error: $e');
//       print('Stack Trace: $stackTrace');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to process document: $e')),
//       );
//     }
//   }

//   String _cleanOCRText(String text) {
//     return text
//         .replaceAll(RegExp(r'[^\w\s\d\.\-/:&]'), ' ')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .replaceAll('1FIGS', 'FIGS')
//         .trim();
//   }

//   Future<String> _performOCRFromImage(File imageFile) async {
//     final inputImage = InputImage.fromFile(imageFile);
//     final textRecognizer = TextRecognizer();

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

//   Future<void> _startCameraProcess() async {
//     setState(() {
//       isCameraVisible = true;
//     });
//     await _initCamera();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Document Scanner'),
//       ),
//       body: Stack(
//         children: [
//           Consumer<POProvider>(
//             builder: (context, poProvider, child) {
//               return RefreshIndicator(
//                 onRefresh: () async {
//                   if (_vendorSearchController.text.isNotEmpty) {
//                     await poProvider.fetchingVendors(
//                       vendorName: _vendorSearchController.text,
//                       skip: 0,
//                       limit: _limit,
//                     );
//                     setState(() {
//                       _skip = 0;
//                     });
//                   }
//                 },
//                 child: CustomScrollView(
//                   slivers: [
//                     SliverToBoxAdapter(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: TextFormField(
//                                     controller: _vendorSearchController,
//                                     focusNode: _searchFocusNode,
//                                     decoration: InputDecoration(
//                                       labelText: 'Search Vendor',
//                                       border: const OutlineInputBorder(),
//                                       suffixIcon: _vendorSearchController
//                                               .text.isNotEmpty
//                                           ? IconButton(
//                                               icon: const Icon(Icons.clear),
//                                               onPressed: () {
//                                                 _vendorSearchController.clear();
//                                                 _searchFocusNode.unfocus();
//                                                 setState(() {
//                                                   _hasSearched = false;
//                                                   _filteredPOs.clear();
//                                                   _showDropdown = false;
//                                                   _showScannedResults = false;
//                                                 });
//                                               },
//                                             )
//                                           : null,
//                                     ),
//                                     onChanged: (val) async {
//                                       setState(() {
//                                         _hasSearched = val.isNotEmpty;
//                                         _skip = 0;
//                                         _showScannedResults = false;
//                                       });

//                                       if (val.isNotEmpty) {
//                                         await poProvider.fetchingVendors(
//                                           vendorName: val,
//                                           skip: 0,
//                                           limit: _limit,
//                                         );
//                                       } else {
//                                         setState(() {
//                                           _filteredPOs.clear();
//                                         });
//                                       }
//                                     },
//                                     onTap: _toggleDropdown,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 IconButton(
//                                   icon: const Icon(Icons.qr_code_scanner),
//                                   onPressed: _startCameraProcess,
//                                 ),
//                               ],
//                             ),
//                             if (_showDropdown)
//                               Container(
//                                 margin: const EdgeInsets.only(top: 5),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(4),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.1),
//                                       blurRadius: 4,
//                                       offset: const Offset(0, 2),
//                                     )
//                                   ],
//                                 ),
//                                 constraints: const BoxConstraints(
//                                   maxHeight: 200,
//                                 ),
//                                 child: NotificationListener<ScrollNotification>(
//                                   onNotification: (scrollNotification) {
//                                     if (scrollNotification.metrics.pixels ==
//                                         scrollNotification
//                                             .metrics.maxScrollExtent) {
//                                       _loadMoreVendors();
//                                     }
//                                     return false;
//                                   },
//                                   child: ListView.builder(
//                                     controller: _scrollController,
//                                     padding: EdgeInsets.zero,
//                                     itemCount:
//                                         poProvider.filteredVendorNames.length +
//                                             (_isLoadingMore ? 1 : 0),
//                                     itemBuilder: (context, index) {
//                                       if (index >=
//                                           poProvider
//                                               .filteredVendorNames.length) {
//                                         return const Center(
//                                             child: Padding(
//                                           padding: EdgeInsets.all(8.0),
//                                           child: CircularProgressIndicator(),
//                                         ));
//                                       }
//                                       final vendor = poProvider
//                                           .filteredVendorNames
//                                           .elementAt(index);
//                                       return ListTile(
//                                         title: Text(vendor),
//                                         onTap: () {
//                                           _vendorSearchController.text = vendor;
//                                           _onVendorSelected(vendor);
//                                         },
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     if (_hasSearched)
//                       SliverFillRemaining(
//                         child: _showScannedResults
//                             ? _buildScannedResults()
//                             : _buildVendorResults(poProvider),
//                       ),
//                     if (!_hasSearched)
//                       const SliverFillRemaining(
//                         child: Center(
//                           child: Text(
//                             "Search for a vendor or scan an invoice",
//                             style: TextStyle(fontSize: 18, color: Colors.grey),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           if (isCameraVisible && isInitialized)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black,
//                 child: Center(
//                   child: CameraPreview(_controller!),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: isCameraVisible
//           ? FloatingActionButton(
//               onPressed: _captureAndProcessImage,
//               child: const Icon(Icons.camera),
//             )
//           : null,
//     );
//   }

//   Widget _buildScannedResults() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Scanned Document Details:',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Text('Vendor: ${_scannedData?['vendor'] ?? 'Not found'}'),
//               Text('Invoice No: ${_scannedData?['invoiceNo'] ?? 'Not found'}'),
//               Text(
//                   'Invoice Date: ${_scannedData?['invoiceDate'] ?? 'Not found'}'),
//               const SizedBox(height: 16),
//               Text(
//                 'Scanned Items:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               ...(_scannedData?['items'] as List? ?? []).map<Widget>((item) {
//                 return ListTile(
//                   title: Text(item['scannedName'] ?? 'Unknown'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                           'Qty: ${item['quantity']} - Price: ₹${item['scannedPrice']}'),
//                       if (item['matched'] == true)
//                         Text(
//                           'Matched: ${item['itemName']} (₹${item['apiPrice']})',
//                           style: TextStyle(color: Colors.green),
//                         ),
//                       if (item['matched'] != true)
//                         Text('No match found',
//                             style: TextStyle(color: Colors.red)),
//                     ],
//                   ),
//                   trailing: item['matched'] == true
//                       ? const Icon(Icons.check_circle, color: Colors.green)
//                       : const Icon(Icons.error, color: Colors.red),
//                 );
//               }),
//             ],
//           ),
//         ),
//         const Divider(),
//         Expanded(
//           child: _scannedPOs.isEmpty
//               ? const Center(
//                   child: Text(
//                     'No matching POs found',
//                     style: TextStyle(fontSize: 18, color: Colors.grey),
//                   ),
//                 )
//               : GridViewApproveWidget<PO>(
//                   items: _scannedPOs,
//                   itemBuilder: (context, index) {
//                     final po = _scannedPOs[index];
//                     return ApprovedPOWidget(
//                       po: po,
//                       poProvider:
//                           Provider.of<POProvider>(context, listen: false),
//                     );
//                   },
//                   fixedHeight: 260,
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildVendorResults(POProvider poProvider) {
//     return poProvider.isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : poProvider.error != null
//             ? Center(child: Text('Error: ${poProvider.error}'))
//             : _filteredPOs.isEmpty
//                 ? const Center(
//                     child: Text("No POs found for this vendor"),
//                   )
//                 : GridViewApproveWidget<PO>(
//                     items: _filteredPOs,
//                     itemBuilder: (context, index) {
//                       final po = _filteredPOs[index];
//                       return ApprovedPOWidget(
//                         po: po,
//                         poProvider: poProvider,
//                       );
//                     },
//                     fixedHeight: 260,
//                   );
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _vendorSearchController.dispose();
//     _searchFocusNode.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

// Future<Map<String, dynamic>> extractFields(String text) async {
//   print('\n=== EXTRACTING FIELDS FROM OCR TEXT ===');
//   final Map<String, dynamic> extracted = {
//     'vendor': 'Not found',
//     'items': <Map<String, dynamic>>[],
//     'totalQuantity': 0.0,
//     'invoiceNo': 'Not found',
//     'invoiceDate': 'Not found',
//     'status': 'No items found',
//   };

//   try {
//     // Split and clean lines
//     final lines = text
//         .split('\n')
//         .map((line) => line.trim())
//         .where((line) => line.isNotEmpty)
//         .toList();
//     print('📜 OCR Lines:');
//     for (var i = 0; i < lines.length; i++) {
//       print('Line ${i + 1}: "${lines[i]}"');
//     }

//     // Extract vendor
//     final vendorRegex = RegExp(
//       r'(?:^|\n)([A-Z][A-Za-z0-9\s&.,-]+?(?:AGENCY|AGENCIES|TRADERS|ENTERPRISES|CORP|CO\.?|LTD|LIMITED|INC\.?|PVT\.?|PRIVATE|SWEET|CAKES))\b',
//       caseSensitive: false,
//     );
//     for (var line in lines) {
//       final vendorMatch = vendorRegex.firstMatch(line);
//       if (vendorMatch != null) {
//         final vendor = vendorMatch.group(1)?.trim();
//         if (vendor != null &&
//             vendor.length > 3 &&
//             !vendor.toLowerCase().contains('total')) {
//           extracted['vendor'] = vendor;
//           print('✅ Vendor extracted: "${extracted['vendor']}"');
//           break;
//         }
//       }
//     }

//     // Extract invoice number
//     final invoiceNoRegex = RegExp(
//       r'(?:Iny|Inv|Bill|Invoice|noice)\s*(?:No\.?|#)?\s*[:]?[\s]*([A-Z0-9-/#]+)|:([A-Z0-9-/#]+)',
//       caseSensitive: false,
//     );
//     for (var line in lines) {
//       final invoiceNoMatch = invoiceNoRegex.firstMatch(line);
//       if (invoiceNoMatch != null) {
//         final invoiceNo =
//             (invoiceNoMatch.group(1) ?? invoiceNoMatch.group(2))?.trim();
//         if (invoiceNo != null && !invoiceNo.startsWith('33')) {
//           extracted['invoiceNo'] = invoiceNo.replaceAll('|', '/');
//           print('✅ Invoice No extracted: "${extracted['invoiceNo']}"');
//           break;
//         }
//       }
//     }

//     // Extract invoice date
//     final dateRegex = RegExp(
//       r'(?:Date|Inv\.?\s*Date|noice|Ack\s*Dute)[\s]*[:]?[\s]*(\d{1,2}[-./]\d{1,2}[-./]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4}|\d{1,2}[-.][A-Za-z]{3}[-.]\d{2,4})|[:\s]*(\d{1,2}/\d{1,2}/\d{4})',
//       caseSensitive: false,
//     );
//     for (var line in lines) {
//       final dateMatch = dateRegex.firstMatch(line);
//       if (dateMatch != null) {
//         final date = dateMatch.group(1) ?? dateMatch.group(2);
//         if (date != null) {
//           extracted['invoiceDate'] = date.trim();
//           print('✅ Invoice Date extracted: "${extracted['invoiceDate']}"');
//           break;
//         }
//       }
//     }

//     // Extract items
//     final List<Map<String, dynamic>> items = [];
//     final headers = [
//       'description of goods',
//       'items',
//       'goods description',
//       'particulars',
//       'item',
//     ];
//     bool isItemSection = false;
//     String currentItemName = '';
//     double currentQuantity = 1.0;
//     double currentPrice = 0.0;
//     bool isBuildingItem = false;
//     int? quantityLineIndex;
//     int? priceLineIndex;

//     for (var i = 0; i < lines.length; i++) {
//       final line = lines[i].trim();
//       final lowerLine = line.toLowerCase();
//       print('\n🔎 Parsing line ${i + 1}: "$lowerLine"');

//       // Start item section when a header is detected
//       if (headers.any((header) => lowerLine.contains(header))) {
//         isItemSection = true;
//         print(
//             '✅ Detected item header at line ${i + 1}: "$lowerLine", starting item section');
//         // Reset any ongoing item building to avoid mixing pre-header and post-header items
//         if (isBuildingItem && currentPrice > 0 && currentItemName.length > 3) {
//           items.add({
//             'quantity': currentQuantity,
//             'scannedName': currentItemName.trim(),
//             'scannedPrice': currentPrice,
//             'matched': false,
//           });
//           print(
//               '✅ Item added: "${currentItemName.trim()}" (Qty: $currentQuantity, ₹$currentPrice)');
//         }
//         isBuildingItem = false;
//         currentItemName = '';
//         currentQuantity = 1.0;
//         currentPrice = 0.0;
//         quantityLineIndex = null;
//         priceLineIndex = null;
//         continue;
//       }

//       // End item section for non-item lines
//       if (lowerLine.contains('total') ||
//           lowerLine.contains('tax') ||
//           lowerLine.contains('invoice') ||
//           lowerLine.contains('noice') ||
//           lowerLine.contains('date') ||
//           lowerLine.contains('gst') ||
//           lowerLine.contains('fss') ||
//           lowerLine.contains('ack') ||
//           lowerLine.contains('code') ||
//           lowerLine.contains('delivery') ||
//           lowerLine.contains('due') ||
//           lowerLine.contains('buyer') ||
//           lowerLine.contains('consignee') ||
//           lowerLine.contains('dispatch') ||
//           lowerLine.contains('cgst') ||
//           lowerLine.contains('sgst')) {
//         if (isBuildingItem && currentPrice > 0 && currentItemName.length > 3) {
//           items.add({
//             'quantity': currentQuantity,
//             'scannedName': currentItemName.trim(),
//             'scannedPrice': currentPrice,
//             'matched': false,
//           });
//           print(
//               '✅ Item added: "${currentItemName.trim()}" (Qty: $currentQuantity, ₹$currentPrice)');
//         }
//         isItemSection = false;
//         isBuildingItem = false;
//         currentItemName = '';
//         currentQuantity = 1.0;
//         currentPrice = 0.0;
//         quantityLineIndex = null;
//         priceLineIndex = null;
//         print('⏭ Skipping non-item line');
//         continue;
//       }

//       // Process potential items
//       if (!isItemSection || (isItemSection && !headers.contains(lowerLine))) {
//         // Skip header-related lines after the "Goods Description" header
//         if (isItemSection &&
//             (lowerLine.contains('rate') ||
//                 lowerLine.contains('net') ||
//                 lowerLine.contains('hsn') ||
//                 lowerLine.contains('mrp') ||
//                 lowerLine.contains('disc') ||
//                 lowerLine.contains('cgst%') ||
//                 lowerLine.contains('sgst%'))) {
//           print('❌ Skipping header-related line: "$line"');
//           continue;
//         }

//         final parts = line.split(RegExp(r'\s+'));
//         if (parts.isEmpty) {
//           print('❌ Line has no parts: "$line"');
//           continue;
//         }

//         // Check for quantity (e.g., "5 CASE", "5")
//         final quantityMatch = RegExp(r'^(\d+)\s*(CASE|CAS)?$').firstMatch(line);
//         if (quantityMatch != null) {
//           if (isBuildingItem) {
//             currentQuantity = double.tryParse(quantityMatch.group(1)!) ?? 1.0;
//             quantityLineIndex = i;
//             print('📏 Found quantity: $currentQuantity');
//           }
//           continue;
//         }

//         // Check for price (e.g., "703.52 21,105.4E", "259.60 15,576.00")
//         final priceMatch =
//             RegExp(r'(\d+\.\d+)\s*(?:\d+,\d+\.\d+[E]?)?$').firstMatch(line);
//         if (priceMatch != null) {
//           if (isBuildingItem) {
//             currentPrice = double.tryParse(priceMatch.group(1)!) ?? 0.0;
//             priceLineIndex = i;
//             print('💵 Found price: $currentPrice');

//             // If we have both quantity and price, finalize the item
//             if (currentPrice > 0 &&
//                 currentPrice <= 10000 &&
//                 currentItemName.length > 3) {
//               // Remove quantity from item name if present
//               final quantityInNameMatch = RegExp(r'(\d+)\s*(CASE|CAS|KG|G)?$')
//                   .firstMatch(currentItemName);
//               if (quantityInNameMatch != null && quantityLineIndex == null) {
//                 currentQuantity =
//                     double.tryParse(quantityInNameMatch.group(1)!) ?? 1.0;
//                 currentItemName = currentItemName
//                     .replaceAll(quantityInNameMatch.group(0)!, '')
//                     .trim();
//               }
//               items.add({
//                 'quantity': currentQuantity,
//                 'scannedName': currentItemName.trim(),
//                 'scannedPrice': currentPrice,
//                 'matched': false,
//               });
//               print(
//                   '✅ Item added: "${currentItemName.trim()}" (Qty: $currentQuantity, ₹$currentPrice)');
//             } else {
//               print(
//                   '❌ Invalid item: Name="$currentItemName", Qty=$currentQuantity, Price=$currentPrice');
//             }
//             isBuildingItem = false;
//             currentItemName = '';
//             currentQuantity = 1.0;
//             currentPrice = 0.0;
//             quantityLineIndex = null;
//             priceLineIndex = null;
//           }
//           continue;
//         }

//         // Skip lines that are just HSN codes, tax rates, or invalid data
//         if (RegExp(r'^\d{8}$').hasMatch(line) || // HSN code (e.g., "18069010")
//             RegExp(r'^\d+\.\d+$').hasMatch(line) || // e.g., "9.00"
//             line.toLowerCase() == 'kq' ||
//             line.toLowerCase() == 'ase') {
//           print('❌ Skipping non-item data: "$line"');
//           continue;
//         }

//         // Build item name
//         if (isBuildingItem) {
//           currentItemName += ' $line';
//         } else {
//           currentItemName = line;
//           isBuildingItem = true;
//           print('📦 Building item: "$currentItemName"');
//         }
//       }
//     }

//     // Finalize any remaining item
//     if (isBuildingItem && currentPrice > 0 && currentItemName.length > 3) {
//       items.add({
//         'quantity': currentQuantity,
//         'scannedName': currentItemName.trim(),
//         'scannedPrice': currentPrice,
//         'matched': false,
//       });
//       print(
//           '✅ Item added: "${currentItemName.trim()}" (Qty: $currentQuantity, ₹$currentPrice)');
//     }

//     if (items.isNotEmpty) {
//       extracted['items'] = items;
//       extracted['totalQuantity'] =
//           items.fold(0.0, (sum, item) => sum + item['quantity']);
//       extracted['status'] = 'Items found';
//       print('\n🔍 Matching items with backend...');
//       await _matchWithBackendItems(extracted);
//     } else {
//       extracted['status'] = 'No valid items found';
//       print('❌ No valid items found in document');
//     }

//     print('\n🟢 Extracted Data:');
//     print('Vendor: ${extracted['vendor']}');
//     print('Invoice No: ${extracted['invoiceNo']}');
//     print('Invoice Date: ${extracted['invoiceDate']}');
//     print('Items: ${items.length}');
//     for (var item in items) {
//       print(
//           ' - ${item['scannedName']}: Qty ${item['quantity']}, ₹${item['scannedPrice']}');
//       if (item['matched']) {
//         print('   → Matched: ${item['itemName']} (₹${item['apiPrice']})');
//       }
//     }
//   } catch (e, stackTrace) {
//     print('❌ extractFields error: $e');
//     print('Stack Trace: $stackTrace');
//     extracted['status'] = 'Processing error: $e';
//   }

//   return extracted;
// }

// Future<void> _matchWithBackendItems(Map<String, dynamic> result) async {
//   try {
//     print('\n=== MATCHING WITH BACKEND ITEMS ===');
//     final List<dynamic> backendItems = await _fetchPurchaseItems();
//     print('Backend Items Fetched: ${backendItems.length}');
//     for (var item in backendItems) {
//       print(' - ${item['itemName']}: ₹${item['newPrice']}');
//     }

//     final List<dynamic> items = result['items'];
//     final scannedVendor = result['vendor']?.toString().toUpperCase() ?? '';

//     for (var i = 0; i < items.length; i++) {
//       final item = items[i];
//       final scannedName = item['scannedName'].toString().toUpperCase();
//       final scannedPrice = item['scannedPrice'] is double
//           ? item['scannedPrice']
//           : double.tryParse(item['scannedPrice'].toString()) ?? 0.0;

//       print('\n🔍 Matching item: "$scannedName" (₹$scannedPrice)');

//       double highestSimilarity = 0.0;
//       Map<String, dynamic>? bestMatch;

//       for (final backendItem in backendItems) {
//         final backendName =
//             backendItem['itemName']?.toString().toUpperCase() ?? '';
//         final backendPrice = backendItem['newPrice'] is double
//             ? backendItem['newPrice']
//             : double.tryParse(backendItem['newPrice'].toString()) ?? 0.0;

//         final similarity = _calculateItemSimilarity(scannedName, backendName);
//         final priceDifference = (scannedPrice - backendPrice).abs();

//         print('  - Backend Item: "$backendName" (₹$backendPrice)');
//         print('    Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
//         print('    Price Difference: ₹$priceDifference');

//         if (similarity > highestSimilarity &&
//             similarity >= 0.75 &&
//             priceDifference <= (backendPrice * 0.05)) {
//           highestSimilarity = similarity;
//           bestMatch = {
//             ...backendItem,
//             'similarity': similarity,
//             'priceDifference': priceDifference,
//           };
//         }
//       }

//       if (bestMatch != null) {
//         items[i] = {
//           ...item,
//           'matched': true,
//           'itemName': bestMatch['itemName'],
//           'apiPrice': bestMatch['newPrice'],
//         };
//         print(
//             '✅ Matched: "${bestMatch['itemName']}" (₹${bestMatch['newPrice']})');
//       } else {
//         print('❌ No match found for "$scannedName"');
//       }
//     }

//     result['items'] = items;
//     result['matchedItemsCount'] = items.where((i) => i['matched']).length;
//     print('Matched Items Count: ${result['matchedItemsCount']}');
//   } catch (e, stackTrace) {
//     print('❌ _matchWithBackendItems error: $e');
//     print('Stack Trace: $stackTrace');
//   }
// }

// double _calculateItemSimilarity(String a, String b) {
//   final cleanA = a
//       .toLowerCase()
//       .replaceAll(RegExp(r'\b(gm|g|kg|ml|l|pcs)\b', caseSensitive: false), '')
//       .replaceAll(RegExp(r'[^\w\s]'), '')
//       .trim();
//   final cleanB = b
//       .toLowerCase()
//       .replaceAll(RegExp(r'\b(gm|g|kg|ml|l|pcs)\b', caseSensitive: false), '')
//       .replaceAll(RegExp(r'[^\w\s]'), '')
//       .trim();

//   print('Similarity Check:');
//   print('  Cleaned A: "$cleanA"');
//   print('  Cleaned B: "$cleanB"');

//   final maxLength = max(cleanA.length, cleanB.length);
//   if (maxLength == 0) return 0.0;

//   final distance = _levenshteinDistance(cleanA, cleanB);
//   final similarity = 1.0 - (distance / maxLength);
//   print(
//       '  Levenshtein Distance: $distance, Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
//   return similarity;
// }

// int _levenshteinDistance(String a, String b) {
//   if (a.isEmpty) return b.length;
//   if (b.isEmpty) return a.length;

//   final List<List<int>> matrix = List.generate(
//     a.length + 1,
//     (_) => List<int>.filled(b.length + 1, 0),
//   );

//   for (int i = 0; i <= a.length; i++) {
//     matrix[i][0] = i;
//   }
//   for (int j = 0; j <= b.length; j++) {
//     matrix[0][j] = j;
//   }

//   for (int i = 1; i <= a.length; i++) {
//     for (int j = 1; j <= b.length; j++) {
//       final int cost = a[i - 1].toLowerCase() == b[j - 1].toLowerCase() ? 0 : 1;
//       matrix[i][j] = [
//         matrix[i - 1][j] + 1,
//         matrix[i][j - 1] + 1,
//         matrix[i - 1][j - 1] + cost,
//       ].reduce(min);
//     }
//   }
//   return matrix[a.length][b.length];
// }

// Future<List<dynamic>> _fetchPurchaseItems() async {
//   try {
//     print('\n=== FETCHING PURCHASE ITEMS FROM API ===');
//     final response = await http.get(
//       Uri.parse('http://192.168.1.106:8888/purchaseorders/getAll'),
//       headers: {'Content-Type': 'application/json'},
//     );

//     print('API Response Status: ${response.statusCode}');
//     print('API Response Body: ${response.body}');

//     if (response.statusCode == 200) {
//       final decoded = json.decode(response.body);
//       List<dynamic> items = [];

//       if (decoded is List) {
//         for (var po in decoded) {
//           if (po['items'] is List) {
//             items.addAll(po['items']);
//           }
//         }
//       } else if (decoded is Map && decoded.containsKey('items')) {
//         items = decoded['items'] as List;
//       } else if (decoded is Map && decoded.containsKey('data')) {
//         items = decoded['data'] is List
//             ? decoded['data']
//             : decoded['data']['items'] ?? [];
//       }

//       final normalizedItems = items
//           .map((item) {
//             return {
//               'itemName': item['itemName']?.toString().trim() ?? '',
//               'newPrice': item['newPrice'] is double
//                   ? item['newPrice']
//                   : double.tryParse(item['newPrice']?.toString() ?? '0') ?? 0.0,
//             };
//           })
//           .where((item) => item['itemName'].isNotEmpty && item['newPrice'] > 0)
//           .toList();

//       print('Normalized Items: ${normalizedItems.length}');
//       for (var item in normalizedItems) {
//         print(' - ${item['itemName']}: ₹${item['newPrice']}');
//       }
//       return normalizedItems;
//     } else {
//       print('❌ API Error: Status ${response.statusCode}');
//       return [];
//     }
//   } catch (e, stackTrace) {
//     print('❌ API Error: $e');
//     print('Stack Trace: $stackTrace');
//     return [];
//   }
// } 



// // import 'dart:convert';
// // import 'dart:math';
// // import 'package:http/http.dart' as http;
// // import 'package:flutter/material.dart';
// // import 'package:camera/camera.dart';
// // import 'package:image/image.dart' as img;
// // import 'package:path_provider/path_provider.dart';
// // import 'package:path/path.dart' as p;
// // import 'dart:io';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:googleapis/vision/v1.dart' as vision;
// // import 'package:googleapis_auth/auth_io.dart'; // Correct import for ServiceAccountCredentials and clientViaServiceAccount
// // import 'package:provider/provider.dart';
// // import 'package:purchaseorders2/models/po.dart';
// // import 'package:purchaseorders2/models/po_item.dart';
// // import 'package:purchaseorders2/notifier/purchasenotifier.dart';
// // import 'package:purchaseorders2/providers/po_provider.dart';
// // import 'package:purchaseorders2/widgets/approved_po_widget.dart';
// // import 'package:purchaseorders2/widgets/gridview_approve_widget.dart';

// // List<CameraDescription>? camera;

// // class DocumentScannerScreen extends StatefulWidget {
// //   const DocumentScannerScreen({super.key});
// //   @override
// //   State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
// // }

// // class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
// //   CameraController? _controller;
// //   bool isInitialized = false;
// //   bool isFocused = false;
// //   bool isClear = false;
// //   bool isCameraVisible = false;
// //   final TextEditingController _vendorSearchController = TextEditingController();
// //   final FocusNode _searchFocusNode = FocusNode();
// //   List<PO> _filteredPOs = [];
// //   List<PO> _scannedPOs = [];
// //   int _skip = 0;
// //   int _limit = 50;
// //   bool _hasSearched = false;
// //   bool _showDropdown = false;
// //   bool _isLoadingMore = false;
// //   final ScrollController _scrollController = ScrollController();
// //   Map<String, dynamic>? _scannedData;
// //   bool _showScannedResults = false;
// //   final GlobalKey<AnimatedListState> _scannedListKey = GlobalKey<AnimatedListState>();

// //   @override
// //   void initState() {
// //     super.initState();
// //     final poProvider = Provider.of<POProvider>(context, listen: false);
// //     poProvider.initVendorScrollListener();
// //     _scrollController.addListener(_scrollListener);
// //   }

// //   void _scrollListener() {
// //     if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
// //       _loadMoreVendors();
// //     }
// //   }

// //   Future<void> _loadMoreVendors() async {
// //     if (_isLoadingMore) return;

// //     setState(() {
// //       _isLoadingMore = true;
// //     });

// //     final poProvider = Provider.of<POProvider>(context, listen: false);
// //     await poProvider.fetchingVendors(
// //       vendorName: _vendorSearchController.text,
// //       skip: _skip + _limit,
// //       limit: _limit,
// //     );

// //     setState(() {
// //       _skip += _limit;
// //       _isLoadingMore = false;
// //     });
// //   }

// //   void _toggleDropdown() {
// //     final poProvider = Provider.of<POProvider>(context, listen: false);

// //     if (!_showDropdown) {
// //       poProvider.fetchingVendors(
// //         vendorName: _vendorSearchController.text,
// //         skip: 0,
// //         limit: _limit,
// //       );
// //     }

// //     setState(() {
// //       _showDropdown = !_showDropdown;
// //       _showScannedResults = false;
// //     });

// //     if (_showDropdown) {
// //       _searchFocusNode.requestFocus();
// //     } else {
// //       _searchFocusNode.unfocus();
// //     }
// //   }

// //   Future<void> _onVendorSelected(String vendor) async {
// //     final notifier = Provider.of<PurchaseOrderNotifier>(context, listen: false);
// //     final poProvider = Provider.of<POProvider>(context, listen: false);

// //     notifier.setSelectedVendor(vendor);
// //     await poProvider.fetchPOsByVendor(vendor);

// //     setState(() {
// //       _hasSearched = true;
// //       _filteredPOs = poProvider.approvedPos
// //           .where((po) => po.vendorName?.toLowerCase() == vendor.toLowerCase())
// //           .toList();
// //       _showDropdown = false;
// //       _showScannedResults = false;
// //     });
// //   }

// //   Future<void> _initCamera() async {
// //     final status = await Permission.camera.request();
// //     if (!status.isGranted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Camera permission not granted')),
// //       );
// //       return;
// //     }

// //     if (camera == null || camera!.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('No cameras available')),
// //       );
// //       return;
// //     }

// //     _controller = CameraController(camera![0], ResolutionPreset.high);
// //     try {
// //       await _controller!.initialize();
// //       setState(() {
// //         isInitialized = true;
// //       });
// //       await Future.delayed(const Duration(milliseconds: 500));
// //       await _focusCamera();
// //     } catch (e) {
// //       print('Error initializing camera: $e');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to initialize camera: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _focusCamera() async {
// //     try {
// //       await _controller!.setFocusMode(FocusMode.auto);
// //       await Future.delayed(const Duration(seconds: 2));
// //       setState(() {
// //         isFocused = true;
// //       });

// //       if (isFocused) {
// //         await _checkImageClarity();
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Focus failed. Try again')),
// //         );
// //       }
// //     } catch (e) {
// //       print("Error focusing camera: $e");
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to focus camera: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _checkImageClarity() async {
// //     await Future.delayed(const Duration(seconds: 2));
// //     setState(() {
// //       isClear = true;
// //     });

// //     if (isClear) {
// //       await _captureAndProcessImage();
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Image not clear, please focus again')),
// //       );
// //     }
// //   }

// //   Future<void> _captureAndProcessImage() async {
// //     final tempDir = await getTemporaryDirectory();
// //     final imgPath = p.join(tempDir.path, 'capture.jpg');

// //     try {
// //       final XFile file = await _controller!.takePicture();
// //       await file.saveTo(imgPath);

// //       final imageBytes = await file.readAsBytes();
// //       final image = img.decodeImage(imageBytes);

// //       if (image == null) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Failed to decode image')),
// //         );
// //         return;
// //       }

// //       final croppedImage = img.copyCrop(
// //         image,
// //         x: 50,
// //         y: 50,
// //         width: image.width - 100,
// //         height: image.height - 100,
// //       );

// //       final croppedImgPath = p.join(tempDir.path, 'cropped_capture.jpg');
// //       final croppedImgFile = File(croppedImgPath)
// //         ..writeAsBytesSync(img.encodeJpg(croppedImage));

// //       await _performOCR(croppedImgFile);
// //     } catch (e) {
// //       print("Error capturing or processing image: $e");
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to process image: $e')),
// //       );
// //     } finally {
// //       setState(() {
// //         isCameraVisible = false;
// //       });
// //       if (_controller != null) {
// //         await _controller!.dispose();
// //         _controller = null;
// //       }
// //     }
// //   }

// //   Future<void> _performOCR(File imageFile) async {
// //     print('\n=== STARTING DOCUMENT SCAN PROCESS ===');
// //     try {
// //       print('📷 Processing image...');
// //       final text = await _performOCRFromImage(imageFile, context);
// //       print('\n=== RAW OCR OUTPUT ===\n$text');

// //       final cleanedText = _cleanOCRText(text);
// //       print('\n=== CLEANED OCR TEXT ===\n$cleanedText');

// //       print('\n🔍 Extracting fields...');
// //       _scannedData = await extractFields(cleanedText);

// //       if (_scannedData == null ||
// //           _scannedData!['items'] == null ||
// //           (_scannedData!['items'] as List).isEmpty) {
// //         print('❌ No items found in scanned document');
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('No item details found in document')),
// //         );
// //         return;
// //       }

// //       final poProvider = Provider.of<POProvider>(context, listen: false);
// //       print('\n🔎 Matching against POs...');
// //       await poProvider.fetchPOsByVendor(_scannedData!['vendor']);
// //       final matchedPOs = poProvider.approvedPos.where((po) {
// //         print('\nChecking PO: ${po.randomId}');

// //         final scannedVendor = _scannedData?['vendor']?.toString().toUpperCase() ?? '';
// //         final poVendor = po.vendorName?.toUpperCase() ?? '';
// //         final vendorSimilarity = _calculateItemSimilarity(scannedVendor, poVendor);

// //         print('Vendor: Scanned="$scannedVendor", PO="$poVendor"');
// //         print('Vendor Similarity: ${(vendorSimilarity * 100).toStringAsFixed(1)}%');
// //         if (vendorSimilarity < 0.8) {
// //           print('❌ Vendor does not match');
// //           return false;
// //         }

// //         final scannedItems = _scannedData!['items'] as List;
// //         print('🔢 Scanned Items: ${scannedItems.length}');

// //         for (var scannedItem in scannedItems) {
// //           final scannedName = scannedItem['itemName']?.toString().toLowerCase() ??
// //               scannedItem['scannedName']?.toString().toLowerCase() ?? '';
// //           final scannedPrice = scannedItem['apiPrice'] is double
// //               ? scannedItem['apiPrice']
// //               : double.tryParse(scannedItem['scannedPrice'].toString()) ?? 0.0;

// //           print('\n🔍 Checking Item: $scannedName (₹$scannedPrice)');

// //           bool itemExists = po.items.any((poItem) {
// //             final poName = poItem.itemName?.toLowerCase() ?? '';
// //             final poPrice = poItem.newPrice ?? 0.0;
// //             final similarity = _calculateItemSimilarity(scannedName, poName);
// //             final priceDiff = (poPrice - scannedPrice).abs();

// //             print('|-- PO Item: $poName (₹$poPrice)');
// //             print('|-- Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
// //             print('|-- Price Diff: ₹$priceDiff');

// //             return similarity >= 0.75 && priceDiff <= (poPrice * 0.05);
// //           });

// //           if (!itemExists) {
// //             print('❌ No matching item in PO');
// //             return false;
// //           }
// //         }
// //         print('✅ PO matched successfully');
// //         return true;
// //       }).toList();

// //       print('\n=== MATCHING RESULTS ===');
// //       print('Found ${matchedPOs.length} matching POs');
// //       if (matchedPOs.isNotEmpty) {
// //         print('Matched POs:');
// //         for (var po in matchedPOs) {
// //           print(' - PO: ${po.randomId}, Vendor: ${po.vendorName}');
// //           print('   Items:');
// //           for (var item in po.items) {
// //             print('     - ${item.itemName}: ₹${item.newPrice}');
// //           }
// //         }
// //       } else {
// //         print('No matching POs found');
// //       }

// //       setState(() {
// //         _scannedPOs = matchedPOs;
// //         _showScannedResults = true;
// //         _hasSearched = true;
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           duration: const Duration(seconds: 3),
// //           content: Text(
// //               matchedPOs.isNotEmpty
// //                   ? 'Found ${matchedPOs.length} matching PO(s)'
// //                   : 'No matching POs found'),
// //         ),
// //       );
// //     } catch (e, stackTrace) {
// //       print('❌ OCR Processing Error: $e');
// //       print('Stack Trace: $stackTrace');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to process document: $e')),
// //       );
// //     }
// //   }

// //   String _cleanOCRText(String text) {
// //     return text
// //         .replaceAll(RegExp(r'[^\w\s\d\.\-/:&]'), ' ')
// //         .replaceAll(RegExp(r'\s+'), ' ')
// //         .replaceAll('1FIGS', 'ITEMS')
// //         .trim();
// //   }

// //   Future<String> _performOCRFromImage(File imageFile, BuildContext context) async {
// //     try {
// //       print('\n=== PERFORMING OCR WITH GOOGLE CLOUD VISION API ===');

// //       // Load credentials from assets
// //       final credentialsJson = await DefaultAssetBundle.of(context)
// //           .loadString('assets/service-account-key.json');
// //       final credentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsJson));
// //       final client = await clientViaServiceAccount(
// //         credentials,
// //         ['https://www.googleapis.com/auth/cloud-vision'],
// //       );

// //       // Initialize Vision API client
// //       final visionApi = vision.VisionApi(client);

// //       // Read and encode image
// //       final imageBytes = await imageFile.readAsBytes();
// //       final imageBase64 = base64Encode(imageBytes);

// //       // Create Vision API request
// //       final request = vision.BatchAnnotateImagesRequest()
// //         ..requests = [
// //           vision.AnnotateImageRequest(
// //             image: vision.Image(content: imageBase64),
// //             features: [
// //               vision.Feature(type: 'DOCUMENT_TEXT_DETECTION'),
// //             ],
// //           ),
// //         ];

// //       // Call Vision API
// //       final response = await visionApi.images.annotate(request);
// //       final textAnnotations = response.responses?.first.textAnnotations;

// //       if (textAnnotations == null || textAnnotations.isEmpty) {
// //         print('❌ No text detected in image');
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('No text detected in document')),
// //         );
// //         return '';
// //       }

// //       // Extract full text
// //       final fullText = textAnnotations.first.description ?? '';
// //       print('📜 Extracted Text:\n$fullText');

// //       // Clean up client
// //       client.close();
// //       return fullText;
// //     } catch (e, stackTrace) {
// //       print('❌ OCR Error: $e');
// //       print('Stack Trace: $stackTrace');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('OCR failed: $e')),
// //       );
// //       return '';
// //     }
// //   }

// //   Future<void> _startCameraProcess() async {
// //     setState(() {
// //       isCameraVisible = true;
// //     });
// //     await _initCamera();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Document Scanner'),
// //       ),
// //       body: Stack(
// //         children: [
// //           Consumer<POProvider>(
// //             builder: (context, poProvider, child) {
// //               return RefreshIndicator(
// //                 onRefresh: () async {
// //                   if (_vendorSearchController.text.isNotEmpty) {
// //                     await poProvider.fetchingVendors(
// //                       vendorName: _vendorSearchController.text,
// //                       skip: 0,
// //                       limit: _limit,
// //                     );
// //                     setState(() {
// //                       _skip = 0;
// //                     });
// //                   }
// //                 },
// //                 child: CustomScrollView(
// //                   slivers: [
// //                     SliverToBoxAdapter(
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(16.0),
// //                         child: Column(
// //                           children: [
// //                             Row(
// //                               children: [
// //                                 Expanded(
// //                                   child: TextFormField(
// //                                     controller: _vendorSearchController,
// //                                     focusNode: _searchFocusNode,
// //                                     decoration: InputDecoration(
// //                                       labelText: 'Search Vendor',
// //                                       border: const OutlineInputBorder(),
// //                                       suffixIcon: _vendorSearchController.text.isNotEmpty
// //                                           ? IconButton(
// //                                               icon: const Icon(Icons.clear),
// //                                               onPressed: () {
// //                                                 _vendorSearchController.clear();
// //                                                 _searchFocusNode.unfocus();
// //                                                 setState(() {
// //                                                   _hasSearched = false;
// //                                                   _filteredPOs.clear();
// //                                                   _showDropdown = false;
// //                                                   _showScannedResults = false;
// //                                                 });
// //                                               },
// //                                             )
// //                                           : null,
// //                                     ),
// //                                     onChanged: (val) async {
// //                                       setState(() {
// //                                         _hasSearched = val.isNotEmpty;
// //                                         _skip = 0;
// //                                         _showScannedResults = false;
// //                                       });

// //                                       if (val.isNotEmpty) {
// //                                         await poProvider.fetchingVendors(
// //                                           vendorName: val,
// //                                           skip: 0,
// //                                           limit: _limit,
// //                                         );
// //                                       } else {
// //                                         setState(() {
// //                                           _filteredPOs.clear();
// //                                         });
// //                                       }
// //                                     },
// //                                     onTap: _toggleDropdown,
// //                                   ),
// //                                 ),
// //                                 const SizedBox(width: 8),
// //                                 IconButton(
// //                                   icon: const Icon(Icons.qr_code_scanner),
// //                                   onPressed: _startCameraProcess,
// //                                 ),
// //                               ],
// //                             ),
// //                             if (_showDropdown)
// //                               Container(
// //                                 margin: const EdgeInsets.only(top: 5),
// //                                 decoration: BoxDecoration(
// //                                   color: Colors.white,
// //                                   borderRadius: BorderRadius.circular(4),
// //                                   boxShadow: [
// //                                     BoxShadow(
// //                                       color: Colors.black.withOpacity(0.1),
// //                                       blurRadius: 4,
// //                                       offset: const Offset(0, 2),
// //                                     )
// //                                   ],
// //                                 ),
// //                                 constraints: const BoxConstraints(
// //                                   maxHeight: 200,
// //                                 ),
// //                                 child: NotificationListener<ScrollNotification>(
// //                                   onNotification: (scrollNotification) {
// //                                     if (scrollNotification.metrics.pixels ==
// //                                         scrollNotification.metrics.maxScrollExtent) {
// //                                       _loadMoreVendors();
// //                                     }
// //                                     return false;
// //                                   },
// //                                   child: ListView.builder(
// //                                     controller: _scrollController,
// //                                     padding: EdgeInsets.zero,
// //                                     itemCount: poProvider.filteredVendorNames.length +
// //                                         (_isLoadingMore ? 1 : 0),
// //                                     itemBuilder: (context, index) {
// //                                       if (index >= poProvider.filteredVendorNames.length) {
// //                                         return const Center(
// //                                             child: Padding(
// //                                           padding: EdgeInsets.all(8.0),
// //                                           child: CircularProgressIndicator(),
// //                                         ));
// //                                       }
// //                                       final vendor = poProvider.filteredVendorNames.elementAt(index);
// //                                       return ListTile(
// //                                         title: Text(vendor),
// //                                         onTap: () {
// //                                           _vendorSearchController.text = vendor;
// //                                           _onVendorSelected(vendor);
// //                                         },
// //                                       );
// //                                     },
// //                                   ),
// //                                 ),
// //                               ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                     if (_hasSearched)
// //                       SliverFillRemaining(
// //                         child: _showScannedResults
// //                             ? _buildScannedResults()
// //                             : _buildVendorResults(poProvider),
// //                       ),
// //                     if (!_hasSearched)
// //                       const SliverFillRemaining(
// //                         child: Center(
// //                           child: Text(
// //                             "Search for a vendor or scan an invoice",
// //                             style: TextStyle(fontSize: 18, color: Colors.grey),
// //                           ),
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //               );
// //             },
// //           ),
// //           if (isCameraVisible && isInitialized)
// //             Positioned.fill(
// //               child: Container(
// //                 color: Colors.black,
// //                 child: Center(
// //                   child: CameraPreview(_controller!),
// //                 ),
// //               ),
// //             ),
// //         ],
// //       ),
// //       floatingActionButton: isCameraVisible
// //           ? FloatingActionButton(
// //               onPressed: _captureAndProcessImage,
// //               child: const Icon(Icons.camera),
// //             )
// //           : null,
// //     );
// //   }

// //   Widget _buildScannedResults() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(16.0),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 'Scanned Document Details:',
// //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 8),
// //               Text('Vendor: ${_scannedData?['vendor'] ?? 'Not found'}'),
// //               Text('Invoice No: ${_scannedData?['invoiceNo'] ?? 'Not found'}'),
// //               Text('Invoice Date: ${_scannedData?['invoiceDate'] ?? 'Not found'}'),
// //               const SizedBox(height: 16),
// //               Text(
// //                 'Scanned Items:',
// //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //               ),
// //               ...(_scannedData?['items'] as List? ?? []).map<Widget>((item) {
// //                 return ListTile(
// //                   title: Text(item['scannedName'] ?? 'Unknown'),
// //                   subtitle: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text('Qty: ${item['quantity']} - Price: ₹${item['scannedPrice']}'),
// //                       if (item['matched'] == true)
// //                         Text(
// //                           'Matched: ${item['itemName']} (₹${item['apiPrice']})',
// //                           style: TextStyle(color: Colors.green),
// //                         ),
// //                       if (item['matched'] != true)
// //                         Text('No match found', style: TextStyle(color: Colors.red)),
// //                     ],
// //                   ),
// //                   trailing: item['matched'] == true
// //                       ? const Icon(Icons.check_circle, color: Colors.green)
// //                       : const Icon(Icons.error, color: Colors.red),
// //                 );
// //               }).toList(),
// //             ],
// //           ),
// //         ),
// //         const Divider(),
// //         Expanded(
// //           child: _scannedPOs.isEmpty
// //               ? const Center(
// //                   child: Text(
// //                     'No matching POs found',
// //                     style: TextStyle(fontSize: 18, color: Colors.grey),
// //                   ),
// //                 )
// //               : GridViewApproveWidget<PO>(
// //                   items: _scannedPOs,
// //                   itemBuilder: (context, index) {
// //                     final po = _scannedPOs[index];
// //                     return ApprovedPOWidget(
// //                       po: po,
// //                       poProvider: Provider.of<POProvider>(context, listen: false),
// //                     );
// //                   },
// //                   fixedHeight: 260,
// //                 ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildVendorResults(POProvider poProvider) {
// //     return poProvider.isLoading
// //         ? const Center(child: CircularProgressIndicator())
// //         : poProvider.error != null
// //             ? Center(child: Text('Error: ${poProvider.error}'))
// //             : _filteredPOs.isEmpty
// //                 ? const Center(
// //                     child: Text("No POs found for this vendor"),
// //                   )
// //                 : GridViewApproveWidget<PO>(
// //                     items: _filteredPOs,
// //                     itemBuilder: (context, index) {
// //                       final po = _filteredPOs[index];
// //                       return ApprovedPOWidget(
// //                         po: po,
// //                         poProvider: poProvider,
// //                       );
// //                     },
// //                     fixedHeight: 260,
// //                   );
// //   }

// //   @override
// //   void dispose() {
// //     _controller?.dispose();
// //     _vendorSearchController.dispose();
// //     _searchFocusNode.dispose();
// //     _scrollController.dispose();
// //     super.dispose();
// //   }
// // }

// // Future<Map<String, dynamic>> extractFields(String text) async {
// //   print('\n=== EXTRACTING FIELDS FROM OCR TEXT ===');
// //   final Map<String, dynamic> extracted = {
// //     'vendor': 'Not found',
// //     'items': <Map<String, dynamic>>[],
// //     'totalQuantity': 0.0,
// //     'invoiceNo': 'Not found',
// //     'invoiceDate': 'Not found',
// //     'status': 'No items found',
// //   };

// //   try {
// //     // Split and clean lines
// //     final lines = text
// //         .split('\n')
// //         .map((line) => line.trim())
// //         .where((line) => line.isNotEmpty)
// //         .toList();
// //     print('📜 OCR Lines:');
// //     for (var i = 0; i < lines.length; i++) {
// //       print('Line ${i + 1}: "${lines[i]}"');
// //     }

// //     // Extract vendor (prioritize names with AGENCY, ENTERPRISES, SWEET, CAKES, etc.)
// //     final vendorRegex = RegExp(
// //       r'(?:^|\n)([A-Z][A-Za-z0-9\s&.,-]+?(?:AGENCY|AGENCIES|TRADERS|ENTERPRISES|CORP|CO\.?|LTD|LIMITED|INC\.?|PVT\.?|PRIVATE|SWEET|CAKES))\b',
// //       caseSensitive: false,
// //     );
// //     for (var line in lines) {
// //       final vendorMatch = vendorRegex.firstMatch(line);
// //       if (vendorMatch != null) {
// //         final vendor = vendorMatch.group(1)?.trim();
// //         if (vendor != null && vendor.length > 3 && !vendor.toLowerCase().contains('total')) {
// //           extracted['vendor'] = vendor;
// //           print('✅ Vendor extracted: "${extracted['vendor']}"');
// //           break;
// //         }
// //       }
// //     }

// //     // Extract invoice number (handle misspellings like "noice")
// //     final invoiceNoRegex = RegExp(
// //       r'(?:Iny|Inv|Bill|Invoice|noice)\s*(?:No\.?|#)?\s*[:]?[\s]*([A-Z0-9-/#]+)',
// //       caseSensitive: false,
// //     );
// //     for (var line in lines) {
// //       final invoiceNoMatch = invoiceNoRegex.firstMatch(line);
// //       if (invoiceNoMatch != null) {
// //         extracted['invoiceNo'] = invoiceNoMatch.group(1)?.trim() ?? 'Not found';
// //         print('✅ Invoice No extracted: "${extracted['invoiceNo']}"');
// //         break;
// //       }
// //     }

// //     // Extract invoice date (support DD-MM-YY, DD MMM YY, etc.)
// //     final dateRegex = RegExp(
// //       r'(?:Date|Inv\.?\s*Date|noice|Ack\s*Dute)[\s]*[:]?[\s]*(\d{1,2}[-./]\d{1,2}[-./]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4}|\d{1,2}[-.][A-Za-z]{3}[-.]\d{2,4})',
// //       caseSensitive: false,
// //     );
// //     for (var line in lines) {
// //       final dateMatch = dateRegex.firstMatch(line);
// //       if (dateMatch != null) {
// //         extracted['invoiceDate'] = dateMatch.group(1)?.trim() ?? 'Not found';
// //         print('✅ Invoice Date extracted: "${extracted['invoiceDate']}"');
// //         break;
// //       }
// //     }

// //     // Extract items (first column as item name after "Rate" header)
// //     final List<Map<String, dynamic>> items = [];
// //     bool isItemSection = false;

// //     for (var i = 0; i < lines.length; i++) {
// //       final line = lines[i].trim();
// //       print('\n🔎 Parsing line: "$line"');

// //       // Start item section after "Rate" header
// //       if (line.toLowerCase().contains('rate')) {
// //         isItemSection = true;
// //         print('✅ Detected Rate header, starting item section');
// //         continue;
// //       }

// //       // Skip non-item lines
// //       if (line.toLowerCase().contains('total') ||
// //           line.toLowerCase().contains('tax') ||
// //           line.toLowerCase().contains('invoice') ||
// //           line.toLowerCase().contains('noice') ||
// //           line.toLowerCase().contains('date') ||
// //           line.toLowerCase().contains('gst') ||
// //           line.toLowerCase().contains('fss') ||
// //           line.toLowerCase().contains('ack') ||
// //           line.toLowerCase().contains('code') ||
// //           line.toLowerCase().contains('delivery') ||
// //           line.toLowerCase().contains('due') ||
// //           line.toLowerCase().contains('buyer') ||
// //           line.toLowerCase().contains('consignee') ||
// //           line.toLowerCase().contains('dispatch')) {
// //         print('⏭ Skipping non-item line');
// //         continue;
// //       }

// //       // Process item lines in item section
// //       if (isItemSection) {
// //         final itemRegex = RegExp(
// //           r'^(.*?)\s+(\d+\.?\d*)\s+(?:Rs\.?|₹)?\s*(\d+\.?\d*)',
// //           caseSensitive: false,
// //         );
// //         final priceRegex = RegExp(r'(?:Rs\.?|₹)?\s*(\d+\.?\d*)');
// //         final quantityRegex = RegExp(r'\b(\d+\.?\d*)\b');

// //         final itemMatch = itemRegex.firstMatch(line);
// //         if (itemMatch != null) {
// //           final itemName = itemMatch.group(1)?.trim();
// //           final quantityStr = itemMatch.group(2);
// //           final priceStr = itemMatch.group(3);

// //           if (itemName != null && itemName.isNotEmpty && quantityStr != null && priceStr != null) {
// //             final quantity = double.tryParse(quantityStr) ?? 1.0;
// //             final price = double.tryParse(priceStr) ?? 0.0;

// //             print('  - Item Name: "$itemName"');
// //             print('  - Quantity: $quantity');
// //             print('  - Price: $price');

// //             if (price > 0 && price <= 10000 && quantity > 0 && itemName.length > 2) {
// //               items.add({
// //                 'quantity': quantity,
// //                 'scannedName': itemName,
// //                 'scannedPrice': price,
// //                 'matched': false,
// //               });
// //               print('✅ Item added: "$itemName" (Qty: $quantity, ₹$price)');
// //             } else {
// //               print('❌ Invalid item: Name="$itemName", Qty=$quantity, Price=$price');
// //             }
// //           }
// //         } else {
// //           // Fallback: try to extract price and quantity separately
// //           final priceMatch = priceRegex.firstMatch(line);
// //           final quantityMatch = quantityRegex.firstMatch(line);
// //           if (priceMatch != null && quantityMatch != null) {
// //             final price = double.tryParse(priceMatch.group(1)!) ?? 0.0;
// //             final quantity = double.tryParse(quantityMatch.group(1)!) ?? 1.0;
// //             final itemName = line
// //                 .replaceAll(priceMatch.group(0)!, '')
// //                 .replaceAll(quantityMatch.group(0)!, '')
// //                 .trim();

// //             if (itemName.isNotEmpty && price > 0 && price <= 10000 && quantity > 0 && itemName.length > 2) {
// //               print('  - Fallback Item Name: "$itemName"');
// //               print('  - Quantity: $quantity');
// //               print('  - Price: $price');

// //               items.add({
// //                 'quantity': quantity,
// //                 'scannedName': itemName,
// //                 'scannedPrice': price,
// //                 'matched': false,
// //               });
// //               print('✅ Fallback Item added: "$itemName" (Qty: $quantity, ₹$price)');
// //             } else {
// //               print('❌ Fallback Invalid item: Name="$itemName", Qty=$quantity, Price=$price');
// //             }
// //           } else {
// //             print('❌ Line does not match item pattern');
// //           }
// //         }
// //       }
// //     }

// //     if (items.isNotEmpty) {
// //       extracted['items'] = items;
// //       extracted['totalQuantity'] = items.fold(0.0, (sum, item) => sum + item['quantity']);
// //       extracted['status'] = 'Items found';
// //       print('\n🔍 Matching items with backend...');
// //       await _matchWithBackendItems(extracted);
// //     } else {
// //       extracted['status'] = 'No valid items found';
// //       print('❌ No valid items found in document');
// //     }

// //     print('\n🟢 Extracted Data:');
// //     print('Vendor: ${extracted['vendor']}');
// //     print('Invoice No: ${extracted['invoiceNo']}');
// //     print('Invoice Date: ${extracted['invoiceDate']}');
// //     print('Items: ${items.length}');
// //     for (var item in items) {
// //       print(' - ${item['scannedName']}: Qty ${item['quantity']}, ₹${item['scannedPrice']}');
// //       if (item['matched']) {
// //         print('   → Matched: ${item['itemName']} (₹${item['apiPrice']})');
// //       }
// //     }

// //   } catch (e, stackTrace) {
// //     print('❌ extractFields error: $e');
// //     print('Stack Trace: $stackTrace');
// //     extracted['status'] = 'Processing error: $e';
// //   }

// //   return extracted;
// // }

// // Future<void> _matchWithBackendItems(Map<String, dynamic> result) async {
// //   try {
// //     print('\n=== MATCHING WITH BACKEND ITEMS ===');
// //     final List<dynamic> backendItems = await _fetchPurchaseItems();
// //     print('Backend Items Fetched: ${backendItems.length}');
// //     for (var item in backendItems) {
// //       print(' - ${item['itemName']}: ₹${item['newPrice']}');
// //     }

// //     final List<dynamic> items = result['items'];
// //     final scannedVendor = result['vendor']?.toString().toUpperCase() ?? '';

// //     for (var i = 0; i < items.length; i++) {
// //       final item = items[i];
// //       final scannedName = item['scannedName'].toString().toUpperCase();
// //       final scannedPrice = item['scannedPrice'] is double
// //           ? item['scannedPrice']
// //           : double.tryParse(item['scannedPrice'].toString()) ?? 0.0;

// //       print('\n🔍 Matching item: "$scannedName" (₹$scannedPrice)');

// //       double highestSimilarity = 0.0;
// //       Map<String, dynamic>? bestMatch;

// //       for (final backendItem in backendItems) {
// //         final backendName = backendItem['itemName']?.toString().toUpperCase() ?? '';
// //         final backendPrice = backendItem['newPrice'] is double
// //             ? backendItem['newPrice']
// //             : double.tryParse(backendItem['newPrice'].toString()) ?? 0.0;

// //         final similarity = _calculateItemSimilarity(scannedName, backendName);
// //         final priceDifference = (scannedPrice - backendPrice).abs();

// //         print('  - Backend Item: "$backendName" (₹$backendPrice)');
// //         print('    Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
// //         print('    Price Difference: ₹$priceDifference');

// //         if (similarity > highestSimilarity &&
// //             similarity >= 0.75 &&
// //             priceDifference <= (backendPrice * 0.05)) {
// //           highestSimilarity = similarity;
// //           bestMatch = {
// //             ...backendItem,
// //             'similarity': similarity,
// //             'priceDifference': priceDifference,
// //           };
// //         }
// //       }

// //       if (bestMatch != null) {
// //         items[i] = {
// //           ...item,
// //           'matched': true,
// //           'itemName': bestMatch['itemName'],
// //           'apiPrice': bestMatch['newPrice'],
// //         };
// //         print('✅ Matched: "${bestMatch['itemName']}" (₹${bestMatch['newPrice']})');
// //       } else {
// //         print('❌ No match found for "$scannedName"');
// //       }
// //     }

// //     result['items'] = items;
// //     result['matchedItemsCount'] = items.where((i) => i['matched']).length;
// //     print('Matched Items Count: ${result['matchedItemsCount']}');
// //   } catch (e, stackTrace) {
// //     print('❌ _matchWithBackendItems error: $e');
// //     print('Stack Trace: $stackTrace');
// //   }
// // }

// // double _calculateItemSimilarity(String a, String b) {
// //   final cleanA = a
// //       .toLowerCase()
// //       .replaceAll(RegExp(r'\b(gm|g|kg|ml|l|pcs)\b', caseSensitive: false), '')
// //       .replaceAll(RegExp(r'[^\w\s]'), '')
// //       .trim();
// //   final cleanB = b
// //       .toLowerCase()
// //       .replaceAll(RegExp(r'\b(gm|g|kg|ml|l|pcs)\b', caseSensitive: false), '')
// //       .replaceAll(RegExp(r'[^\w\s]'), '')
// //       .trim();

// //   print('Similarity Check:');
// //   print('  Cleaned A: "$cleanA"');
// //   print('  Cleaned B: "$cleanB"');

// //   final maxLength = max(cleanA.length, cleanB.length);
// //   if (maxLength == 0) return 0.0;

// //   final distance = _levenshteinDistance(cleanA, cleanB);
// //   final similarity = 1.0 - (distance / maxLength);
// //   print('  Levenshtein Distance: $distance, Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
// //   return similarity;
// // }

// // int _levenshteinDistance(String a, String b) {
// //   if (a.isEmpty) return b.length;
// //   if (b.isEmpty) return a.length;

// //   final List<List<int>> matrix = List.generate(
// //     a.length + 1,
// //     (_) => List<int>.filled(b.length + 1, 0),
// //   );

// //   for (int i = 0; i <= a.length; i++) {
// //     matrix[i][0] = i;
// //   }
// //   for (int j = 0; j <= b.length; j++) {
// //     matrix[0][j] = j;
// //   }

// //   for (int i = 1; i <= a.length; i++) {
// //     for (int j = 1; j <= b.length; j++) {
// //       final int cost = a[i - 1].toLowerCase() == b[j - 1].toLowerCase() ? 0 : 1;
// //       matrix[i][j] = [
// //         matrix[i - 1][j] + 1,
// //         matrix[i][j - 1] + 1,
// //         matrix[i - 1][j - 1] + cost,
// //       ].reduce(min);
// //     }
// //   }
// //   return matrix[a.length][b.length];
// // }

// // Future<List<dynamic>> _fetchPurchaseItems() async {
// //   try {
// //     print('\n=== FETCHING PURCHASE ITEMS FROM API ===');
// //     final response = await http.get(
// //       Uri.parse('http://192.168.1.106:8888/purchaseorders/getAll'),
// //       headers: {'Content-Type': 'application/json'},
// //     );

// //     print('API Response Status: ${response.statusCode}');
// //     print('API Response Body: ${response.body}');

// //     if (response.statusCode == 200) {
// //       final decoded = json.decode(response.body);
// //       List<dynamic> items = [];

// //       if (decoded is List) {
// //         for (var po in decoded) {
// //           if (po['items'] is List) {
// //             items.addAll(po['items']);
// //           }
// //         }
// //       } else if (decoded is Map && decoded.containsKey('items')) {
// //         items = decoded['items'] as List;
// //       } else if (decoded is Map && decoded.containsKey('data')) {
// //         items = decoded['data'] is List ? decoded['data'] : decoded['data']['items'] ?? [];
// //       }

// //       final normalizedItems = items.map((item) {
// //         return {
// //           'itemName': item['itemName']?.toString().trim() ?? '',
// //           'newPrice': item['newPrice'] is double
// //               ? item['newPrice']
// //               : double.tryParse(item['newPrice']?.toString() ?? '0') ?? 0.0,
// //         };
// //       }).where((item) => item['itemName'].isNotEmpty && item['newPrice'] > 0).toList();

// //       print('Normalized Items: ${normalizedItems.length}');
// //       for (var item in normalizedItems) {
// //         print(' - ${item['itemName']}: ₹${item['newPrice']}');
// //       }
// //       return normalizedItems;
// //     } else {
// //       print('❌ API Error: Status ${response.statusCode}');
// //       return [];
// //     }
// //   } catch (e, stackTrace) {
// //     print('❌ API Error: $e');
// //     print('Stack Trace: $stackTrace');
// //     return [];
// //   }
// // }




