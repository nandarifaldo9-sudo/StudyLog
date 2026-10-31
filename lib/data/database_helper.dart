import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Membuka dan menyiapkan database SQLite lokal (satu koneksi untuk seluruh app).
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String namaDatabase = 'studylog.db';
  static const String tabelCatatan = 'catatan';

  /// v1: kolom `waktu`. v2: kolom `tanggal` (sesuai workbook 5.1).
  static const int versiDatabase = 2;

  static const String _sqlBuatTabel = '''
    CREATE TABLE $tabelCatatan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mata_kuliah TEXT NOT NULL,
      judul TEXT NOT NULL,
      isi TEXT NOT NULL,
      tanggal TEXT NOT NULL
    )
  ''';

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
      version: versiDatabase,
      onCreate: (db, version) => db.execute(_sqlBuatTabel),
      onUpgrade: (db, versiLama, versiBaru) async {
        if (versiLama < 2) {
          // Migrasi: data lama dipindahkan, tidak ada yang dihapus.
          await db.execute('ALTER TABLE $tabelCatatan RENAME TO catatan_lama');
          await db.execute(_sqlBuatTabel);
          await db.execute('''
            INSERT INTO $tabelCatatan (id, mata_kuliah, judul, isi, tanggal)
            SELECT id, mata_kuliah, judul, isi, waktu FROM catatan_lama
          ''');
          await db.execute('DROP TABLE catatan_lama');
        }
      },
    );
  }
} 