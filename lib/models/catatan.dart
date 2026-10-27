/// Catatan yang sudah disimpan (sementara di memori pada M2).
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