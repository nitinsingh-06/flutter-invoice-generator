import 'package:hive/hive.dart';

part 'invoice_item_model.g.dart';

/// Represents a single row in the invoice's item table:
/// Serial Number | Item Name | HSN Code | Quantity | Unit Price | Total
///
/// A list of these is stored inside each InvoiceModel. The serial number
/// itself is NOT stored — it's derived from the item's position in the list
/// (index + 1), so reordering/deleting rows never leaves gaps.
///
/// typeId is fixed at 2 and must NEVER change after the app ships.
@HiveType(typeId: 2)
class InvoiceItemModel extends HiveObject {
  @HiveField(0)
  String itemName;

  @HiveField(1)
  String hsnCode;

  /// Stored as double to support fractional quantities (e.g. 1.5 meters).
  @HiveField(2)
  double quantity;

  @HiveField(3)
  double unitPrice;
  
InvoiceItemModel({
    this.itemName = '',
    this.hsnCode = '',
    this.quantity = 1.0,
    this.unitPrice = 0.0,
  });

  /// Row total = Quantity × Unit Price — computed, never stored, so it
  /// can never drift out of sync if quantity/price is edited.
  double get total => quantity * unitPrice;

  bool get isValid => itemName.trim().isNotEmpty && quantity > 0;

  InvoiceItemModel copyWith({
    String? itemName,
    String? hsnCode,
    double? quantity,
    double? unitPrice,
  }) {
    return InvoiceItemModel(
      itemName: itemName ?? this.itemName,
      hsnCode: hsnCode ?? this.hsnCode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}