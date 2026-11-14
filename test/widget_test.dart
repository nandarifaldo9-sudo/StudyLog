import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/data/memori_catatan_repository.dart';
import 'package:studylogform/main.dart';
import 'package:studylogform/widgets/catatan_card.dart';

final senin = DateTime(2026, 10, 26, 8, 0);
final rabu = DateTime(2026, 10, 28, 8, 0);
final sabtu = DateTime(2026, 10, 31, 8, 0);
final senin1930 = DateTime(2026, 10, 26, 19, 30);
final senin2030 = DateTime(2026, 10, 26, 20, 30);
final senin2230 = DateTime(2026, 10, 26, 22, 30);

Future<void> bukaApp(WidgetTester tester, DateTime waktu) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    StudyLogApp(now: () => waktu, repository: MemoriCatatanRepository()),
  );
  await tester.pumpAndSettle();
}

Future<void> bukaForm(WidgetTester tester) async {
  await tester.tap(find.text('Catat sekarang'));
  await tester.pumpAndSettle();
  await tester.pump();
}

Future<void> isiForm(
  WidgetTester tester, {
  required String judul,
  required String isi,
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), judul);
  await tester.enterText(fields.at(1), isi);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Dashboard menampilkan ringkasan dan kuliah berikutnya', (
    tester,
  ) async {
    await bukaApp(tester, senin);

    expect(find.text('Selamat pagi'), findsOneWidget);
    expect(find.text('Kuliah hari ini'), findsOneWidget);
    expect(find.text('Catatan hari ini'), findsOneWidget);
    expect(find.text('Berikutnya hari ini'), findsOneWidget);
    expect(find.text('19:00 - 20:30 • 111500'), findsOneWidget);
    expect(find.text('Catat sekarang'), findsOneWidget);
  });

  testWidgets('Kalender menandai hari libur akademik dan memilih tanggalnya', (
    tester,
  ) async {
    await bukaApp(tester, DateTime(2026, 8, 17, 8));
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Hari Kemerdekaan RI'), findsOneWidget);
    final labelTanggal = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('pilihTanggalJadwal')),
        matching: find.byType(Text),
      ),
    );
    expect(labelTanggal.maxLines, 1);
    expect(labelTanggal.softWrap, isFalse);

    await tester.tap(find.byKey(const Key('pilihTanggalJadwal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tanggal_2026-08-25')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tanggal_2026-08-25')));
    await tester.pump();
    expect(find.text('Hari libur akademik'), findsOneWidget);
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    expect(find.text('25 Agu 2026'), findsOneWidget);
  });

  testWidgets('Kalender dapat dibuka pada layar ponsel sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      StudyLogApp(now: () => senin, repository: MemoriCatatanRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pilihTanggalJadwal')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Jadwal mingguan yang ada dapat dipindah dan dihapus', (
    tester,
  ) async {
    await bukaApp(tester, senin);
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kelolaJadwal')));
    await tester.pumpAndSettle();
    expect(find.text('Tambah mata kuliah'), findsOneWidget);
    expect(find.text('Tambah mingguan'), findsNothing);

    await tester.tap(find.byKey(const Key('menuMingguan_111500')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah atau pindahkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senin').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rabu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('simpanJadwal')));
    await tester.pumpAndSettle();

    expect(find.text('Sistem Manajemen Basis Data'), findsNothing);
    expect(find.text('Teknologi Aplikasi Bergerak'), findsOneWidget);
    await tester.tap(find.byKey(const Key('menuMingguan_111600')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus mingguan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(find.text('Teknologi Aplikasi Bergerak'), findsNothing);
    expect(find.text('Belum ada mata kuliah'), findsOneWidget);
  });

  testWidgets('Kelas untuk satu tanggal ditambahkan dari Kelola Jadwal', (
    tester,
  ) async {
    await bukaApp(tester, DateTime(2026, 11, 14, 8));
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah kelas khusus hari ini'), findsNothing);

    await tester.tap(find.byKey(const Key('kelolaJadwal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pilihTanggalKhusus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tanggal_2026-11-29')));
    await tester.pump();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    expect(find.text('Minggu, 29 Nov 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tambahMataKuliah')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kode mata kuliah'),
      'SPC902',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama mata kuliah'),
      'Kelas Satu Kali',
    );
    await tester.tap(find.byKey(const Key('simpanJadwal')));
    await tester.pumpAndSettle();

    expect(find.text('Kelas Satu Kali'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pilihTanggalJadwal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tanggal_2026-11-29')));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    expect(find.text('Kelas Satu Kali'), findsOneWidget);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Kelas khusus berikutnya'), findsOneWidget);
    expect(find.text('Kelas Satu Kali'), findsWidgets);
    expect(find.textContaining('Minggu, 29 November 2026'), findsOneWidget);
  });

  testWidgets('Halaman Jadwal tidak menampilkan card Hari Minggu', (
    tester,
  ) async {
    await bukaApp(tester, DateTime(2026, 11, 29, 8));
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Minggu • 0 mata kuliah'), findsOneWidget);
    expect(find.text('Hari Minggu'), findsNothing);
  });

  testWidgets('Jadwal mengikuti tanggal baru setelah tengah malam', (
    tester,
  ) async {
    var sekarang = DateTime(2026, 10, 26, 23, 59);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      StudyLogApp(now: () => sekarang, repository: MemoriCatatanRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    expect(find.text('26 Okt 2026'), findsOneWidget);

    sekarang = DateTime(2026, 10, 27);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(find.text('27 Okt 2026'), findsOneWidget);
  });

  testWidgets('Jadwal menampilkan draft mata kuliah untuk tanggal terpilih', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'draft_judul_Penalaran Komputer': 'Catatan draft',
      'draft_isi_Penalaran Komputer': 'Materi yang belum selesai',
    });
    await bukaApp(tester, senin);
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hari berikutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Penalaran Komputer'), findsOneWidget);
    expect(find.text('Ada draft'), findsOneWidget);
  });

  testWidgets('Dashboard membuka form untuk kuliah yang berlangsung', (
    tester,
  ) async {
    await bukaApp(tester, senin1930);

    expect(find.text('Sedang berlangsung'), findsOneWidget);
    await bukaForm(tester);

    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.text('Sistem Manajemen Basis Data'), findsOneWidget);
  });

  testWidgets('Akhir pekan bisa membuka form pada tanggal kuliah berikutnya', (
    tester,
  ) async {
    await bukaApp(tester, sabtu);

    expect(find.text('Kuliah hari ini'), findsOneWidget);
    expect(find.text('Kuliah berikutnya • Senin'), findsOneWidget);
    await tester.tap(find.text('Catat untuk tanggal ini'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.text('Sistem Manajemen Basis Data'), findsOneWidget);
  });

  testWidgets(
    'Jadwal tanggal lampau bisa dicatat sesuai mata kuliah hari itu',
    (tester) async {
      await bukaApp(tester, senin);
      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah catatan'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Hari sebelumnya'));
      await tester.pumpAndSettle();
      expect(find.text('25 Okt 2026'), findsOneWidget);
      expect(find.text('Tidak ada jadwal untuk tanggal ini'), findsOneWidget);

      await tester.tap(find.byTooltip('Hari berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('26 Okt 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Hari berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('27 Okt 2026'), findsOneWidget);
      expect(find.text('Penalaran Komputer'), findsOneWidget);
      expect(find.text('Terkunci'), findsNothing);

      await tester.tap(find.text('Tambah catatan').first);
      await tester.pumpAndSettle();
      expect(find.text('Tambah Catatan'), findsOneWidget);
      expect(find.text('27 Okt 2026'), findsOneWidget);
      expect(find.text('Penalaran Komputer'), findsOneWidget);
    },
  );

  testWidgets('Mengubah tanggal catatan memperbarui mata kuliah terjadwal', (
    tester,
  ) async {
    await bukaApp(tester, rabu);
    await bukaForm(tester);

    await tester.tap(find.byKey(const Key('pilihTanggal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tanggal_2026-10-27')));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(find.text('27 Okt 2026'), findsOneWidget);
    expect(find.text('Penalaran Komputer'), findsOneWidget);
    expect(find.text('Kriptografi'), findsNothing);

    await isiForm(tester, judul: 'Catatan terlambat', isi: 'Materi kemarin.');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan terlambat'), findsOneWidget);
    expect(find.textContaining('27 Okt 2026'), findsOneWidget);
  });

  testWidgets('Tambah dari tab Catatan bisa mengisi tanggal kuliah lampau', (
    tester,
  ) async {
    await bukaApp(tester, sabtu);
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(
      find.text('Belum ada mata kuliah pada tanggal ini.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('pilihTanggal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tanggal_2026-10-26')));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(find.text('26 Okt 2026'), findsOneWidget);
    expect(find.text('Sistem Manajemen Basis Data'), findsOneWidget);
    await isiForm(tester, judul: 'Catatan kemarin', isi: 'Materi tertinggal.');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan kemarin'), findsOneWidget);
  });

  testWidgets('Form menampilkan error untuk judul dan isi kosong', (
    tester,
  ) async {
    await bukaApp(tester, senin);
    await bukaForm(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
  });

  testWidgets('Input hanya spasi ditolak', (tester) async {
    await bukaApp(tester, senin);
    await bukaForm(tester);
    await isiForm(tester, judul: '   ', isi: '   ');
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
  });

  testWidgets('Catatan yang disimpan muncul pada dashboard dan daftar', (
    tester,
  ) async {
    await bukaApp(tester, rabu);
    await bukaForm(tester);
    await isiForm(tester, judul: 'Caesar Cipher', isi: 'Geser huruf.');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.byType(CatatanCard), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsOneWidget);
    expect(find.text('Catatan berhasil disimpan'), findsOneWidget);

    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Semua Catatan'), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsOneWidget);
  });

  testWidgets('Draft tersimpan dan dihapus setelah catatan disimpan', (
    tester,
  ) async {
    await bukaApp(tester, senin);
    await bukaForm(tester);
    await isiForm(tester, judul: 'Draft baru', isi: 'Belum selesai');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    var prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('draft_judul_Sistem Manajemen Basis Data'),
      'Draft baru',
    );

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('draft_judul_Sistem Manajemen Basis Data'), isNull);
  });

  testWidgets('Dashboard menunjukkan jumlah draft dan form memulihkannya', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'draft_judul_Kriptografi': 'Judul draft',
      'draft_isi_Kriptografi': 'Isi draft',
    });
    await bukaApp(tester, rabu);

    expect(find.text('1'), findsWidgets);
    await bukaForm(tester);
    expect(find.text('Draft dipulihkan'), findsOneWidget);
    expect(find.text('Judul draft'), findsOneWidget);
    expect(find.text('Isi draft'), findsOneWidget);
  });

  testWidgets('Kuliah berikutnya hari ini tersedia sebelum jam kuliah', (
    tester,
  ) async {
    await bukaApp(tester, senin);

    expect(find.text('Berikutnya hari ini'), findsOneWidget);
    await bukaForm(tester);
    expect(find.text('Sistem Manajemen Basis Data'), findsOneWidget);
  });

  testWidgets('Jam 20:30 memilih Teknologi Aplikasi Bergerak', (tester) async {
    await bukaApp(tester, senin2030);

    expect(find.text('Teknologi Aplikasi Bergerak'), findsNWidgets(2));
    await bukaForm(tester);
    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.text('Teknologi Aplikasi Bergerak'), findsOneWidget);
  });

  testWidgets(
    'Setelah kuliah hari ini, form tetap tersedia untuk jadwal berikutnya',
    (tester) async {
      await bukaApp(tester, senin2230);

      expect(find.text('Kuliah berikutnya • Selasa'), findsOneWidget);
      await tester.tap(find.text('Catat untuk tanggal ini'));
      await tester.pumpAndSettle();
      expect(find.text('Penalaran Komputer'), findsOneWidget);
    },
  );
}
