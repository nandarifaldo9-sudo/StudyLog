import '../models/catatan.dart';
import 'catatan_repository.dart';

/// Implementasi di memori dengan kontrak yang sama seperti SQLite.
/// Dipakai pada pengujian agar tidak membutuhkan database sungguhan.
class MemoriCatatanRepository implements CatatanRepository {
  final List<HasilCatatan> _data = [];
  int _idBerikutnya = 1;

  @override
  Future<List<HasilCatatan>> semua() async => _data.reversed.toList();

  @override
  Future<HasilCatatan> tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  }) async {
    final baru = HasilCatatan(
      id: _idBerikutnya++,
      mataKuliah: mataKuliah,
      judul: judul,
      isi: isi,
      waktu: waktu,
    );
    _data.add(baru);
    return baru;
  }

  @override
  Future<void> ubah(int id,
      {required String judul, required String isi}) async {
    final i = _data.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _data[i] = _data[i].copyWith(judul: judul, isi: isi);
  }

  @override
  Future<void> hapus(int id) async {
    _data.removeWhere((c) => c.id == id);
  }
}
