import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_bootstrap.dart';

export 'app.dart' show MotoScanApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const MotoScanApp());
}
