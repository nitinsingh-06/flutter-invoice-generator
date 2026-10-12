import 'package:hive/hive.dart';

part 'company_model.g.dart';

/// Represents the business's own profile — the "from" side of every invoice.
/// typeId is fixed at 0 and must NEVER change after the app ships.
@HiveType(typeId: 0)
class CompanyModel extends HiveObject {
  @HiveField(0)
  String? logoPath;

  @HiveField(1)
  String companyName;

  @HiveField(2)
  String gstNumber;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String email;

  @HiveField(5)
  String address;

  /// e.g. "Branch Office: Premnagar Dehradun"
  @HiveField(6)
  String branchAddress;

  @HiveField(7)
  String bankName;

  @HiveField(8)
  String accountNumber;

  @HiveField(9)
  String ifscCode;

  @HiveField(10)
  String upiId;

  @HiveField(11)
  String? signaturePath;

  CompanyModel({
    this.logoPath,
    this.companyName = '',
    this.gstNumber = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.branchAddress = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.upiId = '',
    this.signaturePath,
  });

  bool get isProfileComplete =>
      companyName.trim().isNotEmpty &&
      gstNumber.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  CompanyModel copyWith({
    String? logoPath,
    String? companyName,
    String? gstNumber,
    String? phone,
    String? email,
    String? address,
    String? branchAddress,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? signaturePath,
  }) {
    return CompanyModel(
      logoPath: logoPath ?? this.logoPath,
      companyName: companyName ?? this.companyName,
      gstNumber: gstNumber ?? this.gstNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      branchAddress: branchAddress ?? this.branchAddress,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      signaturePath: signaturePath ?? this.signaturePath,
    );
  }
}