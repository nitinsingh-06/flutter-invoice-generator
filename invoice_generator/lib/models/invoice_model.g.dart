// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';


class InvoiceModelAdapter extends TypeAdapter<InvoiceModel> {
  @override
  final int typeId = 3;

  @override
  InvoiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceModel(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      invoiceDate: fields[2] as DateTime,
      customer: fields[3] as CustomerModel,
      items: (fields[4] as List?)?.cast<InvoiceItemModel>(),
      discount: fields[5] as double,
      gstPercent: fields[6] as double,
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.invoiceDate)
      ..writeByte(3)
      ..write(obj.customer)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.discount)
      ..writeByte(6)
      ..write(obj.gstPercent)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
