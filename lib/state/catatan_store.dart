import 'package:flutter/foundation.dart';

import '../models/catatan.dart';

/// Sumber data tunggal untuk semua layar (state sementara di memori).
/// Setiap perubahan memanggil notifyListeners() agar Consumer/watch
/// membangun ulang UI.
class CatatanStore extends ChangeNotifier {
  final List<HasilCatatan> _data = [];
  int _idBerikutnya = 1;

  /// Semua catatan, terbaru di atas.
  List<HasilCatatan> get semua => List.unmodifiable(_data);

  int get jumlah => _data.length;

  int jumlahUntuk(String mataKuliah) =>
      _data.where((c) => c.mataKuliah == mataKuliah).length;

  HasilCatatan? cari(int id) {
    for (final c in _data) {
      if (c.id == id) return c;
    }
    return null;
  }

  void tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  }) {
    _data.insert(
      0,
      HasilCatatan(
        id: _idBerikutnya++,
        mataKuliah: mataKuliah,
        judul: judul,
        isi: isi,
        waktu: waktu,
      ),
    );
    notifyListeners();
  }

  void ubah(int id, {required String judul, required String isi}) {
    final i = _data.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _data[i] = _data[i].copyWith(judul: judul, isi: isi);
    notifyListeners();
  }

  void hapus(int id) {
    _data.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}