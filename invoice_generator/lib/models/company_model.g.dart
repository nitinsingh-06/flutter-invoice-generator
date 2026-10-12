// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompanyModelAdapter extends TypeAdapter<CompanyModel> {
  @override
  final int typeId = 0;

  @override
  CompanyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompanyModel(
      logoPath: fields[0] as String?,
      companyName: fields[1] as String,
      gstNumber: fields[2] as String,
      phone: fields[3] as String,
      email: fields[4] as String,
      address: fields[5] as String,
      branchAddress: fields[6] as String,
      bankName: fields[7] as String,
      accountNumber: fields[8] as String,
      ifscCode: fields[9] as String,
      upiId: fields[10] as String,
      signaturePath: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CompanyModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.logoPath)
      ..writeByte(1)
      ..write(obj.companyName)
      ..writeByte(2)
      ..write(obj.gstNumber)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.branchAddress)
      ..writeByte(7)
      ..write(obj.bankName)
      ..writeByte(8)
      ..write(obj.accountNumber)
      ..writeByte(9)
      ..write(obj.ifscCode)
      ..writeByte(10)
      ..write(obj.upiId)
      ..writeByte(11)
      ..write(obj.signaturePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
