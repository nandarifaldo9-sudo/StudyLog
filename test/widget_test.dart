import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/main.dart';
import 'package:studylogform/theme/warna_mata_kuliah.dart';
import 'package:studylogform/widgets/catatan_card.dart';

final senin = DateTime(2026, 10, 26, 8, 0);
final rabu = DateTime(2026, 10, 28, 8, 0);
final sabtu = DateTime(2026, 10, 31, 8, 0);
final senin1930 = DateTime(2026, 10, 26, 19, 30); // SMBD berlangsung
final senin2030 = DateTime(2026, 10, 26, 20, 30); // TAB mulai tepat 20:30
final senin2230 = DateTime(2026, 10, 26, 22, 30); // semua selesai

Future<void> bukaApp(WidgetTester tester, DateTime waktu) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(StudyLogApp(now: () => waktu));
  await tester.pumpAndSettle();
}

/// Membuka form dari tombol TAMBAH CATATAN ke-[index] di dashboard.
Future<void> bukaForm(WidgetTester tester, int index) async {
  await tester.tap(find.text('TAMBAH CATATAN').at(index));
  await tester.pumpAndSettle();
  await tester.pump();
}

Future<void> isiForm(WidgetTester tester,
    {required String judul, required String isi}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), judul);
  await tester.enterText(fields.at(1), isi);
}

