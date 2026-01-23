// import 'package:flutter/material.dart';
// import 'package:purchaseorders2/models/outgoing.dart';
// import 'package:purchaseorders2/pdfs/outgoing_pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';
// import '../../providers/outgoing_payment_provider.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';

// class AdvancePaymentPage extends StatefulWidget {
//   final String status;
//   final TabController? tabController;

//   const AdvancePaymentPage({
//     super.key,
//     required this.status,
//     this.tabController,
//   });

//   @override
//   State<AdvancePaymentPage> createState() => _AdvancePaymentPageState();
// }

// class _AdvancePaymentPageState extends State<AdvancePaymentPage> {
//   late final TextEditingController _searchController;
//   late final ValueNotifier<bool> _isLoadingNotifier;
//   late final ValueNotifier<Map<String, dynamic>> _errorNotifier;
//   late final ValueNotifier<String> _searchQueryNotifier;
//   Timer? _debounce;
//   Future<void>? _loadDataFuture;
//   late final FocusNode _searchFocusNode;

//   @override
//   void initState() {
//     super.initState();
//     _searchController = TextEditingController();
//     _isLoadingNotifier = ValueNotifier<bool>(true);
//     _errorNotifier = ValueNotifier<Map<String, dynamic>>({
//       'hasError': false,
//       'message': '',
//     });
//     _searchQueryNotifier = ValueNotifier<String>('');
//     _loadDataFuture = _loadData();
//     _searchController.addListener(_onSearchChanged);
//     _searchFocusNode = FocusNode();

//     widget.tabController?.addListener(_onTabChanged);
//   }

//   void _onTabChanged() {
//     if (widget.tabController?.indexIsChanging == false &&
//         widget.tabController?.index == widget.tabController?.previousIndex &&
//         mounted) {
//       _isLoadingNotifier.value = true;
//       _loadDataFuture = _loadData();
//     }
//   }

//   Future<void> _loadData() async {
//     try {
//       final provider = Provider.of<OutgoingPaymentProvider>(
//         context,
//         listen: false,
//       );

//       if (mounted) {
//         _isLoadingNotifier.value = false;
//         _errorNotifier.value = {
//           'hasError': provider.error.isNotEmpty,
//           'message': provider.error.isNotEmpty
//               ? provider.error
//               : 'No error reported',
//         };
//       }
//     } catch (e) {
//       if (mounted) {
//         _isLoadingNotifier.value = false;
//         _errorNotifier.value = {
//           'hasError': true,
//           'message': 'Error loading data: $e',
//         };
//       }
//     }
//   }

