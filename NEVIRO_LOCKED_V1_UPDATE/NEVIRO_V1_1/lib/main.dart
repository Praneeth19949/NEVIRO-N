import 'package:flutter/material.dart';

import 'app.dart';
import 'services/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.load();
  runApp(NeviroApp(store: store));
}
