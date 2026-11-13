import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/catatan_repository.dart';
import 'data/database_helper.dart';
import 'data/jadwal.dart';
import 'screens/main_page.dart';
import 'viewmodels/catatan_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyLogApp());
}

class StudyLogApp extends StatelessWidget {
  final DateTime Function()? now;
  final CatatanRepository? repository;

  const StudyLogApp({super.key, this.now, this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CatatanViewModel(
            repository ?? SqliteCatatanRepository(DatabaseHelper.instance),
          )..muat(),
        ),
        ChangeNotifierProvider(
          create: (_) => JadwalViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'StudyLog',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: MainPage(now: now),
      ),
    );
  }
}