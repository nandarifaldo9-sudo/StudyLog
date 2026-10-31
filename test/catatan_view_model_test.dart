import 'package:flutter_test/flutter_test.dart';
import 'package:studylogform/data/catatan_repository.dart';
import 'package:studylogform/data/memori_catatan_repository.dart';
import 'package:studylogform/models/catatan.dart';
import 'package:studylogform/viewmodels/catatan_view_model.dart';

/// Repository yang selalu gagal, untuk menguji penanganan galat.
class _RepositoryGagal implements CatatanRepository {
  @override
  Future<List<HasilCatatan>> semua() async => throw Exception('db rusak');

  @override
  Future<HasilCatatan> tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  }) async =>
      throw Exception('db rusak');

  @override
  Future<void> ubah(int id,
          {required String judul, required String isi}) async =>
      throw Exception('db rusak');

  @override
  Future<void> hapus(int id) async => throw Exception('db rusak');
}

void main() {
  final waktu = DateTime(2026, 10, 26, 19, 30);
  late MemoriCatatanRepository repo;
  late CatatanViewModel store;

  setUp(() {
    repo = MemoriCatatanRepository();
    store = CatatanViewModel(repo);
  });

  test('tambah: terbaru di atas dan listener dipanggil', () async {
    var dipanggil = 0;
    store.addListener(() => dipanggil++);

    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'B', isi: 'b', waktu: waktu);

    expect(store.jumlah, 2);
    expect(store.semua.first.judul, 'B');
    expect(dipanggil, 2);
  });

  test('jumlahUntuk menghitung per mata kuliah', () async {
    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    await store.tambah(
        mataKuliah: 'Jaringan Nirkabel', judul: 'B', isi: 'b', waktu: waktu);

    expect(store.jumlahUntuk('Kriptografi'), 1);
    expect(store.jumlahUntuk('Jaringan Nirkabel'), 1);
    expect(store.jumlahUntuk('Penalaran Komputer'), 0);
  });

  test('ubah mengganti judul dan isi tanpa mengubah id dan waktu', () async {
    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    final awal = store.semua.first;

    await store.ubah(awal.id, judul: 'A2', isi: 'a2');

    final baru = store.cari(awal.id)!;
    expect(baru.judul, 'A2');
    expect(baru.isi, 'a2');
    expect(baru.id, awal.id);
    expect(baru.waktu, waktu);
  });

  test('hapus membuang catatan dan memberi tahu listener', () async {
    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    final id = store.semua.first.id;
    var dipanggil = 0;
    store.addListener(() => dipanggil++);

    await store.hapus(id);

    expect(store.cari(id), isNull);
    expect(store.jumlah, 0);
    expect(dipanggil, 1);
  });

  test('persistensi: store baru memuat catatan dari repository yang sama',
      () async {
    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu);
    await store.tambah(
        mataKuliah: 'Kriptografi', judul: 'B', isi: 'b', waktu: waktu);

    final storeBaru = CatatanViewModel(repo); // meniru app dibuka ulang
    expect(storeBaru.jumlah, 0);
    await storeBaru.muat();

    expect(storeBaru.jumlah, 2);
    expect(storeBaru.semua.first.judul, 'B'); // urutan terbaru di atas
    expect(storeBaru.sedangMemuat, isFalse);
    expect(storeBaru.galat, isNull);
  });

  test('muat yang gagal mengisi galat dan tidak melempar', () async {
    final rusak = CatatanViewModel(_RepositoryGagal());

    await rusak.muat();

    expect(rusak.galat, contains('Gagal memuat catatan'));
    expect(rusak.jumlah, 0);
    expect(rusak.sedangMemuat, isFalse);
  });

  test('tambah yang gagal melempar dan daftar tidak berubah', () async {
    final rusak = CatatanViewModel(_RepositoryGagal());

    await expectLater(
      rusak.tambah(
          mataKuliah: 'Kriptografi', judul: 'A', isi: 'a', waktu: waktu),
      throwsException,
    );
    expect(rusak.jumlah, 0);
  });
}
