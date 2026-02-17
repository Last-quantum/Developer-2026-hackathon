import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/plan/application/local_storage_service.dart';

export 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = LocalStorageService();
  await storage.init();

  runApp(MyApp(storage: storage));
}
