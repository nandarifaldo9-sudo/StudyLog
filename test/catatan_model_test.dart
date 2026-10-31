import 'package:flutter_test/flutter_test.dart';
import 'package:studylogform/models/catatan.dart';

void main() {
  final waktu = DateTime(2026, 10, 26, 19, 30);

  test('toMap memakai nama kolom SQLite dan tanggal ISO 8601', () {
    final c = HasilCatatan(
      id: 3,
      mataKuliah: 'Kriptografi',
      judul: 'Caesar Cipher',
      isi: 'Geser huruf.',
      waktu: waktu,
    );

    expect(c.toMap(), {
      'id': 3,
      'mata_kuliah': 'Kriptografi',
      'judul': 'Caesar Cipher',
      'isi': 'Geser huruf.',
      'tanggal': waktu.toIso8601String(),
    });
  });

  test('fromMap(toMap) mengembalikan data yang sama', () {
    final asli = HasilCatatan(
      id: 9,
      mataKuliah: 'Jaringan Nirkabel',
      judul: 'Wi-Fi',
      isi: 'Standar 802.11',
      waktu: waktu,
    );

    final hasil = HasilCatatan.fromMap(asli.toMap());

    expect(hasil.id, 9);
    expect(hasil.mataKuliah, asli.mataKuliah);
    expect(hasil.judul, asli.judul);
    expect(hasil.isi, asli.isi);
    expect(hasil.waktu, asli.waktu);
  });

  test('copyWith hanya mengganti judul dan isi', () {
    final asli = HasilCatatan(
      id: 1,
      mataKuliah: 'Kriptografi',
      judul: 'Lama',
      isi: 'lama',
      waktu: waktu,
    );

    final baru = asli.copyWith(judul: 'Baru');

    expect(baru.judul, 'Baru');
    expect(baru.isi, 'lama');
    expect(baru.id, 1);
    expect(baru.mataKuliah, 'Kriptografi');
    expect(baru.waktu, waktu);
  });
}
