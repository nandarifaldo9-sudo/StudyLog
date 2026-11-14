import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/data/memori_catatan_repository.dart';
import 'package:studylogform/main.dart';
import 'package:studylogform/models/catatan.dart';
import 'package:studylogform/widgets/catatan_card.dart';

final rabu = DateTime(2026, 10, 28, 8, 0); // hanya Kriptografi

class RepositoriCatatanTertunda extends MemoriCatatanRepository {
  final mulaiTambah = Completer<void>();
  final izinkanTambah = Completer<void>();

  @override
  Future<HasilCatatan> tambah({
    required String mataKuliah,
    required String judul,
    required String isi,
    required DateTime waktu,
  }) async {
    mulaiTambah.complete();
    await izinkanTambah.future;
    return super.tambah(
      mataKuliah: mataKuliah,
      judul: judul,
      isi: isi,
      waktu: waktu,
    );
  }
}

Future<void> bukaApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    StudyLogApp(now: () => rabu, repository: MemoriCatatanRepository()),
  );
  await tester.pumpAndSettle();
}

/// Dashboard -> Form -> Simpan -> kembali ke Dashboard.
Future<void> tambahCatatan(
  WidgetTester tester,
  String judul,
  String isi,
) async {
  await tester.tap(find.text('Catat sekarang'));
  await tester.pumpAndSettle();
  await tester.pump();
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), judul);
  await tester.enterText(fields.at(1), isi);
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
}

/// Dashboard -> Catatan -> Detail catatan.
Future<void> bukaDetail(WidgetTester tester, String judul) async {
  await tester.tap(find.text('Catatan'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(judul));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Daftar menampilkan catatan yang baru disimpan', (tester) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');

    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Semua Catatan'), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsOneWidget);
  });

  testWidgets('Detail kembali ke Catatan, lalu navigasi ke Dashboard', (
    tester,
  ) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');
    await bukaDetail(tester, 'Caesar Cipher');

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('Ubah'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Semua Catatan'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('StudyLog'), findsOneWidget);
  });

  testWidgets('Ubah catatan: Detail langsung memperlihatkan judul baru', (
    tester,
  ) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');
    await bukaDetail(tester, 'Caesar Cipher');

    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Ubah Catatan'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Vigenere');
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('Vigenere'), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsNothing);
  });

  testWidgets('Hapus: Batal tidak menghapus, Hapus menghapus', (tester) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');
    await bukaDetail(tester, 'Caesar Cipher');

    final tombolDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Hapus'),
    );

    // Batal
    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();
    expect(find.text('Hapus catatan?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Catatan'), findsOneWidget);

    // Setuju
    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(tombolDialog);
    await tester.pumpAndSettle();

    expect(find.text('Semua Catatan'), findsOneWidget);
    expect(find.byType(CatatanCard), findsNothing);
  });

  testWidgets('Catatan tetap ada saat app dibuka ulang (repository sama)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = MemoriCatatanRepository(); // meniru database yang bertahan

    await tester.pumpWidget(StudyLogApp(now: () => rabu, repository: repo));
    await tester.pumpAndSettle();
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');

    // "Tutup" app, lalu buka lagi dengan database yang sama.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(StudyLogApp(now: () => rabu, repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Caesar Cipher'), findsOneWidget);
    expect(find.byType(CatatanCard), findsOneWidget);
  });

  testWidgets('Form tidak dapat ditutup saat penyimpanan berlangsung', (
    tester,
  ) async {
    final repo = RepositoriCatatanTertunda();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(StudyLogApp(now: () => rabu, repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat sekarang'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Catatan tertunda',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi catatan.');
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await repo.mulaiTambah.future;

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Tambah Catatan'), findsOneWidget);

    repo.izinkanTambah.complete();
    await tester.pumpAndSettle();
    expect(find.text('StudyLog'), findsOneWidget);
    expect(await repo.semua(), hasLength(1));
  });
}
