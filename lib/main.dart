import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/catatan_repository.dart';
import 'data/database_helper.dart';
import 'screens/home_shell.dart';
import 'viewmodels/catatan_view_model.dart';
import 'viewmodels/jadwal_view_model.dart';

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
    const latar = Color(0xFFF6F7FB);
    const utama = Color(0xFF3658A7);
    const garis = Color(0xFFE5E8F0);
    const radius = 18.0;
    final tema = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: utama,
        surface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: latar,
      appBarTheme: const AppBarTheme(
        backgroundColor: latar,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF202638),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: garis),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: garis),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: garis),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: utama, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: garis),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: utama,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        height: 72,
        indicatorColor: const Color(0xFFE6EAF8),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
    );
    return ChangeNotifierProvider(
      create: (_) => CatatanViewModel(
        repository ?? SqliteCatatanRepository(DatabaseHelper.instance),
      )..muat(),
      child: ChangeNotifierProvider(
        create: (_) => JadwalViewModel()..muat(),
        child: MaterialApp(
          title: 'StudyLog',
          debugShowCheckedModeBanner: false,
          theme: tema,
          home: HomeShell(now: now),
        ),
      ),
    );
  }
}
