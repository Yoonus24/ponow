// import 'package:flutter/material.dart';

// void showKeyboardDialog({
//   required BuildContext context,
//   TextEditingController? controller,
//   String? title,
//   bool showAlphabetsFirst = true,
//   VoidCallback? onTextEntered,
// }) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return KeyboardDialog(
//         controller: controller,
//         title: title ?? 'Enter Text',
//         showAlphabetsFirst: showAlphabetsFirst,
//         onTextEntered: onTextEntered,
//       );
//     },
//   );
// }

// class KeyboardDialog extends StatefulWidget {
//   final TextEditingController? controller;
//   final String title;
//   final bool showAlphabetsFirst;
//   final VoidCallback? onTextEntered;

//   const KeyboardDialog({
//     super.key,
//     this.controller,
//     required this.title,
//     this.showAlphabetsFirst = true,
//     this.onTextEntered,
//   });

//   @override
//   _KeyboardDialogState createState() => _KeyboardDialogState();
// }

// class _KeyboardDialogState extends State<KeyboardDialog> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _textController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(
//       length: 2,
//       vsync: this,
//       initialIndex: widget.showAlphabetsFirst ? 0 : 1,
//     );
    
//     // Initialize with existing text if controller is provided
//     if (widget.controller != null && widget.controller!.text.isNotEmpty) {
//       _textController.text = widget.controller!.text;
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _textController.dispose();
//     super.dispose();
//   }

//   void _onKeyPressed(String key) {
//     setState(() {
//       _textController.text += key;
//     });
//   }

//   void _onBackspace() {
//     if (_textController.text.isNotEmpty) {
//       setState(() {
//         _textController.text = _textController.text.substring(0, _textController.text.length - 1);
//       });
//     }
//   }

//   void _onSubmit() {
//     if (widget.controller != null) {
//       widget.controller!.text = _textController.text;
//     }
//     widget.onTextEntered?.call();
//     Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               widget.title,
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: TextField(
//               controller: _textController,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 labelText: 'Type here',
//               ),
//               readOnly: true,
//             ),
//           ),
//           SizedBox(height: 8),
//           TabBar(
//             controller: _tabController,
//             tabs: [
//               Tab(text: 'Alphabets'),
//               Tab(text: 'Numbers'),
//             ],
//           ),
//           SizedBox(
//             height: 200,
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Alphabet Keyboard
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _buildKeyboardRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
//                     _buildKeyboardRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L']),
//                     _buildKeyboardRow(['Z', 'X', 'C', 'V', 'B', 'N', 'M']),
//                     _buildActionRow(),
//                   ],
//                 ),
//                 // Number Keyboard
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _buildKeyboardRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']),
//                     _buildKeyboardRow(['-', '/', ':', ';', '(', ')', '\$', '&', '@', '"']),
//                     _buildActionRow(),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKeyboardRow(List<String> keys) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: keys.map((key) {
//         return Padding(
//           padding: const EdgeInsets.all(2.0),
//           child: Material(
//             child: InkWell(
//               onTap: () => _onKeyPressed(key),
//               child: Container(
//                 width: 30,
//                 height: 40,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(key),
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildActionRow() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         IconButton(
//           icon: Icon(Icons.backspace),
//           onPressed: _onBackspace,
//         ),
//         SizedBox(width: 8),
//         ElevatedButton(
//           onPressed: _onSubmit,
//           child: Text('Submit'),
//         ),
//         SizedBox(width: 8),
//         ElevatedButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text('Cancel'),
//         ),
//       ],
//     );
//   }
// }