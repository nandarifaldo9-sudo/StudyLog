import '../models/catatan.dart';
import 'database_helper.dart';

/// Kontrak penyimpanan catatan. UI dan store tidak menulis SQL langsung.
abstract class CatatanRepository {
  /// READ - semua catatan, terbaru di atas.
  Future<List<HasilCatatan>> semua();

  /// CREATE - mengembalikan catatan lengkap dengan id yang baru dibuat.
  Future<HasilCatatan> tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  });

  /// UPDATE - hanya judul dan isi; id, mata kuliah, dan waktu tetap.
  Future<void> ubah(int id, {required String judul, required String isi});

  /// DELETE
  Future<void> hapus(int id);
}

/// Implementasi SQLite (dipakai aplikasi sungguhan).
class SqliteCatatanRepository implements CatatanRepository {
  SqliteCatatanRepository(this._helper);

  final DatabaseHelper _helper;

  static const _tabel = DatabaseHelper.tabelCatatan;

  @override
  Future<List<HasilCatatan>> semua() async {
    final db = await _helper.database;
    final baris = await db.query(_tabel, orderBy: 'id DESC');
    return baris.map(HasilCatatan.fromMap).toList();
  }

  @override
  Future<HasilCatatan> tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  }) async {
    final db = await _helper.database;
    final id = await db.insert(_tabel, {
      'mata_kuliah': mataKuliah,
      'judul': judul,
      'isi': isi,
      'waktu': waktu.toIso8601String(),
    });
    return HasilCatatan(
      id: id,
      mataKuliah: mataKuliah,
      judul: judul,
      isi: isi,
      waktu: waktu,
    );
  }

  @override
  Future<void> ubah(int id,
      {required String judul, required String isi}) async {
    final db = await _helper.database;
    await db.update(
      _tabel,
      {'judul': judul, 'isi': isi},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> hapus(int id) async {
    final db = await _helper.database;
    await db.delete(_tabel, where: 'id = ?', whereArgs: [id]);
  }
}
