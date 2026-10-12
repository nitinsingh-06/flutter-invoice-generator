import 'package:hive_flutter/hive_flutter.dart';

import '../models/company_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_model.dart';

class HiveService {
  HiveService._();

  static const String companyBoxName = 'company_box';
  static const String invoicesBoxName = 'invoices_box';
  static const String companyProfileKey = 'profile';

  static Box<CompanyModel> get companyBox =>
      Hive.box<CompanyModel>(companyBoxName);

  static Box<InvoiceModel> get invoicesBox =>
      Hive.box<InvoiceModel>(invoicesBoxName);

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CompanyModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CustomerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(InvoiceItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(InvoiceModelAdapter());
    }

    await Hive.openBox<CompanyModel>(companyBoxName);
    await Hive.openBox<InvoiceModel>(invoicesBoxName);
  }

  static CompanyModel? getCompanyProfile() {
    return companyBox.get(companyProfileKey);
  }

  static Future<void> saveCompanyProfile(CompanyModel company) async {
    await companyBox.put(companyProfileKey, company);
  }

  static List<InvoiceModel> getAllInvoices() {
    final invoices = invoicesBox.values.toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  static Future<void> saveInvoice(InvoiceModel invoice) async {
    await invoicesBox.put(invoice.id, invoice);
  }

  static Future<void> deleteInvoice(String id) async {
    await invoicesBox.delete(id);
  }

  static int get invoiceCount => invoicesBox.length;
}