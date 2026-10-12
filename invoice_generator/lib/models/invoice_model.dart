import 'package:hive/hive.dart';

import 'customer_model.dart';
import 'invoice_item_model.dart';

part 'invoice_model.g.dart';

/// typeId is fixed at 3 and must NEVER change after the app ships.
@HiveType(typeId: 3)
class InvoiceModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String invoiceNumber;

  @HiveField(2)
  DateTime invoiceDate;

  @HiveField(3)
  CustomerModel customer;

  @HiveField(4)
  List<InvoiceItemModel> items;

  @HiveField(5)
  double discount;

  @HiveField(6)
  double gstPercent;

  @HiveField(7)
  DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customer,
    List<InvoiceItemModel>? items,
    this.discount = 0,
    this.gstPercent = 0,
    DateTime? createdAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get taxableAmount {
    final result = subtotal - discount;
    return result < 0 ? 0 : result;
  }

  double get gstAmount => taxableAmount * (gstPercent / 100);

  double get grandTotal => taxableAmount + gstAmount;

  bool get isValid => customer.isValid && items.any((item) => item.isValid);

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    CustomerModel? customer,
    List<InvoiceItemModel>? items,
    double? discount,
    double? gstPercent,
    DateTime? createdAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customer: customer ?? this.customer,
      items: items ?? List<InvoiceItemModel>.from(this.items),
      discount: discount ?? this.discount,
      gstPercent: gstPercent ?? this.gstPercent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  InvoiceModel duplicateWith({
    required String newId,
    required String newInvoiceNumber,
  }) {
    return InvoiceModel(
      id: newId,
      invoiceNumber: newInvoiceNumber,
      invoiceDate: DateTime.now(),
      customer: customer.copyWith(),
      items: items.map((item) => item.copyWith()).toList(),
      discount: discount,
      gstPercent: gstPercent,
      createdAt: DateTime.now(),
    );
  }
}