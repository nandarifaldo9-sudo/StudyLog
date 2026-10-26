/// Catatan yang sudah disimpan (sementara di memori pada M1).
class HasilCatatan {
  final String mataKuliah;
  final String judul;
  final String isi;
  final DateTime waktu;

  const HasilCatatan({
    required this.mataKuliah,
    required this.judul,
    required this.isi,
    required this.waktu,
  });
}
