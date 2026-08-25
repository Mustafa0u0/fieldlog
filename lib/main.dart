import 'package:flutter/material.dart';

import 'data/repository.dart';
import 'screens/round_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FieldLogApp(repository: await InspectionRepository.open()));
}

class FieldLogApp extends StatelessWidget {
  const FieldLogApp({required this.repository, super.key});

  final InspectionRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldLog',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: RoundScreen(repository: repository),
    );
  }
}
