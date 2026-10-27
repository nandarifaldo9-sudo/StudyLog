import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_page.dart';
import 'state/catatan_store.dart';

/// StudyLog - Milestone 2
/// Navigasi 4 layar (Beranda, Daftar, Detail, Form) dan state lintas layar
/// lewat CatatanStore (ChangeNotifier + Provider).
void main() => runApp(const StudyLogApp());

class StudyLogApp extends StatelessWidget {
  /// [now] bisa diganti saat pengujian agar hari/jam bisa diatur.
  final DateTime Function()? now;

  const StudyLogApp({super.key, this.now});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatatanStore(),
      child: MaterialApp(
        title: 'StudyLog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: DashboardPage(now: now),
      ),
    );
  }
}