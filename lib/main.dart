import 'package:flutter/material.dart';

import 'screens/dashboard_page.dart';

/// StudyLog - Milestone 1
/// Dashboard menampilkan mata kuliah hari ini. Catatan ditambahkan langsung
/// untuk mata kuliah yang dipilih dari dashboard (tanpa memilih manual).
void main() => runApp(const StudyLogApp());

class StudyLogApp extends StatelessWidget {
  /// [now] bisa diganti saat pengujian agar hari/jam bisa diatur.
  final DateTime Function()? now;

  const StudyLogApp({super.key, this.now});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: DashboardPage(now: now),
    );
  }
}