//   void _onSearchChanged() {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 300), () {
//       if (mounted) {
//         _searchQueryNotifier.value = _searchController.text.trim();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _isLoadingNotifier.dispose();
//     _errorNotifier.dispose();
//     _searchQueryNotifier.dispose();
//     widget.tabController?.removeListener(_onTabChanged);
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   String _formatDate(DateTime? date) {
//     return date != null ? DateFormat('dd-MM-yyyy').format(date) : 'N/A';
//   }

//   String _formatCurrency(double? amount) {
//     return amount != null ? amount.toStringAsFixed(2) : 'N/A';
//   }

//   Future<void> _generateAndViewPdf(Outgoing payment) async {
//     try {
//       final poService = OutgoingPdf();
//       final pdfFile = await poService.generateOutgoingPdf(payment.outgoingId);
//       await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytesSync());
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('PDF generated successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
//       }
//     }
//   }

//   Widget _buildHeaderCell(String text, double width) {
//     return Container(
//       width: width,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }

//   Widget _buildDataCell(String text, double width, {bool allowWrap = false}) {
//     return Container(
//       width: width,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       child: Text(
//         text,
//         style: const TextStyle(color: Colors.black),
//         overflow: allowWrap ? TextOverflow.visible : TextOverflow.ellipsis,
//         softWrap: allowWrap,
//         maxLines: allowWrap ? 2 : 1,
//       ),
//     );
//   }

//   Widget _buildSearchField(OutgoingPaymentProvider provider) {
//     final suggestions = provider.payments
//         .where((p) => (p.status ?? '').toLowerCase() == 'advance paid')
//         .map((p) => (p.vendorName ?? '').trim())
//         .where((name) => name.isNotEmpty)
//         .toSet()
//         .toList();

//     return RawAutocomplete<String>(
//       textEditingController: _searchController,
//       focusNode: _searchFocusNode,
//       optionsBuilder: (TextEditingValue textEditingValue) {
//         if (textEditingValue.text.isEmpty) return suggestions;
//         return suggestions.where(
//           (option) => option.toLowerCase().contains(
//             textEditingValue.text.toLowerCase(),
//           ),
//         );
//       },
//       fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
//         return TextField(
//           controller: controller,
//           focusNode: focusNode,
//           decoration: InputDecoration(
//             hintText: 'Search vendor name',
//             prefixIcon: const Icon(Icons.search),
//             suffixIcon: _searchController.text.isNotEmpty
//                 ? IconButton(
//                     icon: const Icon(Icons.clear, size: 20),
//                     onPressed: () {
//                       controller.clear();
//                       focusNode.unfocus();
//                       _onSearchChanged();
//                     },
//                   )
//                 : null,
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             filled: true,
//             fillColor: Colors.grey[100],
//           ),
//         );
//       },
//       optionsViewBuilder: (context, onSelected, options) {
//         return Align(
//           alignment: Alignment.topLeft,
//           child: Material(
//             elevation: 4,
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               constraints: const BoxConstraints(maxHeight: 200),
//               child: ListView.builder(
//                 padding: EdgeInsets.zero,
//                 shrinkWrap: true,
//                 itemCount: options.length,
//                 itemBuilder: (context, index) {
//                   final option = options.elementAt(index);
//                   return ListTile(
//                     title: Text(option),
//                     onTap: () {
//                       onSelected(option);
//                       _searchController.text = option;
//                       _onSearchChanged();
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void showPaymentDetails(BuildContext context, Outgoing payment) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text(
//           'Payment Details',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildDetailRow('Vendor Name', payment.vendorName ?? 'N/A'),
//               _buildDetailRow('Invoice No', payment.invoiceNo ?? 'N/A'),
//               _buildDetailRow('Invoice Date', _formatDate(payment.invoiceDate)),
//               _buildDetailRow(
//                 'Total Amount',
//                 _formatCurrency(payment.payableAmount),
//               ),
//               _buildDetailRow(
//                 'Advance Paid',
//                 _formatCurrency(payment.advanceAmount),
//               ),
//               _buildDetailRow('Payment Date', _formatDate(payment.paymentDate)),
//               _buildDetailRow(
//                 'Tax %',
//                 '${payment.taxDetails?.toStringAsFixed(2) ?? '0.00'}%',
//               ),
//               _buildDetailRow(
//                 'Discount',
//                 _formatCurrency(payment.discountDetails),
//               ),
//               _buildDetailRow(
//                 'Payable Amount',
//                 _formatCurrency(payment.totalPayableAmount),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           const Text(': '),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.status != 'Advance Paid') {
//       return const Center(
//         child: Text(
//           'Invalid status for Advance Payment page. Please select "Advance Paid".',
//           style: TextStyle(fontSize: 16, color: Colors.red),
//         ),
//       );
//     }

//     return FutureBuilder<void>(
//       future: _loadDataFuture,
//       builder: (context, snapshot) {
//         return ValueListenableBuilder<bool>(
//           valueListenable: _isLoadingNotifier,
//           builder: (context, isLoading, _) {
//             if (snapshot.connectionState == ConnectionState.waiting ||
//                 isLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             return ValueListenableBuilder<Map<String, dynamic>>(
//               valueListenable: _errorNotifier,
//               builder: (context, errorState, _) {
//                 if (errorState['hasError']) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           'Error: ${errorState['message']}',
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: () {
//                             _isLoadingNotifier.value = true;
//                             _loadDataFuture = _loadData();
//                           },
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ValueListenableBuilder<String>(
//                   valueListenable: _searchQueryNotifier,
//                   builder: (context, searchQuery, _) {
//                     return Consumer<OutgoingPaymentProvider>(
//                       builder: (context, provider, child) {
//                         final payments = provider.payments
//                             .where((payment) {
//                               final status = (payment.status ?? '')
//                                   .trim()
//                                   .toLowerCase();
//                               return status == 'advance paid'.toLowerCase();
//                             })
//                             .where((payment) {
//                               final vendorName = (payment.vendorName ?? '')
//                                   .trim()
//                                   .toLowerCase();
//                               final invoiceNo = (payment.invoiceNo ?? '')
//                                   .trim()
//                                   .toLowerCase();
//                               return searchQuery.isEmpty ||
//                                   vendorName.contains(
//                                     searchQuery.toLowerCase(),
//                                   ) ||
//                                   invoiceNo.contains(searchQuery.toLowerCase());
//                             })
//                             .toList();

//                         if (payments.isEmpty) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Text('No advance payments found.'),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'Total payments in provider: ${provider.payments.length}',
//                                   style: const TextStyle(color: Colors.grey),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton(
//                                   onPressed: () {
//                                     _isLoadingNotifier.value = true;
//                                     _loadDataFuture = _loadData();
//                                   },
//                                   child: const Text('Refresh'),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }

//                         return Column(
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: LayoutBuilder(
//                                 builder: (context, constraints) {
//                                   bool isMobile = constraints.maxWidth < 600;

//                                   return isMobile
//                                       ? Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             const Text(
//                                               'ADVANCE OUTGOING',
//                                               style: TextStyle(
//                                                 fontSize: 20,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 16),
//                                             SizedBox(
//                                               width: double.infinity,
//                                               child: _buildSearchField(
//                                                 provider,
//                                               ),
//                                             ),
//                                           ],
//                                         )
//                                       : Row(
//                                           children: [
//                                             const Text(
//                                               'ADVANCE OUTGOING',
//                                               style: TextStyle(
//                                                 fontSize: 20,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const Spacer(),
//                                             SizedBox(
//                                               width: 300,
//                                               child: _buildSearchField(
//                                                 provider,
//                                               ),
//                                             ),
//                                           ],
//                                         );
//                                 },
//                               ),
//                             ),
//                             Expanded(
//                               child: SingleChildScrollView(
//                                 scrollDirection: Axis.horizontal,
//                                 child: SizedBox(
//                                   width: 1300, // Total fixed width
//                                   child: Column(
//                                     children: [
//                                       // Header Row
//                                       Container(
//                                         padding: const EdgeInsets.all(12),
//                                         color: const Color(0xFF4A7AE3),
//                                         child: Row(
//                                           children: [
//                                             _buildHeaderCell('No', 50),
//                                             _buildHeaderCell('Pdf', 100),
//                                             _buildHeaderCell('Action', 100),
//                                             _buildHeaderCell(
//                                               'Vendor Name',
//                                               150,
//                                             ),
//                                             _buildHeaderCell('Invoice No', 120),
//                                             _buildHeaderCell(
//                                               'Invoice Date',
//                                               100,
//                                             ),
//                                             _buildHeaderCell(
//                                               'Total Amount',
//                                               120,
//                                             ),
//                                             _buildHeaderCell(
//                                               'Advance Paid',
//                                               120,
//                                             ),
//                                             _buildHeaderCell(
//                                               'Payment Date',
//                                               100,
//                                             ),
//                                             _buildHeaderCell('Tax %', 80),
//                                             _buildHeaderCell('Discount', 100),
//                                             _buildHeaderCell(
//                                               'Payable Amount',
//                                               120,
//                                             ),
//                                           ],
//                                         ),
//                                       ),

//                                       // Data Rows
//                                       ListView.builder(
//                                         shrinkWrap: true,
//                                         physics:
//                                             const NeverScrollableScrollPhysics(),
//                                         itemCount: payments.length,
//                                         itemBuilder: (context, index) {
//                                           final payment = payments[index];
//                                           return Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               vertical: 12,
//                                             ),
//                                             color: index.isOdd
//                                                 ? Colors.grey[50]
//                                                 : Colors.white,
//                                             child: Row(
//                                               children: [
//                                                 _buildDataCell(
//                                                   '${index + 1}',
//                                                   50,
//                                                 ),

//                                                 // PDF icon only
//                                                 SizedBox(
//                                                   width: 70,
//                                                   child: Center(
//                                                     child: IconButton(
//                                                       icon: const Icon(
//                                                         Icons.picture_as_pdf,
//                                                         size: 20,
//                                                       ),
//                                                       onPressed: () =>
//                                                           _generateAndViewPdf(
//                                                             payment,
//                                                           ),
//                                                     ),
//                                                   ),
//                                                 ),

//                                                 // Eye icon only
//                                                 SizedBox(
//                                                   width: 120,
//                                                   child: Center(
//                                                     child: IconButton(
//                                                       icon: const Icon(
//                                                         Icons.remove_red_eye,
//                                                         size: 20,
//                                                       ),
//                                                       onPressed: () =>
//                                                           showPaymentDetails(
//                                                             context,
//                                                             payment,
//                                                           ),
//                                                     ),
//                                                   ),
//                                                 ),

//                                                 _buildDataCell(
//                                                   payment.vendorName ?? 'N/A',
//                                                   200,
//                                                   allowWrap: true,
//                                                 ),
//                                                 _buildDataCell(
//                                                   payment.invoiceNo ?? 'N/A',
//                                                   100,
//                                                 ),
//                                                 _buildDataCell(
//                                                   _formatDate(
//                                                     payment.invoiceDate,
//                                                   ),
//                                                   100,
//                                                 ),
//                                                 _buildDataCell(
//                                                   _formatCurrency(
//                                                     payment.payableAmount,
//                                                   ),
//                                                   120,
//                                                 ),
//                                                 _buildDataCell(
//                                                   _formatCurrency(
//                                                     payment.advanceAmount,
//                                                   ),
//                                                   120,
//                                                 ),
//                                                 _buildDataCell(
//                                                   _formatDate(
//                                                     payment.paymentDate,
//                                                   ),
//                                                   100,
//                                                 ),
//                                                 _buildDataCell(
//                                                   '${payment.taxDetails?.toStringAsFixed(2) ?? '0.00'}%',
//                                                   80,
//                                                 ),
//                                                 _buildDataCell(
//                                                   _formatCurrency(
//                                                     payment.discountDetails,
//                                                   ),
//                                                   100,
//                                                 ),
//                                                 _buildDataCell(
//                                                   _formatCurrency(
//                                                     payment.totalPayableAmount,
//                                                   ),
//                                                   120,
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
