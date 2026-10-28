/// Catatan yang sudah disimpan. Sejak M3 disimpan di SQLite (tabel `catatan`).
class HasilCatatan {
  final int id;
  final String mataKuliah;
  final String judul;
  final String isi;
  final DateTime waktu;

  const HasilCatatan({
    required this.id,
    required this.mataKuliah,
    required this.judul,
    required this.isi,
    required this.waktu,
  });

  /// Peta kolom SQLite. `waktu` disimpan sebagai teks ISO 8601.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'mata_kuliah': mataKuliah,
      'judul': judul,
      'isi': isi,
      'waktu': waktu.toIso8601String(),
    };
  }

  factory HasilCatatan.fromMap(Map<String, Object?> map) {
    return HasilCatatan(
      id: map['id'] as int,
      mataKuliah: map['mata_kuliah'] as String,
      judul: map['judul'] as String,
      isi: map['isi'] as String,
      waktu: DateTime.parse(map['waktu'] as String),
    );
  }

  HasilCatatan copyWith({String? judul, String? isi}) {
    return HasilCatatan(
      id: id,
      mataKuliah: mataKuliah,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      waktu: waktu,
    );
  }
}
