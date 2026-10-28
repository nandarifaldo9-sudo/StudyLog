import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Membuka dan menyiapkan database SQLite lokal (satu koneksi untuk seluruh app).
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
      _database = null; // izinkan percobaan ulang jika gagal membuka
      rethrow;
    }
  }

  Future<Database> _buka() async {
    final lokasi = join(await getDatabasesPath(), namaDatabase);
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
