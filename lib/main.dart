import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  runApp(const CafeFinderApp());
}

Future<void> _initializeFirebase() async {
  await initializeFirebase();
}
