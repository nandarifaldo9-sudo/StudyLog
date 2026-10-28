import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/catatan_repository.dart';
import 'data/database_helper.dart';
import 'screens/dashboard_page.dart';
import 'state/catatan_store.dart';

/// StudyLog - Milestone 3
/// Data catatan disimpan permanen di SQLite lewat CatatanRepository, dan
/// tetap dibagikan ke semua layar oleh CatatanStore (ChangeNotifier + Provider).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyLogApp());
}

class StudyLogApp extends StatelessWidget {
  /// [now] bisa diganti saat pengujian agar hari/jam bisa diatur.
  final DateTime Function()? now;

  /// [repository] bisa diganti saat pengujian (mis. versi memori).
  /// Jika kosong, dipakai SQLite.
  final CatatanRepository? repository;

  const StudyLogApp({super.key, this.now, this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatatanStore(
        repository ?? SqliteCatatanRepository(DatabaseHelper.instance),
      )..muat(),
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
