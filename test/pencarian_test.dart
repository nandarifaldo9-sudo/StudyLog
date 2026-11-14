import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/data/memori_catatan_repository.dart';
import 'package:studylogform/main.dart';
import 'package:studylogform/viewmodels/catatan_view_model.dart';
import 'package:studylogform/widgets/catatan_card.dart';

final rabu = DateTime(2026, 10, 28, 8, 0);

/// Repository berisi 3 catatan: 2 Kriptografi, 1 Jaringan Nirkabel.
Future<MemoriCatatanRepository> isiRepository() async {
  final repo = MemoriCatatanRepository();
  await repo.tambah(
    mataKuliah: 'Kriptografi',
    judul: 'Caesar Cipher',
    isi: 'Geser huruf.',
    waktu: rabu,
  );
  await repo.tambah(
    mataKuliah: 'Jaringan Nirkabel',
    judul: 'Topologi WLAN',
    isi: 'Infrastruktur dan ad hoc.',
    waktu: rabu,
  );
  await repo.tambah(
    mataKuliah: 'Kriptografi',
    judul: 'Vigenere',
    isi: 'Kunci berulang.',
    waktu: rabu,
  );
  return repo;
}

/// Buka tab Catatan.
Future<void> bukaDaftar(
  WidgetTester tester, {
  MemoriCatatanRepository? repository,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = repository ?? await isiRepository();
  await tester.pumpWidget(StudyLogApp(now: () => rabu, repository: repo));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Catatan'));
  await tester.pumpAndSettle();
}

Future<void> cari(WidgetTester tester, String kataKunci) async {
  await tester.enterText(find.byKey(const Key('kolomCari')), kataKunci);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CatatanViewModel.telusuri', () {
    late CatatanViewModel store;

    setUp(() async {
      store = CatatanViewModel(await isiRepository());
      await store.muat();
    });

    test('kata kunci kosong atau spasi mengembalikan semua catatan', () {
      expect(store.telusuri('').length, 3);
      expect(store.telusuri('   ').length, 3);
    });

    test('mencocokkan judul tanpa membedakan huruf besar/kecil', () {
      final hasil = store.telusuri('caESar');
      expect(hasil.length, 1);
      expect(hasil.first.judul, 'Caesar Cipher');
    });

    test('mencocokkan nama mata kuliah, terbaru di atas', () {
      final hasil = store.telusuri('kripto');
      expect(hasil.map((c) => c.judul).toList(), ['Vigenere', 'Caesar Cipher']);
    });

    test('kata kunci yang tidak cocok mengembalikan daftar kosong', () {
      expect(store.telusuri('zzz'), isEmpty);
    });

    test('isi catatan tidak ikut dicari', () {
      expect(store.telusuri('Geser'), isEmpty);
    });

    test('filter mata kuliah diterapkan bersama kata kunci', () {
      final hasil = store.telusuri('', mataKuliah: 'Kriptografi');
      expect(hasil.map((c) => c.judul).toList(), ['Vigenere', 'Caesar Cipher']);
      expect(store.telusuri('topologi', mataKuliah: 'Kriptografi'), isEmpty);
    });
  });

  testWidgets('Sebelum mencari: semua catatan tampil', (tester) async {
    await bukaDaftar(tester);

    expect(find.byType(CatatanCard), findsNWidgets(3));
    expect(find.byKey(const Key('kolomCari')), findsOneWidget);
  });

  testWidgets('Cari judul: hanya catatan yang cocok', (tester) async {
    await bukaDaftar(tester);
    await cari(tester, 'caesar');

    expect(find.byType(CatatanCard), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsOneWidget);
    expect(find.text('1 catatan ditemukan'), findsOneWidget);
  });

  testWidgets('Cari mata kuliah: semua catatan mata kuliah itu', (
    tester,
  ) async {
    await bukaDaftar(tester);
    await cari(tester, 'krip');

    expect(find.byType(CatatanCard), findsNWidgets(2));
    expect(find.text('Topologi WLAN'), findsNothing);
  });

  testWidgets('Filter menyertakan mata kuliah khusus yang sudah dicatat', (
    tester,
  ) async {
    final repo = await isiRepository();
    await repo.tambah(
      mataKuliah: 'Kelas Pilihan',
      judul: 'Catatan kelas pilihan',
      isi: 'Materi.',
      waktu: rabu,
    );
    await bukaDaftar(tester, repository: repo);

    final filter = find.byKey(const Key('filter_Kelas Pilihan'));
    await tester.scrollUntilVisible(
      filter,
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('filterScroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(filter);
    await tester.pumpAndSettle();
    expect(filter, findsOneWidget);
    await tester.tap(filter);
    await tester.pumpAndSettle();

    expect(find.byType(CatatanCard), findsOneWidget);
    expect(find.text('Catatan kelas pilihan'), findsOneWidget);
  });

  testWidgets('Tidak ada yang cocok: tampil pesan', (tester) async {
    await bukaDaftar(tester);
    await cari(tester, 'zzz');

    expect(find.byType(CatatanCard), findsNothing);
    expect(find.textContaining('Tidak ada catatan yang cocok'), findsOneWidget);
  });

  testWidgets('Tombol hapus pencarian mengembalikan semua catatan', (
    tester,
  ) async {
    await bukaDaftar(tester);
    await cari(tester, 'caesar');
    expect(find.byType(CatatanCard), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.byType(CatatanCard), findsNWidgets(3));
  });

  testWidgets('Hasil pencarian bisa dibuka ke Detail', (tester) async {
    await bukaDaftar(tester);
    await cari(tester, 'topologi');

    await tester.tap(find.text('Topologi WLAN'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('Infrastruktur dan ad hoc.'), findsOneWidget);
  });
}
