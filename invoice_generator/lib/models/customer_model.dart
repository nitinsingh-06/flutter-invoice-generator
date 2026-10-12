import 'package:hive/hive.dart';

part 'customer_model.g.dart';


@HiveType(typeId: 1)
class CustomerModel {
  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
  String phone;

  CustomerModel({
    this.name = '',
    this.address = '',
    this.phone = '',
  });

  bool get isValid => name.trim().isNotEmpty;

  CustomerModel copyWith({
    String? name,
    String? address,
    String? phone,
  }) {
    return CustomerModel(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }
}