Color warnaCard(WidgetTester tester, int index) {
  final cards = tester
      .widgetList<Card>(
        find.descendant(
          of: find.byType(CatatanCard),
          matching: find.byType(Card),
        ),
      )
      .toList();
  return (cards[index].shape as RoundedRectangleBorder).side.color;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Senin: dashboard hanya menampilkan mata kuliah Senin',
      (tester) async {
    await bukaApp(tester, senin);

    expect(find.text('Sistem Manajemen Basis Data'), findsOneWidget);
    expect(find.text('Teknologi Aplikasi Bergerak'), findsOneWidget);
    expect(find.text('Kriptografi'), findsNothing);
    expect(find.text('TAMBAH CATATAN'), findsNWidgets(2));
    // Kode dan jam kuliah tampil di card.
    expect(find.text('111500 • 19:00 - 20:30'), findsOneWidget);
    expect(find.text('111600 • 20:30 - 22:00'), findsOneWidget);
  });

  testWidgets('Rabu: hanya Kriptografi yang tampil', (tester) async {
    await bukaApp(tester, rabu);

    expect(find.text('Kriptografi'), findsOneWidget);
    expect(find.text('TAMBAH CATATAN'), findsOneWidget);
  });

  testWidgets('Sabtu: tidak ada kuliah dan tidak ada tombol tambah',
      (tester) async {
    await bukaApp(tester, sabtu);

    expect(find.textContaining('Tidak ada kuliah hari ini'), findsOneWidget);
    expect(find.text('TAMBAH CATATAN'), findsNothing);
  });

  testWidgets('Form otomatis memakai mata kuliah terpilih tanpa dropdown',
      (tester) async {
    await bukaApp(tester, senin);
    await bukaForm(tester, 1); // Teknologi Aplikasi Bergerak

    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.text('Teknologi Aplikasi Bergerak'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2)); // judul + isi saja
  });

  testWidgets('T1: form kosong menampilkan pesan error', (tester) async {
    await bukaApp(tester, senin);
    await bukaForm(tester, 0);
    await tester.tap(find.text('TAMPILKAN CATATAN'));
    await tester.pump();

    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
    expect(find.text('Tambah Catatan'), findsOneWidget); // masih di form
  });

  testWidgets('T2: judul dan isi hanya spasi ditolak', (tester) async {
    await bukaApp(tester, senin);
    await bukaForm(tester, 0);
    await isiForm(tester, judul: '   ', isi: '   ');
    await tester.tap(find.text('TAMPILKAN CATATAN'));
    await tester.pump();

    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
  });

  testWidgets('T3: input valid kembali ke dashboard dengan card berwarna',
      (tester) async {
    await bukaApp(tester, rabu);
    await bukaForm(tester, 0);
    await isiForm(tester, judul: 'Caesar Cipher', isi: 'Geser huruf.');
    await tester.tap(find.text('TAMPILKAN CATATAN'));
    await tester.pumpAndSettle();

    expect(find.byType(CatatanCard), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsOneWidget);
    expect(find.text('Data ditampilkan (belum tersimpan permanen).'), findsOneWidget);
    expect(find.text('1 catatan'), findsOneWidget);
    expect(warnaCard(tester, 0), warnaMataKuliah['Kriptografi']);
  });

  testWidgets('Mata kuliah berbeda menghasilkan warna card berbeda',
      (tester) async {
    await bukaApp(tester, senin);

    await bukaForm(tester, 0);
    await isiForm(tester, judul: 'Normalisasi', isi: '1NF 2NF 3NF');
    await tester.tap(find.text('TAMPILKAN CATATAN'));
    await tester.pumpAndSettle();

    await bukaForm(tester, 1);
    await isiForm(tester, judul: 'Flutter', isi: 'Widget');
    await tester.tap(find.text('TAMPILKAN CATATAN'));
    await tester.pumpAndSettle();

    expect(find.byType(CatatanCard), findsNWidgets(2));
    // Terbaru di atas: index 0 = TAB, index 1 = SMBD.
    expect(warnaCard(tester, 0), warnaMataKuliah['Teknologi Aplikasi Bergerak']);
    expect(warnaCard(tester, 1), warnaMataKuliah['Sistem Manajemen Basis Data']);
    expect(warnaCard(tester, 0), isNot(warnaCard(tester, 1)));
  });

  testWidgets('Draft tersimpan lalu dihapus setelah catatan disimpan',
      (tester) async {
    await bukaApp(tester, senin);
    await bukaForm(tester, 0);
    await isiForm(tester, judul: 'Draft baru', isi: 'Belum selesai');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    var prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('draft_judul_Sistem Manajemen Basis Data'),
      'Draft baru',
    );

    await tester.tap(find.text('TAMPILKAN CATATAN'));
    await tester.pumpAndSettle();

    prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('draft_judul_Sistem Manajemen Basis Data'),
      isNull,
    );
  });

  testWidgets('Draft lama dipulihkan dan ditandai di dashboard',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'draft_judul_Kriptografi': 'Judul draft',
      'draft_isi_Kriptografi': 'Isi draft',
    });
    await bukaApp(tester, rabu);
    await tester.pump();

    expect(find.text('Ada draft'), findsOneWidget);

    await bukaForm(tester, 0);
    expect(find.text('Draft dipulihkan'), findsOneWidget);
    expect(find.text('Judul draft'), findsOneWidget);
    expect(find.text('Isi draft'), findsOneWidget);
  });

  testWidgets('Sebelum jam kuliah: semua akan datang, tanpa CATAT SEKARANG',
      (tester) async {
    await bukaApp(tester, senin); // 08:00

    expect(find.text('Akan datang'), findsNWidgets(2));
    expect(find.text('CATAT SEKARANG'), findsNothing);
  });

  testWidgets('Senin 19:30: SMBD berlangsung dan CATAT SEKARANG membukanya',
      (tester) async {
    await bukaApp(tester, senin1930);

    expect(find.text('Sedang berlangsung'), findsOneWidget);
    expect(find.text('Akan datang'), findsOneWidget);
    expect(find.text('CATAT SEKARANG'), findsOneWidget);

    await tester.tap(find.text('CATAT SEKARANG'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.text('Sistem Manajemen Basis Data'), findsOneWidget);
  });

  testWidgets('Senin 20:30: berpindah ke Teknologi Aplikasi Bergerak',
      (tester) async {
    await bukaApp(tester, senin2030);

    expect(find.text('Selesai'), findsOneWidget); // SMBD
    expect(find.text('Sedang berlangsung'), findsOneWidget); // TAB

    await tester.tap(find.text('CATAT SEKARANG'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Teknologi Aplikasi Bergerak'), findsOneWidget);
  });

  testWidgets('Senin 22:30: semua selesai, tanpa CATAT SEKARANG',
      (tester) async {
    await bukaApp(tester, senin2230);

    expect(find.text('Selesai'), findsNWidgets(2));
    expect(find.text('CATAT SEKARANG'), findsNothing);
    expect(find.text('TAMBAH CATATAN'), findsNWidgets(2)); // tetap bisa
  });
}
