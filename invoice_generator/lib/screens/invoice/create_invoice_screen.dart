import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/customer_model.dart';
import '../../models/invoice_item_model.dart';
import '../../models/invoice_model.dart';
import '../../services/hive_service.dart';
import '../../services/invoice_number_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_text_field.dart';
import '../pdf_preview/pdf_preview_screen.dart';

/// The core screen of the app: collects customer details, a dynamic list
/// of line items, discount, and GST%, and computes all totals live.
///
/// Can be used in two modes:
/// - **Create mode** ([existingInvoice] is null): starts blank with a
///   freshly auto-generated invoice number.
/// - **Edit mode** ([existingInvoice] is provided): pre-fills every field
///   from the existing invoice, and saving overwrites it (same [id]).
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key, this.existingInvoice});

  final InvoiceModel? existingInvoice;

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _discountController;
  late final TextEditingController _gstController;

  late String _invoiceId;
  late String _invoiceNumber;
  late DateTime _invoiceDate;

  /// Each row keeps its own set of controllers so editing one field never
  /// rebuilds/loses focus on the others — a common pitfall with dynamic
  /// form lists if controllers are recreated on every build instead of
  /// being kept alive per-row.
  final List<_ItemRowControllers> _itemRows = [];

  bool get _isEditMode => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingInvoice;

    _invoiceId = existing?.id ?? _uuid.v4();
    _invoiceNumber = existing?.invoiceNumber ?? InvoiceNumberService.generateNext();
    _invoiceDate = existing?.invoiceDate ?? DateTime.now();

    _customerNameController = TextEditingController(text: existing?.customer.name ?? '');
    _customerAddressController = TextEditingController(text: existing?.customer.address ?? '');
    _customerPhoneController = TextEditingController(text: existing?.customer.phone ?? '');
    _discountController = TextEditingController(
      text: existing != null && existing.discount > 0 ? existing.discount.toStringAsFixed(2) : '',
    );
    _gstController = TextEditingController(
      text: existing != null && existing.gstPercent > 0 ? existing.gstPercent.toStringAsFixed(0) : '18',
    );

    if (existing != null && existing.items.isNotEmpty) {
      for (final item in existing.items) {
        _itemRows.add(_ItemRowControllers.fromItem(item));
      }
    } else {
      _addItemRow(); // Every invoice starts with at least one empty row.
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _gstController.dispose();
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _itemRows.add(_ItemRowControllers());
    });
  }

  void _removeItemRow(int index) {
    if (_itemRows.length == 1) {
      // Never allow the table to go fully empty — keep exactly one row so
      // there's always something for the user to fill in.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An invoice needs at least one item row')),
      );
      return;
    }
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
    });
  }

  // ---------------------------------------------------------------------
  // Live calculations — recomputed on every build from current controller
  // text, so the totals section always reflects exactly what's on screen,
  // with zero risk of drifting out of sync.
  // ---------------------------------------------------------------------

  double get _subtotal {
    return _itemRows.fold(0.0, (sum, row) => sum + row.total);
  }

  double get _discount => double.tryParse(_discountController.text) ?? 0;

  double get _gstPercent => double.tryParse(_gstController.text) ?? 0;

  double get _taxableAmount {
    final result = _subtotal - _discount;
    return result < 0 ? 0 : result;
  }

  double get _gstAmount => _taxableAmount * (_gstPercent / 100);

  double get _grandTotal => _taxableAmount + _gstAmount;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  InvoiceModel _buildInvoiceModel() {
    final items = _itemRows
        .map((row) => InvoiceItemModel(
              itemName: row.nameController.text.trim(),
              hsnCode: row.hsnController.text.trim(),
              quantity: double.tryParse(row.qtyController.text) ?? 0,
              unitPrice: double.tryParse(row.priceController.text) ?? 0,
            ))
        .where((item) => item.isValid)
        .toList();

    final customer = CustomerModel(
      name: _customerNameController.text.trim(),
      address: _customerAddressController.text.trim(),
      phone: _customerPhoneController.text.trim(),
    );

    return InvoiceModel(
      id: _invoiceId,
      invoiceNumber: _invoiceNumber,
      invoiceDate: _invoiceDate,
      customer: customer,
      items: items,
      discount: _discount,
      gstPercent: _gstPercent,
      createdAt: widget.existingInvoice?.createdAt,
    );
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final invoice = _buildInvoiceModel();

    if (!invoice.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a customer name and at least one valid item'),
        ),
      );
      return;
    }

    await HiveService.saveInvoice(invoice);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(invoice: invoice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Invoice' : 'Create Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionCard(
              title: 'Invoice Details',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ReadOnlyField(
                        label: 'Invoice Number',
                        value: _invoiceNumber,
                        icon: Icons.tag_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: _ReadOnlyField(
                          label: 'Invoice Date',
                          value: DateFormat('dd/MM/yyyy').format(_invoiceDate),
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Customer Details',
              children: [
                CustomTextField(
                  controller: _customerNameController,
                  label: 'Customer Name',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Customer name is required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _customerAddressController,
                  label: 'Customer Address',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _customerPhoneController,
                  label: 'Customer Phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Items',
              trailing: TextButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Item'),
              ),
              children: [
                for (int i = 0; i < _itemRows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ItemRow(
                      serialNumber: i + 1,
                      controllers: _itemRows[i],
                      onChanged: () => setState(() {}),
                      onDelete: () => _removeItemRow(i),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Charges',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _discountController,
                        label: 'Discount',
                        icon: Icons.discount_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _gstController,
                        label: 'GST %',
                        icon: Icons.percent_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TotalsSummary(
              subtotal: _subtotal,
              discount: _discount,
              gstPercent: _gstPercent,
              gstAmount: _gstAmount,
              grandTotal: _grandTotal,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _generateInvoice,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate Invoice'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Holds the four text controllers for a single item-table row, plus a
/// computed [total]. Kept as one object per row so Flutter's widget
/// rebuilds never lose keystrokes or focus mid-edit.
class _ItemRowControllers {
  _ItemRowControllers()
      : nameController = TextEditingController(),
        hsnController = TextEditingController(),
        qtyController = TextEditingController(text: '1'),
        priceController = TextEditingController();

  _ItemRowControllers.fromItem(InvoiceItemModel item)
      : nameController = TextEditingController(text: item.itemName),
        hsnController = TextEditingController(text: item.hsnCode),
        qtyController = TextEditingController(text: _trimZero(item.quantity)),
        priceController = TextEditingController(text: _trimZero(item.unitPrice));

  final TextEditingController nameController;
  final TextEditingController hsnController;
  final TextEditingController qtyController;
  final TextEditingController priceController;

  double get total {
    final qty = double.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    return qty * price;
  }

  void dispose() {
    nameController.dispose();
    hsnController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }

  /// Formats a double without a trailing ".0" for whole numbers, so
  /// pre-filled quantity/price fields look natural when editing
  /// (e.g. "2" instead of "2.0").
  static String _trimZero(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}

/// A single row of the dynamic item table: serial number, item name,
/// HSN code, quantity, unit price, computed total, and a delete button.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.serialNumber,
    required this.controllers,
    required this.onChanged,
    required this.onDelete,
  });

  final int serialNumber;
  final _ItemRowControllers controllers;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  '$serialNumber',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppTheme.errorRed,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          CustomTextField(
            controller: controllers.nameController,
            label: 'Item Name',
            onChanged: (_) => onChanged(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: controllers.hsnController,
                  label: 'HSN Code',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: controllers.qtyController,
                  label: 'Qty',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: controllers.priceController,
                  label: 'Unit Price',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${CurrencyFormatter.format(controllers.total)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only display field (used for Invoice Number and Invoice Date) —
/// styled to look like a text field without being directly editable.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card wrapper with a title (and optional trailing action) used to group
/// each section of the form — avoids repeating the same Card+Padding+Title
/// structure five times across the screen.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Displays Subtotal, Discount, GST, and Grand Total — the summary block
/// at the bottom of the Create Invoice screen, always in sync with the
/// live calculations passed in from the parent.
class _TotalsSummary extends StatelessWidget {
  const _TotalsSummary({
    required this.subtotal,
    required this.discount,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
  });

  final double subtotal;
  final double discount;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow('Subtotal', CurrencyFormatter.format(subtotal)),
            if (discount > 0)
              _totalRow('Discount', '- ${CurrencyFormatter.format(discount)}'),
            _totalRow(
              'GST @${gstPercent.toStringAsFixed(gstPercent % 1 == 0 ? 0 : 1)}%',
              CurrencyFormatter.format(gstAmount),
            ),
            const Divider(height: 24),
            _totalRow(
              'Grand Total',
              CurrencyFormatter.format(grandTotal),
              isEmphasis: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isEmphasis = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isEmphasis ? 16 : 14,
              fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w400,
              color: isEmphasis ? null : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isEmphasis ? 18 : 14,
              fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w600,
              color: isEmphasis ? AppTheme.accentOrange : null,
            ),
          ),
        ],
      ),
    );
  }
}
