import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/invoice_model.dart';
import '../../services/hive_service.dart';
import '../../services/invoice_number_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../invoice/create_invoice_screen.dart';
import '../pdf_preview/pdf_preview_screen.dart';

/// Lists every saved invoice with search, and per-invoice actions: Edit,
/// Delete, Duplicate, Print Again, Share Again.
///
/// Reads directly from [HiveService] on each load rather than holding its
/// own separate state store — Invoice History has no business logic of
/// its own beyond displaying/filtering/dispatching to other screens or
/// service calls, matching the "separate UI from business logic" principle.
class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final _uuid = const Uuid();
  final _searchController = TextEditingController();

  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInvoices() {
    setState(() {
      _allInvoices = HiveService.getAllInvoices();
      _applyFilter();
    });
  }

  /// Filters by customer name or invoice number — the two things a user
  /// realistically remembers when searching for a past invoice.
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredInvoices = query.isEmpty
          ? _allInvoices
          : _allInvoices.where((invoice) {
              return invoice.customer.name.toLowerCase().contains(query) ||
                  invoice.invoiceNumber.toLowerCase().contains(query);
            }).toList();
    });
  }

  Future<void> _editInvoice(InvoiceModel invoice) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(existingInvoice: invoice),
      ),
    );
    _loadInvoices(); // Refresh in case it was edited and saved.
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
          'This will permanently delete invoice ${invoice.invoiceNumber}. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.deleteInvoice(invoice.id);
      _loadInvoices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${invoice.invoiceNumber} deleted')),
      );
    }
  }

  Future<void> _duplicateInvoice(InvoiceModel invoice) async {
    final duplicate = invoice.duplicateWith(
      newId: _uuid.v4(),
      newInvoiceNumber: InvoiceNumberService.generateNext(),
    );
    await HiveService.saveInvoice(duplicate);
    _loadInvoices();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated as ${duplicate.invoiceNumber}')),
    );
  }

  void _openPdf(InvoiceModel invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: invoice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer name or invoice number',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filteredInvoices.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredInvoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final invoice = _filteredInvoices[index];
                      return _InvoiceCard(
                        invoice: invoice,
                        onTap: () => _openPdf(invoice),
                        onEdit: () => _editInvoice(invoice),
                        onDelete: () => _deleteInvoice(invoice),
                        onDuplicate: () => _duplicateInvoice(invoice),
                        onPrintAgain: () => _openPdf(invoice),
                        onShareAgain: () => _openPdf(invoice),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off_rounded : Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearchQuery ? 'No matching invoices' : 'No invoices yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearchQuery
                  ? 'Try a different customer name or invoice number'
                  : 'Invoices you create will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single invoice row card: customer name, invoice number/date, grand
/// total, and an overflow menu with Edit/Delete/Duplicate/Print/Share.
/// Extracted as its own widget to keep the parent's [build] focused on
/// list orchestration rather than per-row layout details.
class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onPrintAgain,
    required this.onShareAgain,
  });

  final InvoiceModel invoice;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onPrintAgain;
  final VoidCallback onShareAgain;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.customer.name.isNotEmpty
                          ? invoice.customer.name
                          : 'Unnamed Customer',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${invoice.invoiceNumber} • $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.format(invoice.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'print':
                      onPrintAgain();
                      break;
                    case 'share':
                      onShareAgain();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Invoice')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate Invoice')),
                  PopupMenuItem(value: 'print', child: Text('Print Again')),
                  PopupMenuItem(value: 'share', child: Text('Share Again')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
