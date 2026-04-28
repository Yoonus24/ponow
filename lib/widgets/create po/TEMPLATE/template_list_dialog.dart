// lib/widgets/create_po/template_list_dialog.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/po_template.dart';
import '../../../providers/template_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateListDialog extends StatefulWidget {
  final Function(POTemplate) onTemplateSelected;

  const TemplateListDialog({super.key, required this.onTemplateSelected});

  @override
  _TemplateListDialogState createState() => _TemplateListDialogState();
}

class _TemplateListDialogState extends State<TemplateListDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TemplateProvider>(
        context,
        listen: false,
      ).fetchTemplates(isRefresh: true);
    });

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<TemplateProvider>(context, listen: false);

      provider.loadMoreTemplates(search: _searchController.text);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final provider = Provider.of<TemplateProvider>(context, listen: false);

      provider.fetchTemplates(search: _searchController.text, isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width < 1024;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: isMobile ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildTemplateList(isMobile, isTablet)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Select Template',
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search templates...',
        prefixIcon: const Icon(Icons.search),

        // ✅ ADD THIS
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();

                  Provider.of<TemplateProvider>(
                    context,
                    listen: false,
                  ).fetchTemplates(isRefresh: true); // 🔥 reload all
                },
              )
            : null,

        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildTemplateList(bool isMobile, bool isTablet) {
    return Consumer<TemplateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.templates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.templates.isEmpty) {
          return Center(child: Text(provider.error!));
        }

        final templates = provider.templates;

        if (templates.isEmpty) {
          return RefreshIndicator(
            color: Colors.blue,
            onRefresh: () async {
              await Provider.of<TemplateProvider>(
                context,
                listen: false,
              ).fetchTemplates(search: _searchController.text, isRefresh: true);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No templates found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        if (isMobile) {
          return RefreshIndicator(
            color: Colors.blue,
            onRefresh: () async {
              await Provider.of<TemplateProvider>(
                context,
                listen: false,
              ).fetchTemplates(search: _searchController.text, isRefresh: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: templates.length + 1,
              itemBuilder: (context, index) {
                if (index < templates.length) {
                  return _buildTemplateCard(templates[index]);
                } else {
                  if (provider.isFetchingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return const SizedBox();
                  }
                }
              },
            ),
          );
        } else {
          return RefreshIndicator(
            color: Colors.blue,
            onRefresh: () async {
              await Provider.of<TemplateProvider>(
                context,
                listen: false,
              ).fetchTemplates(search: _searchController.text, isRefresh: true);
            },
            child: GridView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: templates.length + 1,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 2 : 3,
                mainAxisExtent: 260,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                if (index < templates.length) {
                  return _buildTemplateCard(templates[index]);
                } else {
                  if (provider.isFetchingMore) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    return const SizedBox();
                  }
                }
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildTemplateCard(POTemplate t) {
    final provider = Provider.of<TemplateProvider>(context, listen: false);

    return Dismissible(
      key: ValueKey(t.templateId),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!t.isActive) {
            await provider.activateTemplate(t.templateId);
          } else {}
        } else {
          if (t.isActive) {
            await provider.deactivateTemplate(t.templateId);
          } else {}
        }
        await provider.fetchTemplates(
          search: _searchController.text,
          isRefresh: true,
        );

        return false;
      },
      background: _buildSwipeBg(
        color: Colors.green.shade600,
        icon: Icons.check_circle,
        text: "ACTIVATE",
        alignLeft: true,
      ),
      secondaryBackground: _buildSwipeBg(
        color: Colors.red.shade600,
        icon: Icons.power_settings_new,
        text: "DEACTIVATE",
        alignLeft: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showTemplateDetailsDialog(t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderRow(t),
                      const SizedBox(height: 6),
                      Text(
                        t.vendorName,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFooterRow(t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(POTemplate t) {
    return Row(
      children: [
        Expanded(
          child: Text(
            t.templateName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: t.isActive ? Colors.green.shade600 : Colors.red.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            t.isActive ? "ACTIVE" : "INACTIVE",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow(POTemplate t) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "${t.itemCount} items | Amount : ${t.totalOrderAmount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12.8,
              color: Colors.grey.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (t.isActive)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: OutlinedButton(
              onPressed: () {
                widget.onTemplateSelected(t);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueGrey.shade800,
                side: BorderSide(color: Colors.blueGrey.shade400, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              child: const Text("USE"),
            ),
          ),
      ],
    );
  }

  Widget _buildSwipeBg({
    required Color color,
    required IconData icon,
    required String text,
    required bool alignLeft,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: alignLeft
              ? [color.withOpacity(0.9), color.withOpacity(0.6)]
              : [color.withOpacity(0.6), color.withOpacity(0.9)],
          begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisAlignment: alignLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (!alignLeft)
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 10),
          if (alignLeft)
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }

  void _showTemplateDetailsDialog(POTemplate t) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 780),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Template Details',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildInfoRow('Template', t.templateName),
              _buildInfoRow('Vendor', t.vendorName),
              _buildInfoRow('Total Items', t.itemCount.toString()),

              _buildTableHeader(),

              const SizedBox(height: 13),

              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: t.items.length,
                  itemBuilder: (context, i) {
                    final item = t.items[i];
                    final bool isLast = i == t.items.length - 1;
                    return _buildItemRow(
                      itemName: item.itemName ?? '-',
                      quantity: item.quantity ?? 0,
                      uom: item.uom ?? '-',
                      isLast: isLast,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 15.5, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Item',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'Qty',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'UOM',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required String itemName,
    required num quantity,
    required String uom,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              itemName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 14.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(quantity.toString(), style: GoogleFonts.poppins()),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text(uom, style: GoogleFonts.poppins())),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
