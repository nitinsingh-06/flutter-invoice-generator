import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/hive_service.dart';
Future<void> main() async {
  // Required whenever async platform code (Hive, path_provider, etc.) runs
  // before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();

  // Sets up Hive's storage directory for the current platform, registers
  // every model's TypeAdapter, and opens all boxes the app uses.
  await HiveService.init();

  runApp(
    // ProviderScope must wrap the whole app exactly once at the root —
    // it is the storage container for every Riverpod provider defined
    // anywhere in the app.
    
    const ProviderScope(
      child: BillGeneratorApp(),
    ),
  );
}