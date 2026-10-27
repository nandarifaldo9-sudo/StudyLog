import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/main.dart';
import 'package:studylogform/widgets/catatan_card.dart';

final rabu = DateTime(2026, 10, 28, 8, 0); // hanya Kriptografi

Future<void> bukaApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(StudyLogApp(now: () => rabu));
  await tester.pumpAndSettle();
}

/// Beranda -> Form -> SIMPAN -> kembali ke Beranda.
Future<void> tambahCatatan(
    WidgetTester tester, String judul, String isi) async {
  await tester.tap(find.text('TAMBAH CATATAN'));
  await tester.pumpAndSettle();
  await tester.pump();
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), judul);
  await tester.enterText(fields.at(1), isi);
  await tester.tap(find.text('SIMPAN'));
  await tester.pumpAndSettle();
}

/// Beranda -> Daftar -> Detail catatan pertama.
Future<void> bukaDetail(WidgetTester tester, String judul) async {
  await tester.tap(find.text('LIHAT SEMUA CATATAN'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(judul));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Daftar menampilkan catatan yang baru disimpan', (tester) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');

    await tester.tap(find.text('LIHAT SEMUA CATATAN'));
    await tester.pumpAndSettle();

    expect(find.text('Semua Catatan'), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsOneWidget);
  });

  testWidgets('Back stack: Detail -> Daftar -> Beranda', (tester) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');
    await bukaDetail(tester, 'Caesar Cipher');

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('UBAH'), findsOneWidget);
    expect(find.text('HAPUS'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Semua Catatan'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('StudyLog'), findsOneWidget);
  });

  testWidgets('Ubah catatan: Detail langsung memperlihatkan judul baru',
      (tester) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');
    await bukaDetail(tester, 'Caesar Cipher');

    await tester.tap(find.text('UBAH'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Ubah Catatan'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Vigenere');
    await tester.tap(find.text('SIMPAN PERUBAHAN'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('Vigenere'), findsOneWidget);
    expect(find.text('Caesar Cipher'), findsNothing);
  });

  testWidgets('Hapus: BATAL tidak menghapus, HAPUS menghapus', (tester) async {
    await bukaApp(tester);
    await tambahCatatan(tester, 'Caesar Cipher', 'Geser huruf.');
    await bukaDetail(tester, 'Caesar Cipher');

    final tombolDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('HAPUS'),
    );

    // Batal
    await tester.tap(find.text('HAPUS'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus catatan?'), findsOneWidget);
    await tester.tap(find.text('BATAL'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Catatan'), findsOneWidget);

    // Setuju
    await tester.tap(find.text('HAPUS'));
    await tester.pumpAndSettle();
    await tester.tap(tombolDialog);
    await tester.pumpAndSettle();

    expect(find.text('Semua Catatan'), findsOneWidget);
    expect(find.byType(CatatanCard), findsNothing);
  });
}