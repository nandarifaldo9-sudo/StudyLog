import 'package:flutter_test/flutter_test.dart';
import 'package:studylogform/state/catatan_store.dart';

void main() {
  final waktu = DateTime(2026, 10, 26, 19, 30);
  late CatatanStore store;

  setUp(() => store = CatatanStore());

  test('tambah: terbaru di atas dan listener dipanggil', () {
    var dipanggil = 0;
    store.addListener(() => dipanggil++);

    store.tambah(mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    store.tambah(mataKuliah: 'Kriptografi', judul: 'B', isi: 'b', waktu: waktu);

    expect(store.jumlah, 2);
    expect(store.semua.first.judul, 'B');
    expect(dipanggil, 2);
  });

  test('jumlahUntuk menghitung per mata kuliah', () {
    store.tambah(mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    store.tambah(
        mataKuliah: 'Jaringan Nirkabel', judul: 'B', isi: 'b', waktu: waktu);

    expect(store.jumlahUntuk('Kriptografi'), 1);
    expect(store.jumlahUntuk('Jaringan Nirkabel'), 1);
    expect(store.jumlahUntuk('Penalaran Komputer'), 0);
  });

  test('ubah mengganti judul dan isi tanpa mengubah id dan waktu', () {
    store.tambah(mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    final awal = store.semua.first;

    store.ubah(awal.id, judul: 'A2', isi: 'a2');

    final baru = store.cari(awal.id)!;
    expect(baru.judul, 'A2');
    expect(baru.isi, 'a2');
    expect(baru.id, awal.id);
    expect(baru.waktu, waktu);
  });

  test('hapus membuang catatan dan memberi tahu listener', () {
    store.tambah(mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    final id = store.semua.first.id;
    var dipanggil = 0;
    store.addListener(() => dipanggil++);

    store.hapus(id);

    expect(store.cari(id), isNull);
    expect(store.jumlah, 0);
    expect(dipanggil, 1);
  });
}