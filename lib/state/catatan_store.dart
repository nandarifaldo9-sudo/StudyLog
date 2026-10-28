import 'package:flutter/foundation.dart';

import '../data/catatan_repository.dart';
import '../models/catatan.dart';

/// Sumber data tunggal untuk semua layar.
///
/// M2: data hanya di memori. M3: setiap perubahan ditulis dulu ke
/// [CatatanRepository] (SQLite), baru daftar di memori diperbarui dan
/// notifyListeners() dipanggil agar Consumer/watch membangun ulang UI.
class CatatanStore extends ChangeNotifier {
  CatatanStore(this._repository);

  final CatatanRepository _repository;
  final List<HasilCatatan> _data = [];

  bool _sedangMemuat = false;
  String? _galat;
  bool _disposed = false;

  /// Semua catatan, terbaru di atas.
  List<HasilCatatan> get semua => List.unmodifiable(_data);

  int get jumlah => _data.length;

  bool get sedangMemuat => _sedangMemuat;

  /// Pesan galat terakhir saat memuat dari database (null jika baik-baik saja).
  String? get galat => _galat;

  int jumlahUntuk(String mataKuliah) =>
      _data.where((c) => c.mataKuliah == mataKuliah).length;

  HasilCatatan? cari(int id) {
    for (final c in _data) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Memuat seluruh catatan dari database. Dipanggil sekali saat app dibuka.
  Future<void> muat() async {
    _sedangMemuat = true;
    _galat = null;
    _beritahu();
    try {
      final hasil = await _repository.semua();
      _data
        ..clear()
        ..addAll(hasil);
    } catch (e) {
      _galat = 'Gagal memuat catatan: $e';
    } finally {
      _sedangMemuat = false;
      _beritahu();
    }
  }

  Future<void> tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  }) async {
    final baru = await _repository.tambah(
      mataKuliah: mataKuliah,
      judul: judul,
      isi: isi,
      waktu: waktu,
    );
    _data.insert(0, baru);
    _beritahu();
  }

  Future<void> ubah(int id,
      {required String judul, required String isi}) async {
    if (cari(id) == null) return;
    await _repository.ubah(id, judul: judul, isi: isi);
    final i = _data.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _data[i] = _data[i].copyWith(judul: judul, isi: isi);
    _beritahu();
  }

  Future<void> hapus(int id) async {
    await _repository.hapus(id);
    _data.removeWhere((c) => c.id == id);
    _beritahu();
  }

  void _beritahu() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
