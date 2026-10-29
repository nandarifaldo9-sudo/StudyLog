
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Membuka dan menyiapkan database SQLite lokal.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String namaDatabase = 'studylog.db';
  static const String tabelCatatan = 'catatan';

  Future<Database>? _database;

  Future<Database> get database async {
    try {
      return await (_database ??= _buka());
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<Database> _buka() async {
    // Pilih implementasi database sesuai platform.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final lokasi = kIsWeb
        ? namaDatabase
        : join(await getDatabasesPath(), namaDatabase);

    return openDatabase(
      lokasi,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tabelCatatan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mata_kuliah TEXT NOT NULL,
            judul TEXT NOT NULL,
            isi TEXT NOT NULL,
            waktu TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
